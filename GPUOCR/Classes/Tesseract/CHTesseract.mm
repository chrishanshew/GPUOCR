//
//  CHTesseract.m
//  CHTesseract
//
//  Created by Chris Hanshew on 5/18/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHTesseract.h"
#import "Result.h"
#import "apitypes.h"
#import "baseapi.h"
#import "osdetect.h"
#import "CHOCRRecognitionOutput.h"
#import "CHOCRRecognitionResult.h"

namespace tesseract {
    class TessBaseAPI;
}

@interface CHTesseract() {
    tesseract::TessBaseAPI *_tesseract;
    NSMutableData *_pixelData;
}

- (void)configureTesseractEnvironment;

@end

@implementation CHTesseract

#pragma mark - Lifecycle

- (instancetype)initForAnalysis {
    self = [super init];
    if (self) {
        [self configureTesseractEnvironment];
        _tesseract = new tesseract::TessBaseAPI;
        _tesseract->InitForAnalysePage();
    }
    return self;
}

- (instancetype)initForOrientationDetection {
    self = [super init];
    if (self) {
        [self configureTesseractEnvironment];
        _tesseract = new tesseract::TessBaseAPI;
        _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO_OSD);
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

- (void)setImageWithData:(NSMutableData *)data withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes {
    _pixelData = data;
    _tesseract->Clear();
    _tesseract->SetImage((const unsigned char *)_pixelData.bytes, size.width, size.height, (int)bytes, (size.width * bytes));
}

- (void)recognize {
    _tesseract->Recognize(0);
}

- (NSString *)recognizeText {
    return [NSString stringWithUTF8String:_tesseract->GetUTF8Text()];
}

- (CHOCRRecognitionResult *)recognizeAtLevel:(CHTesseractAnalysisLevel)level {
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;
    _tesseract->Recognize(0);
    tesseract::ResultIterator* iterator = _tesseract->GetIterator();

    NSMutableArray *boxes = [NSMutableArray array];
    Result *box;

    // Box Dimensions
    int left, top, right, bottom;
    
    // Base line
    int xStart, yStart, xEnd, yEnd;
    
    int index = 0;
    
    do {

        // Get the dimensions of the detected box
        iterator->BoundingBox((tesseract::PageIteratorLevel)level, &left, &top, &right, &bottom);
        
        // Baseline
        iterator->Baseline((tesseract::PageIteratorLevel)level, &xStart, &yStart, &xEnd, &yEnd);
        
        box = [[Result alloc] init];
        box.index = index;
        box.level = level;
        box.left = left;
        box.top = top;
        box.right = right;
        box.bottom = bottom;
        box.start = CGPointMake(xStart, yStart);
        box.end = CGPointMake(xEnd, yEnd);
        char * text = iterator->GetUTF8Text(iteratorLevel);
        if (text) {
            box.text = [NSString stringWithUTF8String:text];
            box.confidence = iterator->Confidence(iteratorLevel);
            NSLog(@"%@", box.text);
        }
        [boxes addObject:box];
        index++;

    } while (iterator->Next((tesseract::PageIteratorLevel)level));
    
    CHOCRRecognitionResult *result = [[CHOCRRecognitionResult alloc] init];
    result.boxes = boxes;

    delete iterator;

    return result;
}

- (NSString *)hOCRText {
    return [NSString stringWithUTF8String:_tesseract->GetHOCRText(0)];
}

- (CHOCRAnalysisResult *)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level {
    tesseract::PageIterator *iterator = _tesseract->AnalyseLayout();

    if (iterator) {

        NSMutableArray *boxes = [NSMutableArray array];
        Result *box;

        // Box Dimensions
        int left, top, right, bottom;

        // Base line
        int xStart, yStart, xEnd, yEnd;
        
        int index = 0;
        
        do {
            // Get the dimensions of the detected box
            iterator->BoundingBox((tesseract::PageIteratorLevel)level, &left, &top, &right, &bottom);

            // Baseline
            iterator->Baseline((tesseract::PageIteratorLevel)level, &xStart, &yStart, &xEnd, &yEnd);
            
            box = [[Result alloc] init];
            box.index = index;
            box.level = level;
            box.left = left;
            box.top = top;
            box.right = right;
            box.bottom = bottom;
            box.start = CGPointMake(xStart, yStart);
            box.end = CGPointMake(xEnd, yEnd);

            [boxes addObject:box];
            index++;
        } while (iterator->Next((tesseract::PageIteratorLevel)level));

        CHOCRAnalysisResult *result = [[CHOCRAnalysisResult alloc] init];
        result.boxes = boxes;

        delete iterator;
        
        return result;
    }
    
    return nil;
}

-(void)detect {
    _tesseract->Recognize(0);
    OSResults osResults;
    if (_tesseract->DetectOS(&osResults)) {
        osResults.print_scores();
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
