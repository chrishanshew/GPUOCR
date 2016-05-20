//
//  RoundButtonView.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/19/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface RoundButtonView : UIView

@property(nonatomic, strong) IBOutlet UIButton *button;
@property(nonatomic, strong) IBOutlet UIVisualEffectView *visualEffectView;
@property(nonatomic, strong) IBOutlet UIImageView *buttonImage;

@end
