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

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface ViewController () <CHOCRRecogntionOutputDelegate> {
    // Inputs
    GPUImageVideoCamera *_videoCamera;
    
    // OCR Output
    CHOCRRecognitionOutput *_recognitionOutput;
    
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
        
        _uiFilterGroup = [[GPUImageFilterGroup alloc] init];
        /*
            OCR Filters
         */
        
        // Thresholder
        GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;
        
        // Recognition Output
        _recognitionOutput = [[CHOCRRecognitionOutput alloc] initWithImageSize:CGSizeMake(720, 1280) resultsInBGRAFormat:YES forLanguage:@"eng" withDelegate:self];
        [adaptiveThresholdFilter addTarget:_recognitionOutput];
        
        _ocrFilterGroup = [[GPUImageFilterGroup alloc] init];
        [_ocrFilterGroup setInitialFilters:@[adaptiveThresholdFilter, _recognitionOutput]];
        [_videoCamera addTarget:adaptiveThresholdFilter];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        [_videoCamera setCaptureSessionPreset:AVCaptureSessionPreset1280x720];
        [_videoCamera addTarget:(GPUImageView *) self.view];
    } else {
        // Rear Camera not available, present alert
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_videoCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_videoCamera stopCameraCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)capture:(id)sender {
    if (_recognitionOutput.enabled) {
        _recognitionOutput.enabled = NO;
    } else {
        _recognitionOutput.enabled = YES;
    }
}

#pragma mark - CHOCRRecognitionOutputDelegate

- (void)output:(CHOCRRecognitionOutput *)output didFinishRecognitionWithResult:(CHOCRRecognitionResult *)result {
   
}

- (void)willBeginRecognitionWithOutput:(CHOCRRecognitionOutput *)output {
    
}

@end
