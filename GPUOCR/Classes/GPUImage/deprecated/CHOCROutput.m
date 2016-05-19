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

@interface CHOCROutput ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property(nonatomic, strong) CHTesseract *tesseract;

- (CGSize)getImageSize;

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

        __block CHOCROutput *weakSelf = self;
        [self setNewFrameAvailableBlock: (^{
            if (weakSelf.enabled && weakSelf.operationQueue.operationCount == 0) {
                [weakSelf outputWillBeginOCRForRegion:weakSelf];
                [weakSelf lockFramebufferForReading];

                GLubyte * outputBytes = [weakSelf rawBytesForImage];
                CGSize size = [weakSelf getImageSize];
                int height = size.height;
                int width = size.width;

                NSMutableData *pixels = [NSMutableData dataWithCapacity:(height * width)];

                // TODO: Optimizable?
                // Read last byte (alpha) for RBGA pixels

                // starting at 0 may only apply to adaptive thresholder
                for (int i = 0; i < ((4 * width) * height); i+=4) {
                    [pixels appendBytes:(const void *)&outputBytes[i] length:1];
                }
                [weakSelf unlockFramebufferAfterReading];

                [weakSelf.tesseract setImageWithData:pixels withSize:size bytesPerPixel:1];

                if (weakSelf.operationQueue.operationCount == 0) {
                    [weakSelf.operationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                        CFTimeInterval startTime = CACurrentMediaTime();
                        CHText *text = [weakSelf.tesseract recognizeTextAtLevel: weakSelf.level];
                        [weakSelf output:weakSelf completedOCRWithText:text];
                        CFTimeInterval endTime = CACurrentMediaTime();
                        NSLog(@"Total Runtime: %g s", endTime - startTime);
                    }]];
                }
            }
        })];
    }
    return self;
}

-(CGSize)getImageSize {
    return imageSize;
}

#pragma mark - <CHOCROutputDelegate>

- (void)output:(CHOCROutput *)output completedOCRWithText:(CHText *)text {
    if ([_delegate respondsToSelector:@selector(output:completedOCRWithText:)]) {
        [_delegate output:output completedOCRWithText:text];
    }
}

- (void)outputWillBeginOCRForRegion:(CHOCROutput *)output {
    if ([_delegate respondsToSelector:@selector(outputWillBeginOCRForRegion:)]) {
        [_delegate outputWillBeginOCRForRegion:output];
    }
}

@end
