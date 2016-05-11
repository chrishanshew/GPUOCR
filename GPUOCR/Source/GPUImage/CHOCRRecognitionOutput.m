//
//  CHOCRRecognitionOutput.m
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#define kDefaultBytesPerPixel 4

#import "CHOCRRecognitionOutput.h"

@interface CHOCRRecognitionOutput ()

@property(nonatomic, strong) CHTesseract* tesseract;

-(void (^)())analyzeLayoutBlock;

@end

@implementation CHOCRRecognitionOutput

#pragma mark - Init

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _tesseract = [[CHTesseract alloc]initForRecognitionWithLanguage:language];
        [self setNewFrameAvailableBlock:[self analyzeLayoutBlock]];
    }
    return self;
}

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language withDelegate:(id<CHOCRRecogntionOutputDelegate>)delegate {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _delegate = delegate;
        _tesseract = [[CHTesseract alloc]initForRecognitionWithLanguage:language];
        [self setNewFrameAvailableBlock:[self analyzeLayoutBlock]];
    }
    return self;
}

#pragma mark - New Frame Available Block

-(void (^)())analyzeLayoutBlock {
    __block CHOCRRecognitionOutput *weakSelf = self;
    return ^(void) {
        if (weakSelf.enabled) {
            [weakSelf willBeginRecognitionWithOutput:weakSelf];
            [weakSelf lockFramebufferForReading];
            

            unsigned char * outputBytes = [weakSelf rawBytesForImage];
            int height = weakSelf.maximumOutputSize.height;
            int width = weakSelf.maximumOutputSize.width;

            unsigned char * mappedBytes = (unsigned char *)malloc(width * height);
            int index = 0;

            // Iterate the RGBA Bytes and the use the last byte (alpha) to create a 1 bit monochrome image
            for (int i = 4; i < ((4 * width) * height) - 4; i+=4) {
                mappedBytes[index++] = outputBytes[i];
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [weakSelf.tesseract setImage:mappedBytes withSize:weakSelf.maximumOutputSize bytesPerPixel:1];
                CHOCRRecognitionResult *result = [weakSelf.tesseract recognizeAtLevel: CHTesseractAnalysisLevelBlock];
                [weakSelf.tesseract clear];
                [weakSelf output:weakSelf didFinishRecognitionWithResult:result];
            });
            
            [weakSelf unlockFramebufferAfterReading];
        }
    };
}

#pragma mark - Delegate

- (void)output:(CHOCRRecognitionOutput *)output didFinishRecognitionWithResult:(CHOCRRecognitionResult *)result {
    if ([_delegate respondsToSelector:@selector(output:didFinishRecognitionWithResult:)]) {
        [_delegate output:output didFinishRecognitionWithResult:result];
    }
}

- (void)willBeginRecognitionWithOutput:(CHOCRRecognitionOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginRecognitionWithOutput:)]) {
        [_delegate willBeginRecognitionWithOutput:output];
    }
}

@end
