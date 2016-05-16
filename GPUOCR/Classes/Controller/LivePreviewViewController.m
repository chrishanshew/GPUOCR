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
        [_videoCamera setCaptureSessionPreset:settings.captureSessionPreset];
        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

        _processingSize = [Settings sizeForCaptureSessionPreset:_videoCamera.captureSessionPreset andOrientation:_videoCamera.outputImageOrientation];
        
        resultsFilter = [[CHResultFilter alloc] initWithProcessingSize:_processingSize];

        // OCR Filters
        tesseractOutput = [[CHTesseractOutput alloc] initWithProcessingSize:_processingSize];
        tesseractOutput.delegate = self;
        [_videoCamera addTarget:tesseractOutput];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        [_videoCamera addTarget:resultsFilter];
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
    if (![_videoCamera.captureSessionPreset isEqualToString:settings.captureSessionPreset]) {
        if (running) [_videoCamera stopCameraCapture];
        _videoCamera.captureSessionPreset = settings.captureSessionPreset;
        if (running) [_videoCamera startCameraCapture];
    }
    
    // Size
    CGSize newProcessingSize = [Settings sizeForCaptureSessionPreset:_videoCamera.captureSessionPreset andOrientation:_videoCamera.outputImageOrientation];
    if (!CGSizeEqualToSize(_processingSize, newProcessingSize)) {
        if (running) [_videoCamera stopCameraCapture];
        _processingSize = newProcessingSize;
        [tesseractOutput forceProcessingAtSize:_processingSize];
        [resultsFilter forceProcessingAtSize:_processingSize];
        if (running) [_videoCamera startCameraCapture];
    }
}

#pragma mark - <CHTesseractOutputDelegate>

- (void)output:(CHTesseractOutput*)output didFinishDetectionWithResult:(CHResultGroup *)result {
    [resultsFilter setResults:result.results];
}

- (void)willBeginDetectionWithOutput:(CHTesseractOutput *)output {

}

@end
