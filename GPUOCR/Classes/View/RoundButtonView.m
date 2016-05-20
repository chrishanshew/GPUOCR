//
//  RoundButtonView.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/19/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "RoundButtonView.h"

@implementation RoundButtonView

-(void)awakeFromNib {
    [super awakeFromNib];

}

-(void)drawRect:(CGRect)rect {
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    CGContextAddEllipseInRect(ctx, rect);
//    CGContextSetFillColor(ctx, CGColorGetComponents([[UIColor whiteColor] CGColor]));
//    CGContextFillPath(ctx);
    
    CGContextRef ref = UIGraphicsGetCurrentContext();
    
    
    /* Create the rounded path and fill it */
    UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:rect.size.width/2];
    CGContextSetFillColorWithColor(ref, [UIColor whiteColor].CGColor);
    [roundedPath fill];
    
    /* Draw a subtle white line at the top of the view */
    [roundedPath addClip];
    CGContextSetStrokeColorWithColor(ref, [UIColor colorWithWhite:1.0 alpha:0.6].CGColor);
    CGContextSetBlendMode(ref, kCGBlendModeOverlay);
    
    CGContextStrokePath(ref);
}

@end
