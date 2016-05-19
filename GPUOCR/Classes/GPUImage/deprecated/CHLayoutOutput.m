//
//  CHLayoutOutput.m
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHLayoutOutput.h"
#import "CHTesseract.h"

#define kAnalysisOutputMaxConcurrentOperations 1

@interface CHLayoutOutput ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) CHTesseract *tesseract;

- (CGSize)getImageSize;

@end

@implementation CHLayoutOutput

#pragma mark - Init

-(instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat {
    self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
    if (self) {

        _tesseract = [[CHTesseract alloc] initForAnalysis];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = kAnalysisOutputMaxConcurrentOperations;

        __block CHLayoutOutput *weakSelf = self;
        [self setNewFrameAvailableBlock: (^{
                if (weakSelf.enabled && weakSelf.operationQueue.operationCount == 0) {
                    [weakSelf willBeginAnalysisWithOutput:weakSelf];
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
                            NSArray *regions = [weakSelf.tesseract analyzeLayoutAtLevel: weakSelf.level];
                            [weakSelf output:weakSelf completedAnalysisWithRegions:regions];
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

#pragma mark - <CHLayoutOutputDelegate>

- (void)willBeginAnalysisWithOutput:(CHLayoutOutput *)output {
    if ([_delegate respondsToSelector:@selector(willBeginAnalysisWithOutput:)]) {
        [_delegate willBeginAnalysisWithOutput:output];
    }
}

-(void)output:(CHLayoutOutput*)output completedAnalysisWithRegions:(NSArray *)regions {
    if ([_delegate respondsToSelector:@selector(output:completedAnalysisWithRegions:)]) {
        [_delegate output:output completedAnalysisWithRegions:regions];
    }
}

@end
