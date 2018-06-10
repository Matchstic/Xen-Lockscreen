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

#import "XENPUnlockSwitchCell.h"
#import "XENPResources.h"

@implementation XENPUnlockSwitchCell

- (instancetype)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        
        NSMutableArray *items = [@[@{@"label":@"Left", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Left%@", [XENPResources imageSuffix]]},
                                   @{@"label":@"Upwards", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Upwards%@", [XENPResources imageSuffix]]},
                                   @{@"label":@"Right", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Right%@", [XENPResources imageSuffix]]}
                                   ] mutableCopy];
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
            [items addObject:@{@"label":@"Home", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Home%@", [XENPResources imageSuffix]]}];
        }
        
        int defaultVal = [UIDevice currentDevice].systemVersion.floatValue < 10.0 ? 0 : 3;
        
        _switchView = [[XENPMultipleSwitchView alloc] initWithItems:items andSpecifierKey:@"slideToUnlockModeDirection"];
        [_switchView didSelectNode:([XENPResources getPreferenceKey:@"slideToUnlockModeDirection"] ? [[XENPResources getPreferenceKey:@"slideToUnlockModeDirection"] intValue] : defaultVal)];
        _switchView.delegate = self;
        
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

-(void)didSelectNode:(int)node {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        // TODO: Notify of Accessibility "change".
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kAXSRestingHomeButtonUnlockEnabledNotification" object:nil];
    }
}

@end
