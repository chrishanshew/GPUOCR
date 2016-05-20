//
//  CHRegionGenerator.m
//  CHOCR
//
//  Created by Chris Hanshew on 2/13/16.
//  Copyright © 2016 Chris Hanshew Software, LLC. All rights reserved.
//

#import <OpenGLES/gltypes.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CHRegionGenerator.h"

@interface CHRegionGenerator () {
    GLfloat _lineWidth;
    GLfloat _colorUniform;
    GLfloat *lineCoordinates;
    dispatch_queue_t _resultsAccessQueue;
    NSArray *_regions;
    CGAffineTransform _regionTransform;
}

- (CGAffineTransform) transformFromRectToRect:(CGRect) fromRect toRect:(CGRect)toRect;

@end

NSString *const kCHOCRDrawRectVertexShader = SHADER_STRING
(
        attribute vec4 position;

        void main()
        {
            gl_Position = vec4(((position.xy * 2.0) - 1.0), 0.0, 1.0);
        }
);

NSString *const kCHOCRDrawRectFragmentShader = SHADER_STRING
(
        uniform lowp vec4 lineColor;
 
 void main()
 {
     gl_FragColor = lineColor;
 }
);

GPUVector4 const kDefaultLineColor = {1.0, 0.0, 0.0, 1.0};

@implementation CHRegionGenerator

- (id)init{
    
    self = [super initWithVertexShaderFromString:kCHOCRDrawRectVertexShader fragmentShaderFromString:kCHOCRDrawRectFragmentShader];
    if (self) {
        _resultsAccessQueue = dispatch_queue_create("com.chrishanshew.gpuocr.resultsaccessqueue", DISPATCH_QUEUE_CONCURRENT);
        _regions = [NSArray array];

        runSynchronouslyOnVideoProcessingQueue(^{
            _colorUniform =[filterProgram uniformIndex:@"lineColor"];
        });
    }
    return self;
}

-(void)forceProcessingAtSize:(CGSize)frameSize {
    [super forceProcessingAtSize:frameSize];
    CGRect frameRect = CGRectMake(0,0, frameSize.width, frameSize.height);
    CGRect openGLRect = CGRectMake(0,0,1,1);
    _regionTransform = [self transformFromRectToRect:frameRect toRect:openGLRect];
}

-(void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize {
    [super forceProcessingAtSizeRespectingAspectRatio:frameSize];
    CGRect frameRect = CGRectMake(0,0, frameSize.width, frameSize.height);
    CGRect openGLRect = CGRectMake(0,0,1,1);
    _regionTransform = [self transformFromRectToRect:frameRect toRect:openGLRect];
}

- (void)setRegions:(NSArray *)results {
    dispatch_barrier_async(_resultsAccessQueue, ^{
        NSUInteger length = results.count <= 512 ? results.count : 511;
        _regions = [NSArray arrayWithArray:[results subarrayWithRange: NSMakeRange(0, length)]];
    });
}

-(void)addRegion:(CHRegion *)region {
    dispatch_barrier_async(_resultsAccessQueue, ^{
        if (_regions.count <= 512) {
            _regions = [_regions arrayByAddingObject:region];
        }
    });
}

- (NSArray *)getRegions {
    __block NSArray *regions;
    dispatch_sync(_resultsAccessQueue, ^{
        regions = [NSArray arrayWithArray:_regions];
    });
    return regions;
}


-(void)renderRegionsWithFrameTime:(CMTime)frameTime {
    if (self.preventRendering)
    {
        return;
    }

    if (lineCoordinates == NULL)
    {
        lineCoordinates = calloc(512 * (8 * 2), sizeof(GLfloat));
    }

    runSynchronouslyOnVideoProcessingQueue(^{
        self.preventRendering = YES;

        [GPUImageContext setActiveShaderProgram:filterProgram];

        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
        [outputFramebuffer activateFramebuffer];

        CGPoint leftStart, leftEnd, topEnd, rightEnd;

        NSUInteger currentVertexIndex = 0;

        for (CHRegion *region in [self getRegions]) {
            CGRect rect = CGRectApplyAffineTransform(region.rect, _regionTransform);

            leftStart = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
            leftEnd = CGPointMake(rect.origin.x, rect.origin.y);
            topEnd =  CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
            rightEnd = CGPointMake(topEnd.x, rect.origin.y + rect.size.height);

            // Left
            // Start
            lineCoordinates[currentVertexIndex++] = leftStart.x;
            lineCoordinates[currentVertexIndex++] = leftStart.y;
            // End
            lineCoordinates[currentVertexIndex++] = leftEnd.x;
            lineCoordinates[currentVertexIndex++] = leftEnd.y;

            // Top
            // Start
            lineCoordinates[currentVertexIndex++] = leftEnd.x;
            lineCoordinates[currentVertexIndex++] = leftEnd.y;
            // End
            lineCoordinates[currentVertexIndex++] = topEnd.x;
            lineCoordinates[currentVertexIndex++] = topEnd.y;

            // Right
            // Start
            lineCoordinates[currentVertexIndex++] = topEnd.x;
            lineCoordinates[currentVertexIndex++] = topEnd.y;
            // End
            lineCoordinates[currentVertexIndex++] = rightEnd.x;
            lineCoordinates[currentVertexIndex++] = rightEnd.y;

            // Bottom
            // Start
            lineCoordinates[currentVertexIndex++] = rightEnd.x;
            lineCoordinates[currentVertexIndex++] = rightEnd.y;
            // End
            lineCoordinates[currentVertexIndex++] = leftStart.x;
            lineCoordinates[currentVertexIndex++] = leftStart.y;
        }

        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);

        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_ONE, GL_ONE);
        glEnable(GL_BLEND);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, lineCoordinates);
        glDrawArrays(GL_LINES, 0, ((unsigned int)_regions.count * 8));

        glDisable(GL_BLEND);

        [self informTargetsAboutNewFrameAtTime:frameTime];
        self.preventRendering = NO;
    });
}

-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
    GPUVector4 lineColor = {red, green, blue, alpha};
    [self setVec4:lineColor forUniform:_colorUniform program:filterProgram];
}

-(void)setLineWidth:(float)width {
    runSynchronouslyOnVideoProcessingQueue(^{
        _lineWidth = width;
        [GPUImageContext setActiveShaderProgram:filterProgram];
        glLineWidth(_lineWidth);
    });
}

- (CGAffineTransform) transformFromRectToRect:(CGRect) fromRect toRect:(CGRect)toRect {
    CGAffineTransform trans1 = CGAffineTransformMakeTranslation(-fromRect.origin.x, -fromRect.origin.y);
    CGAffineTransform scale = CGAffineTransformMakeScale(toRect.size.width/fromRect.size.width, toRect.size.height/fromRect.size.height);
    CGAffineTransform trans2 = CGAffineTransformMakeTranslation(toRect.origin.x, toRect.origin.y);
    return CGAffineTransformConcat(CGAffineTransformConcat(trans1, scale), trans2);
}

@end
