//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHRecognizeResponse.h"
#import "CHRecognizeRequest.h"
#import "CHText.h"


@implementation CHRecognizeResponse

-(instancetype)initWithResults:(NSArray *)results forRequest:(CHRecognizeRequest *)request {
    self = [super init];
    if (self) {
        _results = results;
        _request = request;
    }
    return self;
}

@end