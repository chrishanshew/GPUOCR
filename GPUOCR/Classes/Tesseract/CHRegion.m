//
// Created by Chris Hanshew on 5/16/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRegion.h"

@implementation CHRegion

- (CGRect) getRect {
    return CGRectMake(_left, _top, (_right - _left), (_bottom - _top));
}

@end