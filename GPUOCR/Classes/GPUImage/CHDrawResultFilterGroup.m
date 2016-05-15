//
//  CHDrawResultFilterGroup.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHDrawResultFilterGroup.h"
#import "CHOCRDrawResultFilter.h"

@interface CHDrawResultFilterGroup () {
    GPUImageAlphaBlendFilter *blendFilter;
    GPUImageGammaFilter *gammaFilter;
    CHOCRDrawResultFilter* drawResultFilter;
}

@end

@implementation CHDrawResultFilterGroup

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING
-(instancetype)initWithProcessingSize:(CGSize)processingSize {
    self = [super init];
    if (self) {
        blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        gammaFilter = [[GPUImageGammaFilter alloc] init];
        drawResultFilter = [[CHOCRDrawResultFilter alloc] init];

        [gammaFilter addTarget:blendFilter];
        [drawResultFilter addTarget:blendFilter];

        [self addFilter:gammaFilter];
        [self addFilter:blendFilter];
        self.initialFilters = @[gammaFilter, blendFilter];
        self.terminalFilter = blendFilter;
        [self forceProcessingAtSize:processingSize];

        __block CHOCRDrawResultFilter *weakDrawResultsFilter = drawResultFilter;
        [gammaFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            [weakDrawResultsFilter renderResultsWithFrameTime:time];
        }];
    }
    return self;
}

-(void)forceProcessingAtSize:(CGSize)frameSize {
    [super forceProcessingAtSize:frameSize];
    [drawResultFilter forceProcessingAtSize:frameSize];
}

-(void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize {
    [super forceProcessingAtSizeRespectingAspectRatio:frameSize];
    [drawResultFilter forceProcessingAtSizeRespectingAspectRatio:frameSize];
}

-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
    [drawResultFilter setLineColorWithRed:red green:green blue:blue alpha:alpha];
}

-(void)setLineWidth:(float)width {
    [drawResultFilter setLineWidth:width];
}

-(void)setResults:(NSArray *)results {
    [drawResultFilter setResults:results];
}

@end
