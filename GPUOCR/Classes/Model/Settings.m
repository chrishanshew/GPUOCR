//
//  Settings.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/14/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "Settings.h"

@implementation Settings

NSString * const GPUOCRSettingsUpdatedNotification = @"com.chrishanshew.gpuocr.nsnotificationcenter.settingsupdated";

static NSString * const GPUOCRNSUserDefaultsHasSettingsKey = @"com.chrishanshew.gpuocr.nsuserdefaults.hassettings";
static NSString * const GPUOCRNSUserDefaultsLevelKey = @"com.chrishanshew.gpuocr.nsuserdefaults.level";
static NSString * const GPUOCRNSUserDefaultsLineWidthKey = @"com.chrishanshew.gpuocr.nsuserdefaults.linewidth";
static NSString * const GPUOCRNSUserDefaultsAVCapturePresetKey = @"com.chrishanshew.gpuocr.nsuserdefaults.avcapturepreset";
static NSString * const GPUOCRNSUserDefaultsLineColorKey = @"com.chrishanshew.gpuocr.nsuserdefaults.linecolor";
static NSString * const GPUOCRNSUserDefaultsHexColorKey = @"com.chrishanshew.gpuocr.nsuserdefaults.hexlinecolor";

-(void)saveAsUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:_level forKey:GPUOCRNSUserDefaultsLevelKey];
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
        settings.level = [userDefaults integerForKey:GPUOCRNSUserDefaultsLevelKey];
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
    settings.level = CHTesseractAnalysisLevelTextLine;
    settings.lineWidth = 1.0;
    settings.lineColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    settings.hexColor = 0xfe0000;
    settings.captureSessionPreset = AVCaptureSessionPreset640x480;
    return settings;
}

+(CGSize)sizeForCaptureSessionPreset:(NSString *)preset andOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = CGSizeMake(352.0, 288.0); // Default
    if ([preset isEqualToString:AVCaptureSessionPreset352x288]) {
        size = CGSizeMake(352.0, 288.0);
    }
    if ([preset isEqualToString:AVCaptureSessionPreset640x480]) {
        size = CGSizeMake(640.0, 480.0);
    }
    if ([preset isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
        size = CGSizeMake(960.0, 540.0);
    }
    if ([preset isEqualToString:AVCaptureSessionPresetiFrame1280x720]) {
        size = CGSizeMake(1280.0, 720.0);
    }
    if ([preset isEqualToString:AVCaptureSessionPreset1280x720]) {
        size = CGSizeMake(1280.0, 720.0);
    }
    if ([preset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        size = CGSizeMake(1920.0, 1080.0);
    }
    if ([preset isEqualToString:AVCaptureSessionPreset3840x2160]) {
        size = CGSizeMake(3840.0, 2160.0);
    }
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}

@end
