//
//  CHRecognitionOutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"
#import "CHRegion.h"

@class CHRecognitionOutput;
@class CHText;

@protocol CHRecognitionOutputDelegate <NSObject>

@required
- (void)output:(CHRecognitionOutput *)output completedRecognitionWithText:(CHText *)text;

@optional
- (void)output:(CHRecognitionOutput *)output willRecognizeRegion:(CHRegion *)region;

@end

@interface CHRecognitionOutput : GPUImageRawDataOutput <CHRecognitionOutputDelegate>

@property(nonatomic, weak)id<CHRecognitionOutputDelegate> delegate;
@property(nonatomic, strong, readonly)NSString* language;
@property (nonatomic, assign, readonly) CHRegion *region;

- (instancetype)initWithImageSize:(CGSize)newImageSize forRegion:(CHRegion *)region resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language;

@end
