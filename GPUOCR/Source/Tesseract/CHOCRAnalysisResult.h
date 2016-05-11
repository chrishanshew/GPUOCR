                              //
//  CHAnalysisResult.h
//  CHTesseract
//
//  Created by Chris Hanshew on 5/19/14.
//  Copyright (c) 2014 Chris Hanshew Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHTesseract.h"

@interface CHOCRAnalysisResult : NSObject

@property(nonatomic)CHTesseractAnalysisLevel level;
@property(nonatomic)CGSize imageSize;
@property(nonatomic, strong)NSArray *boxes;

@end
