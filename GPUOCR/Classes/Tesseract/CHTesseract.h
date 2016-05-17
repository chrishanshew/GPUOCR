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
- (void)setImage:(const unsigned char *)image withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes;

- (CHText *)recognizeTextAtLevel:(CHTesseractAnalysisLevel)level;
- (NSArray *)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level;

- (NSString *)hOCRText;

- (void)clear;

- (void)setVariableNamed:(NSString *)named withValue:(NSString *)value;
- (NSString *)tesseractVersion;

@end
