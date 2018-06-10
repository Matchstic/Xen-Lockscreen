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

#import "XENLaunchpadCollectionCell.h"
#import "XENResources.h"

@implementation XENLaunchpadCollectionCell

-(void)setupWithSnapshotView:(UIView *)snapshot andIconView:(UIView *)icon {
    _iconOnly = NO;
    
    [self.snapshotView removeFromSuperview];
    self.snapshotView = nil;
    
    [self.iconView removeFromSuperview];
    self.iconView = nil;
    
    self.snapshotView = snapshot;
    self.iconView = icon;
    
    self.iconView.transform = CGAffineTransformMakeScale([XENResources launchpadIconSize], [XENResources launchpadIconSize]);
    self.snapshotView.layer.cornerRadius = 6.25;
    
    [self addSubview:self.snapshotView];
    [self addSubview:self.iconView];
}

-(void)setupWithIconView:(UIView *)icon {
    _iconOnly = YES;
    
    [self.iconView removeFromSuperview];
    self.iconView = nil;
    
    self.iconView = icon;
    self.iconView.transform = CGAffineTransformMakeScale([XENResources launchpadIconSize], [XENResources launchpadIconSize]);
    
    [self addSubview:self.iconView];
}

-(void)layoutSubviews {
    if (!_iconOnly) {
        CGFloat iconHeight = (IS_IPAD ? 72 : 60) * [XENResources launchpadIconSize];
        
        self.snapshotView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - iconHeight);
    
        UIView *actualSnaphot = self.snapshotView.subviews.firstObject;
        actualSnaphot.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        CGFloat transform = self.snapshotView.frame.size.width/SCREEN_MIN_LENGTH;
        actualSnaphot.transform = CGAffineTransformMakeScale(transform, transform);
        actualSnaphot.frame = CGRectMake(0, 0, actualSnaphot.frame.size.width, actualSnaphot.frame.size.height);
    
        self.snapshotView.center = CGPointMake(self.frame.size.width/2, self.snapshotView.center.y);
    
        self.iconView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height - iconHeight);
    } else {
        // When running in icon only mode, the flow layout handles the size we need to be. So... Just go to bounds.
        self.iconView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
}

-(void)prepareForReuse {
    [super prepareForReuse];
    
    /*UIView *actualSnaphot = self.snapshotView.subviews.firstObject;
    [actualSnaphot removeFromSuperview];
    
    [self.snapshotView removeFromSuperview];
    self.snapshotView = nil;
    
    [self.iconView removeFromSuperview];
    self.iconView = nil;*/
}

-(void)dealloc {
    [self.snapshotView removeFromSuperview];
    self.snapshotView = nil;
    
    [self.iconView removeFromSuperview];
    self.iconView = nil;
}

@end
