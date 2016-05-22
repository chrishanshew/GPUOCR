//
// Created by Chris Hanshew on 5/16/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSUInteger, CHTesseractAnalysisLevel) {
    CHTesseractAnalysisLevelBlock = 0,
    CHTesseractAnalysisLevelParagraph,
    CHTesseractAnalysisLevelTextLine,
    CHTesseractAnalysisLevelWord,
    CHTesseractAnalysisLevelSymbol
};

@interface CHRegion : NSObject

@property(nonatomic) NSUInteger analysisTimestamp;

// Position Index
@property(nonatomic) NSUInteger index; // Detection index relative to other results in group

@property(nonatomic) CHTesseractAnalysisLevel analysisLevel;

// Raw Coordinates
@property(nonatomic) NSInteger left;
@property(nonatomic) NSInteger top;
@property(nonatomic) NSInteger right;
@property(nonatomic) NSInteger bottom;

// Baseline Points
@property(nonatomic) CGPoint start;
@property(nonatomic) CGPoint end;

// Text Direction
@property(nonatomic) NSInteger offset;
@property(nonatomic) NSInteger textSlope;

// Input Image Info
@property(nonatomic) CGSize imageSize;

// Computed Geometry
@property(nonatomic, readonly, getter=getRect) CGRect rect;

-(float)intersectRatioToRegion:(CHRegion *)region;

@end