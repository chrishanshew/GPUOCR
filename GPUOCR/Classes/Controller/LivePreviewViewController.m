//
//  LivePreviewViewController.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/10/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LivePreviewViewController.h"
#import "StillImageViewController.h"
#import "Settings.h"
#import "GPUImage.h"
#import "CHLayoutProcessor.h"
#import "CHOCRProcessor.h"
#import "CHRegionFilter.h"

#define kDefaultAdaptiveThresholderBlurRadius 4

@interface LivePreviewViewController () <CHLayoutProcessorDelegate, CHOCRProcessorDelegate, UIGestureRecognizerDelegate> {
    CGSize _processingSize;

    // Inputs
    GPUImageStillCamera *_stillCamera;

    GPUImageLanczosResamplingFilter *resamplingFilter;

    // Filter Groups
    CHRegionFilter *regionFilter;
    CHLayoutProcessor *analysisGroup;
    CHOCRProcessor *recognitionGroup;

    // Tap - Photo Recognition
    UIImage *_selectedImage;
}

@property(nonatomic, strong) IBOutlet UILongPressGestureRecognizer *longPressGesture;
@property(nonatomic, strong) IBOutlet UITapGestureRecognizer *tapGesture;
@property(nonatomic, strong) IBOutlet UIButton *settingsButton;

-(IBAction)showSettings:(id)sender;
-(IBAction)onLongPressGestureReceived:(UILongPressGestureRecognizer *)sender;
-(IBAction)onTapGestureReceived:(UITapGestureRecognizer *)sender;

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

        resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
        [resamplingFilter forceProcessingAtSize:_processingSize];

        regionFilter = [[CHRegionFilter alloc] init];
        [regionFilter forceProcessingAtSize:_processingSize];

        // OCR Filters
        analysisGroup = [[CHLayoutProcessor alloc] initWithProcessingSize:_processingSize];
        analysisGroup.delegate = self;

//        recognitionGroup = [[CHOCRProcessor alloc] initWithProcessingSize:_processingSize];
//        recognitionGroup.delegate = self;

        // Gesture Recognizers
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGestureReceived:)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSettings) name:GPUOCRSettingsUpdatedNotification object:nil];
    if ([GPUImageVideoCamera isBackFacingCameraPresent]) {
        [_stillCamera addTarget:resamplingFilter];
        [resamplingFilter addTarget:regionFilter atTextureLocation:0];
        [resamplingFilter addTarget:analysisGroup atTextureLocation:1];
        GPUImageView *cameraView = (GPUImageView *)self.view;
        cameraView.fillMode = kGPUImageFillModePreserveAspectRatio;
        [regionFilter addTarget:cameraView];
        [self updateSettings];
    } else {
        // Rear Camera not available, present alert
    }
    [_stillCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_stillCamera stopCameraCapture];
    [_stillCamera removeAllTargets];
    [regionFilter removeAllTargets];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowStillImageController"]) {
        StillImageViewController *stillImageViewController = (StillImageViewController *)[segue destinationViewController];
        stillImageViewController.image = _selectedImage;
    }
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

-(IBAction)onTapGestureReceived:(UITapGestureRecognizer *)sender {
     [_stillCamera capturePhotoAsImageProcessedUpToFilter:resamplingFilter withOrientation:UIImageOrientationUp withCompletionHandler:^(UIImage *processedImage, NSError *error) {
         _selectedImage = processedImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"ShowStillImageController" sender:self];
        });
    }];
}

#pragma mark - Notifications

-(void)updateSettings {
    Settings *settings = [Settings currentSettings];

    // Detection Level
    analysisGroup.level = settings.level;

    // Line Width and Color
    [regionFilter setLineWidth:settings.lineWidth];
    CGFloat red, green, blue, alpha;
    [settings.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    [regionFilter setLineColorWithRed:red green:green blue:blue alpha:alpha];

    // Capture Preset
    CGSize newSize = [Settings sizeForCaptureSessionPreset:settings.captureSessionPreset andOrientation:_stillCamera.outputImageOrientation];
    if (!CGSizeEqualToSize(newSize, _processingSize)) {
        _processingSize = newSize;
        [resamplingFilter forceProcessingAtSize:_processingSize];
        [analysisGroup forceProcessingAtSize:_processingSize];
        [regionFilter forceProcessingAtSize:_processingSize];
    }
}

#pragma mark - <CHLayoutProcessorDelegate>

- (void)processor:(CHLayoutProcessor *)processor newRegionAvailable:(CHRegion *)region {
//    [regionFilter addRegion:region];
}

- (void)processor:(CHLayoutProcessor *)processor finishedLayoutAnalysisWithRegions:(NSArray *)regions {
    [regionFilter setRegions:regions];
}

- (void)willBeginLayoutAnalysis:(CHLayoutProcessor *)processor {
}

#pragma mark - <CHOCRProcessorDelegate>

- (void)processor:(CHOCRProcessor *)processor completedOCRWithText:(CHText *)text inRegion:(CHRegion *)region {

}

- (void)processor:(CHOCRProcessor *)processor willBeginOCRInRegion:(CHRegion *)region {

}

@end
