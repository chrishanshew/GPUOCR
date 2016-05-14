//
//  CHImageProcessor.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/13/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "CHTesseract.h"

@class CHImageProcessor;

@protocol CHImageProcessorDelegate
@optional
-(void)imageProcessorWillBeginProcessing:(CHImageProcessor *)imageProcessor;
-(void)imageProcessor:(CHImageProcessor *)imageProcessor finishedProcessingWithResult:(CHResultGroup *) result;
@end

@interface CHImageProcessor : NSObject

-(void)processImage:(UIImage *)image fromLevel:(CHTesseractAnalysisLevel)fromLevel toLevel:(CHTesseractAnalysisLevel)toLevel;

@end
