//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "GPUImage.h"
#import "CHOCROutput.h"

@class CHRegion;
@class CHOCRProcessor;

@protocol CHOCRProcessorDelegate <NSObject>

@required
- (void)processor:(CHOCRProcessor *)processor completedOCRWithText:(CHText *)text inRegion:(CHRegion *)region;

@optional
- (void)processor:(CHOCRProcessor *)processor willBeginOCRInRegion:(CHRegion *)region;

@end

@interface CHOCRProcessor : GPUImageFilterGroup

-(instancetype)initWithProcessingSize:(CGSize)size;

@property(nonatomic, weak) id<CHOCRProcessorDelegate> delegate;
@property(nonatomic, strong, setter=setRegion:) CHRegion *region;

@end