//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "GPUImage.h"
#import "CHRecognitionOutput.h"

@class CHRegion;

@interface CHRecognitionGroup : GPUImageFilterGroup

-(instancetype)initWithProcessingSize:(CGSize)size;

@property(nonatomic, weak)id<CHRecognitionOutputDelegate> delegate;
@property(nonatomic, strong, setter=setRegion:) CHRegion *region;

@end