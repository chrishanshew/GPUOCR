//
// Created by Chris Hanshew on 5/14/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHOCRDetectionOutput.h"

@interface CHOCRDetectionOutput () {
    CHTesseract *_tesseract;
    NSOperationQueue *_operationQueue;
}

-(void (^)())analyzeLayoutBlock;

@end

@implementation CHOCRDetectionOutput

#pragma mark - Init

-(instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat {
    self = [self initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat withDelegate: nil];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat withDelegate:(id<CHOCRDetectionOutputDelegate>)delegate {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _delegate = delegate;
        _tesseract = [[CHTesseract alloc] initForOrientationDetection];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        [self setNewFrameAvailableBlock: self.analyzeLayoutBlock];
    }
    return self;
}


#pragma mark - New Frame Available Block

-(void (^)())analyzeLayoutBlock {
    __block CHOCRDetectionOutput *weakSelf = self;
    __block CHTesseract *weakTesseract = _tesseract;
    return ^(void) {
        if (weakSelf.enabled && _operationQueue.operationCount == 0) {
            [weakSelf lockFramebufferForReading];


            GLubyte * outputBytes = [weakSelf rawBytesForImage];
            int height = weakSelf.maximumOutputSize.height;
            int width = weakSelf.maximumOutputSize.width;

            NSMutableData *pixels = [NSMutableData dataWithCapacity:(height * width)];

            // TODO: Optimizable?
            // Read last byte (alpha) for RBGA pixels
            for (int i = 0; i < ((4 * width) * height); i+=4) {
                [pixels appendBytes:(const void *)&outputBytes[i] length:1];
            }

            [weakSelf unlockFramebufferAfterReading];

            if (_operationQueue.operationCount == 0) {
                [_operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                    [weakTesseract setImageWithData:pixels withSize:weakSelf.maximumOutputSize bytesPerPixel:1];
                    CHResultGroup *result = [weakTesseract detectionAtLevel: _level];
                    [weakSelf output:self didFinishDetectionWithResult:result];
                    [weakTesseract clear];
                }]];
            }
        }
    };
}

#pragma mark - Delegate

- (void)willBeginDetectionWithOutput:(CHOCRDetectionOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginDetectionWithOutput:)]) {
        [_delegate willBeginDetectionWithOutput:output];
    }
}

-(void)output:(CHOCRDetectionOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishDetectionWithResult:)]) {
        [_delegate output:output didFinishDetectionWithResult:result];
    }
}

@end