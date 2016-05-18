//
// Created by Chris Hanshew on 5/18/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CHTesseractTaskPriority) {
    CHTesseractTaskPriorityLow = 0,
    CHTesseractTaskPriorityNormal,
    CHTesseractTaskPriorityHigh
};

#pragma mark - Task Protocol

@protocol CHTesseractTask <NSObject>

@property(nonatomic, strong, readonly) NSString *taskId;
@property(nonatomic,readonly) CHTesseractTaskPriority priority;
@property(nonatomic, strong, readonly) NSDate *created;
@property(nonatomic, strong, readonly) NSDate *started;
@property(nonatomic, strong, readonly) NSDate *completed;

@end

#pragma mark - Task Results

@protocol CHTesseractResult <NSObject>

@property(nonatomic, strong, readonly) id<CHTesseractTask> task;

@end

#pragma mark - Task Implementations

@interface CHLayoutAnalysisTask <CHTesseractTask>



@end

@interface CHOCRTask <CHTesseractTask>



@end

#pragma mark - Result Implementations

//- (id)copyWithZone:(NSZone *)zone
//{
//id copy = [[[self class] alloc] init];
//
//if (copy) {
//// Copy NSObject subclasses
//[copy setVendorID:[[self.vendorID copyWithZone:zone] autorelease]];
//[copy setAvailableCars:[[self.availableCars copyWithZone:zone] autorelease]];
//
//// Set primitives
//[copy setAtAirport:self.atAirport];
//}
//
//return copy;
//}