//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CHRegion.h"

@interface CHAnalysisRequest : NSObject

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, readonly) CHTesseractAnalysisLevel level;

-(instancetype)initWithImage:(UIImage *)image forLevel:(CHTesseractAnalysisLevel)level;

@end