//
//  RecordView.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/19/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ENUM(NSUInteger, ControlOption) {
    ControlOptionCamera,
    ControlOptionVideo,
    ControlOptionDisk
};

@interface ControlOverlayView: UIView <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIVisualEffectView *visualEffectView;
@property (strong, nonatomic) IBOutlet UIStackView *stackView;
@property (strong, nonatomic) IBOutlet UIImageView *folderImageView;
@property (strong, nonatomic) IBOutlet UIImageView *cameraImageView;
@property (strong, nonatomic) IBOutlet UIImageView *videoImageView;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (strong, nonatomic) IBOutlet UIButton *centerButton;

-(IBAction)onFolderImageTapped:(id)sender;
-(IBAction)onCameraImageTapped:(id)sender;
-(IBAction)onVideoImageTapped:(id)sender;
-(IBAction)onCenterButtonTapped:(id)sender;
-(IBAction)onSettingsButtonTapped:(id)sender;

-(void)drawCenter;

@end
