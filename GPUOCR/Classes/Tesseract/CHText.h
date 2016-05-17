//
// Created by Chris Hanshew on 5/16/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHRegion;

@interface CHText : NSObject

@property(nonatomic, strong) CHRegion *region;
@property(nonatomic, strong) NSString *text;
@property(nonatomic) float confidence;

@end