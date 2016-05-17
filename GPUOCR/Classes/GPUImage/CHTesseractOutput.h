//
//  CHTesseractOutput.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "GPUImage.h"
#import "CHTesseract.h"

@class CHTesseractOutput;

@protocol CHTesseractOutputDelegate <NSObject>

@optional
- (void)output:(CHTesseractOutput *)output completedAnalysisWithRegions:(NSArray *)regions;
- (void)willBeginDetectionWithOutput:(CHTesseractOutput *)output;

@end

@interface CHTesseractOutput : GPUImageFilterGroup

-(instancetype)initWithProcessingSize:(CGSize)size;

@property(nonatomic, weak)id<CHTesseractOutputDelegate> delegate;
@property(nonatomic, setter=setMode:)CHTesseractMode mode;
@property(nonatomic, setter=setLevel:)CHTesseractAnalysisLevel level;
@property(nonatomic, setter=setBlurRadius:)float blurRadius;

@end
