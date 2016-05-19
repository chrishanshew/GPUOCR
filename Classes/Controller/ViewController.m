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
#import "CHOCROutput.h"
#import "CHLayoutOutput.h"
#import "CHDetectionOutput.h"
#import "CHRegionGenerator.h"

#define kDefaultAdaptiveThresholderBlurRadius 4.0

@interface ViewController () <CHOCRRecogntionOutputDelegate, CHOCRAnalysisOutputDelegate, CHOCRDetectionOutputDelegate> {
    CGSize _processingSize;
    CHTesseractAnalysisLevel _level;

    // Inputs
    GPUImageVideoCamera *_videoCamera;

    // OCR Output
    CHOCRRecognitionOutput *_recognitionOutput;
    CHOCRAnalysisOutput *_analysisOutput;
    CHOCRDetectionOutput *_detectionOutput;
    
    // Filter Groups
    GPUImageFilterGroup *_uiFilterGroup;
    GPUImageFilterGroup *_ocrFilterGroup;

    CHOCRDrawResultFilter *_drawRect;
}

@property(nonnull, strong) IBOutlet UIButton *settingsButton;
-(IBAction)showSettings:(id)sender;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _processingSize = CGSizeMake(288, 352);
        _level = CHTesseractAnalysisLevelTextLine;

        /*
            Inputs
         */
        _videoCamera = [[GPUImageVideoCamera alloc] init];
        [_videoCamera setCaptureSessionPreset:AVCaptureSessionPreset352x288];

        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

        _uiFilterGroup = [[GPUImageFilterGroup alloc] init];

        /*
            OCR Filters
         */

        // Thresholder
        GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        adaptiveThresholdFilter.blurRadiusInPixels = kDefaultAdaptiveThresholderBlurRadius;
        [adaptiveThresholdFilter forceProcessingAtSizeRespectingAspectRatio:_processingSize];

        // Recognition Output
        _recognitionOutput = [[CHOCRRecognitionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES forLanguage:@"eng" withDelegate:self];
        _recognitionOutput.level = _level;

        // Analysis Output
        _analysisOutput = [[CHOCRAnalysisOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES withDelegate:self];
        _analysisOutput.level = _level;

        // DetectionOutput
        _detectionOutput = [[CHOCRDetectionOutput alloc] initWithImageSize:_processingSize resultsInBGRAFormat:YES withDelegate:self];
        _detectionOutput.level = _level;

        [adaptiveThresholdFilter addTarget:_detectionOutput];
        
        _ocrFilterGroup = [[GPUImageFilterGroup alloc] init];
        [_ocrFilterGroup setInitialFilters:@[adaptiveThresholdFilter, _analysisOutput]];
        [_videoCamera addTarget:adaptiveThresholdFilter];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [blendFilter forceProcessingAtSizeRespectingAspectRatio:_processingSize];
        GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
        [gammaFilter forceProcessingAtSizeRespectingAspectRatio:_processingSize];
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

-(IBAction)showSettings:(id)sender {
    [self performSegueWithIdentifier:@"ShowSettingsController" sender:self];
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
