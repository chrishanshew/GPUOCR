//
//  CHOCRAnalysisOutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHTesseract.h"

@class CHOCRAnalysisOutput;

@protocol CHOCRAnalysisOutputDelegate <NSObject>

@required
- (void)output:(CHOCRAnalysisOutput*)output didFinishAnalysisWithResult:(CHResultGroup *)result;

@optional
- (void)willBeginAnalysisWithOutput:(CHOCRAnalysisOutput *)output;

@end

@interface CHOCRAnalysisOutput : GPUImageRawDataOutput <CHOCRAnalysisOutputDelegate>

@property(nonatomic, weak)id<CHOCRAnalysisOutputDelegate> delegate;
@property(nonatomic, readonly)CHTesseractAnalysisLevel level;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat withDelegate:(id<CHOCRAnalysisOutputDelegate>)delegate;

@end
