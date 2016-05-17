//
//  CHAnalysisOutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHRegion.h"

@class CHAnalysisOutput;

@protocol CHAnalysisOutputDelegate <NSObject>

@required
- (void)output:(CHAnalysisOutput*)output completedAnalysisWithRegions:(NSArray *)regions;

@optional
- (void)willBeginAnalysisWithOutput:(CHAnalysisOutput *)output;

@end

@interface CHAnalysisOutput : GPUImageRawDataOutput <CHAnalysisOutputDelegate>

@property(nonatomic, weak)id<CHAnalysisOutputDelegate> delegate;
@property(nonatomic)CHTesseractAnalysisLevel level;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;

@end
