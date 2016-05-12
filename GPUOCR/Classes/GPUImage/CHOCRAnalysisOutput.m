//
//  CHOCRAnalysisOutput.m
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHOCRAnalysisOutput.h"

@interface CHOCRAnalysisOutput () {
    CHTesseract *_tesseract;
    NSOperationQueue *_operationQueue;
}

-(void (^)())analyzeLayoutBlock;

@end

@implementation CHOCRAnalysisOutput

#pragma mark - Init

-(instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat {
    self = [self initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat withDelegate: nil];
    if (self) {
        _tesseract = [[CHTesseract alloc] initForAnalysis];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        [self setNewFrameAvailableBlock: self.analyzeLayoutBlock];
    }
    return self;
}

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat withDelegate:(id<CHOCRAnalysisOutputDelegate>)delegate {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _delegate = delegate;
        _tesseract = [[CHTesseract alloc] initForAnalysis];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        [self setNewFrameAvailableBlock: self.analyzeLayoutBlock];
    }
    return self;
}

#pragma mark - New Frame Available Block

-(void (^)())analyzeLayoutBlock {
    __block CHOCRAnalysisOutput *weakSelf = self;
    __block CHTesseract *weakTesseract = _tesseract;
    return ^(void) {
        if (weakSelf.enabled && _operationQueue.operationCount == 0) {
            [weakSelf willBeginAnalysisWithOutput:weakSelf];
            [weakSelf lockFramebufferForReading];
            
            
            GLubyte * outputBytes = [weakSelf rawBytesForImage];
            int height = weakSelf.maximumOutputSize.height;
            int width = weakSelf.maximumOutputSize.width;
            
            NSMutableData *pixels = [NSMutableData dataWithCapacity:(height * width)];
            
            // TODO: Optimizable?
            // Read last byte (alpha) for RBGA pixels
            for (int i = 4; i < ((4 * width) * height) + 4; i+=4) {
                [pixels appendBytes:(const void *)&outputBytes[i] length:1];
            }
            
            [weakSelf unlockFramebufferAfterReading];
            
            if (_operationQueue.operationCount == 0) {
                [_operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                    [weakTesseract setImageWithData:pixels withSize:weakSelf.maximumOutputSize bytesPerPixel:1];
                    CHOCRAnalysisResult *result = [weakTesseract analyzeLayoutAtLevel: CHTesseractAnalysisLevelTextLine];
                    [weakTesseract clear];
                    [weakSelf output:weakSelf didFinishAnalysisWithResult:result];
                }]];
            }
        }
    };
}

#pragma mark - Delegate

- (void)willBeginAnalysisWithOutput:(CHOCRAnalysisOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginAnalysisWithOutput:)]) {
        [_delegate willBeginAnalysisWithOutput:output];
    }
}

-(void)output:(CHOCRAnalysisOutput*)output didFinishAnalysisWithResult:(CHOCRAnalysisResult *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishAnalysisWithResult:)]) {
        [_delegate output:output didFinishAnalysisWithResult:result];
    }
}

@end
