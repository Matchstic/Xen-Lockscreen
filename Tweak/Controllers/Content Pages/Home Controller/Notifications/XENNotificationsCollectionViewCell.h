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

#import <UIKit/UIKit.h>
#import "XENLegibilityLabel.h"

@interface XENNotificationsCollectionViewCell : UICollectionViewCell {
    UIView *_baseView;
    int _columnForCell;
}

@property (nonatomic, retain) XENLegibilityLabel *count;
@property (nonatomic, retain) SBIconImageView *icon;
@property (nonatomic, strong) NSString *bundleId;
@property (readwrite) int currentValue;

+(UIImage*)circularImage:(UIImage*)img inRect:(CGRect)rect;
+(UIImage *)image:(UIImage*)img WithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur;

-(void)setupWithBundleIdentifier:(NSString*)bulletin;
-(void)setNotificationCount:(int)count;
-(void)setNotificationCount:(int)count animate:(BOOL)animate;
-(void)setCellColumn:(int)column;
-(void)setNewNotificationGlow:(BOOL)isOn;

@end
