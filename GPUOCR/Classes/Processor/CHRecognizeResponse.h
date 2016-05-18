//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHRecognizeRequest;
@class CHText;


@interface CHRecognizeResponse : NSObject

@property (nonatomic, strong, readonly) CHRecognizeRequest *request;
@property (nonatomic, strong, readonly) NSArray *results;

-(instancetype)initWithResults:(NSArray *)results forRequest:(CHRecognizeRequest *)request;

@end