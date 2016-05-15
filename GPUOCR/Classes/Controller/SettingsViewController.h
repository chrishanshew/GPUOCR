//
// Created by Chris Hanshew on 5/14/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIkit.h>
#import "Settings.h"

@class SettingsViewController;

@protocol SettingsViewControllerDelegate <NSObject>

-(void)settingsController:(SettingsViewController *)controller willDismissWithUpdatedSettings:(Settings *)settings;

@end

@interface SettingsViewController : UIViewController

@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIButton *dismissButton;
@property (nonatomic, strong) IBOutlet UISegmentedControl *selectModeControl;
@property (nonatomic, strong) IBOutlet UISegmentedControl *selectLevelControl;
@property (nonatomic, strong) IBOutlet UISegmentedControl *selectDimensionControl;
@property (nonatomic, strong) IBOutlet UIView *linePreview;
@property (nonatomic, strong) IBOutlet UIImageView *lineColorImageView;
@property (nonatomic, strong) IBOutlet UISlider *lineColorSlider;
@property (nonatomic, strong) IBOutlet UISlider *lineAlphaSlider;
@property (nonatomic, strong) IBOutlet UISlider *lineWidthSlider;

@property (nonatomic, strong) IBOutlet UISwitch *showDebugSwitch;

-(IBAction)onDismissTouched:(id)sender;
-(IBAction)onSelectModeValueChanged:(id)sender;
-(IBAction)onSelectLevelValueChanged:(id)sender;
-(IBAction)onSelectDimensionValueChange:(id)sender;
-(IBAction)onLineColorValueChanged:(id)sender;
-(IBAction)onLineAlphaValueChange:(id)sender;
-(IBAction)onlineWidthValueChanged:(id)sender;

@end