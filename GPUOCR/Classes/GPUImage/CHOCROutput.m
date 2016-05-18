//
//  CHOCROutput.m
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#define kDefaultBytesPerPixel 4
#define kRecognitionOutputMaxConcurrentOperations 1

#import "CHOCROutput.h"
#import "CHTesseract.h"

@interface CHOCROutput () {
    CHTesseract *_tesseract;
    NSOperationQueue *_operationQueue;
}

-(void (^)())recognizeTextBlock;

@end

@implementation CHOCROutput

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
    __block CHOCROutput *weakSelf = self;
    return ^(void) {
        if (weakSelf.enabled && _operationQueue.operationCount == 0 && _region) {
            weakSelf.enabled = NO;
            [weakSelf output:weakSelf willBeginOCRForRegion:weakSelf.region];
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
                    [_tesseract setImageWithData:pixels withSize:imageSize bytesPerPixel:1];
                    CHText *text = [_tesseract recognizeTextAtLevel:_region.level];
                    text.region = _region;
                    [_delegate output:weakSelf completedOCRWithText:text];
                    [_tesseract clear];
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

- (void)output:(CHOCROutput *)output completedOCRWithText:(CHText *)text {
    if ([_delegate respondsToSelector:@selector(output:completedOCRWithText:)]) {
        [_delegate output:output completedOCRWithText:text];
    }
}

- (void)output:(CHOCROutput *)output willBeginOCRForRegion:(CHRegion *)region {
    if ([_delegate respondsToSelector:@selector(output:willBeginOCRForRegion:)]) {
        [_delegate output:output willBeginOCRForRegion:region];
    }
}

@end
