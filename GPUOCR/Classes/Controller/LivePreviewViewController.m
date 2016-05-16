//
//  LivePreviewViewController.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/10/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LivePreviewViewController.h"
#import "Settings.h"
#import "GPUImage.h"
#import "CHTesseractOutput.h"
#import "CHResultFilter.h"

#define kDefaultAdaptiveThresholderBlurRadius 4.0

@interface LivePreviewViewController () <CHTesseractOutputDelegate> {
    CGSize _processingSize;

    // Inputs
    GPUImageVideoCamera *_videoCamera;

    GPUImageLanczosResamplingFilter *_resamplingFilter;
    
    // Filter Groups
    CHResultFilter *resultsFilter;
    CHTesseractOutput *tesseractOutput;

}

@property(nonnull, strong) IBOutlet UIButton *settingsButton;
-(IBAction)showSettings:(id)sender;

-(void)updateSettings;

@end

@implementation LivePreviewViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        Settings *settings = [Settings currentSettings];
        
        _videoCamera = [[GPUImageVideoCamera alloc] init];
        [_videoCamera setCaptureSessionPreset:AVCaptureSessionPreset3840x2160];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

        _processingSize = [Settings sizeForCaptureSessionPreset:settings.captureSessionPreset andOrientation:_videoCamera.outputImageOrientation];
        
        _resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
        [_videoCamera addTarget:_resamplingFilter];

        // OCR Filters
        tesseractOutput = [[CHTesseractOutput alloc] initWithProcessingSize:_processingSize];
        tesseractOutput.delegate = self;
        [_resamplingFilter addTarget:tesseractOutput];

        resultsFilter = [[CHResultFilter alloc] initWithProcessingSize:_processingSize];
        [_resamplingFilter addTarget:resultsFilter];
        [_resamplingFilter forceProcessingAtSizeRespectingAspectRatio:_processingSize];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        GPUImageView *cameraView = (GPUImageView *)self.view;
        cameraView.fillMode = kGPUImageFillModePreserveAspectRatio;
        [resultsFilter addTarget:cameraView atTextureLocation:0];
        [self updateSettings];
    } else {
        // Rear Camera not available, present alert
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSettings) name:GPUOCRSettingsUpdatedNotification object:nil];
    [_videoCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_videoCamera stopCameraCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IB Actions

-(IBAction)showSettings:(id)sender {
    [self performSegueWithIdentifier:@"ShowSettingsController" sender:self];
}

#pragma mark - Notifications

-(void)updateSettings {
    BOOL running = [_videoCamera isRunning];
    Settings *settings = [Settings currentSettings];
    
    // Detection Level
    tesseractOutput.level = settings.level;
    tesseractOutput.mode = settings.mode;
    
    // Line Width and Color
    [resultsFilter setLineWidth:settings.lineWidth];
    CGFloat red, green, blue, alpha;
    [settings.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    [resultsFilter setLineColorWithRed:red green:green blue:blue alpha:alpha];
    
    // Capture Preset
//    if (![_videoCamera.captureSessionPreset isEqualToString:settings.captureSessionPreset]) {
//        if (running) [_videoCamera stopCameraCapture];
//        _videoCamera.captureSessionPreset = settings.captureSessionPreset;
//        if (running) [_videoCamera startCameraCapture];
//    }
    
    // Size
    CGSize newProcessingSize = [Settings sizeForCaptureSessionPreset:settings.captureSessionPreset andOrientation:_videoCamera.outputImageOrientation];
    if (!CGSizeEqualToSize(_processingSize, newProcessingSize)) {
        [_resamplingFilter forceProcessingAtSizeRespectingAspectRatio:_processingSize];
//        if (running) [_videoCamera stopCameraCapture];
//        _processingSize = newProcessingSize;
//        [_videoCamera removeTarget:tesseractOutput];
//        tesseractOutput = [[CHTesseractOutput alloc] init];
//        tesseractOutput.delegate = self;
//        [tesseractOutput forceProcessingAtSize:_processingSize];
//        [_videoCamera addTarget:tesseractOutput];
//
//        [_videoCamera removeTarget:resultsFilter];
//        [resultsFilter = [CHResultFilter alloc] initWithProcessingSize:_processingSize];
//        [resultsFilter forceProcessingAtSize:_processingSize];
//        [_videoCamera]
//        if (running) [_videoCamera startCameraCapture];
    }
}

#pragma mark - <CHTesseractOutputDelegate>

- (void)output:(CHTesseractOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result {
    [resultsFilter setResults:result.results];
}

- (void)willBeginDetectionWithOutput:(CHTesseractOutput *)output {

}

@end
