//
//  CHRegionFilter.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/15/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "CHRegionFilter.h"
#import "CHRegionGenerator.h"
#import "CHRegion.h"

@interface CHRegionFilter () {
    GPUImageAlphaBlendFilter *blendFilter;
    GPUImageGammaFilter *gammaFilter;
    CHRegionGenerator* regionGenerator;
    GPUImageLanczosResamplingFilter *resamplingFilter;

    NSMutableArray *_regions;
    dispatch_queue_t _resultsAccessQueue;
}

@end

@implementation CHRegionFilter

// TODO: REMOVE SIZE PARAMETER - USE FORCEPROCESSING
-(instancetype)init {
    self = [super init];
    if (self) {

        _resultsAccessQueue = dispatch_queue_create("com.chrishanshew.gpuocr.resultsaccessqueue", DISPATCH_QUEUE_CONCURRENT);
        _regions = [NSMutableArray array];

        // GPUImage Filters
        resamplingFilter = [[GPUImageLanczosResamplingFilter alloc] init];
        [self addFilter:resamplingFilter];
        blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        [self addFilter:blendFilter];
        gammaFilter = [[GPUImageGammaFilter alloc] init];
        [self addFilter:gammaFilter];

        regionGenerator = [[CHRegionGenerator alloc] init];
        [self addFilter:regionGenerator];

        self.initialFilters = @[resamplingFilter];
        [resamplingFilter addTarget:gammaFilter];
        [gammaFilter addTarget:blendFilter];
        [regionGenerator addTarget:blendFilter];
        self.terminalFilter = blendFilter;

        __block CHRegionGenerator *weakResultsGenerator = regionGenerator;
        [gammaFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
            NSArray *regions = [self getRegions];
            [weakResultsGenerator renderRegions:regions atFrameTime:time];
        }];
    }
    return self;
}

-(void)setLineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha {
    [regionGenerator setLineColorWithRed:red green:green blue:blue alpha:alpha];
}

-(void)setLineWidth:(float)width {
    [regionGenerator setLineWidth:width];
}

- (void)setRegions:(NSArray *)regions {
    dispatch_barrier_async(_resultsAccessQueue, ^{
        _regions = [NSArray arrayWithArray:regions];
    });
}

-(void)addRegion:(CHRegion *)region {

    NSMutableArray *regions = [NSMutableArray arrayWithArray:[self getRegions]];
    // Is there a matching index?
    if ((regions.count - 1) > region.index) {
        // Get stored region with matching index
        CHRegion* test = [regions objectAtIndex:region.index];
        float intersectPercent = [region intersectRatioToRegion:test];
        // TODO: Determine if threshold value can be dynamically updated
        if (intersectPercent > 0.85) { // Threshold
            // We consider it a match
            [regions replaceObjectAtIndex:region.index withObject:region];
        } else {
            // Determine which direction to traverse

            if (test.rect.origin.x < region.rect.origin.x  || test.rect.origin.y < region.rect.origin.y) {

            }
        }

    } else {
        // NOT GOOD
        // traversal begins at the end of the collection
    }

}

- (NSArray *)getRegions {
    __block NSArray *regions;
    dispatch_sync(_resultsAccessQueue, ^{
        regions = [NSArray arrayWithArray:_regions];
    });
    return regions;
}

@end
