//
//  CHOCROutput.h
//  CHOCR
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//


#import "GPUImage.h"
#import "CHRegion.h"

@class CHOCROutput;
@class CHText;

@protocol CHOCROutputDelegate <NSObject>

@required
- (void)output:(CHOCROutput *)output completedOCRWithText:(CHText *)text;

@optional
- (void)output:(CHOCROutput *)output willBeginOCRForRegion:(CHRegion *)region;

@end

@interface CHOCROutput : GPUImageRawDataOutput <CHOCROutputDelegate>

@property(nonatomic, weak)id<CHOCROutputDelegate> delegate;
@property(nonatomic, strong, readonly)NSString* language;
@property(nonatomic, strong, setter=setRegion:) CHRegion *region;

- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat forLanguage:(NSString *)language;

@end
