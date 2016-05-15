//
//  CHTesseractOutput.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHTesseractOutput.h"
#import "CHOCRAnalysisOutput.h"
#import "CHOCRRecognitionOutput.h"
#import "CHOCRDetectionOutput.h"

#define kDefaultAdaptiveThresholderBlurRadius 4.0

@interface CHTesseractOutput () <CHOCRRecogntionOutputDelegate, CHOCRAnalysisOutputDelegate, CHOCRDetectionOutputDelegate> {
    CGSize _processingSize;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    CHOCRAnalysisOutput *analysisOutput;
    CHOCRDetectionOutput *detectionOutput;
    CHOCRRecognitionOutput *recognitionOutput;
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
        
        // Thresholder
        _blurRadius = kDefaultAdaptiveThresholderBlurRadius;
        adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = _blurRadius;
        [adaptiveThresholdFilter forceProcessingAtSizeRespectingAspectRatio:_processingSize];
        [self addFilter:adaptiveThresholdFilter];
        self.initialFilters = @[adaptiveThresholdFilter];
        self.terminalFilter = adaptiveThresholdFilter;

        // Recognition Output
        recognitionOutput = [[CHOCRRecognitionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES forLanguage:@"eng" withDelegate:self];
        recognitionOutput.level = _level;
        
        // Analysis Output
        analysisOutput = [[CHOCRAnalysisOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES withDelegate:self];
        analysisOutput.level = _level;
        
        // DetectionOutput
        detectionOutput = [[CHOCRDetectionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES withDelegate:self];
        detectionOutput.level = _level;
        
        // Default
        _mode = CHTesseractModeAnalysis;
        [adaptiveThresholdFilter addTarget:[self outputForMode:_mode]];
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

- (void)output:(CHOCRRecognitionOutput *)output didFinishRecognitionWithResult:(CHResultGroup *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishDetectionWithResult:)]) {
        [_delegate output:self didFinishDetectionWithResult:result];
    }
}

- (void)willBeginRecognitionWithOutput:(CHOCRRecognitionOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:self];
    }
}

#pragma mark - <CHOCRAnaylsisOutputDelegate>

- (void)output:(CHOCRAnalysisOutput*)output didFinishAnalysisWithResult:(CHResultGroup *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishDetectionWithResult:)]) {
        [_delegate output:self didFinishDetectionWithResult:result];
    }
}

- (void)willBeginAnalysisWithOutput:(CHOCRAnalysisOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:self];
    }
}

#pragma mark - <CHOCRDetectionOutputDelegate>

- (void)output:(CHOCRDetectionOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishDetectionWithResult:)]) {
        [_delegate output:self didFinishDetectionWithResult:result];
    }
}

- (void)willBeginDetectionWithOutput:(CHOCRDetectionOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:self];
    }
}

@end
