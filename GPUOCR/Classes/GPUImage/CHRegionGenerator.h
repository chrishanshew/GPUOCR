//
//  CHRegionGenerator.h
//  CHOCR
//
//  Created by Chris Hanshew on 2/13/16.
//  Copyright © 2016 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHRegion.h"

@interface CHRegionGenerator : GPUImageFilter

-(void)renderRegions:(NSArray *)regions atFrameTime:(CMTime)frameTime;
-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
-(void)setLineWidth:(float)width;

@end
