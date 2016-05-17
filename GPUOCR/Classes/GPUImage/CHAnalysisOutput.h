//
//  CHAnalysisOutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHTesseract.h"

@class CHAnalysisOutput;

@protocol CHOCRAnalysisOutputDelegate <NSObject>

@required
- (void)output:(CHAnalysisOutput*)output didFinishAnalysisWithLayout:(CHLayout *)layout;

@optional
- (void)willBeginAnalysisWithOutput:(CHAnalysisOutput *)output;

@end

@interface CHAnalysisOutput : GPUImageRawDataOutput <CHOCRAnalysisOutputDelegate>

@property(nonatomic, weak)id<CHOCRAnalysisOutputDelegate> delegate;
@property(nonatomic)CHTesseractAnalysisLevel level;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;

@end
