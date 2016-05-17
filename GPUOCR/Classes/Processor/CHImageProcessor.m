//
//  CHImageProcessor.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/13/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "CHImageProcessor.h"
#import "CHDetectionOutput.h"
#import "CHRecognitionOutput.h";

// NOT TARGETED

@interface CHImageProcessor() <CHImageProcessorDelegate, CHOCRDetectionOutputDelegate, CHRecognitionOutputDelegate> {
    UIImage *_image;
    GPUImagePicture *_imageInput;
    GPUImageLanczosResamplingFilter *_resamplingFilter;
    CHDetectionOutput *_detectionOutput;
    CHRecognitionOutput *_recognitionOutput;

    NSMutableDictionary *_resultGroupsForLevel;
}

@end

@implementation CHImageProcessor

-(instancetype)initWithUIImage:(UIImage *)image {
    self = [super init];
    if (self) {
        _image = image;
    }
    return self;
}

-(void)processFromLevel:(CHTesseractAnalysisLevel)fromLevel toLevel:(CHTesseractAnalysisLevel)toLevel {
    NSAssert(fromLevel < toLevel, @"fromLevel must be less than toLevel");
    [self processorWillBeginProcessing:self];
    _startLevel = fromLevel;
    _currentLevel = _startLevel;
    _endLevel = toLevel;

    _resultGroupsForLevel = [NSMutableDictionary dictionary];

    NSInteger maxTextureSize = [GPUImageContext maximumTextureSizeForThisDevice];
    _imageInput = [[GPUImagePicture alloc] initWithImage:_image];
    _resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
    [_resamplingFilter forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(maxTextureSize, maxTextureSize)];
    [_imageInput addTarget:_resamplingFilter];

    // TODO: CROP FILTER TO MAINTAIN ASPECT RATIO BEFORE DETECTION?

    _detectionOutput = [[CHDetectionOutput alloc] initWithImageSize:CGSizeMake(maxTextureSize, maxTextureSize) resultsInBGRAFormat:YES withDelegate:self];
    [_resamplingFilter addTarget:_detectionOutput];
}

-(BOOL)cancel {
    return NO;
}

#pragma mark - <CHOCRDetectionOutputDelegate>

- (void)output:(CHDetectionOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result {
    // Store Results
    [_resultGroupsForLevel setObject:result forKey:[NSNumber numberWithInteger:result.level]];

    // Start Next Level
    if (result.level < _endLevel) {
        _currentLevel = result.level++;
        _detectionOutput.level = _currentLevel;
        [_imageInput processImage];
    } else {
        // Start Recognition

    }
}

- (void)willBeginDetectionWithOutput:(CHDetectionOutput *)output {

}

#pragma mark - <CHOCRRecognitionOutputDelegate>

- (void)output:(CHRecognitionOutput *)output didFinishRecognitionWithResult:(CHResultGroup *)result {

}

- (void)willBeginRecognitionWithOutput:(CHRecognitionOutput *)output {

}

#pragma mark - <CHImageProcessorDelegate>

-(void)processorWillBeginProcessing:(CHImageProcessor *)processor {
    if ([_delegate respondsToSelector:@selector(processorWillBeginProcessing:)]) {
        [_delegate processorWillBeginProcessing:processor];
    }
}
-(void)processor:(CHImageProcessor *)processor didProcessResultGroup:(CHResultGroup *)group {
    if ([_delegate respondsToSelector:@selector(processor:didProcessResultGroup:)]) {
        [_delegate processor:processor didProcessResultGroup:group];
    }
}
-(void)processor:(CHImageProcessor *)processor didProcessResult:(CHResult *)result atLevel:(CHTesseractAnalysisLevel)level {
    if ([_delegate respondsToSelector:@selector(processor:didProcessResult:atLevel)]) {
        [_delegate processor:processor didProcessResult:result atLevel:level];
    }
}
-(void)processor:(CHImageProcessor *)processor didUpdateProgress:(float)progress forLevel:(CHTesseractAnalysisLevel)level {
    if ([_delegate respondsToSelector:@selector(processor:didUpdateProgress:forLevel)]) {
        [_delegate processor:processor didUpdateProgress:progress forLevel:level];
    }
}
-(void)processorWillCancelProcessing:(CHImageProcessor *)processor {
    if ([_delegate respondsToSelector:@selector(processorWillCancelProcessing:)]) {
        [_delegate processorWillCancelProcessing:processor];
    }
}
-(void)processor:(CHImageProcessor *)processor didCompleteProcessing:(CHResultGroup *)group error:(NSError *)error {
    if ([_delegate respondsToSelector:processor:didCompleteProcessing:error]) {
        [_delegate processor:processor didCompleteProcessing:group error:error];
    }
}

@end
