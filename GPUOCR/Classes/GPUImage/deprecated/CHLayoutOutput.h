//
//  CHLayoutOutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHRegion.h"

@class CHLayoutOutput;

@protocol CHLayoutOutputDelegate <NSObject>

@required
- (void)output:(CHLayoutOutput*)output completedAnalysisWithRegions:(NSArray *)regions;

@optional
- (void)willBeginAnalysisWithOutput:(CHLayoutOutput *)output;

@end

@interface CHLayoutOutput : GPUImageRawDataOutput <CHLayoutOutputDelegate>

@property (nonatomic, weak)id<CHLayoutOutputDelegate> delegate;
@property (nonatomic)CHTesseractAnalysisLevel level;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat;

@end
