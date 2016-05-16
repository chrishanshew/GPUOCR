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
}

@end

@implementation CHResultFilter

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING
-(instancetype)initWithProcessingSize:(CGSize)processingSize {
    self = [super init];
    if (self) {
        blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        gammaFilter = [[GPUImageGammaFilter alloc] init];
        resultGenerator = [[CHResultGenerator alloc] init];

        [gammaFilter addTarget:blendFilter];
        [resultGenerator addTarget:blendFilter];

        [self addFilter:gammaFilter];
        [self addFilter:blendFilter];
        self.initialFilters = @[gammaFilter, blendFilter];
        self.terminalFilter = blendFilter;
        [self forceProcessingAtSize:processingSize];

        __block CHResultGenerator *weakResultsGenerator = resultGenerator;
        [gammaFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            [weakResultsGenerator renderResultsWithFrameTime:time];
        }];
    }
    return self;
}

-(void)forceProcessingAtSize:(CGSize)frameSize {
    [super forceProcessingAtSize:frameSize];
    [resultGenerator forceProcessingAtSize:frameSize];
}

-(void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize {
    [super forceProcessingAtSizeRespectingAspectRatio:frameSize];
    [resultGenerator forceProcessingAtSizeRespectingAspectRatio:frameSize];
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
