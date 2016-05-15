//
//  Settings.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/14/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "Settings.h"

@implementation Settings

static NSString * const GPUOCRNSUserDefaultsHasSettingsKey = @"com.chrishanshew.gpuocr.nsuserdefaults.hassettings";
static NSString * const GPUOCRNSUserDefaultsModeKey = @"com.chrishanshew.gpuocr.nsuserdefaults.mode";
static NSString * const GPUOCRNSUserDefaultsLineWidthKey = @"com.chrishanshew.gpuocr.nsuserdefaults.linewidth";
static NSString * const GPUOCRNSUserDefaultsAVCapturePresetKey = @"com.chrishanshew.gpuocr.nsuserdefaults.avcapturepreset";
static NSString * const GPUOCRNSUserDefaultsLineColorKey = @"com.chrishanshew.gpuocr.nsuserdefaults.linecolor";
static NSString * const GPUOCRNSUserDefaultsHexColorKey = @"com.chrishanshew.gpuocr.nsuserdefaults.hexlinecolor";

-(void)saveAsUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:_mode forKey:GPUOCRNSUserDefaultsModeKey];
    [userDefaults setFloat:_lineWidth forKey:GPUOCRNSUserDefaultsLineWidthKey];
    [userDefaults setObject:_captureSessionPreset forKey:GPUOCRNSUserDefaultsAVCapturePresetKey];
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:_lineColor];
    [userDefaults setObject:colorData forKey:GPUOCRNSUserDefaultsLineColorKey];
    [userDefaults setInteger:_hexColor forKey:GPUOCRNSUserDefaultsHexColorKey];
    [userDefaults setBool:YES forKey:GPUOCRNSUserDefaultsHasSettingsKey];
}

+(instancetype)currentSettings {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    Settings* settings;
    if ([userDefaults boolForKey:GPUOCRNSUserDefaultsHasSettingsKey]) {
        settings = [[Settings alloc] init];
        settings.mode = [userDefaults integerForKey:GPUOCRNSUserDefaultsModeKey];
        settings.lineWidth = [userDefaults floatForKey:GPUOCRNSUserDefaultsLineWidthKey];
        settings.captureSessionPreset = [userDefaults stringForKey:GPUOCRNSUserDefaultsAVCapturePresetKey];
        NSData *colorData = [userDefaults objectForKey:GPUOCRNSUserDefaultsLineColorKey];
        settings.lineColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        settings.hexColor = [userDefaults integerForKey:GPUOCRNSUserDefaultsHexColorKey];
    } else {
         settings = [Settings defaultSettings];
        [settings saveAsUserDefaults];
    }
    return settings;
}

+(instancetype)defaultSettings {
    Settings* settings = [[Settings alloc] init];
    settings.mode = LivePreviewModeAnalysis;
    settings.lineWidth = 1.0;
    settings.lineColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    settings.hexColor = 0xfe0000;
    settings.captureSessionPreset = AVCaptureSessionPreset640x480;
    return settings;
}

@end
