//
//  CHLayoutProcessor.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHLayoutProcessor.h"
#import "CHLayoutOutput.h"
#import "CHTesseract.h"

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface CHLayoutProcessor () <CHLayoutProcessorDelegate> {
    CGSize _processingSize;
    CHTesseract *_tesseract;
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter;
    GPUImageRawDataOutput *_rawDataOutput;
    dispatch_queue_t _processingQueue;
}

@property(nonatomic) BOOL isProcessing;

- (void)newFrameAvailable;

@end

@implementation CHLayoutProcessor

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING

-(instancetype)initWithProcessingSize:(CGSize)size {
    self = [super init];
    if (self) {
        
        _processingSize = size;
        _level = CHTesseractAnalysisLevelBlock;
        _processingQueue = dispatch_queue_create("com.chrishanshew.gpuocr.layoutprocessor.processingqueue", NULL);
        adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;

        _rawDataOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:size resultsInBGRAFormat:YES];
        __block CHLayoutProcessor *blockSelf = self;
        [_rawDataOutput setNewFrameAvailableBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockSelf newFrameAvailable];
            });
        }];

        self.initialFilters = @[adaptiveThresholdFilter];
        [adaptiveThresholdFilter addTarget:_rawDataOutput];
        self.terminalFilter = adaptiveThresholdFilter;
    }
    return self;
}

- (void)newFrameAvailable {
    if (_isProcessing || isEndProcessing) {
        return;
    }

    [self willBeginLayoutAnalysis:self];

    [_rawDataOutput lockFramebufferForReading];
    void * rawImageData = (void *)[_rawDataOutput rawBytesForImage];
    [_rawDataOutput unlockFramebufferAfterReading];

    __block CHLayoutProcessor *blockSelf = self;
    dispatch_async(_processingQueue, ^{
        CFTimeInterval startTime = CACurrentMediaTime();
        NSMutableData *pixels = [NSMutableData dataWithCapacity:(_processingSize.width * _processingSize.height)];

        // TODO: Optimizable?
        // starting at 0 may only apply to adaptive thresholder.  luminance uses alpha channel
        for (int i = 0; i < ((4 * _processingSize.width) * _processingSize.height); i+=4) {
            [pixels appendBytes:(const void *)&rawImageData[i] length:1];
        }

        if (!_tesseract) {
            _tesseract = [[CHTesseract alloc] initForAnalysis];
        }

        [_tesseract setImageWithData:pixels withSize:_processingSize bytesPerPixel:1];
        [_tesseract analyzeLayoutAtLevel:_level newRegionAvailable:^(CHRegion *region) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockSelf processor:blockSelf newRegionAvailable:region];
            });
        } completion:^(NSArray *regions) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockSelf processor:blockSelf finishedLayoutAnalysisWithRegions:regions];
            });
        }];
        [_tesseract clear];

        NSLog(@"Layout Analyzed in %g s", CACurrentMediaTime() - startTime);
    });
}

-(void)setLevel:(CHTesseractAnalysisLevel)level {
    _level = level;
}

-(void)setBlurRadius:(float)blurRadius {
    _blurRadius = blurRadius;
    adaptiveThresholdFilter.blurRadiusInPixels = _blurRadius;
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

#pragma mark - <CHLayoutProcessorDelegate>

- (void)processor:(CHLayoutProcessor *)processor newRegionAvailable:(CHRegion *)region {
    [_delegate processor:processor newRegionAvailable:region];
}

- (void)processor:(CHLayoutProcessor *)processor finishedLayoutAnalysisWithRegions:(NSArray *)regions {
    _isProcessing = NO;
    [_delegate processor:processor finishedLayoutAnalysisWithRegions:regions];
}

- (void)willBeginLayoutAnalysis:(CHLayoutProcessor *)processor {
    _isProcessing = YES;
    if ([_delegate respondsToSelector:@selector(willBeginLayoutAnalysis:)]) {
        [_delegate willBeginLayoutAnalysis:processor];
    }
}

@end
