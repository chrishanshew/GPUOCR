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
#import "CHAnalysisGroup.h"
#import "CHRecognitionGroup.h"
#import "CHRegionFilter.h"

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface LivePreviewViewController () <CHAnalysisOutputDelegate, CHRecognitionOutputDelegate, UIGestureRecognizerDelegate> {
    CGSize _processingSize;

    // Inputs
    GPUImageStillCamera *_stillCamera;

    GPUImageLanczosResamplingFilter *resamplingFilter;

    // Filter Groups
    CHRegionFilter *regionFilter;
    CHAnalysisGroup *analysisGroup;
    CHRecognitionGroup *recognitionGroup;

    // Tap - Photo Recognition
}

@property(nonatomic, strong) IBOutlet UILongPressGestureRecognizer *longPressGesture;
@property(nonatomic, strong) IBOutlet UIButton *settingsButton;

-(IBAction)showSettings:(id)sender;
-(IBAction)onLongPressGestureReceived:(UILongPressGestureRecognizer *)sender;

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
        analysisGroup = [[CHAnalysisGroup alloc] initWithProcessingSize:_processingSize];
        analysisGroup.delegate = self;

        recognitionGroup = [[CHRecognitionGroup alloc] initWithProcessingSize:_processingSize];
        recognitionGroup.delegate = self;

        resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
        [resamplingFilter forceProcessingAtSize:_processingSize];
        [_stillCamera addTarget:resamplingFilter];
        [resamplingFilter addTarget:regionFilter atTextureLocation:0];
        [resamplingFilter addTarget:analysisGroup atTextureLocation:1];
        [resamplingFilter addTarget:recognitionGroup atTextureLocation:2];
        [resamplingFilter forceProcessingAtSize:_processingSize];

        // Gesture Recognizers
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGestureReceived:)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        GPUImageView *cameraView = (GPUImageView *)self.view;
        [regionFilter addTarget:cameraView];
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

- (IBAction)onLongPressGestureReceived:(UILongPressGestureRecognizer *)sender {
    if ([sender isEqual:_longPressGesture]) {
        if (sender.state == UIGestureRecognizerStateBegan) {

        }
    }
}

#pragma mark - Notifications

-(void)updateSettings {
    BOOL running = [_stillCamera isRunning];
    Settings *settings = [Settings currentSettings];
    
    // Detection Level
    analysisGroup.level = settings.level;

    // Line Width and Color
    [regionFilter setLineWidth:settings.lineWidth];
    CGFloat red, green, blue, alpha;
    [settings.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    [regionFilter setLineColorWithRed:red green:green blue:blue alpha:alpha];
    
    // Capture Preset
//    if (![_stillCamera.captureSessionPreset isEqualToString:settings.captureSessionPreset]) {
//        if (running) [_stillCamera stopCameraCapture];
//        _stillCamera.captureSessionPreset = settings.captureSessionPreset;
//        if (running) [_stillCamera startCameraCapture];
//    }
    
    // Size
//    CGSize newProcessingSize = [Settings sizeForCaptureSessionPreset:settings.captureSessionPreset andOrientation:_stillCamera.outputImageOrientation];
//    if (!CGSizeEqualToSize(_processingSize, newProcessingSize)) {
//        if (running) [_stillCamera stopCameraCapture];
//        _processingSize = newProcessingSize;
//        [analysisGroup forceProcessingAtSize:_processingSize];
//        [regionFilter forceProcessingAtSize:_processingSize];
//        if (running) [_stillCamera startCameraCapture];
//    }
}

#pragma mark - <CHAnalysisOutputDelegate>

- (void)output:(CHAnalysisGroup *)output completedAnalysisWithRegions:(NSArray *)regions; {
    [regionFilter setRegions:regions];
    if (regions.count > 0) {
        [recognitionGroup setRegion:[regions objectAtIndex:0]];
    }
}

- (void)willBeginAnalysisWithOutput:(CHAnalysisOutput *)output {

}

#pragma mark - <CHAnalysisOutputDelegate>

- (void)output:(CHRecognitionOutput *)output completedRecognitionWithText:(CHText *)text {
    NSLog(@"%@", text.text);
}

- (void)output:(CHRecognitionOutput *)output willRecognizeRegion:(CHRegion *)region {

}

@end
