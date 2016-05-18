//
// Created by Chris Hanshew on 5/18/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHTesseractService.h"
#import "CHTesseractTask.h"

#define kMaxWorkerCount = 2

/**
 *
 * Workflow
 *
 * - Receive Request
 * - If queue is empty start processing, else write data to disk and wait for next tesseract object
 *
 *
 */

@interface CHTesseractService () {
    NSMutableArray *_taskQueue;
    NSMutableArray *_idleWorkers;
    NSMutableArray *_activeWorkers;

    dispatch_queue_t _processingQueue;

    NSURL *_tmpDirectoryURL;
}

@end

@implementation CHTesseractService

+(instancetype)sharedService {
    static CHTesseractService *sharedService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedService = [[self alloc] init];
    });
    return sharedService;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _tmpDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    }
    return self;
}

#pragma mark - Task Queueing

-(BOOL)queue:(id<CHTesseractTask>)task {

    if

}

-(void)execute:(id<CHTesseractTask>)task {
    if ([task isKindOfClass:[CHLayoutAnalysisTask class]]) {

    }
    if ([task isKindOfClass:[CHOCRTask class]]) {

    }
}

#pragma mark - File System Operations

-(void)saveTask:(id<CHTesseractTask>)task {
    NSMutableData *taskData = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:taskData];
    [archiver encodeObject:task];
    [taskData writeToURL:[NSURL fileURLWithPath:task.taskId isDirectory:NO relativeToURL:_tmpDirectoryURL] atomically:YES];
}

-(id<CHTesseractTask>)taskForId:(NSString *) taskId {
    NSURL *taskURL = [NSURL fileURLWithPath:taskId isDirectory:NO relativeToURL:_tmpDirectoryURL];
    NSData *codedTask = [[NSData alloc] initWithContentsOfFile:taskURL];
    if (codedTask == nil) return nil;

    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedTask];
    id<CHTesseractTask> task = (id<CHTesseractTask>)[unarchiver decodeObject];

    if (task) {
        [[NSFileManager defaultManager] removeItemAtURL:taskURL error:nil];
        return task;
    }
    return nil;
}


@end