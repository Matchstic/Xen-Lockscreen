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

#import "XENWeatherBackgroundView.h"
#import "XENWeatherLayerFactory.h"

@implementation XENWeatherBackgroundView

/*-(id)initWithCondition:(int)condition isDay:(BOOL)isDay {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _conditionLayer = [[XENWeatherLayerFactory sharedInstance] layerForCondition:condition isDay:isDay];
            _gradientLayer = [[XENWeatherLayerFactory sharedInstance] colourBackingLayerForCondition:condition isDay:isDay];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _gradientLayer.frame = CGRectZero;
                _gradientLayer.bounds = CGRectZero;
                
                [self.layer addSublayer:_gradientLayer];
                
                _conditionLayer.opacity = 1.0;
                _conditionLayer.hidden = NO;
                _conditionLayer.geometryFlipped = YES;
                
                _idkView = [[UIView alloc] initWithFrame:_conditionLayer.frame];
                _idkView.backgroundColor = [UIColor clearColor];
                
                if (_conditionLayer.bounds.size.width > 0) {
                    _idkView.transform = CGAffineTransformMakeScale(SCREEN_WIDTH/_conditionLayer.bounds.size.width, SCREEN_HEIGHT/_conditionLayer.bounds.size.height);
                }
                _idkView.frame = CGRectMake(0, 0, _idkView.frame.size.width, _idkView.frame.size.height);
                
                [_idkView.layer addSublayer:_conditionLayer];
                
                [self addSubview:_idkView];
                
                self.clipsToBounds = YES;
                self.layer.shouldRasterize = YES;
                self.layer.rasterizationScale = [UIScreen mainScreen].scale;
                
                [self setNeedsLayout];
            });
        });
    }
    
    return self;
}*/

-(void)transitionToCondition:(int)condition isDay:(BOOL)isDay {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CALayer *newConditionLayer = [[XENWeatherLayerFactory sharedInstance] layerForCondition:condition isDay:isDay];
        CALayer *newGradientLayer = [[XENWeatherLayerFactory sharedInstance] colourBackingLayerForCondition:condition isDay:isDay];
        
        NSLog(@"Got views, moving to main thread again.");
        
         dispatch_async(dispatch_get_main_queue(), ^{
             newGradientLayer.frame = _gradientLayer.frame;
             
             [self.layer insertSublayer:newGradientLayer below:_gradientLayer];
             
             newConditionLayer.opacity = 1.0;
             newConditionLayer.hidden = NO;
             newConditionLayer.geometryFlipped = YES;
             
             UIView *newIdkView = [[UIView alloc] initWithFrame:newConditionLayer.frame];
             newIdkView.backgroundColor = [UIColor clearColor];
             newIdkView.alpha = 1.0;
             
             if (newConditionLayer.bounds.size.width > 0) {
                 newIdkView.transform = CGAffineTransformMakeScale(SCREEN_WIDTH/newConditionLayer.bounds.size.width, SCREEN_HEIGHT/newConditionLayer.bounds.size.height);
             }
             
             newIdkView.frame = CGRectMake(0, 0, newIdkView.frame.size.width, newIdkView.frame.size.height);
             
             [newIdkView.layer addSublayer:newConditionLayer];
             
             [self insertSubview:newIdkView belowSubview:_idkView];
             
             [UIView animateWithDuration:0.3 animations:^{
                 _idkView.alpha = 0.0;
                 _conditionLayer.opacity = 0.0;
             } completion:^(BOOL finished) {
                 [self unloadLayers];
                 
                 _idkView = newIdkView;
                 _conditionLayer = newConditionLayer;
                 _gradientLayer = newGradientLayer;
             }];
         });
    });
}

-(void)unloadLayers {
    [_conditionLayer removeFromSuperlayer];
    _conditionLayer = nil;
    
    [_idkView removeFromSuperview];
    _idkView = nil;
    
    [_gradientLayer removeFromSuperlayer];
    _gradientLayer = nil;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    _gradientLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    _gradientLayer.bounds = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    _idkView.transform = CGAffineTransformIdentity;
    _idkView.frame = _conditionLayer.frame;
    if (_conditionLayer.bounds.size.width > 0) {
        _idkView.transform = CGAffineTransformMakeScale(SCREEN_WIDTH/_conditionLayer.bounds.size.width, SCREEN_HEIGHT/_conditionLayer.bounds.size.height);
    }
    _idkView.frame = CGRectMake(0, 0, _idkView.frame.size.width, _idkView.frame.size.height);
    //_conditionLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    //_conditionLayer.bounds = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    //_conditionLayer.frame = _conditionLayer.bounds;
}

-(void)dealloc {
    [_gradientLayer removeFromSuperlayer];
    _gradientLayer = nil;
    
    [_conditionLayer removeFromSuperlayer];
    _conditionLayer = nil;
    
    [_idkView removeFromSuperview];
    _idkView = nil;
}

@end
