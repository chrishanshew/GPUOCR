//
//  CHLayoutProcessor.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "GPUImage.h"
#import "CHLayoutOutput.h"
#import "CHRegion.h"

@class CHLayoutProcessor;

@protocol CHLayoutProcessorDelegate <NSObject>

@required
- (void)processor:(CHLayoutProcessor *)processor finishedLayoutAnalysisWithRegions:(NSArray *)regions;
- (void)processor:(CHLayoutProcessor *)processor newRegionAvailable:(CHRegion *)region;

@optional

- (void)willBeginLayoutAnalysis:(CHLayoutProcessor *)processor;

@end

@interface CHLayoutProcessor : GPUImageFilterGroup

-(instancetype)initWithProcessingSize:(CGSize)size;

@property(nonatomic, weak)id<CHLayoutProcessorDelegate> delegate;
@property(nonatomic, setter=setLevel:)CHTesseractAnalysisLevel level;
@property(nonatomic, setter=setBlurRadius:)float blurRadius;

@end
