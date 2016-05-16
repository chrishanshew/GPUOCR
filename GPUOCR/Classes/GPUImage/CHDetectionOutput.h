//
// Created by Chris Hanshew on 5/14/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "CHTesseract.h"

@class CHDetectionOutput;

@protocol CHOCRDetectionOutputDelegate <NSObject>

@required
- (void)output:(CHDetectionOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result;

@optional
- (void)willBeginDetectionWithOutput:(CHDetectionOutput *)output;

@end

@interface CHDetectionOutput : GPUImageRawDataOutput <CHOCRDetectionOutputDelegate>

@property(nonatomic, weak)id<CHOCRDetectionOutputDelegate> delegate;
@property(nonatomic)CHTesseractAnalysisLevel level;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat withDelegate:(id<CHOCRDetectionOutputDelegate>)delegate;

@end