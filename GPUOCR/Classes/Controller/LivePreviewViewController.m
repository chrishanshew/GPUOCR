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
#import "CHRegionFilter.h"

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface LivePreviewViewController () <CHTesseractOutputDelegate> {
    CGSize _processingSize;

    // Inputs
    GPUImageStillCamera *_stillCamera;

    // Filter Groups
    CHRegionFilter *regionFilter;
    CHTesseractOutput *tesseractOutput;

    // Long Press - Real time recognition

    // Tap - Photo Recognition
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


        // TODO: CAMERA ALWAYS AT MAX
        _stillCamera = [[GPUImageStillCamera alloc] init];
        [_stillCamera setCaptureSessionPreset:AVCaptureSessionPresetPhoto];
        _stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

        _processingSize = [Settings sizeForCaptureSessionPreset:settings.captureSessionPreset andOrientation:_stillCamera.outputImageOrientation];
        
        regionFilter = [[CHRegionFilter alloc] init];
        [regionFilter forceProcessingAtSize:_processingSize];

        // OCR Filters
        tesseractOutput = [[CHTesseractOutput alloc] initWithProcessingSize:_processingSize];
        tesseractOutput.delegate = self;
        [_stillCamera addTarget:tesseractOutput];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        [_stillCamera addTarget:regionFilter];
        GPUImageView *cameraView = (GPUImageView *)self.view;
        [regionFilter addTarget:cameraView atTextureLocation:0];
        [self updateSettings];
    } else {
        // Rear Camera not available, present alert
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSettings) name:GPUOCRSettingsUpdatedNotification object:nil];
    [_stillCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_stillCamera stopCameraCapture];
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
    BOOL running = [_stillCamera isRunning];
    Settings *settings = [Settings currentSettings];
    
    // Detection Level
    tesseractOutput.level = settings.level;
    tesseractOutput.mode = settings.mode;
    
    // Line Width and Color
    [regionFilter setLineWidth:settings.lineWidth];
    CGFloat red, green, blue, alpha;
    [settings.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    [regionFilter setLineColorWithRed:red green:green blue:blue alpha:alpha];
    
    // Capture Preset
    if (![_stillCamera.captureSessionPreset isEqualToString:settings.captureSessionPreset]) {
        if (running) [_stillCamera stopCameraCapture];
        _stillCamera.captureSessionPreset = settings.captureSessionPreset;
        if (running) [_stillCamera startCameraCapture];
    }
    
    // Size
    CGSize newProcessingSize = [Settings sizeForCaptureSessionPreset:settings.captureSessionPreset andOrientation:_stillCamera.outputImageOrientation];
    if (!CGSizeEqualToSize(_processingSize, newProcessingSize)) {
        if (running) [_stillCamera stopCameraCapture];
        _processingSize = newProcessingSize;
        [tesseractOutput forceProcessingAtSize:_processingSize];
        [regionFilter forceProcessingAtSize:_processingSize];
        if (running) [_stillCamera startCameraCapture];
    }
}

#pragma mark - <CHTesseractOutputDelegate>

- (void)output:(CHTesseractOutput *)output completedAnalysisWithRegions:(NSArray *)regions; {
    [regionFilter setRegions:regions];
}

- (void)willBeginDetectionWithOutput:(CHTesseractOutput *)output {

}

@end
