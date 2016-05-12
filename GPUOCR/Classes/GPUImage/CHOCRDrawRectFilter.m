//
//  CHOCRDrawRectFilter.m
//  CHOCR
//
//  Created by Chris Hanshew on 2/13/16.
//  Copyright © 2016 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHOCRDrawRectFilter.h"

@interface CHOCRDrawRectFilter ()

@property(nonatomic, readonly) CGRect rect;

@end

NSString *const kCHOCRDrawRectVertexShader = SHADER_STRING
(
// uniform lowp vec3 crosshairColor;
// 
// varying highp vec2 centerLocation;
// varying highp float pointSpacing;
// 
// void main()
// {
//     crosshairColor = vec3(1.0,0,0);
//     centerLocation = vec2(1.0, 1.0);
//     lowp vec2 distanceFromCenter = abs(centerLocation - gl_PointCoord.xy);
//     lowp float axisTest = step(pointSpacing, gl_PointCoord.y) * step(distanceFromCenter.x, 0.09) + step(pointSpacing, gl_PointCoord.x) * step(distanceFromCenter.y, 0.09);
//     
//     gl_FragColor = vec4(crosshairColor * axisTest, axisTest);
//     //     gl_FragColor = vec4(distanceFromCenterInX, distanceFromCenterInY, 0.0, 1.0);
// }
 
 void main()
  {
      //     GLfloat vertices[] = ({-1, -1, 0, // bottom left corner
      //         -1,  1, 0, // top left corner
      //         1,  1, 0, // top right corner
      //         1, -1, 0}); // bottom right corner
      //     
      //     GLubyte indices[] = ({0,1,2, // first triangle (bottom left - top left - top right)
      //         0,2,3}); // second triangle (bottom left - top right - bottom right)
      //     
      //     glVertexPointer(3, GL_FLOAT, 0, vertices);
      //     glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);
      

      glVertexPointer(2, GL_FLOAT, 0, vec4(.5, .5, .5, .5));
      glDrawArrays(GL_LINES, 0, 2);
  }
 );

NSString *const kCHOCRDrawRectFragmentShader = SHADER_STRING
(
        void main()
        {
//            GLfloat vertices[] = ({-1, -1, 0, // bottom left corner
//                    -1,  1, 0, // top left corner
//                    1,  1, 0, // top right corner
//                    1, -1, 0}); // bottom right corner
//
//            GLubyte indices[] = ({0,1,2, // first triangle (bottom left - top left - top right)
//                    0,2,3}); // second triangle (bottom left - top right - bottom right)
//
//            glVertexPointer(3, GL_FLOAT, 0, vertices);
//            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);
            gl_FragColor = vec4(1,0,0,1);
        }
);

@implementation CHOCRDrawRectFilter

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:kCHOCRDrawRectVertexShader fragmentShaderFromString:kCHOCRDrawRectFragmentShader]))
    {
        return nil;
    }
//    pixelSizeUniform = [filterProgram uniformIndex:@"pixelSize"];
//    centerUniform = [filterProgram uniformIndex:@"center"];
//
//    self.pixelSize = CGSizeMake(0.05, 0.05);
//    self.center = CGPointMake(0.5, 0.5);

    return self;
}

-(instancetype)initWithRect:(CGRect)rect {
    self = [super init];
    if (self) {
        _rect = rect;
    }
    return self;
}

@end
