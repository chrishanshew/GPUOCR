//
//  Settings.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/14/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LivePreviewMode) {
    LivePreviewModeAnalysis = 0,
    LivePreviewModeOSD,
    LivePreviewModeRecognition
};

@interface Settings : NSObject

@property(nonatomic) LivePreviewMode mode;
@property(nonatomic, strong) NSString *captureSessionPreset;
@property(nonatomic) float lineWidth;
@property(nonatomic, strong) UIColor *lineColor;
@property(nonatomic) NSInteger hexColor;

-(void)saveAsUserDefaults;
+(instancetype)currentSettings;
+(instancetype)defaultSettings;

@end
