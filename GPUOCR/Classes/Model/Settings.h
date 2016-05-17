//
//  Settings.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/14/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "CHTesseract.h"

FOUNDATION_EXPORT NSString * const GPUOCRSettingsUpdatedNotification;

@interface Settings : NSObject

@property(nonatomic) CHTesseractAnalysisLevel level;
@property(nonatomic, strong) NSString *captureSessionPreset;
@property(nonatomic) float lineWidth;
@property(nonatomic, strong) UIColor *lineColor;
@property(nonatomic) NSInteger hexColor;

-(void)saveAsUserDefaults;
+(instancetype)currentSettings;
+(instancetype)defaultSettings;
+(CGSize)sizeForCaptureSessionPreset:(NSString *)preset andOrientation:(UIInterfaceOrientation)orientation;

@end
