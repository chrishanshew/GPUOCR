//
//  CHRecognitionOutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHTesseract.h"

@class CHRecognitionOutput;
@class CHRegion;

@protocol CHOCRRecogntionOutputDelegate <NSObject>

@required
- (void)output:(CHRecognitionOutput *)output completedRecognitionWithText:(CHText *)result;

@optional
- (void)output:(CHRecognitionOutput *)output willRecognizeRegion:(CHRegion *)region;

@end

@interface CHRecognitionOutput : GPUImageRawDataOutput <CHOCRRecogntionOutputDelegate>

@property(nonatomic, weak)id<CHOCRRecogntionOutputDelegate> delegate;
@property(nonatomic, strong, readonly)NSString* language;

@property(nonatomic)CHTesseractAnalysisLevel level; // TODO: Will become unused
@property (nonatomic, strong) CHRegion *region;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language;
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language withDelegate:(id<CHOCRRecogntionOutputDelegate>)delegate;

@end
