//
// Created by Chris Hanshew on 5/23/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRegionTree.h"
#import "CHRegion.h"

@interface CHRegionNode ()

@end

@implementation CHRegionNode

-(instancetype)initWithRegion:(CHRegion *)region {
    self = [super init];
    if (self) {
        _rect = CGRectZero;
        _region = region;
    }
    return self;
}

-(BOOL)isLeaf {
    return _left == nil && _right == nil && _region != nil;
}

-(BOOL)isOrphan {
    return _left == nil && _right == nil && _region == nil;
}

@end

@interface CHRegionTree () {
    CHRegionNode *_root;
}

-(BOOL)insert:(CHRegionNode *)new into:(CHRegionNode *)node;

@end

@implementation CHRegionTree

-(void)insert:(CHRegionNode *)node {
    if (_root) {
        [self insert:node into:_root];
    } else {
        _root = node;
    }
}

-(BOOL)insert:(CHRegionNode *)new into:(CHRegionNode *)node {
    // If the bounding box of node fully contains new, add new as leaf
    if(CGRectContainsRect(node.rect, new.region.rect)) {
        // If node is a leaf, create a new parent sized for both leaves
        if ([node isLeaf]) {

        }
        if (!node.left || !node.right) {
            if (node.left) {
                node.right = new;
            }
        }
    } else {
        if (node.left);

        }
    }
    return NO;
}

@end