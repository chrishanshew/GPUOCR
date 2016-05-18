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

    GPUImagePicture *imageInput;
    CHRegionFilter *regionFilter;

    NSArray *_regions;
    dispatch_queue_t _regionAccessQueue;
}

@property (nonatomic, strong, setter=setRegions:, getter=getRegions) NSArray *regions;
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
//    [regionFilter addTarget:(GPUImageView *)self.view];
    [imageInput addTarget:regionFilter];
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
    [imageInput removeAllTargets];
    _regions = [NSArray array];
}

-(void)updateSettings {
    Settings *settings = [Settings currentSettings];
    
    // Line Width and Color
    [regionFilter setLineWidth:settings.lineWidth];
    CGFloat red, green, blue, alpha;
    [settings.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    [regionFilter setLineColorWithRed:red green:green blue:blue alpha:alpha];
}

#pragma mark - IBActions

-(IBAction)processImage:(id)sender {
    [self updateSettings];

    // Stop any future OCR processing by clearing regions.  This "resets" the OCR processing loop until new regions are analyzed.
    _regions = [NSArray array];

    // Add Layout Processor to determine detected regions
    CHLayoutProcessor *layoutProcessor = [[CHLayoutProcessor alloc] initWithProcessingSize:_image.size];
    layoutProcessor.delegate = self;
    layoutProcessor.level = [Settings currentSettings].level;
    [layoutProcessor forceProcessingAtSize:_image.size];
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

-(NSArray *)getRegions {
    __block NSArray *regions;
    dispatch_sync(_regionAccessQueue, ^{
        regions = [NSArray arrayWithArray:_regions];
    });
    return regions;
}

-(void)setRegions:(NSArray *)regions {
    dispatch_barrier_async(_regionAccessQueue, ^{
        _regions = [NSArray arrayWithArray:regions];
    });
}

#pragma mark - <CHLayoutProcessorDelegate>

- (void)processor:(CHLayoutProcessor *)processor finishedLayoutAnalysisWithRegions:(NSArray *)regions {
    [imageInput removeTarget:processor];
    if (regions.count > 0) {
        NSArray *sortedRegions = [regions sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSUInteger first = ((CHRegion *) a).index;
            NSUInteger second = ((CHRegion *) b).index;
            return [[NSNumber numberWithInteger:first] compare:[NSNumber numberWithInteger:second]];
        }];
        _regions = sortedRegions;
        [regionFilter setRegions:sortedRegions];

        CHRegion *region = [sortedRegions firstObject];
        if (region) {
            CHOCRProcessor *ocrProcessor = [[CHOCRProcessor alloc] initWithProcessingSize:_image.size];
            ocrProcessor.delegate = self;
            [ocrProcessor forceProcessingAtSize:_image.size];
            [ocrProcessor addTarget:(GPUImageView *)self.view];
            [imageInput addTarget:ocrProcessor];
            ocrProcessor.region = region;
            [imageInput processImage];
        }
    }
}

- (void)willBeginLayoutAnalysis:(CHLayoutProcessor *)processor {
    
}

#pragma mark - <CHOCRProcessorDelegate>

- (void)processor:(CHOCRProcessor *)processor completedOCRWithText:(CHText *)text {
    NSLog(@"%@", text.text);

    // Queue the next region or end processing if all regions have been processed
    NSUInteger index = text.region.index;
    index +=1;
    if ((_regions.count - 1) >= index) {
        processor.region  = [_regions objectAtIndex:index];
        [imageInput processImage];
    } else {
        [imageInput removeTarget:processor];
    }
}

- (void)processor:(CHOCRProcessor *)processor willBeginOCRForRegion:(CHRegion *)region {

}

@end