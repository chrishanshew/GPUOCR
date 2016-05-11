//
//  CHTesseract.m
//  CHTesseract
//
//  Created by Chris Hanshew on 5/18/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHTesseract.h"
#import "CHBoundingBox.h"
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
    void * _pixels;
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
    if (_pixels) {
        free(_pixels);
    }
}

#pragma mark - Tesseract API

- (void)setImage:(const unsigned char *)image withSize:(CGSize)size bytesPerPixel:(NSUInteger)bytes {
    if (_pixels) {
        _tesseract->Clear();
        free(_pixels);
    }
    _pixels = (void *)image;
    _tesseract->SetImage(image, size.width, size.height, (int)bytes, (size.width * bytes));
}

- (void)recognize {
    _tesseract->Recognize(0);
}

- (NSString *)recognizeText {
    return [NSString stringWithUTF8String:_tesseract->GetUTF8Text()];
}

- (CHOCRRecognitionResult *)recognizeAtLevel:(CHTesseractAnalysisLevel)level {
    _tesseract->Recognize(0);
    tesseract::ResultIterator* iterator = _tesseract->GetIterator();

    NSMutableArray *boxes = [NSMutableArray array];
    CHBoundingBox *box;

    // Box Dimensions
    int left, top, right, bottom;
    
    // Base line
    int xStart, yStart, xEnd, yEnd;

    do {

        // Get the dimensions of the detected box
        iterator->BoundingBox((tesseract::PageIteratorLevel)level, &left, &top, &right, &bottom);
        iterator->Baseline((tesseract::PageIteratorLevel)level, &xStart, &yStart, &xEnd, &yEnd);
        box = [[CHBoundingBox alloc] init];
        box.left = left;
        box.top = top;
        box.right = right;
        box.bottom = bottom;
        box.start = CGPointMake(xStart, yStart);
        box.end = CGPointMake(xEnd, yEnd);
        char * text = iterator->GetUTF8Text((tesseract::PageIteratorLevel)level);
        if (text) {
            box.text = [NSString stringWithUTF8String:text];
            NSLog(@"%@", box.text);
        }
        [boxes addObject:box];

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
        CHBoundingBox *box;

        // Box Dimensions
        int left, top, right, bottom;

        // Orientation
        tesseract::Orientation orientation;
        tesseract::WritingDirection writingDirection;
        tesseract::TextlineOrder textlineOrder;
        float deskewAngle;
        
        do {
            // Get the dimensions of the detected box
            iterator->BoundingBox((tesseract::PageIteratorLevel)level, &left, &top, &right, &bottom);

            // TODO: Get the text orientation of the detected box
            iterator->Orientation(&orientation, &writingDirection, &textlineOrder, &deskewAngle);

            box = [[CHBoundingBox alloc] init];
            box.left = left;
            box.top = top;
            box.right = right;
            box.bottom = bottom;
            box.deskewAngle = deskewAngle; // TODO: Not working

            [boxes addObject:box];
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
    if (_pixels) {
//        free(_pixels);
    }
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
