//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRecognitionGroup.h"

@interface CHRecognitionGroup () <CHRecognitionOutputDelegate>
{
    GPUImageCropFilter *cropFilter;
    GPUImageLanczosResamplingFilter *resamplingFilter;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    CHRecognitionOutput *recognitionOutput;
}

@end

@implementation CHRecognitionGroup

-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {

        // Crop
        cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];

        // Scale
//        resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
//        resamplingFilter.enabled = NO;

        // Threshold
        adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = 4;

        // OCR
        recognitionOutput = [[CHRecognitionOutput alloc] initWithImageSize:size resultsInBGRAFormat:YES forLanguage:@"eng"];
        recognitionOutput.delegate = self;

        self.initialFilters = @[cropFilter];
        [cropFilter addTarget:adaptiveThresholdFilter];
        [adaptiveThresholdFilter addTarget:recognitionOutput];
        self.terminalFilter = adaptiveThresholdFilter;
    }

    return self;
}

-(void)setRegion:(CHRegion *)region {
    _region = region;
    recognitionOutput.region = region;
    // Update Crop
//    [cropFilter setCropRegion:[_region getRect]];
    
    // Update resampling scale
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