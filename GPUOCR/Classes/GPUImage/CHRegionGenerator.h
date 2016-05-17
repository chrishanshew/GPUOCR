//
//  CHRegionGenerator.h
//  CHOCR
//
//  Created by Chris Hanshew on 2/13/16.
//  Copyright © 2016 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"

@interface CHRegionGenerator : GPUImageFilter

@property(nonatomic, strong, readonly) NSArray *results;

-(void)setRegions:(NSArray *)results;
-(void)renderRegionsWithFrameTime:(CMTime)frameTime;
-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
-(void)setLineWidth:(float)width;

@end
