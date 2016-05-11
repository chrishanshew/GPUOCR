//
//  CHOCRDrawRectFilter.h
//  CHOCR
//
//  Created by Chris Hanshew on 2/13/16.
//  Copyright © 2016 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"

@interface CHOCRDrawRectFilter : GPUImageFilter

-(instancetype)initWithRect:(CGRect)rect;

@end
