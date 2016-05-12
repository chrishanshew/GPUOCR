//
//  Result.m
//  CHTesseract
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "Result.h"

@implementation Result

- (CGRect) getRect {
    return CGRectMake(_right, _top, (_right + _left), (_top + _bottom));
}

- (double) getSlope {
    double m = (_end.y - _start.y) / (_end.x - _start.x);
    return _end.y - (m * _end.x);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"===\nIndex: %lu\nBaseline  Rect: %@", _index, CGRectCreateDictionaryRepresentation([self getRect])];
}

@end
