//
//  CHImageProcessor.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/13/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CHAnalysisRequest.h"

@class CHImageProcessor;
@class CHResult;
@class CHAnalysisRequest;
@class CHRecognizeRequest;
@class CHRecognizeResponse;
@class CHAnalysisResponse;

@protocol CHImageProcessorDelegate <NSObject>
@optional
-(void)processor:(CHImageProcessor *)processor willExecuteAnalysisRequest:(CHAnalysisRequest *)request;
-(void)processor:(CHImageProcessor *)processor didFinishAnalysisWithResponse:(CHAnalysisResponse *)response;

-(void)processor:(CHImageProcessor *) processor willExecuteRecognizeRequest:(CHRecognizeRequest *)request;
-(void)processor:(CHImageProcessor *) processor didFinishRecognitionWithResponse:(CHRecognizeResponse *)response;
@end

@interface CHImageProcessor : NSObject

@property (nonatomic, weak)id<CHImageProcessorDelegate> delegate;

-(void)executeAnalysisRequest:(CHAnalysisRequest *)request;
-(void)executeRecognizeRequest:(CHRecognizeRequest *)request;

@end
