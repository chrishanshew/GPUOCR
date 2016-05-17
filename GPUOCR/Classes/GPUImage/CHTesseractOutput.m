//
//  CHTesseractOutput.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHTesseractOutput.h"
#import "CHAnalysisOutput.h"
#import "CHRecognitionOutput.h"
#import "CHDetectionOutput.h"

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface CHTesseractOutput () <CHOCRRecogntionOutputDelegate, CHOCRAnalysisOutputDelegate, CHOCRDetectionOutputDelegate> {
    CGSize _processingSize;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    CHAnalysisOutput *analysisOutput;
    CHDetectionOutput *detectionOutput;
    CHRecognitionOutput *recognitionOutput;
    GPUImageLanczosResamplingFilter *resamplingFilter;
}

-(GPUImageRawDataOutput *)outputForMode:(CHTesseractMode)mode;

@end

@implementation CHTesseractOutput

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING


-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {
        
        _processingSize = size;
        _level = CHTesseractAnalysisLevelBlock;

        // Recognition Output
        recognitionOutput = [[CHRecognitionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES forLanguage:@"eng" withDelegate:self];
        recognitionOutput.level = _level;

        // Analysis Output
        analysisOutput = [[CHAnalysisOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES];
        analysisOutput.level = _level;

        // DetectionOutput
        detectionOutput = [[CHDetectionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES withDelegate:self];
        detectionOutput.level = _level;

        // Default
        _mode = CHTesseractModeAnalysis;

        resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
        [self addFilter:resamplingFilter];

        adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;
        [self addFilter:adaptiveThresholdFilter];

        self.initialFilters = @[resamplingFilter];
        [resamplingFilter addTarget:adaptiveThresholdFilter];
        [adaptiveThresholdFilter addTarget:[self outputForMode:_mode]];
        self.terminalFilter = adaptiveThresholdFilter;


        [self forceProcessingAtSizeRespectingAspectRatio:size];
    }
    return self;
}

-(void)setMode:(CHTesseractMode)mode {
    adaptiveThresholdFilter.enabled = NO;
    [adaptiveThresholdFilter removeTarget:[self outputForMode:_mode]];
    _mode = mode;
    [adaptiveThresholdFilter addTarget:[self outputForMode:_mode]];
    adaptiveThresholdFilter.enabled = YES;
}

-(void)setLevel:(CHTesseractAnalysisLevel)level {
    _level = level;
    analysisOutput.level = _level;
    recognitionOutput.level = _level;
    detectionOutput.level = _level;
}

-(void)setBlurRadius:(float)blurRadius {
    _blurRadius = blurRadius;
    adaptiveThresholdFilter.blurRadiusInPixels = _blurRadius;
}

-(GPUImageRawDataOutput *)outputForMode:(CHTesseractMode)mode {
    switch (mode) {
        case CHTesseractModeAnalysis:
        {
            return analysisOutput;
        }
        case CHTesseractModeAnalysisWithOSD:
        {
            return detectionOutput;
        }
        case CHTesseractModeAnalysisWithRecognition:
        {
            return recognitionOutput;
        }
    }
}

// TODO: CONSOLIDATE DELEGATES TO SINGLE PROTOCOL

#pragma mark - <CHOCRRecognitionOutputDelegate>

- (void)output:(CHRecognitionOutput *)output didFinishRecognitionWithResult:(CHResultGroup *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishDetectionWithResult:)]) {
        [_delegate output:self didFinishDetectionWithResult:result];
    }
}

- (void)willBeginRecognitionWithOutput:(CHRecognitionOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:self];
    }
}

#pragma mark - <CHOCRAnaylsisOutputDelegate>

-(void)output:(CHAnalysisOutput*)output didFinishAnalysisWithLayout:(CHLayout *)layout {
    if ([_delegate respondsToSelector:@selector(output:didFinishAnalysisWithLayout:)]) {
        [_delegate output:output didFinishAnalysisWithLayout:layout];
    }
}

- (void)willBeginAnalysisWithOutput:(CHAnalysisOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:self];
    }
}

#pragma mark - <CHOCRDetectionOutputDelegate>

- (void)output:(CHDetectionOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishDetectionWithResult:)]) {
        [_delegate output:self didFinishDetectionWithResult:result];
    }
}

- (void)willBeginDetectionWithOutput:(CHDetectionOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:self];
    }
}

@end
