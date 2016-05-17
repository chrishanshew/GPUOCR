//
//  CHRegionFilter.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHRegionFilter.h"
#import "CHRegionGenerator.h"

@interface CHRegionFilter () {
    GPUImageAlphaBlendFilter *blendFilter;
    GPUImageGammaFilter *gammaFilter;
    CHRegionGenerator* regionGenerator;
    GPUImageLanczosResamplingFilter *resamplingFilter;
}

@end

@implementation CHRegionFilter

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING
-(instancetype)init {
    self = [super init];
    if (self) {
        resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
        [self addFilter:resamplingFilter];
        blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [self addFilter:blendFilter];
        gammaFilter = [[GPUImageGammaFilter alloc] init];
        [self addFilter:gammaFilter];

        regionGenerator = [[CHRegionGenerator alloc] init];
        [self addFilter:regionGenerator];

        self.initialFilters = @[resamplingFilter];
        [resamplingFilter addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        [regionGenerator addTarget:blendFilter];
        self.terminalFilter = blendFilter;

        __block CHRegionGenerator *weakResultsGenerator = regionGenerator;
        [gammaFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            [weakResultsGenerator renderRegionsWithFrameTime:time];
        }];
    }
    return self;
}

-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
    [regionGenerator setLineColorWithRed:red green:green blue:blue alpha:alpha];
}

-(void)setLineWidth:(float)width {
    [regionGenerator setLineWidth:width];
}

-(void)setRegions:(NSArray *)results {
    [regionGenerator setRegions:results];
}

@end
