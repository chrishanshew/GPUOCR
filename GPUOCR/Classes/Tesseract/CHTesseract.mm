//
//  CHTesseract.m
//  CHTesseract
//
//  Created by Chris Hanshew on 5/18/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHTesseract.h"
#import "CHResultGroup.h"
#import "CHResult.h"
#import "apitypes.h"
#import "baseapi.h"
#import "osdetect.h"

namespace tesseract {
    class TessBaseAPI;
}

@interface CHTesseract() {
    tesseract::TessBaseAPI *_tesseract;
    NSData *_pixelData;
}

- (void)configureTesseractEnvironment;

- (void)getBoundingBox:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forResult:(CHResult *)result;
- (void)getBaseline:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forResult:(CHResult *)result;
- (void)getOrientation:(tesseract::ResultIterator *)iterator forResult:(CHResult *)result;
- (void)getText:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forResult:(CHResult *)result;
- (void)getTextDirection:(CHResultGroup *)group;
- (void)getOrientation;

@end

@implementation CHTesseract

#pragma mark - Lifecycle

- (instancetype)initForAnalysis {
    self = [super init];
    if (self) {
        [self configureTesseractEnvironment];
        _tesseract = new tesseract::TessBaseAPI;
        _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO);
        _tesseract->InitForAnalysePage();
    }
    return self;
}

- (instancetype)initForOrientationDetection {
    self = [super init];
    if (self) {
        [self configureTesseractEnvironment];
        _tesseract = new tesseract::TessBaseAPI;
//        _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO_OSD);
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *tessdataPath = [bundle resourcePath];
        _tesseract->Init([[tessdataPath stringByAppendingString:@"/"]cStringUsingEncoding:NSUTF8StringEncoding], [@"osd" cStringUsingEncoding:NSUTF8StringEncoding]);
        
    }
    return self;
}

- (instancetype)initForRecognitionWithLanguage:(NSString *)language {
    self = [super init];
    if (self) {
        [self configureTesseractEnvironment];
        _tesseract = new tesseract::TessBaseAPI;
        _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO);
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *tessdataPath = [bundle resourcePath];
        _tesseract->Init([[tessdataPath stringByAppendingString:@"/"]cStringUsingEncoding:NSUTF8StringEncoding], [language cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return self;
}

- (void)dealloc {
    if (_tesseract) {
        _tesseract->End();
        delete _tesseract;
    }
}

#pragma mark - Tesseract API

- (void)setImageWithData:(NSData *)data withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes {
    _pixelData = data;
    _tesseract->Clear();
    _tesseract->SetImage((const unsigned char *)_pixelData.bytes, size.width, size.height, (int)bytes, (size.width * bytes));
}

- (void)setImage:(const unsigned char *)data withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes {
    _pixelData = [NSMutableData dataWithBytes:data length:(size.width * bytes) * size.height];
    _tesseract->Clear();
    _tesseract->SetImage((const unsigned char *)_pixelData.bytes, size.width, size.height, (int)bytes, (size.width * bytes));
}

- (void)recognize {
    _tesseract->Recognize(0);
}

- (NSString *)recognizeText {
    return [NSString stringWithUTF8String:_tesseract->GetUTF8Text()];
}

- (CHResultGroup *)recognizeAtLevel:(CHTesseractAnalysisLevel)level {
    _tesseract->Recognize(0);
    tesseract::ResultIterator* iterator = _tesseract->GetIterator();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;

    if (iterator) {
        NSMutableArray *results = [NSMutableArray array];
        CHResult *result;
        int index = 0;

        do {
            result = [[CHResult alloc] init];
            [self getBoundingBox:iterator atLevel:iteratorLevel forResult:result];
            [self getBaseline:iterator atLevel:iteratorLevel forResult:result];
            [self getText:iterator atLevel:iteratorLevel forResult:result];

            result.index = index++;
            [results addObject:result];

        } while (iterator->Next(iteratorLevel));

        CHResultGroup *resultGroup = [[CHResultGroup alloc] init];
        resultGroup.results = results;

        [self getTextDirection:resultGroup];

        delete iterator;

        return resultGroup;
    }
    return nil;
}

- (CHResultGroup *)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level {
    _tesseract->AnalyseLayout();
    tesseract::ResultIterator* iterator = _tesseract->GetIterator();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;

    if (iterator) {
        NSMutableArray *results = [NSMutableArray array];
        CHResult *result;

        int index = 0;
        do {
            result = [[CHResult alloc] init];

            [self getBoundingBox:iterator atLevel:iteratorLevel forResult:result];
            [self getBaseline:iterator atLevel:iteratorLevel forResult:result];

            result.index = index++;
            [results addObject:result];
        } while (iterator->Next(iteratorLevel));

        CHResultGroup *resultGroup = [[CHResultGroup alloc] init];
        resultGroup.results = results;

        [self getTextDirection:resultGroup];

        delete iterator;
        
        return resultGroup;
    }
    
    return nil;
}

- (CHResultGroup *)detectionAtLevel:(CHTesseractAnalysisLevel)level {
    _tesseract->AnalyseLayout();
    tesseract::ResultIterator *iterator = _tesseract->GetIterator();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;

    if (iterator) {
        NSMutableArray *results = [NSMutableArray array];
        CHResult *result;

        int index = 0;

        do {
            result = [[CHResult alloc] init];

            [self getBoundingBox:iterator atLevel:iteratorLevel forResult:result];
            [self getBaseline:iterator atLevel:iteratorLevel forResult:result];
            [self getOrientation:iterator forResult:result];

            result.index = index++;
            [results addObject:result];
        } while (iterator->Next(iteratorLevel));

        CHResultGroup *resultGroup = [[CHResultGroup alloc] init];
        resultGroup.results = results;

        [self getTextDirection:resultGroup];

        delete iterator;

        return resultGroup;
    }
    return nil;
}

- (NSString *)hOCRText {
    return [NSString stringWithUTF8String:_tesseract->GetHOCRText(0)];
}

- (void)getBoundingBox:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forResult:(CHResult *)result {
    int left, top, right, bottom;
    iterator->BoundingBox(level, &left, &top, &right, &bottom);
    result.left = left;
    result.top = top;
    result.right = right;
    result.bottom = bottom;
//    NSLog(@"%@", CGRectCreateDictionaryRepresentation(result.getRect));
}

- (void)getBaseline:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forResult:(CHResult *)result {
    int xStart, yStart, xEnd, yEnd;
    iterator->Baseline(level, &xStart, &yStart, &xEnd, &yEnd);
    result.start = CGPointMake(xStart, yStart);
    result.end = CGPointMake(xEnd, yEnd);
}

- (void)getOrientation:(tesseract::ResultIterator *)iterator forResult:(CHResult *)result {
    tesseract::Orientation orientation;
    tesseract::WritingDirection writingDirection;
    tesseract::TextlineOrder textlineOrder;
    float deskew;
    iterator->Orientation(&orientation, &writingDirection, &textlineOrder, &deskew);
    //NSLog(@"Orientation: %i\nWriting Direction: %i\nTextline Order: %i\nDeskew: %f", orientation, writingDirection, textlineOrder, deskew);
}

- (void)getText:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forResult:(CHResult *)result {
    char * text = iterator->GetUTF8Text(level);
    if (text) {
        result.text = [NSString stringWithUTF8String:text];
        result.confidence = iterator->Confidence(level);
        NSLog(@"%@", result.text);
    }
}

- (void)getTextDirection:(CHResultGroup *)group {
    // Text Direction
    int offset; float slope;
    _tesseract->GetTextDirection(&offset, &slope);
    group.offset = offset;
    group.slope = slope;
//    NSLog(@"Offset: %i, Slope: %f", offset, slope);
}

- (void)getOrientation {
    OSResults osResults;
    if (_tesseract->DetectOS(&osResults)) {
        NSLog(@"Orientations:");
        for (int i = 0; i <= 3; i++) {
            NSLog(@"%f", osResults.orientations[i]);
        }
    }
}

- (void)setVariableNamed:(NSString *)named withValue:(NSString *)value {
    _tesseract->SetVariable([named cStringUsingEncoding:NSUTF8StringEncoding], [value cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)clear {
    _tesseract->Clear();
}

- (NSString *)tesseractVersion {
    return [NSString stringWithUTF8String:_tesseract->Version()];
}

#pragma mark - Tesseract Configuration

- (void)configureTesseractEnvironment {
    if (!getenv("TESSDATA_PREFIX")) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *tessdataPath = [bundle resourcePath];
        setenv("TESSDATA_PREFIX", [[tessdataPath stringByAppendingString:@"/tessdata"] UTF8String], 1);
    }
}

@end
