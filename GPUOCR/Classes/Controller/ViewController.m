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
#import "CHOCRDetectionOutput.h"
#import "CHOCRDrawResultFilter.h"

#define kDefaultAdaptiveThresholderBlurRadius 1.0

@interface ViewController () <CHOCRRecogntionOutputDelegate, CHOCRAnalysisOutputDelegate, CHOCRDetectionOutputDelegate> {
    CGSize _processingSize;

    // Inputs
    GPUImageVideoCamera *_videoCamera;
    GPUImageStillCamera *_stillCamera;
    
    // OCR Output
    CHOCRRecognitionOutput *_recognitionOutput;
    CHOCRAnalysisOutput *_analysisOutput;
    CHOCRDetectionOutput *_detectionOutput;
    
    // Filter Groups
    GPUImageFilterGroup *_uiFilterGroup;
    GPUImageFilterGroup *_ocrFilterGroup;

    CHOCRDrawResultFilter *_drawRect;
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

        _processingSize = CGSizeMake(720, 1280);

        // Thresholder
        GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;
        [adaptiveThresholdFilter forceProcessingAtSizeRespectingAspectRatio:_processingSize];

        // Recognition Output
        _recognitionOutput = [[CHOCRRecognitionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES forLanguage:@"eng" withDelegate:self];
        
        // Analysis Output
        _analysisOutput = [[CHOCRAnalysisOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES withDelegate:self];

        // DetectionOutput
        _detectionOutput = [[CHOCRDetectionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES withDelegate:self];

        [adaptiveThresholdFilter addTarget:_analysisOutput];
        
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

        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [blendFilter forceProcessingAtSize:_processingSize];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [_videoCamera addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        [blendFilter addTarget:(GPUImageView *)self.view];

        _drawRect = [[CHOCRDrawResultFilter alloc] init];
        [_drawRect forceProcessingAtSize:_processingSize];
        [_drawRect addTarget:blendFilter];

        [gammaFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            [_drawRect renderResultsWithFrameTime:time];
        }];
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
    if (_videoCamera.isRunning) {
        [_videoCamera pauseCameraCapture];
    } else {
        [_videoCamera resumeCameraCapture];
    }
    
}

#pragma mark - <CHOCRRecognitionOutputDelegate>

- (void)output:(CHOCRRecognitionOutput *)output didFinishRecognitionWithResult:(CHResultGroup *)result {
    [_drawRect setResults:result.results];
}

- (void)willBeginRecognitionWithOutput:(CHOCRRecognitionOutput *)output {
    
}

#pragma mark - <CHOCRAnaylsisOutputDelegate>

- (void)output:(CHOCRAnalysisOutput*)output didFinishAnalysisWithResult:(CHResultGroup *)result {
    [_drawRect setResults:result.results];
}

- (void)willBeginAnalysisWithOutput:(CHOCRAnalysisOutput *)output {
    
}

#pragma mark - <CHOCRDetectionOutputDelegate>

- (void)output:(CHOCRDetectionOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result {
    [_drawRect setResults:result.results];
}

- (void)willBeginDetectionWithOutput:(CHOCRDetectionOutput *)output {

}

@end
