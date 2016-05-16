//
//  CHResultFilter.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "GPUImage.h"

@interface CHResultFilter : GPUImageFilterGroup

-(instancetype)initWithProcessingSize:(CGSize)processingSize;

-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
-(void)setLineWidth:(float)width;
-(void)setResults:(NSArray *)results;

@end
