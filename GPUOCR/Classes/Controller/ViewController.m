//
//  ViewController.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/10/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "GPUImage.h"
#import "CHOCRRecognitionOutput.h"
#import "CHOCRAnalysisOutput.h"
#import "CHOCRDrawRectFilter.h"

#define kDefaultAdaptiveThresholderBlurRadius 4.0

@interface ViewController () <CHOCRRecogntionOutputDelegate, CHOCRAnalysisOutputDelegate> {
    // Inputs
    GPUImageVideoCamera *_videoCamera;
    GPUImageStillCamera *_stillCamera;
    
    // OCR Output
    CHOCRRecognitionOutput *_recognitionOutput;
    CHOCRAnalysisOutput *_analysisOutput;
    
    // Filter Groups
    GPUImageFilterGroup *_uiFilterGroup;
    GPUImageFilterGroup *_ocrFilterGroup;

}

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        /*
            Inputs
         */
        _videoCamera = [[GPUImageVideoCamera alloc] init];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        
        _stillCamera = [[GPUImageStillCamera alloc] init];
        _stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        
        _uiFilterGroup = [[GPUImageFilterGroup alloc] init];
        /*
            OCR Filters
         */
        
        // Thresholder
        GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;
        
        // Recognition Output
        _recognitionOutput = [[CHOCRRecognitionOutput alloc] initWithImageSize:CGSizeMake(720, 1280) resultsInBGRAFormat:YES forLanguage:@"eng" withDelegate:self];
        
        
        // Analysis Output
        _analysisOutput = [[CHOCRAnalysisOutput alloc] initWithImageSize:CGSizeMake(720, 1280) resultsInBGRAFormat:YES withDelegate:self];
        
        [adaptiveThresholdFilter addTarget:_analysisOutput];
        
        _ocrFilterGroup = [[GPUImageFilterGroup alloc] init];
        [_ocrFilterGroup setInitialFilters:@[adaptiveThresholdFilter, _recognitionOutput]];
        [_videoCamera addTarget:adaptiveThresholdFilter];
        
        
        CHOCRDrawRectFilter *drawRect = [[CHOCRDrawRectFilter alloc] init];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [blendFilter forceProcessingAtSize:CGSizeMake(720, 1280)];
        
        
        
//        [_stillCamera addTarget:adaptiveThresholdFilter];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        [_videoCamera setCaptureSessionPreset:AVCaptureSessionPreset1280x720];
        CHOCRDrawRectFilter *drawRect = [[CHOCRDrawRectFilter alloc] init];
        
//        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
//        [blendFilter forceProcessingAtSize:CGSizeMake(720, 1280)];
//        
//        [drawRect addTarget:blendFilter];
//        [blendFilter addTarget:(GPUImageView*)self.view];
//        [_videoCamera addTarget:(GPUImageView *) drawRect];
        
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [blendFilter forceProcessingAtSize:CGSizeMake(720, 1280)];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [_videoCamera addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        
        [drawRect addTarget:blendFilter];
        
        [blendFilter addTarget:(GPUImageView *)self.view];
    } else {
        // Rear Camera not available, present alert
    }
    
//    if ([GPUImageStillCamera isBackFacingCameraPresent]) {
//        [_stillCamera setCaptureSessionPreset:AVCaptureSessionPreset1280x720];
//        [_stillCamera addTarget:(GPUImageView *) self.view];
//    } else {
//        // Rear Camera not available, present alert
//    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_videoCamera startCameraCapture];
    //[_stillCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_videoCamera stopCameraCapture];
    //[_stillCamera stopCameraCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)capture:(id)sender {
    if (_videoCamera.isRunning) {
        [_videoCamera pauseCameraCapture];
    } else {
        [_videoCamera resumeCameraCapture];
    }
    
}

#pragma mark - CHOCRRecognitionOutputDelegate

- (void)output:(CHOCRRecognitionOutput *)output didFinishRecognitionWithResult:(CHOCRRecognitionResult *)result {
   
}

- (void)willBeginRecognitionWithOutput:(CHOCRRecognitionOutput *)output {
    
}

#pragma mark - CHOCRAnaylsisOutputDelegate

- (void)output:(CHOCRAnalysisOutput*)output didFinishAnalysisWithResult:(CHOCRAnalysisResult *)result {
    NSLog(@"Box Count: %lu", (unsigned long)result.boxes.count);
    [_stillCamera resumeCameraCapture];
}

- (void)willBeginAnalysisWithOutput:(CHOCRAnalysisOutput *)output {
    
}

@end
