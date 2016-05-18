//
//  CHRecognitionOutput.m
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#define kDefaultBytesPerPixel 4
#define kRecognitionOutputMaxConcurrentOperations 1

#import "CHRecognitionOutput.h"
#import "CHTesseract.h"

@interface CHRecognitionOutput () {
    CHTesseract *_tesseract;
    NSOperationQueue *_operationQueue;
}

-(void (^)())recognizeTextBlock;

@end

@implementation CHRecognitionOutput

#pragma mark - Init

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {
        _language = language;
        _tesseract = [[CHTesseract alloc]initForRecognitionWithLanguage:language];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = kRecognitionOutputMaxConcurrentOperations;
        [self setNewFrameAvailableBlock:[self recognizeTextBlock]];
    }
    return self;
}

#pragma mark - New Frame Available Block

-(void (^)())recognizeTextBlock {
    __block CHRecognitionOutput *weakSelf = self;
    __block CHTesseract *weakTesseract = _tesseract;
    return ^(void) {
        if (weakSelf.enabled && _operationQueue.operationCount == 0 && _region) {
            weakSelf.enabled = NO;
            [weakSelf output:weakSelf willRecognizeRegion:weakSelf.region];
            [weakSelf lockFramebufferForReading];
            
            GLubyte * outputBytes = [weakSelf rawBytesForImage];
            int height = imageSize.height;
            int width = imageSize.width;
            int bytesPerPixel = weakSelf.bytesPerRowInOutput / width;

            NSMutableData *pixels = [NSMutableData dataWithCapacity:(height * width)];

            // Read last byte (alpha) for RBGA pixels
            for (int i = 0; i < ((4 * width) * height); i+=4) {
                [pixels appendBytes:(const void *)&outputBytes[i] length:1];
            }
            
            [weakSelf unlockFramebufferAfterReading];
            
            if (_operationQueue.operationCount == 0) {
                [_operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                    [weakTesseract setImageWithData:pixels withSize:imageSize bytesPerPixel:1];
                    CHText *text = [weakTesseract recognizeTextAtLevel:weakSelf.region.level];
                    text.region = weakSelf.region;
                    [weakSelf output:weakSelf completedRecognitionWithText:text];
                    [weakTesseract clear];
                }]];
            }
            weakSelf.enabled = YES;
        }
    };
}

-(void)setRegion:(CHRegion *)region {
    if (_operationQueue.operationCount == 0) {
        _region = region;
    }
}

#pragma mark - Delegate

- (void)output:(CHRecognitionOutput *)output completedRecognitionWithText:(CHText *)text {
    if ([_delegate respondsToSelector:@selector(output:completedRecognitionWithText:)]) {
        [_delegate output:output completedRecognitionWithText:text];
    }
}

- (void)output:(CHRecognitionOutput *)output willRecognizeRegion:(CHRegion *)region {
    if ([_delegate respondsToSelector:@selector(output:willRecognizeRegion:)]) {
        [_delegate output:output willRecognizeRegion:region];
    }
}

@end
