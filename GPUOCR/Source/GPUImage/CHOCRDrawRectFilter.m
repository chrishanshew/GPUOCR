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

NSString *const kCHOCRDrawRectFilterShader = SHADER_STRING
(
        void main()
        {
            GLfloat vertices[] = ({-1, -1, 0, // bottom left corner
                    -1,  1, 0, // top left corner
                    1,  1, 0, // top right corner
                    1, -1, 0}); // bottom right corner

            GLubyte indices[] = ({0,1,2, // first triangle (bottom left - top left - top right)
                    0,2,3}); // second triangle (bottom left - top right - bottom right)

            glVertexPointer(3, GL_FLOAT, 0, vertices);
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);
        }
);

@implementation CHOCRDrawRectFilter

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kCHOCRDrawRectFilterShader]))
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
