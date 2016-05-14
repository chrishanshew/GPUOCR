//
//  CHGPUOCRViewController.m
//  CHOCRViewController
//
//  Created by Chris Hanshew on 12/25/13.
//  Copyright (c) 2013 Chris Hanshew. All rights reserved.
//

#import "CHGPUOCRViewController.h"
#import <CoreVideo/CoreVideo.h>
#import "apitypes.h"
#import "baseapi.h"
#import "osdetect.h"
#import "allheaders.h"
#import "CHOCRDrawRectFilter.h"
#import "CHAnalysisResult.h"


#define kAVCaptureVideoPreviewZPosition -1

namespace tesseract {
    class TessBaseAPI;
}

@interface CHGPUOCRViewController () {

    GPUImagePicture *_picture;
    
    GPUImageGrayscaleFilter *_grayscaleFilter;
    GPUImageRawDataInput *_rawDataInput;
    GPUImageRawDataOutput *_rawDataOutput;
    GPUImageRawDataOutput *_rawDataOutput2;
    
    tesseract::TessBaseAPI *_tesseract;
    tesseract::TessBaseAPI *_analysis;
    NSString *_tesseractDataPath;
    dispatch_semaphore_t semaphore;
}

-(void)ocr;
-(void)hOCR;
-(void)layout;

@end

@implementation CHGPUOCRViewController

- (id)init
{
    self = [super initWithNibName:@"CHGPUOCRViewController" bundle:[NSBundle bundleForClass:[self class]]];
    if (self) {

    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureTesseractEnvironment];
    [self configureTesseractAPI];
    
    [self hOCR];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - OCR Test Methods

- (void)ocr {
    
    // Configure Video Camera
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    [_videoCamera setDelegate:self];
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.audioEncodingTarget = nil;
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc]initWithCropRegion:CGRectMake(0, 0, 1, 1)];
    
    GPUImageAdaptiveThresholdFilter *thresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc]init];
    _rawDataOutput = [[GPUImageRawDataOutput alloc]initWithImageSize:CGSizeMake(1080, 1920) resultsInBGRAFormat:YES];
    [cropFilter addTarget:thresholdFilter];
    [thresholdFilter addTarget:_rawDataOutput];
    
    
    [_videoCamera addTarget:cropFilter];
    
    //    TORCH
    //    AVCaptureDevice *device = _videoCamera.inputCamera;
    //    if ([device hasTorch]) {
    //        [device lockForConfiguration:nil];
    //        [device setTorchMode:AVCaptureTorchModeOn];  // use AVCaptureTorchModeOff to turn off
    //        [device unlockForConfiguration];
    //    }
    __block GPUImageRawDataOutput *weakOutput = _rawDataOutput;
    [_rawDataOutput setNewFrameAvailableBlock:^{
        [weakOutput lockFramebufferForReading];
        GLubyte *outputBytes = [weakOutput rawBytesForImage];
        NSInteger bytesPerRow = [weakOutput bytesPerRowInOutput];
        CGSize size = [weakOutput maximumOutputSize];
        //NSLog(@"Bytes per row: %ld", (unsigned long)bytesPerRow);
        
        _tesseract->SetImage(outputBytes, 1080, 1920, 4, bytesPerRow);
        //_tesseract->SetSourceResolution(326);
        //_tesseract->AnalyseLayout();
        
        _tesseract->Recognize(0);
        
        //        tesseract::PageIterator* it =  _tesseract->AnalyseLayout();
        //
        //        float deskew_angle;
        //        if (it) {
        //            tesseract::Orientation orientation;
        //            tesseract::WritingDirection direction;
        //            tesseract::TextlineOrder order;
        //            it->Orientation(&orientation, &direction, &order, &deskew_angle);
        //            printf("Orientation: %d;\nWritingDirection: %d\nTextlineOrder: %d\n" \
        //                   "Deskew angle: %.4f\n",
        //                   orientation, direction, order, deskew_angle);
        //        }
        
//        Pix *pix = _tesseract->GetThresholdedImage();
//        
//        Pixa *pixa = (Pixa *)malloc(sizeof *pixa);
//        
//        pixa->pix = &pix;
//        
//        Boxa *boxa = _tesseract->GetComponentImages(tesseract::PageIteratorLevel::RIL_SYMBOL, true, &pixa, NULL);
//        
//        Box *box = boxa->box[0];
//        
//        if (pixa) {
//            pixaDestroy(&pixa);
//            free(pixa);
//        }
//        
//        if (boxa) {
//            boxaDestroy(&boxa);
//            free(boxa);
//        }
        
//        const char * test = _tesseract->GetBoxText(0);
//        NSString *objcText = [NSString stringWithUTF8String:test];
//        
//        for (int i = 0; i < [objcText length]; i++) {
//            NSLog(@"%c", [objcText characterAtIndex:i]);
//        }
//        
//        NSLog(@"Box: \n%@", objcText);
//        NSLog(@"Box Size: %zu", strlen(test));
//        delete[] test;
//        
        const char * utf8 = _tesseract->GetUTF8Text();
        NSLog(@"Text: %@", [NSString stringWithUTF8String:utf8]);
        delete[] utf8;
        //_tesseract->Clear();
        [weakOutput unlockFramebufferAfterReading];
    }];
    
    // Configure Preview Layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_videoCamera.captureSession];
    [_previewLayer setFrame:[UIScreen mainScreen].bounds];
    _previewLayer.zPosition = kAVCaptureVideoPreviewZPosition;
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.view.layer addSublayer:_previewLayer];
    
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [_videoCamera startCameraCapture];
    
}

- (void)hOCR {
    semaphore = dispatch_semaphore_create(1);
    int max = [GPUImageContext maximumTextureSizeForThisDevice];
    //_picture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"test_image_400x400.png"]];
    _stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    _stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;


    // Configure Video Camera
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    [_videoCamera setDelegate:self];
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.audioEncodingTarget = nil;

    _rawDataOutput = [[GPUImageRawDataOutput alloc]initWithImageSize:CGSizeMake(720, 1280) resultsInBGRAFormat:YES];
    _rawDataOutput.enabled = YES;


    __block GPUImageRawDataOutput *weakOutput = _rawDataOutput;
    [_rawDataOutput setNewFrameAvailableBlock:^{
        if (weakOutput.enabled) {
            CFTimeInterval startTime;
            CFTimeInterval endTime;

            startTime = CACurrentMediaTime();
            [weakOutput lockFramebufferForReading];

            unsigned char * outputBytes = (unsigned char *)[weakOutput rawBytesForImage];
            int height = weakOutput.maximumOutputSize.height;
            int width = weakOutput.maximumOutputSize.width;
            int outputSize = (4 * width) * height;
            __block unsigned char * mappedBytes = (unsigned char *)malloc(width * height);
            int bx = 0;

            // Iterate the RGBA Bytes and the use the last byte to create a 1 bit monochrome image
            for (int i = 4; i < outputSize - 4; i+=4) {
                mappedBytes[bx++] = outputBytes[i];
            }

            [weakOutput unlockFramebufferAfterReading];

            endTime = CACurrentMediaTime();
            NSLog(@"Total Runtime: %g s", endTime - startTime);
//            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                weakOutput.enabled = NO;
                NSLog(@"Bytes per row: %ld", (unsigned long) weakOutput.bytesPerRowInOutput);
                NSLog(@"Maximum OutPutSize %@", NSStringFromCGSize(weakOutput.maximumOutputSize));
                _tesseract->SetImage((const unsigned char *)mappedBytes, width, height, 1, width);
                char * outputText = _tesseract->GetUTF8Text();
                _tesseract->Clear();
                delete mappedBytes;
                NSLog(@"TEXT: %@", [NSString stringWithUTF8String:outputText]);
//                dispatch_semaphore_signal(semaphore);
                weakOutput.enabled = YES;
            });
        }
    }];


//    _rawDataOutput2 = [[GPUImageRawDataOutput alloc]initWithImageSize:CGSizeMake(1080, 1920) resultsInBGRAFormat:YES];
//
//    __block GPUImageRawDataOutput *weakOutput2 = _rawDataOutput2;
//    [_rawDataOutput2 setNewFrameAvailableBlock:^{
//        if (weakOutput2.enabled) {
//            [weakOutput2 lockFramebufferForReading];
//            [_rawDataInput updateDataFromBytes:weakOutput2.rawBytesForImage size:weakOutput2.maximumOutputSize];
//            [_rawDataInput processData];
//            [weakOutput2 unlockFramebufferAfterReading];
//        }
//    }];

//    GLubyte initBytes[256 * 4];
//    _rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:initBytes size:CGSizeMake(256.0, 1.0) pixelFormat:GPUPixelFormatLuminance];
//    [_rawDataInput addTarget:_rawDataOutput];


    GPUImageLuminanceThresholdFilter *thresholdFilter = [[GPUImageLuminanceThresholdFilter alloc]init];
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
    adaptiveThresholdFilter.blurRadiusInPixels = 4;
    [adaptiveThresholdFilter addTarget:_rawDataOutput];
    [adaptiveThresholdFilter addTarget:(GPUImageView *)self.view];
//    [thresholdFilter addTarget:_rawDataOutput2];
//    __block GPUImageLuminanceThresholdFilter *weakThresholdFilter = thresholdFilter;
//    [thresholdFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time){
//        [weakOutput setImageSize:weakThresholdFilter.outputFrameSize];
//        [weakOutput2 setImageSize:weakThresholdFilter.outputFrameSize];
//    }];

//    GPUImageGrayscaleFilter *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
//    [grayscaleFilter addTarget:thresholdFilter];

//    GPUImageLanczosResamplingFilter* resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
//    [resamplingFilter forceProcessingAtSize:CGSizeMake(2160, 3840)];
//    [resamplingFilter addTarget:thresholdFilter];

    [_videoCamera addTarget:adaptiveThresholdFilter];
//    [_picture addTarget:thresholdFilter];
//    [_picture useNextFrameForImageCapture];
//    [_picture processImage];

//    // Configure Preview Layer
//    _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_videoCamera.captureSession];
//    [_previewLayer setFrame:[UIScreen mainScreen].bounds];
//    _previewLayer.zPosition = kAVCaptureVideoPreviewZPosition;
//    //[_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
//    [self.view.layer addSublayer:_previewLayer];
    
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [_videoCamera startCameraCapture];

}

- (void)layout {
    
    // Configure Video Camera
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    [_videoCamera setDelegate:self];
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.audioEncodingTarget = nil;
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc]initWithCropRegion:CGRectMake(0, 0, 1, 1)];
    
    GPUImageAdaptiveThresholdFilter *thresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc]init];
    _rawDataOutput = [[GPUImageRawDataOutput alloc]initWithImageSize:CGSizeMake(720, (1280 * 1)) resultsInBGRAFormat:YES];
    [cropFilter addTarget:thresholdFilter];
    [thresholdFilter addTarget:_rawDataOutput];
    GPUImageRawDataInput *input = [[GPUImageRawDataInput alloc] init];
    [_videoCamera addTarget:cropFilter];
    [cropFilter addTarget:input];

    __block GPUImageRawDataOutput *weakOutput = _rawDataOutput;
    [_rawDataOutput setNewFrameAvailableBlock:^{
        [weakOutput lockFramebufferForReading];
        GLubyte *outputBytes = [weakOutput rawBytesForImage];
        NSInteger bytesPerRow = [weakOutput bytesPerRowInOutput];
        NSLog(@"Bytes per row: %ld", (unsigned long)bytesPerRow);
        
        _tesseract->SetImage(outputBytes, 720, (1 * 1280), 4, bytesPerRow);
        
        tesseract::PageIterator* it = _tesseract->AnalyseLayout();
        int textline = 0;
        if (it) {
            it->Begin();
            int left, top, right, bottom;
            do {
                it->BoundingBox(tesseract::PageIteratorLevel::RIL_WORD, &left, &top, &right, &bottom);
                NSLog(@"\nline: %i \nleft: %i \ntop: %i, \nright: %i, \nbottom: %i", textline, left, top, right, bottom);
                textline++;
            } while (it->Next(tesseract::PageIteratorLevel::RIL_WORD));
        }
        //        float deskew_angle;
//        if (it) {
//            tesseract::Orientation orientation;
//            tesseract::WritingDirection direction;
//            tesseract::TextlineOrder order;
//            it->Orientation(&orientation, &direction, &order, &deskew_angle);
//            printf("Orientation: %d;\nWritingDirection: %d\nTextlineOrder: %d\n" \
//                   "Deskew angle: %.4f\n", orientation, direction, order, deskew_angle);
//        }
        
        [weakOutput unlockFramebufferAfterReading];
    }];
    
    // Configure Preview Layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_videoCamera.captureSession];
    [_previewLayer setFrame:[UIScreen mainScreen].bounds];
    _previewLayer.zPosition = kAVCaptureVideoPreviewZPosition;
    //[_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.view.layer addSublayer:_previewLayer];
    
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [_videoCamera startCameraCapture];
    
}

- (void)detect {
    // Configure Video Camera
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    [_videoCamera setDelegate:self];
    _videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    _videoCamera.horizontallyMirrorRearFacingCamera = NO;
    _videoCamera.audioEncodingTarget = nil;
    
    //GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc]initWithCropRegion:CGRectMake(0, 0, 1, 1)];
    
    GPUImageAdaptiveThresholdFilter *thresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc]init];
    _rawDataOutput = [[GPUImageRawDataOutput alloc]initWithImageSize:CGSizeMake(720, (1280 * 1)) resultsInBGRAFormat:YES];
    //[cropFilter addTarget:thresholdFilter];
    [thresholdFilter addTarget:_rawDataOutput];
    
    [_videoCamera addTarget:thresholdFilter];
    
    __block GPUImageRawDataOutput *weakOutput = _rawDataOutput;
    [_rawDataOutput setNewFrameAvailableBlock:^{
        [weakOutput lockFramebufferForReading];
        GLubyte *outputBytes = [weakOutput rawBytesForImage];
        NSInteger bytesPerRow = [weakOutput bytesPerRowInOutput];
        NSLog(@"Bytes per row: %ld", (unsigned long)bytesPerRow);
        
        _tesseract->SetImage(outputBytes, 720, (1 * 1280), 4, bytesPerRow);
        _tesseract->Recognize(0);
        
        OSResults osreslults;
        _tesseract->DetectOS(&osreslults);
        
        for (int i = 0; i <= 3; i++) {
            NSLog(@"%f", osreslults.orientations[i]);
        }
        
        [weakOutput unlockFramebufferAfterReading];
    }];
    
    // Configure Preview Layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_videoCamera.captureSession];
    [_previewLayer setFrame:[UIScreen mainScreen].bounds];
    _previewLayer.zPosition = kAVCaptureVideoPreviewZPosition;
    //[_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.view.layer addSublayer:_previewLayer];
    
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [_videoCamera startCameraCapture];
}

#pragma mark - GPUImage Video Capture Delegate

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {}

#pragma mark - Screen Tap

- (IBAction)handleScreenTap:(id)sender {
    

}

#pragma mark - Tesseract

- (void)configureTesseractEnvironment {
    
    if (!getenv("TESSDATA_PREFIX")) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *tessdataPath = [bundle resourcePath];
        setenv("TESSDATA_PREFIX", [[tessdataPath stringByAppendingString:@"/"] UTF8String], 1);
    }
}

- (void)configureTesseractAPI {
    _tesseract = new tesseract::TessBaseAPI();
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *tessdataPath = [bundle resourcePath];
    _tesseract->Init([[tessdataPath stringByAppendingString:@"/tessdata"]cStringUsingEncoding:NSUTF8StringEncoding], [@"eng" cStringUsingEncoding:NSUTF8StringEncoding]);
//    _analysis = new tesseract::TessBaseAPI();
//    _analysis->InitForAnalysePage();

    _tesseract->SetPageSegMode(tesseract::PageSegMode::PSM_AUTO);
    //_tesseract->SetVariable("tessedit_char_whitelist", "0123456789");
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    UIInterfaceOrientation orient = UIInterfaceOrientationPortrait;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationLandscapeLeft:
            orient = UIInterfaceOrientationLandscapeLeft;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orient = UIInterfaceOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationPortrait:
            orient = UIInterfaceOrientationPortrait;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orient = UIInterfaceOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // When in doubt, stay the same.
            orient = fromInterfaceOrientation;
            break;
    }
    _videoCamera.outputImageOrientation = orient;
    
}

@end
