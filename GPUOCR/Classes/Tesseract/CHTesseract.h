//
//  CHTesseract.h
//  CHTesseract
//
//  Created by Chris Hanshew on 5/18/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CHDetectionResult.h"

@class CHAnalysisResult;
@class CHRecognitionResult;

typedef NS_ENUM(NSUInteger, CHTesseractAnalysisLevel) {
    CHTesseractAnalysisLevelBlock = 0,
    CHTesseractAnalysisLevelParagraph,
    CHTesseractAnalysisLevelTextLine,
    CHTesseractAnalysisLevelWord,
    CHTesseractAnalysisLevelSymbol
};

@interface CHTesseract : NSObject

@property(nonatomic, strong, readonly)NSString *language;

- (instancetype)initForAnalysis;
- (instancetype)initForOrientationDetection;
- (instancetype)initForRecognitionWithLanguage:(NSString *)language;

// Default 1 bpp
- (void)setImageWithData:(NSMutableData *)data withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes;
//- (void)setImage:(const unsigned char *)image withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes;

- (void)recognize;
- (void)detect;
- (NSString *)recognizeText;
- (CHRecognitionResult *)recognizeAtLevel:(CHTesseractAnalysisLevel)level;
- (NSString *)hOCRText;
- (CHAnalysisResult *)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level;

- (void)setVariableNamed:(NSString *)named withValue:(NSString *)value;

- (void)clear;

- (NSString *)tesseractVersion;

@end
