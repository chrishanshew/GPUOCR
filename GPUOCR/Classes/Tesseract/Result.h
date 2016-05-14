//
//  Result.h
//  CHTesseract
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CHTesseract.h"

@interface Result : NSObject

// Position Index
@property(nonatomic) NSUInteger index; // Detection index relative to other results in group

// Raw Coordinates
@property(nonatomic) NSInteger left;
@property(nonatomic) NSInteger top;
@property(nonatomic) NSInteger right;
@property(nonatomic) NSInteger bottom;

// Text Recognition
@property(nonatomic, strong) NSString *text; // Returns nil when performing layout analysis
@property(nonatomic) float confidence; // Recognition probability

// Baseline Points
@property(nonatomic) CGPoint start;
@property(nonatomic) CGPoint end;

// Iterator Level
@property(nonatomic) CHTesseractAnalysisLevel level;

@property(nonatomic) CGSize imageSize;

// Computed Geometry
@property(nonatomic, readonly, getter=getRect) CGRect rect;
@property(nonatomic, readonly, getter=getSlope) double slope;

@end
