//
//  CHImageProcessor.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/13/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHImageProcessor.h"
#import "GPUImage.h"

// NOT TARGETED

@interface CHImageProcessor() {
    GPUImagePicture *_imageInput;
}

@end

@implementation CHImageProcessor

-(void)processImage:(UIImage *)image fromLevel:(CHTesseractAnalysisLevel)fromLevel toLevel:(CHTesseractAnalysisLevel)toLevel {

}

@end
