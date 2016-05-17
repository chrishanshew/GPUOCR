//
//  CHRegionFilter.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "GPUImage.h"

@interface CHRegionFilter : GPUImageFilterGroup

-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
-(void)setLineWidth:(float)width;
-(void)setRegions:(NSArray *)results;

@end
