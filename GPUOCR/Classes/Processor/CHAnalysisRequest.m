//
// Created by Chris Hanshew on 5/17/16.
// Copyright (c) 2016 Chris Hanshew. All rights reserved.
//

#import "CHAnalysisRequest.h"


@implementation CHAnalysisRequest

-(instancetype)initWithImage:(UIImage *)image forLevel:(CHTesseractAnalysisLevel)level {
    self = [super init];
    if (self) {
        _image = image;
        _level = level;
    }
    return self;
}

@end