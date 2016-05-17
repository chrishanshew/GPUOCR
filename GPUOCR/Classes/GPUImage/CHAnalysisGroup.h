//
//  CHAnalysisGroup.h
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "GPUImage.h"
#import "CHAnalysisOutput.h"
#import "CHRegion.h"

@interface CHAnalysisGroup : GPUImageFilterGroup

-(instancetype)initWithProcessingSize:(CGSize)size;

@property(nonatomic, weak)id<CHAnalysisOutputDelegate> delegate;
@property(nonatomic, setter=setLevel:)CHTesseractAnalysisLevel level;
@property(nonatomic, setter=setBlurRadius:)float blurRadius;

@end
