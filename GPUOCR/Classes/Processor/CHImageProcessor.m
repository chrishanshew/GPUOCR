//
//  CHImageProcessor.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/13/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "CHImageProcessor.h"
#import "CHOCROutput.h"
#import "CHAnalysisRequest.h"
#import "CHRecognizeRequest.h"
#import "CHRecognizeResponse.h"
#import "CHAnalysisResponse.h"
#import "CHLayoutProcessor.h"

// NOT TARGETED

@interface CHImageProcessor() <CHImageProcessorDelegate, CHLayoutOutputDelegate> {
    UIImage *_image;
    GPUImagePicture *_imageInput;
    GPUImageLanczosResamplingFilter *_resamplingFilter;
    CHOCROutput *_recognitionOutput;

    NSMutableDictionary *_resultGroupsForLevel;
}

@end

@implementation CHImageProcessor

-(instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

-(void)executeAnalysisRequest:(CHAnalysisRequest *)request {
    GPUImagePicture *imageInput = [[GPUImagePicture alloc] initWithImage:request.image];
    CHLayoutProcessor *analysisGroup = [[CHLayoutProcessor alloc] initWithProcessingSize:request.image.size];
    analysisGroup.delegate = self;

    [imageInput addTarget:analysisGroup];
    [imageInput processImage];
}

-(void)executeRecognizeRequest:(CHRecognizeRequest *)request {

}

#pragma mark - <CHAnalysisOutputDelegate>

- (void)willBeginAnalysisWithOutput:(CHLayoutOutput *)output {

}

-(void)output:(CHLayoutOutput*)output completedAnalysisWithRegions:(NSArray *)regions {

}

@end
