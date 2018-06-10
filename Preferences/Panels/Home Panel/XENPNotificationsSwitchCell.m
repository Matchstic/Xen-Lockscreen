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

#import "XENPNotificationsSwitchCell.h"
#import "XENPResources.h"

@implementation XENPNotificationsSwitchCell

- (instancetype)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        NSArray *items = @[@{@"label":@"Stock", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/NotificationSwitch/Default_Notif%@", [XENPResources imageSuffix]]},
                           @{@"label":@"Bubble", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/NotificationSwitch/Bubble_Notif%@", [XENPResources imageSuffix]]}
                           
                           ];
        _switchView = [[XENPMultipleSwitchView alloc] initWithItems:items andSpecifierKey:@"useXENNotificationUI"];
        [_switchView didSelectNode:([XENPResources getPreferenceKey:@"useXENNotificationUI"] ? [[XENPResources getPreferenceKey:@"useXENNotificationUI"] intValue] : 1)];
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
            [_switchView setEnabled:NO];
        }
        
        [self.contentView addSubview:_switchView];
    }
    
    return self;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    // Return a custom cell height.
    return 180.f;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    _switchView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, 180.f);
}

@end
