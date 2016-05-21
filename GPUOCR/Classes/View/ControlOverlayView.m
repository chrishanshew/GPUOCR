//
//  RecordView.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/19/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "ControlOverlayView.h"

@implementation ControlOverlayView

-(void)awakeFromNib {
    [super awakeFromNib];
}

-(void)drawRect:(CGRect)rect {
    _visualEffectView.layer.mask = ({
        CGRect roundedRect = self.bounds;
        roundedRect.origin.x = roundedRect.size.width / 4.0f;
        roundedRect.origin.y = roundedRect.size.height / 4.0f;
        roundedRect.size.width /= 2.0f;
        roundedRect.size.height /= 2.0f;
        
        CGFloat cornerRadius = roundedRect.size.height / 2.0f;
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
        UIBezierPath *croppedPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:cornerRadius];
        [path appendPath:croppedPath];
        [path setUsesEvenOddFillRule:YES];
        
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.path = path.CGPath;
        mask.fillRule = kCAFillRuleEvenOdd;
        mask;
    });
}

-(void)drawCenter {
    

}

#pragma mark - IBActions

-(IBAction)onFolderImageTapped:(id)sender {
    
}

-(IBAction)onCameraImageTapped:(id)sender {
    
}

-(IBAction)onVideoImageTapped:(id)sender {
    
}

-(IBAction)onSettingsButtonTapped:(id)sender {
    
}

-(IBAction)onCenterButtonTapped:(id)sender {
    
}

@end
