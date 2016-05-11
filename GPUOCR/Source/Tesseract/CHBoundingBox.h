//
//  CHBoundingBox.h
//  CHTesseract
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CHBoundingBox : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic)NSInteger left;
@property (nonatomic)NSInteger top;
@property (nonatomic)NSInteger right;
@property (nonatomic)NSInteger bottom;
@property (nonatomic)float deskewAngle;

// Baseline Points
@property (nonatomic)CGPoint start;
@property (nonatomic)CGPoint end;

@property (nonatomic, readonly, getter=getRect)CGRect rect;
@end
