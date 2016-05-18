//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHAnalysisResponse.h"
#import "CHAnalysisRequest.h"
#import "CHRegion.h"
#import "CHAnalysisRequest.h"


@implementation CHAnalysisResponse

-(instancetype)initWithRegions:(NSArray *)regions :forRequest:(CHAnalysisRequest *)request {
    self = [super init];
    if (self) {
        _regions = regions;
        _request = request;
    }
    return self;
}

@end