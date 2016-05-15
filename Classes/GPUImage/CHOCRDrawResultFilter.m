//
//  CHOCRDrawResultFilter.m
//  CHOCR
//
//  Created by Chris Hanshew on 2/13/16.
//  Copyright © 2016 Chris Hanshew Software, LLC. All rights reserved.
//

#import <OpenGLES/gltypes.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CHOCRDrawResultFilter.h"
#import "CHResult.h"

@interface CHOCRDrawResultFilter () {
    GLint lineWidthUniform, lineColorUniform;
    GLfloat _widthUniform, _heightUniform;
    GLfloat *lineCoordinates;
    dispatch_queue_t _resultsAccessQueue;
    GLuint _projectionUniform;
    CATransform3D _transform3D;
}

@end

NSString *const kCHOCRDrawRectVertexShader = SHADER_STRING
(
        uniform float width;
        uniform float height;
        attribute vec4 position;

        void main()
        {
            gl_Position =
                    vec4(position.x * 2.0 / width - 1.0,
                    position.y * 2.0 / height - 1.0,
                    position.z,
                    1.0);
        }
);

NSString *const kCHOCRDrawRectFragmentShader = SHADER_STRING
(
 //uniform vec3 lineColor;
 
 void main()
 {
     gl_FragColor = vec4(1.0,0,0, 1.0);
 }
);

@implementation CHOCRDrawResultFilter

- (id)init{
    
    self = [super initWithVertexShaderFromString:kCHOCRDrawRectVertexShader fragmentShaderFromString:kCHOCRDrawRectFragmentShader];
    if (self) {
        _resultsAccessQueue = dispatch_queue_create("com.chrishanshew.gpuocr.resultsaccessqueue", DISPATCH_QUEUE_CONCURRENT);
        _results = [NSArray array];
    }
    return self;
}

-(void)forceProcessingAtSize:(CGSize)frameSize {
    [super forceProcessingAtSize:frameSize];
    runSynchronouslyOnVideoProcessingQueue(^{
        _widthUniform = [filterProgram uniformIndex:@"width"];
        _heightUniform = [filterProgram uniformIndex:@"height"];
        [self setFloat:frameSize.width forUniform:_widthUniform program:filterProgram];
        [self setFloat:frameSize.height forUniform:_heightUniform program:filterProgram];
        glViewport(0, 0, frameSize.width, frameSize.height);
    });
}

- (void)setResults:(NSArray *)results {
    dispatch_barrier_async(_resultsAccessQueue, ^{
        NSUInteger length = results.count <= 512 ? results.count : 511;
        _results = [NSArray arrayWithArray:[results subarrayWithRange: NSMakeRange(0, length)]];
    });
}

- (NSArray *)getResults {
    __block NSArray *results;
    dispatch_sync(_resultsAccessQueue, ^{
        results = [NSArray arrayWithArray:_results];
    });
    return results;
}


-(void)renderResultsWithFrameTime:(CMTime)frameTime {
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

        CGRect rect;
        CGPoint leftStart, leftEnd, topEnd, rightEnd;

        NSUInteger currentVertexIndex = 0;

        for (CHResult *result in _results) {

            rect = result.rect;

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
        glDrawArrays(GL_LINES, 0, ((unsigned int)_results.count * 8));

        glDisable(GL_BLEND);

        [self informTargetsAboutNewFrameAtTime:frameTime];
        self.preventRendering = NO;
    });
}

@end
