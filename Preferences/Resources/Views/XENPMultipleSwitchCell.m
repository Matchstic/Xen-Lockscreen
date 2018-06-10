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

#import "XENPMultipleSwitchCell.h"

@implementation XENPMultipleSwitchCell

-(instancetype)initWithImage:(UIImage *)image label:(NSString *)label node:(int)node andDelegate:(id)delegate {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _node = node;
        self.delegate = delegate;
        
        _imageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.tintColor = [[UIApplication sharedApplication] keyWindow].tintColor;
        
        [self addSubview:_imageView];
        
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.text = label;
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:12];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [[UIApplication sharedApplication] keyWindow].tintColor;
        _label.layer.borderColor = [[UIApplication sharedApplication] keyWindow].tintColor.CGColor;
        [_label sizeToFit];
        
        [self addSubview:_label];
        
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didReceiveTap:)];
        [self addGestureRecognizer:_tapGesture];
    }
    
    return self;
}

-(void)didReceiveTap:(id)sender {
    [self.delegate didSelectNode:self.node];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    _imageView.frame = CGRectMake(0, self.frame.size.height * 0.05, self.frame.size.width, self.frame.size.height * 0.7);
    _label.frame = CGRectMake(self.frame.size.width/2 - _label.frame.size.width/2 - 7.5, self.frame.size.height * 0.8, _label.frame.size.width + 15, self.frame.size.height * 0.125);
    _label.layer.cornerRadius = _label.frame.size.height/2;
}

-(void)setEnabled:(BOOL)enabled {
    _label.layer.borderWidth = (enabled ? 1.0 : 0.0);
}

@end
