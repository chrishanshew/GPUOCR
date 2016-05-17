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

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface CHTesseractOutput () <CHOCRRecogntionOutputDelegate, CHOCRAnalysisOutputDelegate> {
    CGSize _processingSize;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    CHAnalysisOutput *analysisOutput;
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
            return analysisOutput;
        }
        case CHTesseractModeAnalysisWithRecognition:
        {
            return recognitionOutput;
        }
    }
}

// TODO: CONSOLIDATE DELEGATES TO SINGLE PROTOCOL

#pragma mark - <CHOCRRecognitionOutputDelegate>

- (void)output:(CHRecognitionOutput *)output completedRecognitionWithText:(CHText *)result {
    if ([_delegate respondsToSelector:@selector(output:completed)]) {
        
    }
}

- (void)output:(CHRecognitionOutput *)output willRecognizeRegion:(CHRegion *)region {
    
}

- (void)output:(CHTesseractOutput *)output completedAnalysisWithRegions:(NSArray *)regions; {
    if ([_delegate respondsToSelector:@selector(output:completedAnalysisWithRegions:)]) {
        [_delegate output:output completedAnalysisWithRegions:regions];
    }
}

- (void)willBeginDetectionWithOutput:(CHTesseractOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:output];
    }
}

@end
