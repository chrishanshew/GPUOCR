//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRecognizeRequest.h"
#import "CHRegion.h"


@implementation CHRecognizeRequest

-(instancetype)initWithData:(NSData *)data forRegions:(NSArray *) regions {
    self = [super init];
    if (self) {
        _imageData = data;
        _regions = regions;
    }
    return self;
}

@end