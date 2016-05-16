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
@class CHResult;

@protocol CHImageProcessorDelegate <NSObject>
@optional
-(void)processorWillBeginProcessing:(CHImageProcessor *)processor;
-(void)processor:(CHImageProcessor *)processor didProcessResultGroup:(CHResultGroup *)group;
-(void)processor:(CHImageProcessor *)processor didProcessResult:(CHResult *)result atLevel:(CHTesseractAnalysisLevel)level;
-(void)processor:(CHImageProcessor *)processor didUpdateProgress:(float)progress forLevel:(CHTesseractAnalysisLevel)level;
-(void)processorWillCancelProcessing:(CHImageProcessor *)processor;
-(void)processor:(CHImageProcessor *)processor didCompleteProcessing:(CHResultGroup *)group error:(NSError *)error;
@end

@interface CHImageProcessor : NSObject

@property (nonatomic, weak)id<CHImageProcessorDelegate> delegate;
@property (nonatomic, strong, readonly, getter=getReferenceImage)UIImage *referenceImage;
@property (nonatomic, readonly)CHTesseractAnalysisLevel startLevel;
@property (nonatomic, readonly)CHTesseractAnalysisLevel endLevel;
@property (nonatomic, readonly)CHTesseractAnalysisLevel currentLevel;
@property (nonatomic, readonly)float currentLevelProgress;

-(instancetype)initWithUIImage:(UIImage *)image;

-(void)processFromLevel:(CHTesseractAnalysisLevel)fromLevel toLevel:(CHTesseractAnalysisLevel)toLevel;
-(BOOL)cancel;

@end
