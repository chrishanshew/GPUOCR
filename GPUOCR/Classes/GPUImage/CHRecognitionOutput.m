//
//  CHRecognitionOutput.m
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#define kDefaultBytesPerPixel 4

#import "CHRecognitionOutput.h"

@interface CHRecognitionOutput () {
    CHTesseract *_tesseract;
    NSOperationQueue *_operationQueue;
}

-(void (^)())analyzeLayoutBlock;

@end

@implementation CHRecognitionOutput

#pragma mark - Init

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _tesseract = [[CHTesseract alloc]initForRecognitionWithLanguage:language];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        [self setNewFrameAvailableBlock:[self analyzeLayoutBlock]];
    }
    return self;
}

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language withDelegate:(id<CHOCRRecogntionOutputDelegate>)delegate {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _delegate = delegate;
        _tesseract = [[CHTesseract alloc]initForRecognitionWithLanguage:language];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        [self setNewFrameAvailableBlock:[self analyzeLayoutBlock]];
    }
    return self;
}

#pragma mark - New Frame Available Block

-(void (^)())analyzeLayoutBlock {
    __block CHRecognitionOutput *weakSelf = self;
    __block CHTesseract *weakTesseract = _tesseract;
    return ^(void) {
        if (weakSelf.enabled && _operationQueue.operationCount == 0) {
            [weakSelf willBeginRecognitionWithOutput:weakSelf];
            [weakSelf lockFramebufferForReading];
            
            GLubyte * outputBytes = [weakSelf rawBytesForImage];
            int height = weakSelf.maximumOutputSize.height;
            int width = weakSelf.maximumOutputSize.width;

            NSMutableData *pixels = [NSMutableData dataWithCapacity:(height * width)];

            // Read last byte (alpha) for RBGA pixels
            for (int i = 0; i < ((4 * width) * height); i+=4) {
                [pixels appendBytes:(const void *)&outputBytes[i] length:1];
            }
            
            [weakSelf unlockFramebufferAfterReading];
            
            if (_operationQueue.operationCount == 0) {
                [_operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                    [weakTesseract setImageWithData:pixels withSize:weakSelf.maximumOutputSize bytesPerPixel:1];
                    CHResultGroup *result = [weakTesseract recognizeAtLevel: _level];
                    [weakSelf output:weakSelf didFinishRecognitionWithResult:result];
                    [weakTesseract clear];
                }]];
            }
        }
    };
}

#pragma mark - Delegate

- (void)output:(CHRecognitionOutput *)output didFinishRecognitionWithResult:(CHResultGroup *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishRecognitionWithResult:)]) {
        [_delegate output:output didFinishRecognitionWithResult:result];
    }
}

- (void)willBeginRecognitionWithOutput:(CHRecognitionOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginRecognitionWithOutput:)]) {
        [_delegate willBeginRecognitionWithOutput:output];
    }
}

@end
