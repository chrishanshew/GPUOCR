//
// Created by Chris Hanshew on 5/18/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StillImageViewController.h"
#import "CHLayoutProcessor.h"
#import "CHOCRProcessor.h"
#import "CHRegionFilter.h"
#import "Settings.h"

@interface StillImageViewController () <CHLayoutProcessorDelegate, CHOCRProcessorDelegate> {

    CHRegionFilter *regionFilter;
    CHLayoutProcessor *layoutProcessor;
    CHOCRProcessor *ocrProcessor;

    GPUImagePicture *imageInput;
    NSMutableArray *_regions;
    dispatch_queue_t _regionAccessQueue;
}

@property (nonatomic, strong) IBOutlet UIButton *dismissButton;
@property (nonatomic, strong) IBOutlet UIButton *processButton;

-(IBAction)processImage:(id)sender;
-(IBAction)dismiss:(id)sender;
-(IBAction)showSettings:(id)sender;

@end

@implementation StillImageViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _regionAccessQueue = dispatch_queue_create("com.chrishanshew.gpuocr.regionaccessqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    imageInput = [[GPUImagePicture alloc] initWithImage:_image];
    regionFilter = [[CHRegionFilter alloc] init];
    [regionFilter forceProcessingAtSize:_image.size];
    [regionFilter addTarget:(GPUImageView *)self.view];
    [imageInput addTarget:regionFilter];

    layoutProcessor = [[CHLayoutProcessor alloc] initWithProcessingSize:_image.size];
    layoutProcessor.delegate = self;
    [layoutProcessor forceProcessingAtSize:_image.size];
    
    ocrProcessor = [[CHOCRProcessor alloc] initWithProcessingSize:_image.size];
    ocrProcessor.delegate = self;
    [ocrProcessor forceProcessingAtSize:_image.size];
    
    [self updateSettings];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSettings) name:GPUOCRSettingsUpdatedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)updateSettings {
    Settings *settings = [Settings currentSettings];
    
    // Detection Level
    layoutProcessor.level = settings.level;
    
    // Line Width and Color
    [regionFilter setLineWidth:settings.lineWidth];
    CGFloat red, green, blue, alpha;
    [settings.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    [regionFilter setLineColorWithRed:red green:green blue:blue alpha:alpha];
}

#pragma mark - IBActions

-(IBAction)processImage:(id)sender {
    [self removeAllRegions];
    [self updateSettings];
    [imageInput removeTarget:ocrProcessor];
    [imageInput addTarget:layoutProcessor];
    
    [imageInput processImage];
}

-(IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)showSettings:(id)sender {
    [self performSegueWithIdentifier:@"ShowSettingsController" sender:self];
}

#pragma mark - Region Array Access

-(void)removeAllRegions {
    dispatch_barrier_sync(_regionAccessQueue, ^{
        if (_regions) {
             [_regions removeAllObjects];
        }
    });
}

-(void)setRegions:(NSArray *)regions {
    dispatch_barrier_sync(_regionAccessQueue, ^{
        _regions = [NSMutableArray arrayWithArray:regions];
    });
}

-(CHRegion *)nextRegion {
    __block CHRegion *region;
    dispatch_sync(_regionAccessQueue, ^{
        region = [_regions firstObject];
        [_regions removeObject:region];
    });
    return region;
}

#pragma mark - <CHLayoutProcessorDelegate>

- (void)processor:(CHLayoutProcessor *)processor finishedLayoutAnalysisWithRegions:(NSArray *)regions {
    _regions = [NSMutableArray arrayWithArray:regions];
    [regionFilter setRegions:regions];

    [imageInput removeTarget:processor];
    CHRegion *region = [self nextRegion];
    if (region) {
        [imageInput addTarget:ocrProcessor];
        ocrProcessor.region  = region;
        [imageInput processImage];
    }
}

- (void)willBeginLayoutAnalysis:(CHLayoutProcessor *)processor {
    
}

#pragma mark - <CHOCRProcessorDelegate>

- (void)processor:(CHOCRProcessor *)processor completedOCRWithText:(CHText *)text {
    NSLog(@"%@", text.text);
    
    CHRegion *region = [self nextRegion];
    if (region) {
        ocrProcessor.region  = region;
        [imageInput processImage];
    } else {
        // DONE
    }
}

- (void)processor:(CHOCRProcessor *)processor willBeginOCRForRegion:(CHRegion *)region {

}

@end