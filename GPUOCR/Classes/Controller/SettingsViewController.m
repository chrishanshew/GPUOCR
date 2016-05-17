//
// Created by Chris Hanshew on 5/14/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SettingsViewController.h"

@interface SettingsViewController () {
    Settings *_settings;
    NSArray *_captureSessionPresets;
}

-(void)update;
-(UIColor *)uiColorFromHex:(NSInteger)value;

@end

@implementation SettingsViewController

static NSInteger const hexColor[] = {0x000000, 0xfe0000, 0xff7900, 0xffb900, 0xffde00, 0xfcff00, 0xd2ff00, 0x05c000, 0x00c0a7, 0x0600ff, 0x6700bf, 0x9500c0, 0xbf0199, 0xffffff};

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _settings = [Settings currentSettings];
        _captureSessionPresets = @[AVCaptureSessionPreset352x288, AVCaptureSessionPreset640x480, AVCaptureSessionPreset1280x720, AVCaptureSessionPreset1920x1080];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _lineWidthSlider.value = _settings.lineWidth;
    _selectDimensionControl.selectedSegmentIndex = [_captureSessionPresets indexOfObject:_settings.captureSessionPreset];
    
    [self update];
}

-(void)update {
    _lineWidthSlider.value = _settings.lineWidth;
    
    CGFloat alpha;
    [_settings.lineColor getWhite:NULL alpha:&alpha];
    _lineAlphaSlider.value = alpha;
    
    _linePreview.layer.borderColor = [_settings.lineColor CGColor];
    _linePreview.layer.borderWidth = _settings.lineWidth;
    
    _selectLevelControl.selectedSegmentIndex = _settings.level;
    _selectDimensionControl.selectedSegmentIndex = [_captureSessionPresets indexOfObject:_settings.captureSessionPreset];
    
    for (int i = 0; i < 13; i++) {
        if (hexColor[i] == _settings.hexColor) {
            _lineColorSlider.value = i + 0.5;
        }
    }
}

-(UIColor *)uiColorFromHex:(NSInteger)value {
    float red = ((float)((value & 0xFF0000) >> 16)) / 0xFF;
    float green = ((float)((value & 0x00FF00) >> 8)) / 0xFF;
    float blue = ((float)(value & 0x0000FF)) / 0xFF;
    float alpha = _lineAlphaSlider.value;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

#pragma mark - IBAction

-(IBAction)onDismissTouched:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

-(IBAction)onSelectLevelValueChanged:(id)sender {
    _settings.level = _selectLevelControl.selectedSegmentIndex;
    [_settings saveAsUserDefaults];
}

-(IBAction)onSelectDimensionValueChange:(id)sender {
    _settings.captureSessionPreset = [_captureSessionPresets objectAtIndex:_selectDimensionControl.selectedSegmentIndex];
    [_settings saveAsUserDefaults];
}

-(IBAction)onLineColorValueChanged:(id)sender {
    NSInteger index = (NSInteger) _lineColorSlider.value;
    NSInteger hexValue = hexColor[index];
    _settings.hexColor = hexValue;
    _settings.lineColor = [self uiColorFromHex:hexValue];
    [_settings saveAsUserDefaults];
    [self update];
}

-(IBAction)onLineAlphaValueChange:(id)sender {
    CGFloat red, blue, green, alpha;
    [_settings.lineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    _settings.lineColor = [UIColor colorWithRed:red green:green blue:blue alpha:_lineAlphaSlider.value];
    [_settings saveAsUserDefaults];
    [self update];
}

-(IBAction)onlineWidthValueChanged:(id)sender {
    _settings.lineWidth = _lineWidthSlider.value;
    [_settings saveAsUserDefaults];
    [self update];
}

@end