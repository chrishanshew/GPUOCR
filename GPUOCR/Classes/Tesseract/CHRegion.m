//
// Created by Chris Hanshew on 5/16/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRegion.h"
#import "Settings.h"
#import "GPUImageHazeFilter.h"
#import "GPUImageRawDataOutput.h"

@interface CHRegion () {
    CGRect _rect;
}

@end

@implementation CHRegion

- (CGRect) getRect {
    if (CGRectIsEmpty(_rect)) {
        _rect = CGRectMake(_left, _top, (_right - _left), (_bottom - _top));
    }
    return _rect;
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

-(float)getSlope {
    return (_start.y - _end.y) / (_start.x - _end.x);
}

-(float)intersectRatioToRegion:(CHRegion *)region {
    CGRect intersection = CGRectIntersection(self.rect, region.rect);
    int area = self.rect.size.width * self.rect.size.height;
    int intersectArea = intersection.size.width * intersection.size.height;
    return intersectArea / area;
}

@end