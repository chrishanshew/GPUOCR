//
//  CHOCRRecognitionOutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHResultGroup.h"

@class CHOCRRecognitionOutput;

@protocol CHOCRRecogntionOutputDelegate <NSObject>

@required
- (void)output:(CHOCRRecognitionOutput *)output didFinishRecognitionWithResult:(CHResultGroup *)result;

@optional
- (void)willBeginRecognitionWithOutput:(CHOCRRecognitionOutput *)output;

@end

@interface CHOCRRecognitionOutput : GPUImageRawDataOutput <CHOCRRecogntionOutputDelegate>

@property(nonatomic, weak)id<CHOCRRecogntionOutputDelegate> delegate;
@property(nonatomic, strong, readonly)NSString* language;
@property(nonatomic)CHTesseractAnalysisLevel level;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language;
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language withDelegate:(id<CHOCRRecogntionOutputDelegate>)delegate;

@end
