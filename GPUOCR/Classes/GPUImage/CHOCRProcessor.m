//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHOCRProcessor.h"

@interface CHOCRProcessor () <CHOCROutputDelegate, CHOCRProcessorDelegate>
{
    CGSize _processingSize;
    GLint _maxTextureSize;
    GPUImageCropFilter *_cropFilter;
    GPUImageTransformFilter *_scaleTransformFilter;
    GPUImageTransformFilter *_rotationTransformFilter;
    GPUImageAdaptiveThresholdFilter *_adaptiveThresholdFilter;
    GPUImageLuminanceThresholdFilter *_luminanceThresholdFilter;
    CHOCROutput *_recognitionOutput;
}

-(void)setCropRegion:(CGRect)region;

@end

@implementation CHOCRProcessor

-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {
        _processingSize = size;
        _maxTextureSize = [GPUImageContext maximumTextureSizeForThisDevice];

        // TODO: Rotation to level baseline
        // Rotation
        _rotationTransformFilter = [[GPUImageTransformFilter alloc] init];

        // Crop
        _cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];

        // Scale
        _scaleTransformFilter = [[GPUImageTransformFilter alloc] init];

        // Threshold
        _luminanceThresholdFilter = [[GPUImageLuminanceThresholdFilter alloc] init];

        // OCR
        _recognitionOutput = [[CHOCROutput alloc] initWithImageSize:size resultsInBGRAFormat:YES forLanguage:@"eng"];
        _recognitionOutput.delegate = self;

        self.initialFilters = @[_luminanceThresholdFilter];
        [_luminanceThresholdFilter addTarget:_cropFilter];
        [_cropFilter addTarget:_recognitionOutput];
//        [_rotationTransformFilter addTarget:_recognitionOutput];
//        [_scaleTransformFilter addTarget:_adaptiveThresholdFilter];
//        [_adaptiveThresholdFilter addTarget:_recognitionOutput];
        self.terminalFilter = _cropFilter;
    }

    return self;
}

-(void)setRegion:(CHRegion *)region {
    if (_recognitionOutput.enabled) {
        _region = region;
        _recognitionOutput.region = region;
        CGRect regionRect = [region getRect];
        [self setCropRegion:regionRect];
    }
}

// TODO: CLEAN UP CALCULATIONS OR USE CORE GRAPHICS

-(void)setCropRegion:(CGRect)region {
    
    // Padding
    // TODO: Affine transforms?

    // TODO: Rotation Transform based on slope of region

    // TODO: Crop Padding

    CGFloat padding = 20; //px
    CGFloat originX = region.origin.x;
    CGFloat originY = region.origin.y;
    CGFloat width = region.size.width;
    CGFloat height = region.size.height;
    
    if (originX - padding >= 0 && originY - padding >= 0 && (originX + width) + padding <= _processingSize.width && (originY + height) + padding <= _processingSize.height) {
        originX -= padding;
        originY -= padding;
        width += (padding * 2);
        height += (padding * 2);
    }
    
    // Scaled Origin
    CGFloat cropScaleOriginX = originX / _processingSize.width;
    CGFloat cropScaleOriginY = originY / _processingSize.height;
    
    // Scaled Size
    CGFloat cropScaleWidth = width / _processingSize.width;
    CGFloat cropScaleHeight = height / _processingSize.height;
    
    CGRect scaledCropRect = CGRectMake(cropScaleOriginX, cropScaleOriginY, cropScaleWidth, cropScaleHeight);
    [_cropFilter setCropRegion:scaledCropRect];
    
    // Down stream size
    CGRect maxTextureWithAspect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(width, height), CGRectMake(0, 0, _maxTextureSize, _maxTextureSize));
    [_recognitionOutput setImageSize:maxTextureWithAspect.size];

//    CGFloat transformScaleX = maxTextureWithAspect.size.width / (maxTextureWithAspect.size.width - width);
//    CGFloat transformScaleY = maxTextureWithAspect.size.height / (maxTextureWithAspect.size.height - height);
//
//    CATransform3D transform = CATransform3DMakeScale(transformScaleX, transformScaleY, 1);
//    [_scaleTransformFilter setTransform3D:transform];
}

// TODO: Override Force Processing

#pragma mark - <CHOCRProcessorDelegate>

- (void)output:(CHOCROutput *)output completedOCRWithText:(CHText *)text {
    [self processor:self completedOCRWithText:text];
}

- (void)output:(CHOCROutput *)output willBeginOCRForRegion:(CHRegion *)region {
   [self processor:self willBeginOCRForRegion:region];
}

#pragma mark - <CHOCRProcessorDelegate>

- (void)processor:(CHOCRProcessor *)processor completedOCRWithText:(CHText *)text {
    if ([_delegate respondsToSelector:@selector(processor:completedOCRWithText:)]) {
        [_delegate processor:processor completedOCRWithText:text];
    }
}

- (void)processor:(CHOCRProcessor *)processor willBeginOCRForRegion:(CHRegion *)region {
    if ([_delegate respondsToSelector:@selector(processor:willBeginOCRForRegion:)]) {
        [_delegate processor:processor willBeginOCRForRegion:region];
    }
}

@end