//
//  CHTesseract.m
//  CHTesseract
//
//  Created by Chris Hanshew on 5/18/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHTesseract.h"
#import "apitypes.h"
#import "baseapi.h"
#import "osdetect.h"

namespace tesseract {
    class TessBaseAPI;
}

@interface CHTesseract() {
    tesseract::TessBaseAPI *_tesseract;
    NSMutableData *_pixelData;
    CGSize _imageSize;
}

- (void)configureTesseractEnvironment;

- (void)getBoundingBox:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forRegion:(CHRegion *)region;
- (void)getBaseline:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forRegion:(CHRegion *)region;

@end

@implementation CHTesseract

#pragma mark - Lifecycle

- (instancetype)initForAnalysis {
    self = [super init];
    if (self) {
        [self configureTesseractEnvironment];
        _tesseract = new tesseract::TessBaseAPI;
        _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO);
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *tessdataPath = [bundle resourcePath];
        _pixelData = [NSMutableData dataWithLength:0];
        _tesseract->Init([[tessdataPath stringByAppendingString:@"/"]cStringUsingEncoding:NSUTF8StringEncoding], [@"osd" cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return self;
}

- (instancetype)initForOrientationDetection {
    self = [super init];
    if (self) {
        [self configureTesseractEnvironment];
        _tesseract = new tesseract::TessBaseAPI;
        _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO_OSD);
        _pixelData = [NSMutableData dataWithLength:0];
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
        _pixelData = [NSMutableData dataWithLength:0];
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
    _imageSize = size;
    [_pixelData replaceBytesInRange:NSMakeRange(0, data.length) withBytes:data.bytes];
    [_pixelData setLength:data.length];
    _tesseract->SetImage((const unsigned char *)_pixelData.bytes, size.width, size.height, (int)bytes, (size.width * bytes));
}

- (CHText *)recognizeTextAtLevel:(CHTesseractAnalysisLevel)level {
    _tesseract->Recognize(NULL);
    tesseract::ResultIterator* iterator = _tesseract->GetIterator();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;
    CHText *result;
    if (iterator) {

        do {
            char * utfText = iterator->GetUTF8Text(iteratorLevel);
            if (utfText != 0) {
                NSString *text = [NSString stringWithUTF8String: utfText];
                result = [[CHText alloc] init];
                result.text = text;
                result.confidence = iterator->Confidence(iteratorLevel);
                delete utfText;
            }
            
        } while (iterator->Next(iteratorLevel));

        delete iterator;
    }

    return result;
}

-(void)recognizeTextAtLevel:(CHTesseractAnalysisLevel)level completion:(void(^)(CHText *text))completion {
    completion([self recognizeTextAtLevel:level]);
}

- (NSArray *)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level {
    tesseract::PageIterator* iterator = _tesseract->AnalyseLayout();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;
    NSMutableArray *regions = [NSMutableArray array];

    if (iterator) {

        NSDate *date = [NSDate date];
        NSUInteger timestamp = date.timeIntervalSince1970;

        CHRegion *region;

        int index = 0;

        do {
            region = [[CHRegion alloc] init];
            region.analysisTimestamp = timestamp;
            region.analysisLevel = level;
            region.imageSize = _imageSize;

            [self getBoundingBox:(tesseract::ResultIterator *)iterator atLevel:iteratorLevel forRegion:region];
            [self getBaseline:(tesseract::ResultIterator *)iterator atLevel:iteratorLevel forRegion:region];

            region.index = index;
            index +=1;
            [regions addObject:region];

        } while (iterator->Next(iteratorLevel));

        delete iterator;
    }

    return regions;
}

- (void)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level newRegionAvailable:(void(^)(CHRegion *region))newRegionAvailable completion:(void(^)(NSArray *regions))completion {
    tesseract::PageIterator* iterator = _tesseract->AnalyseLayout();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;
    NSMutableArray *regions = [NSMutableArray array];
    if (iterator) {

        NSDate *date = [NSDate date];
        NSUInteger timestamp = date.timeIntervalSince1970;

        CHRegion *region;

        int index = 0;

        do {
            region = [[CHRegion alloc] init];
            region.analysisTimestamp = timestamp;
            region.analysisLevel = level;
            region.imageSize = _imageSize;

            [self getBoundingBox:(tesseract::ResultIterator *)iterator atLevel:iteratorLevel forRegion:region];
            [self getBaseline:(tesseract::ResultIterator *)iterator atLevel:iteratorLevel forRegion:region];

            region.index = index;
            index +=1;

            newRegionAvailable(region);
            [regions addObject:region];
        } while (iterator->Next(iteratorLevel));

        delete iterator;
    }
    completion(regions);
}

//- (CHResultGroup *)detectionAtLevel:(CHTesseractAnalysisLevel)level {
//    _tesseract->AnalyseLayout();
//    tesseract::ResultIterator *iterator = _tesseract->GetIterator();
//    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;
//
//    if (iterator) {
//        NSMutableArray *results = [NSMutableArray array];
//        CHResult *result;
//
//        int index = 0;
//
//        do {
//            result = [[CHResult alloc] init];
//
//            [self getBoundingBox:iterator atLevel:iteratorLevel forResult:result];
//            [self getBaseline:iterator atLevel:iteratorLevel forResult:result];
//            [self getOrientation:iterator forResult:result];
//
//            result.index = index++;
//            [results addObject:result];
//        } while (iterator->Next(iteratorLevel));
//
//        CHResultGroup *resultGroup = [[CHResultGroup alloc] init];
//        resultGroup.results = results;
//
//        [self getTextDirection:resultGroup];
//
//        delete iterator;
//
//        return resultGroup;
//    }
//    return nil;
//}

- (NSString *)hOCRText {
    return [NSString stringWithUTF8String:_tesseract->GetHOCRText(0)];
}

- (void)getBoundingBox:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forRegion:(CHRegion *)region {
    int left, top, right, bottom;
    iterator->BoundingBox(level, &left, &top, &right, &bottom);
    region.left = left;
    region.top = top;
    region.right = right;
    region.bottom = bottom;
//    NSLog(@"%@", CGRectCreateDictionaryRepresentation(result.getRect));
}

- (void)getBaseline:(tesseract::ResultIterator *)iterator atLevel:(tesseract::PageIteratorLevel)level forRegion:(CHRegion *)region {
    int xStart, yStart, xEnd, yEnd;
    iterator->Baseline(level, &xStart, &yStart, &xEnd, &yEnd);
    region.start = CGPointMake(xStart, yStart);
    region.end = CGPointMake(xEnd, yEnd);
}

//
//- (void)getOrientation:(tesseract::ResultIterator *)iterator forRegion:(CHRegion *)region {
//    tesseract::Orientation orientation;
//    tesseract::WritingDirection writingDirection;
//    tesseract::TextlineOrder textlineOrder;
//    float deskew;
//    iterator->Orientation(&orientation, &writingDirection, &textlineOrder, &deskew);
//    //NSLog(@"Orientation: %i\nWriting Direction: %i\nTextline Order: %i\nDeskew: %f", orientation, writingDirection, textlineOrder, deskew);
//}
//
//- (void)getTextDirection:(CHResultGroup *)group {
//    int offset; float slope;
//    _tesseract->GetTextDirection(&offset, &slope);
//    group.offset = offset;
//    group.slope = slope;
////    NSLog(@"Offset: %i, Slope: %f", offset, slope);
//}

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

- (void)clearAdaptiveClassifier {
    _tesseract->ClearAdaptiveClassifier();
}

- (void)clearPersistentCache {
    _tesseract->ClearPersistentCache();
}

- (void)end {
    _tesseract->End();
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
