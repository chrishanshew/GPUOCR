//
//  CHBoundingBox.m
//  CHTesseract
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import "CHBoundingBox.h"

@implementation CHBoundingBox

-(CGRect) getRect {
    return CGRectMake(_right, _top, (_right + _left), (_top + _bottom));
}

- (NSString *)description {
    return [NSString stringWithFormat:@"RECT: %@", CGRectCreateDictionaryRepresentation([self getRect])];
}

@end
