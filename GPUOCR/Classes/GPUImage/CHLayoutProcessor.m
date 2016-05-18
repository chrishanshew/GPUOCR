//
//  CHLayoutProcessor.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHLayoutProcessor.h"
#import "CHLayoutOutput.h"

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface CHLayoutProcessor () <CHLayoutOutputDelegate> {
    CGSize _processingSize;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    CHLayoutOutput *analysisOutput;
    GPUImageLanczosResamplingFilter *resamplingFilter;
}

@end

@implementation CHLayoutProcessor

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING

-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {
        
        _processingSize = size;
        _level = CHTesseractAnalysisLevelBlock;

        // Analysis Output
        analysisOutput = [[CHLayoutOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES];
        analysisOutput.delegate = self;
        analysisOutput.level = _level;

        adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;

        self.initialFilters = @[adaptiveThresholdFilter];
        [adaptiveThresholdFilter addTarget:analysisOutput];
        self.terminalFilter = adaptiveThresholdFilter;
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

#pragma mark - <CHLayoutOutputDelegate>

- (void)willBeginAnalysisWithOutput:(CHLayoutOutput *)output {
    [self willBeginLayoutAnalysis:self];
}

- (void)output:(CHLayoutOutput *)output completedAnalysisWithRegions:(NSArray *)regions; {
    [self processor:self finishedLayoutAnalysisWithRegions:regions];
}

#pragma mark - <CHLayoutProcessorDelegate>

- (void)processor:(CHLayoutProcessor *)processor finishedLayoutAnalysisWithRegions:(NSArray *)regions {
    if ([_delegate respondsToSelector:@selector(processor:finishedLayoutAnalysisWithRegions:)]) {
        [_delegate processor:processor finishedLayoutAnalysisWithRegions:regions];
    }
}

- (void)willBeginLayoutAnalysis:(CHLayoutProcessor *)processor {
    if ([_delegate respondsToSelector:@selector(willBeginLayoutAnaylsis:)]) {
        [_delegate willBeginLayoutAnalysis:processor];
    }
}

@end
