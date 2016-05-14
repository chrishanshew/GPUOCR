//
// Created by Chris Hanshew on 5/14/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "CHTesseract.h"

@class CHOCRDetectionOutput;

@protocol CHOCRDetectionOutputDelegate <NSObject>

@required
- (void)output:(CHOCRDetectionOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result;

@optional
- (void)willBeginDetectionWithOutput:(CHOCRDetectionOutput *)output;

@end

@interface CHOCRDetectionOutput : GPUImageRawDataOutput <CHOCRDetectionOutputDelegate>

@property(nonatomic, weak)id<CHOCRDetectionOutputDelegate> delegate;
@property(nonatomic, readonly)CHTesseractAnalysisLevel level;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat withDelegate:(id<CHOCRDetectionOutputDelegate>)delegate;

@end