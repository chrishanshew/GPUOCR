//
//  CHTesseract.h
//  CHTesseract
//
//  Created by Chris Hanshew on 5/18/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CHRegion.h"
#import "CHText.h"

@interface CHTesseract : NSObject

@property(nonatomic, strong, readonly)NSString *language;

- (instancetype)initForAnalysis;
- (instancetype)initForOrientationDetection;
- (instancetype)initForRecognitionWithLanguage:(NSString *)language;

// Default 1 bpp
- (void)setImageWithData:(NSData *)data withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes;

- (CHText *)recognizeTextAtLevel:(CHTesseractAnalysisLevel)level;
- (void)recognizeTextAtLevel:(CHTesseractAnalysisLevel)level completion:(void(^)(CHText *text))completion;
- (NSArray *)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level;
- (void)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level newRegionAvailable:(void(^)(CHRegion *region))newRegionAvailable completion:(void(^)(NSArray *regions))completion;

- (NSString *)hOCRText;

- (void)clear;
- (void)clearAdaptiveClassifier;
- (void)clearPersistentCache;
- (void)end;

- (void)setVariableNamed:(NSString *)named withValue:(NSString *)value;
- (NSString *)tesseractVersion;

@end
