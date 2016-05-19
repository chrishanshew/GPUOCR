//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHOCRProcessor.h"
#import "CHTesseract.h"

@interface CHOCRProcessor () <CHOCRProcessorDelegate>
{
    CGSize _outputImageSize;
    CHTesseract *_tesseract;
    GLint _maxTextureSize;
    GPUImageCropFilter *_cropFilter;
    GPUImageTransformFilter *_scaleTransformFilter;
    GPUImageTransformFilter *_rotationTransformFilter;
    GPUImageAdaptiveThresholdFilter *_adaptiveThresholdFilter;
    GPUImageLuminanceThresholdFilter *_luminanceThresholdFilter;
    GPUImageRawDataOutput *_rawDataOutput;
    dispatch_queue_t _processingQueue;
}

@property (nonatomic) BOOL isProcessing;

- (void)newFrameAvailable;
- (void)setCropRegion:(CGRect)region;

@end

@implementation CHOCRProcessor

-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {
        _processingQueue = dispatch_queue_create("com.chrishanshew.gpuocr.ocrprocessor.processingqueue", NULL);
        _maxTextureSize = [GPUImageContext maximumTextureSizeForThisDevice] / 2;
        _isProcessing = NO;
        // TODO: Rotation to level baseline
        // Rotation
        _rotationTransformFilter = [[GPUImageTransformFilter alloc] init];

        // Crop
        _cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 0, 1, 1)];

        // Scale
        _scaleTransformFilter = [[GPUImageTransformFilter alloc] init];

        // Threshold
        _luminanceThresholdFilter = [[GPUImageLuminanceThresholdFilter alloc] init];

        _rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:size resultsInBGRAFormat:YES];
        __block CHOCRProcessor *blockSelf = self;
        [_rawDataOutput setNewFrameAvailableBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockSelf newFrameAvailable];
            });
        }];

        self.initialFilters = @[_cropFilter];
        [_cropFilter addTarget:_luminanceThresholdFilter];
        [_luminanceThresholdFilter addTarget:_rawDataOutput];
//        [_rotationTransformFilter addTarget:_recognitionOutput];
//        [_scaleTransformFilter addTarget:_adaptiveThresholdFilter];
//        [_adaptiveThresholdFilter addTarget:_recognitionOutput];
        self.terminalFilter = _luminanceThresholdFilter;
    }

    return self;
}

- (void)newFrameAvailable {
    if (!_region || _isProcessing || isEndProcessing) {
        return;
    }

    [self processor:self willBeginOCRInRegion:self.region];

    [_rawDataOutput lockFramebufferForReading];
    void * rawImageData = (void *) [_rawDataOutput rawBytesForImage];
    [_rawDataOutput unlockFramebufferAfterReading];

    __block CHOCRProcessor *blockSelf = self;
    dispatch_async(_processingQueue, ^{
        CFTimeInterval startTime = CACurrentMediaTime();
        NSMutableData *pixels = [NSMutableData dataWithCapacity:(_outputImageSize.width * _outputImageSize.height)];

        // TODO: Optimizable?
        // starting at 0 may only apply to adaptive thresholder.  luminance uses alpha channel
        for (int i = 0; i < ((4 * _outputImageSize.width) * _outputImageSize.height); i+=4) {
            [pixels appendBytes:(const void *)&rawImageData[i] length:1];
        }

        if (!_tesseract) {
            _tesseract = [[CHTesseract alloc] initForRecognitionWithLanguage:@"eng"];
        }

        [_tesseract setImageWithData:pixels withSize:_outputImageSize bytesPerPixel:1];
        CHText *text = [_tesseract recognizeTextAtLevel:blockSelf.region.analysisLevel];
        [_tesseract clear];

        dispatch_async(dispatch_get_main_queue(), ^{
            [blockSelf processor:blockSelf completedOCRWithText:text inRegion:blockSelf.region];
        });
        NSLog(@"OCR completed in %g s", CACurrentMediaTime() - startTime);
    });
}

-(void)setRegion:(CHRegion *)region {
    _region = region;
    [self setCropRegion:[_region getRect]];
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
    
//    if (originX - padding >= 0 && originY - padding >= 0 && (originX + width) + padding <= _region.imageSize.width && (originY + height) + padding <= _region.imageSize.height) {
//        originX -= padding;
//        originY -= padding;
//        width += (padding * 2);
//        height += (padding * 2);
//    }
//
    // Scaled Origin
    CGFloat cropScaleOriginX = originX / _region.imageSize.width;
    CGFloat cropScaleOriginY = originY / _region.imageSize.height;
    
    // Scaled Size
    CGFloat cropScaleWidth = width / _region.imageSize.width;
    CGFloat cropScaleHeight = height / _region.imageSize.height;
    
    CGRect scaledCropRect = CGRectMake(cropScaleOriginX, cropScaleOriginY, cropScaleWidth, cropScaleHeight);
    [_cropFilter setCropRegion:scaledCropRect];
    
    // Down stream size
    CGRect maxTextureWithAspect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(width, height), CGRectMake(0, 0, _maxTextureSize, _maxTextureSize));
    [_rawDataOutput setImageSize:maxTextureWithAspect.size];
    _outputImageSize = maxTextureWithAspect.size;

//    CGFloat transformScaleX = maxTextureWithAspect.size.width / (maxTextureWithAspect.size.width - width);
//    CGFloat transformScaleY = maxTextureWithAspect.size.height / (maxTextureWithAspect.size.height - height);
//
//    CATransform3D transform = CATransform3DMakeScale(transformScaleX, transformScaleY, 1);
//    [_scaleTransformFilter setTransform3D:transform];
}

#pragma mark - GPUImage Overrides

-(void)endProcessing {
    [super endProcessing];
    dispatch_sync(_processingQueue, ^{
        [_tesseract clear];
        [_tesseract clearAdaptiveClassifier];
        [_tesseract clearPersistentCache];
        [_tesseract end];
    });
    _tesseract = nil;
}

#pragma mark - <CHOCRProcessorDelegate>

- (void)processor:(CHOCRProcessor *)processor completedOCRWithText:(CHText *)text inRegion:(CHRegion *)region {
    _isProcessing = NO;
    if ([_delegate respondsToSelector:@selector(processor:completedOCRWithText:inRegion:)]) {
        [_delegate processor:processor completedOCRWithText:text inRegion: region];
    }
}

- (void)processor:(CHOCRProcessor *)processor willBeginOCRInRegion:(CHRegion *)region {
    _isProcessing = YES;
    if ([_delegate respondsToSelector:@selector(processor:willBeginOCRInRegion:)]) {
        [_delegate processor:processor willBeginOCRInRegion:region];
    }
}

@end