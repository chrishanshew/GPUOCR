//
// Created by Chris Hanshew on 5/16/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRegion.h"

@implementation CHRegion

- (CGRect) getRect {
    return CGRectMake(_left, _top, (_right - _left), (_bottom - _top));
}

-(BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if (![super isEqual:object]) {
        return NO;
    }

    CHRegion *test = (CHRegion *)object;
    return self.index == test.index && self.analysisTimestamp == test.analysisTimestamp;
}

@end