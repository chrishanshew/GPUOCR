//
//  CHGPUOCRViewController.h
//  CHOCRViewController
//
//  Created by Chris Hanshew on 12/25/13.
//  Copyright (c) 2013 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface CHGPUOCRViewController : UIViewController <GPUImageVideoCameraDelegate> {
    GPUImageVideoCamera *_videoCamera;
    GPUImageStillCamera *_stillCamera;
    GPUImageBuffer *_imageBuffer;
    AVCaptureVideoPreviewLayer *_previewLayer;
}

@property(nonatomic, strong) IBOutlet UITapGestureRecognizer *tapRecognizer;

- (IBAction)handleScreenTap:(id)sender;

@end
