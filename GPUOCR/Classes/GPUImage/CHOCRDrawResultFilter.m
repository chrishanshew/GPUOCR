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
#import "Result.h"

@interface CHOCRDrawResultFilter () {
    GLint lineWidthUniform, lineColorUniform;
    GLfloat *lineCoordinates;
    dispatch_queue_t _resultsAccessQueue;
    GLuint _projectionUniform;
    CATransform3D _transform3D;
}

@end

NSString *const kCHOCRDrawRectVertexShader = SHADER_STRING
(
        attribute vec4 position;
        uniform mat4 projection;

        void main()
        {
            gl_Position =
                    vec4(position.x * 2.0 / 720.0 - 1.0,
                    position.y * -2.0 / 1280.0 + 1.0,
                    position.z,
                    1.0) * projection;
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

- (id)init {
    
    self = [super initWithVertexShaderFromString:kCHOCRDrawRectVertexShader fragmentShaderFromString:kCHOCRDrawRectFragmentShader];
    if (self) {
        _resultsAccessQueue = dispatch_queue_create("com.chrishanshew.gpuocr.resultsaccessqueue", DISPATCH_QUEUE_CONCURRENT);
        _results = [NSArray array];
        _projectionUniform = [filterProgram uniformIndex:@"projection"];
    }
    return self;
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
        lineCoordinates = calloc(512 * 10, sizeof(GLfloat));
    }

    runSynchronouslyOnVideoProcessingQueue(^{
        self.preventRendering = YES;

        [GPUImageContext setActiveShaderProgram:filterProgram];
        
        outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
        [outputFramebuffer activateFramebuffer];

        CGSize filterFrameSize = self.outputFrameSize;

        CGPoint leftStart, leftEnd, topEnd, rightEnd;

        NSUInteger currentVertexIndex = 0;

        for (Result *result in _results) {

            CGRect normalizedRect = result.rect;

            leftStart = CGPointMake(normalizedRect.origin.x, normalizedRect.origin.y + normalizedRect.size.height);
            leftEnd = CGPointMake(normalizedRect.origin.x, normalizedRect.origin.y);
            topEnd =  CGPointMake(normalizedRect.origin.x + normalizedRect.size.width, normalizedRect.origin.y);
            rightEnd = CGPointMake(topEnd.x, normalizedRect.origin.y + normalizedRect.size.height);

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

            // Baseline
            // Start
            lineCoordinates[currentVertexIndex++] = result.start.x;
            lineCoordinates[currentVertexIndex++] = result.start.y;
            // End
            lineCoordinates[currentVertexIndex++] = result.end.x;
            lineCoordinates[currentVertexIndex++] = result.end.y;
        }

        [self setTransform3D:CATransform3DMakeRotation(M_PI, 0.0, 0.0, 1.0)];

        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);

        glViewport(0, 0, filterFrameSize.width, filterFrameSize.height);

        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_ONE, GL_ONE);
        glEnable(GL_BLEND);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, lineCoordinates);
        glDrawArrays(GL_LINES, 0, ((unsigned int)_results.count * 10));

        glDisable(GL_BLEND);

        [self informTargetsAboutNewFrameAtTime:frameTime];
        self.preventRendering = NO;
    });
}

- (void)setTransform3D:(CATransform3D)newValue;
{
    _transform3D = newValue;

    GPUMatrix4x4 temporaryMatrix;

    [self convert3DTransform:&_transform3D toMatrix:&temporaryMatrix];
    [self setMatrix4f:temporaryMatrix forUniform:_projectionUniform program:filterProgram];
}

- (void)convert3DTransform:(CATransform3D *)transform3D toMatrix:(GPUMatrix4x4 *)matrix;
{
    //	struct CATransform3D
    //	{
    //		CGFloat m11, m12, m13, m14;
    //		CGFloat m21, m22, m23, m24;
    //		CGFloat m31, m32, m33, m34;
    //		CGFloat m41, m42, m43, m44;
    //	};

    GLfloat *mappedMatrix = (GLfloat *)matrix;

    mappedMatrix[0] = (GLfloat)transform3D->m11;
    mappedMatrix[1] = (GLfloat)transform3D->m12;
    mappedMatrix[2] = (GLfloat)transform3D->m13;
    mappedMatrix[3] = (GLfloat)transform3D->m14;
    mappedMatrix[4] = (GLfloat)transform3D->m21;
    mappedMatrix[5] = (GLfloat)transform3D->m22;
    mappedMatrix[6] = (GLfloat)transform3D->m23;
    mappedMatrix[7] = (GLfloat)transform3D->m24;
    mappedMatrix[8] = (GLfloat)transform3D->m31;
    mappedMatrix[9] = (GLfloat)transform3D->m32;
    mappedMatrix[10] = (GLfloat)transform3D->m33;
    mappedMatrix[11] = (GLfloat)transform3D->m34;
    mappedMatrix[12] = (GLfloat)transform3D->m41;
    mappedMatrix[13] = (GLfloat)transform3D->m42;
    mappedMatrix[14] = (GLfloat)transform3D->m43;
    mappedMatrix[15] = (GLfloat)transform3D->m44;
}


@end
