//
//  CHOCRDrawResultFilter.h
//  CHOCR
//
//  Created by Chris Hanshew on 2/13/16.
//  Copyright © 2016 Chris Hanshew Software, LLC. All rights reserved.
//

#import "GPUImage.h"

@interface CHOCRDrawResultFilter : GPUImageFilter

@property(nonatomic, strong, readonly) NSArray *results;

-(void)renderResultsWithFrameTime:(CMTime)frameTime;
-(void)setResults:(NSArray *)results;

@end
