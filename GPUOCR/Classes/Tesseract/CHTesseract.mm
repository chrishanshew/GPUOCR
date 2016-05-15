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
#import "environ.h"
#import "apitypes.h"
#import "baseapi.h"
#import "osdetect.h"
#import "pix.h"


namespace tesseract {
    class TessBaseAPI;
}

@interface CHTesseract() {
    tesseract::TessBaseAPI *_tesseract;
    NSData *_pixelData;
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
        _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO);
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
        // Text Direction
        int offset; float slope;
        // Box Dimensions
        int left, top, right, bottom;
        // Base line
        int xStart, yStart, xEnd, yEnd;
        do {

            // Get the dimensions of the detected box
            iterator->BoundingBox(iteratorLevel, &left, &top, &right, &bottom);
            result.left = left;
            result.top = top;
            result.right = right;
            result.bottom = bottom;

            // Baseline
            iterator->Baseline(iteratorLevel, &xStart, &yStart, &xEnd, &yEnd);
            result.start = CGPointMake(xStart, yStart);
            result.end = CGPointMake(xEnd, yEnd);

            // Text
            char * text = iterator->GetUTF8Text(iteratorLevel);
            if (text) {
                result.text = [NSString stringWithUTF8String:text];
                result.confidence = iterator->Confidence(iteratorLevel);
                NSLog(@"%@", result.text);
            }
            result.index = index++;
            [results addObject:result];

        } while (iterator->Next((tesseract::PageIteratorLevel)level));

        CHResultGroup *resultGroup = [[CHResultGroup alloc] init];
        resultGroup.results = results;

        _tesseract->GetTextDirection(&offset, &slope);
        resultGroup.offset = offset;
        resultGroup.slope = slope;

        Pix *inputImage = _tesseract->GetInputImage();
        resultGroup.imageSize = CGSizeMake(inputImage->w, inputImage->h);
        resultGroup.bytesPerPixel = inputImage->d;
        delete inputImage;

        delete iterator;

        return resultGroup;
    }
    return nil;
}

- (NSString *)hOCRText {
    return [NSString stringWithUTF8String:_tesseract->GetHOCRText(0)];
}

- (CHResultGroup *)analyzeLayoutAtLevel:(CHTesseractAnalysisLevel)level {
    _tesseract->InitForAnalysePage();
    tesseract::PageIterator *iterator = _tesseract->AnalyseLayout();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;

    if (iterator) {
        NSMutableArray *results = [NSMutableArray array];
        CHResult *result;

        int index = 0;
        // Text Direction
        int offset; float slope;
        // Box Dimensions
        int left, top, right, bottom;
        // Base line
        int xStart, yStart, xEnd, yEnd;
        do {
            result = [[CHResult alloc] init];
            
            // Get the dimensions of the detected box
            iterator->BoundingBox(iteratorLevel, &left, &top, &right, &bottom);
            result.left = left;
            result.top = top;
            result.right = right;
            result.bottom = bottom;

            // Baseline
            iterator->Baseline(iteratorLevel, &xStart, &yStart, &xEnd, &yEnd);
            result.start = CGPointMake(xStart, yStart);
            result.end = CGPointMake(xEnd, yEnd);

            result.index = index++;
            [results addObject:result];
        } while (iterator->Next((tesseract::PageIteratorLevel)level));

        CHResultGroup *resultGroup = [[CHResultGroup alloc] init];
        resultGroup.results = results;

        _tesseract->GetTextDirection(&offset, &slope);
        resultGroup.offset = offset;
        resultGroup.slope = slope;

        Pix *inputImage = _tesseract->GetInputImage();
        if (inputImage) {
            resultGroup.imageSize = CGSizeMake(inputImage->w, inputImage->h);
            resultGroup.bytesPerPixel = inputImage->d;
            delete inputImage;
        }

        delete iterator;
        
        return resultGroup;
    }
    
    return nil;
}

- (CHResultGroup *)detectionAtLevel:(CHTesseractAnalysisLevel)level {
    _tesseract->Recognize(0);
    OSResults osResults;
    if (_tesseract->DetectOS(&osResults)) {
        osResults.print_scores();
        NSLog(@"Orientations:");
        for (int i = 0; i <= 3; i++) {
            NSLog(@"%f", osResults.orientations[i]);
        }
    }

    tesseract::PageIterator *iterator = _tesseract->AnalyseLayout();
    tesseract::PageIteratorLevel iteratorLevel = (tesseract::PageIteratorLevel)level;

    if (iterator) {
        NSMutableArray *results = [NSMutableArray array];
        CHResult *result;

        int index = 0;
        // Text Direction
        int offset; float slope;
        // Box Dimensions
        int left, top, right, bottom;
        // Base line
        int xStart, yStart, xEnd, yEnd;
        // Orientation
        tesseract::Orientation orientation;
        tesseract::WritingDirection writingDirection;
        tesseract::TextlineOrder textlineOrder;
        float deskew;

        do {
            result = [[CHResult alloc] init];

            // Get the dimensions of the detected box
            iterator->BoundingBox(iteratorLevel, &left, &top, &right, &bottom);
            result.left = left;
            result.top = top;
            result.right = right;
            result.bottom = bottom;

            // Baseline
            iterator->Baseline(iteratorLevel, &xStart, &yStart, &xEnd, &yEnd);
            result.start = CGPointMake(xStart, yStart);
            result.end = CGPointMake(xEnd, yEnd);

            // Orientation
            iterator->Orientation(&orientation, &writingDirection, &textlineOrder, &deskew);
            NSLog(@"Orientation: %i\nWriting Direction: %i\nTextline Order: %i\nDeskew: %f", orientation, writingDirection, textlineOrder, deskew);

            result.index = index++;
            [results addObject:result];
        } while (iterator->Next(iteratorLevel));

        CHResultGroup *resultGroup = [[CHResultGroup alloc] init];
        resultGroup.results = results;

        _tesseract->GetTextDirection(&offset, &slope);
        resultGroup.offset = offset;
        resultGroup.slope = slope;

        Pix *inputImage = _tesseract->GetInputImage();
        if (inputImage) {
            resultGroup.imageSize = CGSizeMake(inputImage->w, inputImage->h);
            resultGroup.bytesPerPixel = inputImage->d;
            delete inputImage;
        }
        

        delete iterator;

        return resultGroup;
    }
    return nil;
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
