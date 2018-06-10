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

#import "XENCCStatsView.h"
#import "XENResources.h"

@implementation XENCCStatsView

-(instancetype)initWithVariant:(int)variant customImage:(UIImage*)image andDefaultString:(NSString*)string {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        _imageView = [[UIImageView alloc] initWithImage:image];
        _imageView.backgroundColor = [UIColor clearColor];
        if ([XENResources togglesGlyphTintForState:0 isCircle:NO])
            _imageView.tintColor = [XENResources togglesGlyphTintForState:0 isCircle:NO];
        else
            _imageView.tintColor = [UIColor whiteColor];
        _imageView.alpha = 0.75;
        
        [self addSubview:_imageView];
        
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.backgroundColor = [UIColor clearColor];
        _label.alpha = 0.75;
        _label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        if ([XENResources togglesGlyphTintForState:0 isCircle:NO])
            _label.textColor = [XENResources togglesGlyphTintForState:0 isCircle:NO];
        else
            _label.textColor = [UIColor whiteColor];
        _label.text = string;
        _label.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_label];
        
        _variant = variant;
    }
    
    return self;
}

-(void)updateLabel:(NSString *)string {
    _label.text = string;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // DEBUG
    _imageView.frame = CGRectMake(0, 0, 50, 50);
    
    _imageView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2 - _imageView.frame.size.height/2);
    _label.frame = CGRectMake(0, self.frame.size.height/2, self.frame.size.width, _imageView.frame.size.height);
}

-(void)dealloc {
    [_imageView removeFromSuperview];
    _imageView = nil;
    
    [_label removeFromSuperview];
    _label = nil;
}

@end
