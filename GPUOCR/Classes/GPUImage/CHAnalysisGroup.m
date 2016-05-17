//
//  CHAnalysisGroup.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHAnalysisGroup.h"
#import "CHAnalysisOutput.h"

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface CHAnalysisGroup () <CHAnalysisOutputDelegate> {
    CGSize _processingSize;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    CHAnalysisOutput *analysisOutput;
    GPUImageLanczosResamplingFilter *resamplingFilter;
}

@end

@implementation CHAnalysisGroup

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING

-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {
        
        _processingSize = size;
        _level = CHTesseractAnalysisLevelBlock;

        // Analysis Output
        analysisOutput = [[CHAnalysisOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES];
        analysisOutput.delegate = self;
        analysisOutput.level = _level;

        resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];

        adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;

        self.initialFilters = @[resamplingFilter];
        [resamplingFilter addTarget:adaptiveThresholdFilter];
        [adaptiveThresholdFilter addTarget:analysisOutput];
        self.terminalFilter = adaptiveThresholdFilter;

        [self forceProcessingAtSizeRespectingAspectRatio:size];
    }
    return self;
}

-(void)setLevel:(CHTesseractAnalysisLevel)level {
    _level = level;
    analysisOutput.level = _level;
}

-(void)setBlurRadius:(float)blurRadius {
    _blurRadius = blurRadius;
    adaptiveThresholdFilter.blurRadiusInPixels = _blurRadius;
}

- (void)willBeginAnalysisWithOutput:(CHAnalysisOutput *)output {
    
}

- (void)output:(CHAnalysisOutput *)output completedAnalysisWithRegions:(NSArray *)regions; {
    if ([_delegate respondsToSelector:@selector(output:completedAnalysisWithRegions:)]) {
        [_delegate output:output completedAnalysisWithRegions:regions];
    }
}

@end
