/*
 Copyright (C) 2018  Matt Clarke
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#import "XENPHeaderSwitch.h"

@implementation XENPHeaderSwitch

-(instancetype)initWithFrame:(CGRect)frame andCallback:(void(^)(void))callback {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.callback = callback;
        
        self.layer.cornerRadius = 16;
        self.layer.masksToBounds = YES;
        
        _baseView = [[UIView alloc] initWithFrame:CGRectMake(-90, 0, 120, self.bounds.size.height)];
        _baseView.backgroundColor = [UIColor whiteColor];
        _baseView.userInteractionEnabled = NO;
        
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = _baseView.bounds;
        maskLayer.fillColor = [UIColor blackColor].CGColor;
        
        static CGFloat const kRadius = 15;
        CGRect const circleRect = CGRectMake(CGRectGetMidX(_baseView.bounds) - kRadius,
                                             CGRectGetMidY(_baseView.bounds) - kRadius,
                                             2 * kRadius, 2 * kRadius);
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:circleRect];
        [path appendPath:[UIBezierPath bezierPathWithRect:_baseView.bounds]];
        maskLayer.path = path.CGPath;
        maskLayer.fillRule = kCAFillRuleEvenOdd;
        
        _baseView.layer.mask = maskLayer;
        
        [self addSubview:_baseView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
        
        [self setOn:NO animated:NO];
    }
    
    return self;
}

-(void)handleTap:(UITapGestureRecognizer*)tap {
    [self setOn:!_currentValue animated:YES];
    
    self.callback();
}

-(void)setFrame:(CGRect)frame {
    frame.size = CGSizeMake(60, 32);
    [super setFrame:frame];
}

-(void)setOn:(BOOL)on animated:(BOOL)animated {
    _currentValue = on;
    
    // Animate
    NSTimeInterval duration = (animated ? 0.2 : 0.01);// match this to the value of the UIView animateWithDuration: call
    
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _baseView.center = CGPointMake((on ? 44 : 16), 16);
    } completion:^(BOOL finished) {}];
}

-(BOOL)currentValue {
    return _currentValue;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    //_baseView.frame = self.bounds;
}

@end
