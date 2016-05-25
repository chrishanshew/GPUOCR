//
// Created by Chris Hanshew on 5/23/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class CHRegion;

@interface CHRegionNode : NSObject

@property (nonatomic) CGRect rect;
@property (nonatomic, weak) CHRegionNode* parent;
@property (nonatomic, strong) CHRegionNode *left;
@property (nonatomic, strong) CHRegionNode *right;
@property (nonatomic, weak) CHRegion *region;

-(BOOL)initWithRegion:(CHRegion *)region;
-(BOOL)isLeaf;
-(BOOL)isOrphan;

@end

@interface CHRegionTree : NSObject

-(void)insert:(CHRegionNode *)node;
-(void)sync:(CHRegionNode *)node;

@end