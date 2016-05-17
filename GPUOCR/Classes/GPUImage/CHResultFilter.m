//
//  CHResultFilter.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHResultFilter.h"
#import "CHResultGenerator.h"

@interface CHResultFilter () {
    GPUImageAlphaBlendFilter *blendFilter;
    GPUImageGammaFilter *gammaFilter;
    CHResultGenerator* resultGenerator;
    GPUImageLanczosResamplingFilter *resamplingFilter;
}

@end

@implementation CHResultFilter

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

        resultGenerator = [[CHResultGenerator alloc] init];
        [self addFilter:resultGenerator];

        self.initialFilters = @[resamplingFilter];
        [resamplingFilter addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        [resultGenerator addTarget:blendFilter];
        self.terminalFilter = blendFilter;

        __block CHResultGenerator *weakResultsGenerator = resultGenerator;
        [gammaFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            [weakResultsGenerator renderResultsWithFrameTime:time];
        }];
    }
    return self;
}

-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
    [resultGenerator setLineColorWithRed:red green:green blue:blue alpha:alpha];
}

-(void)setLineWidth:(float)width {
    [resultGenerator setLineWidth:width];
}

-(void)setResults:(NSArray *)results {
    [resultGenerator setResults:results];
}

@end
