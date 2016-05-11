//
//  CHOCRAnalysisOutput.m
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHOCRAnalysisOutput.h"

@interface CHOCRAnalysisOutput ()

@property (nonatomic, strong)CHTesseract *tesseract;
@property (nonatomic) dispatch_queue_t queue;

-(void (^)())analyzeLayoutBlock;

@end

@implementation CHOCRAnalysisOutput

#pragma mark - Init

-(instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat {
    self = [self initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat withDelegate: nil];
    if (self) {

    }
    return self;
}

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat withDelegate:(id<CHOCRAnalysisOutputDelegate>)delegate {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _delegate = delegate;
        _tesseract = [[CHTesseract alloc] initForAnalysis];
        _queue = dispatch_queue_create("com.chrishanshew.tesseract.analysisoutput", DISPATCH_QUEUE_SERIAL);
        [self setNewFrameAvailableBlock: self.analyzeLayoutBlock];
    }
    return self;
}

#pragma mark - New Frame Available Block

-(void (^)())analyzeLayoutBlock {
    __block CHOCRAnalysisOutput *weakSelf = self;
    return ^(void) {
        if (weakSelf.enabled) {
            weakSelf.enabled = NO;
            [weakSelf lockFramebufferForReading];
            [weakSelf willBeginAnalysisWithOutput:weakSelf];

            unsigned char * outputBytes = [weakSelf rawBytesForImage];
            int height = weakSelf.maximumOutputSize.height;
            int width = weakSelf.maximumOutputSize.width;

            unsigned char * mappedBytes = (unsigned char *)malloc(width * height);
            int index = 0;

            // Iterate the RGBA Bytes and the use the last byte (alpha) to create a 1 bit monochrome image
            for (int i = 4; i < ((4 * width) * height) - 4; i+=4) {
                mappedBytes[index++] = outputBytes[i];
            }

            [weakSelf unlockFramebufferAfterReading];

            dispatch_async(_queue, ^{
                [weakSelf.tesseract setImage:mappedBytes withSize:weakSelf.maximumOutputSize bytesPerPixel:1];
                CHOCRAnalysisResult *result = [weakSelf.tesseract analyzeLayoutAtLevel:weakSelf.level];
                [weakSelf.tesseract clear];
                [weakSelf output:weakSelf didFinishAnalysisWithResult:result];
                weakSelf.enabled = YES;
            });
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
