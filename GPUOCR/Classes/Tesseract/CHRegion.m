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
    float _slope;
    CGPoint _midPoint;
}

@end

@implementation CHRegion

-(instancetype)init {
    self = [super init];
    if (self) {
        _rect = CGRectNull;
        _midPoint = CGPointZero;
        _slope = NAN;
    }
    return self;
}

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
    if (isnan(_slope)) {
        _slope = (_start.y - _end.y) / (_start.x - _end.x);
    }
    return _slope;
}

-(CGPoint)getMidPoint {
    if (CGPointEqualToPoint(_midPoint, CGPointZero)) {
        _midPoint = CGPointMake(CGRectGetMidX(self.rect), CGRectGetMidY(self.rect));
    }
    return _midPoint;
}

-(BOOL)isSimilarRegion:(CHRegion *)region threshold:(float)threshold {

    int xDiff = abs(self.rect.origin.x - region.rect.origin.x);
    int yDiff = abs(self.rect.origin.y - region.rect.origin.y);
    int widthDiff = abs(self.rect.size.width - region.rect.size.width);
    int heightDiff = abs(self.rect.size.height - region.rect.size.height);

    return NO;
}


-(float)intersectRatioToRegion:(CHRegion *)region {
    if (CGRectEqualToRect(self.rect, region.rect)) {
        return 1;
    }
    CGRect intersection = CGRectIntersection(self.rect, region.rect);
    if (!CGRectIsNull(intersection)) {
        int area = self.rect.size.width * self.rect.size.height;
        int intersectArea = intersection.size.width * intersection.size.height;
        return intersectArea / area;
    }
    return 0;
}

@end