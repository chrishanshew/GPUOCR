//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRecognitionGroup.h"

@interface CHRecognitionGroup () <CHRecognitionOutputDelegate>
{
    CHRecognitionOutput *recognitionOutput;
}

@end

@implementation CHRecognitionGroup

-(instancetype)initWithProcessingSize:(CGSize)size forRegion:(CHRegion *)region {
    self = [super init];
    if (self) {
        _region = region;

        CGRect regionRect = [_region getRect];

        // Crop
        GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:regionRect];
        [self addFilter:cropFilter];

        // Scale
        GPUImageLanczosResamplingFilter *resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
        [self addFilter:resamplingFilter];
        resamplingFilter.enabled = NO;

        // Threshold
        GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = 4;
        [self addFilter:adaptiveThresholdFilter];

        // OCR
         recognitionOutput = [[CHRecognitionOutput alloc] initWithImageSize:size forRegion:_region resultsInBGRAFormat:YES forLanguage:@"eng"];
        recognitionOutput.delegate = self;

        self.initialFilters = @[cropFilter];
        [cropFilter addTarget:resamplingFilter];
        [resamplingFilter addTarget:adaptiveThresholdFilter];
        [adaptiveThresholdFilter addTarget:recognitionOutput];
        self.terminalFilter = resamplingFilter;
    }

    return self;
}

// TODO: Override Force Processing

- (void)output:(CHRecognitionOutput *)output completedRecognitionWithText:(CHText *)text {
    if ([_delegate respondsToSelector:@selector(output:completedRecognitionWithText:)]) {
        [_delegate output:output completedRecognitionWithText:text];
    }
}

- (void)output:(CHRecognitionOutput *)output willRecognizeRegion:(CHRegion *)region {
    if ([_delegate respondsToSelector:@selector(output:willRecognizeRegion:)]) {
        [_delegate output:output willRecognizeRegion:region];
    }
}

@end