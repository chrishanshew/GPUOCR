//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHAnalysisRequest;

@interface CHAnalysisResponse : NSObject

@property (nonatomic, strong, readonly) NSArray *regions;
@property (nonatomic, strong, readonly) CHAnalysisResponse *request;

-(instancetype)initWithRegions:(NSArray *)regions :forRequest:(CHAnalysisRequest *)request;

@end