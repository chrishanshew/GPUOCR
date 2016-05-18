//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHRegion;

@interface CHRecognizeRequest : NSObject

@property (nonatomic, strong, readonly) NSData *imageData;
@property (nonatomic, strong, readonly) NSArray *regions;

-(instancetype)initWithData:(NSData *)data forRegions:(NSArray *) regions;

@end