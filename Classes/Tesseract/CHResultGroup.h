//
// Created by Chris Hanshew on 5/14/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHTesseract.h"

@interface CHResultGroup : NSObject

@property(nonatomic)CHTesseractAnalysisLevel level;

// Text Direction
@property(nonatomic) NSInteger offset;
@property(nonatomic) NSInteger slope;

// Input Image Info
@property(nonatomic) CGSize imageSize;
@property(nonatomic) NSUInteger bytesPerPixel;
@property(nonatomic) NSUInteger samplesPerPixel;

// Results
@property(nonatomic, strong) NSArray *results;

@end