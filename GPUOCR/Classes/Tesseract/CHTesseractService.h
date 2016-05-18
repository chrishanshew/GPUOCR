//
// Created by Chris Hanshew on 5/18/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface CHTesseractService : NSObject

+(instancetype)sharedService;

/**
 * Queues a task for processing.
 *
 * @return true if task will be processed immediately and false if the task must be deferred
 */
-(BOOL)queue:(id<CHTesseractTask>)task;

@end