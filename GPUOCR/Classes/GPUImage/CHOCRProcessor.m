//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHOCRProcessor.h"

@interface CHOCRProcessor () <CHOCROutputDelegate, CHOCRProcessorDelegate>
{
    CGSize _processingSize;
    GLint _maxTextureSize;
    GPUImageCropFilter *cropFilter;
    GPUImageTransformFilter *transformFilter;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    CHOCROutput *recognitionOutput;
}

-(void)setCropRegion:(CGRect)region;

@end

@implementation CHOCRProcessor

-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {
        _processingSize = size;
        _maxTextureSize = [GPUImageContext maximumTextureSizeForThisDevice] / 1;
        // Crop
        cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];

        // Scale
        transformFilter = [[GPUImageTransformFilter alloc] init];

        // Threshold
        adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = 4;

        // OCR
        recognitionOutput = [[CHOCROutput alloc] initWithImageSize:size resultsInBGRAFormat:YES forLanguage:@"eng"];
        recognitionOutput.delegate = self;

        self.initialFilters = @[cropFilter];
        [cropFilter addTarget:adaptiveThresholdFilter];
        [adaptiveThresholdFilter addTarget:transformFilter];
        [transformFilter addTarget:recognitionOutput];
        self.terminalFilter = transformFilter;
    }

    return self;
}

-(void)setRegion:(CHRegion *)region {
    if (recognitionOutput.enabled) {
        _region = region;
        recognitionOutput.region = region;
        CGRect regionRect = [region getRect];
        [self setCropRegion:regionRect];
    }
}

// TODO: CLEAN UP CALCULATIONS OR USE CORE GRAPHICS

-(void)setCropRegion:(CGRect)region {
    
    // Padding
    // TODO: Affine transforms?
    
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
    [cropFilter setCropRegion:scaledCropRect];
    
    // Down stream size
    CGRect maxTextureWithAspect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(width, height), CGRectMake(0, 0, _maxTextureSize, _maxTextureSize));
    [recognitionOutput setImageSize:maxTextureWithAspect.size];

    CGFloat transformScaleX = maxTextureWithAspect.size.width / (maxTextureWithAspect.size.width - width);
    CGFloat transformScaleY = maxTextureWithAspect.size.height / (maxTextureWithAspect.size.height - height);

    CATransform3D transform = CATransform3DMakeScale(transformScaleX, transformScaleY, 1);
    [transformFilter setTransform3D:transform];
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