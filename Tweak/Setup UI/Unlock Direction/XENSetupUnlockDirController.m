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

#import "XENSetupUnlockDirController.h"
#import "XENSNotifStylingController.h"
#import "XENSetupWindow.h"

@interface XENSetupUnlockDirController ()

@end

@implementation XENSetupUnlockDirController

-(NSArray*)switchViewItems {
    NSMutableArray *items = [@[@{@"label":@"Left", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Left%@", [XENResources imageSuffix]]},
                              @{@"label":@"Upwards", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Upwards%@", [XENResources imageSuffix]]},
                              @{@"label":@"Right", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Right%@", [XENResources imageSuffix]]}
                              ] mutableCopy];
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10) {
        [items addObject:@{@"label":@"Home", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/UnlockSwitch/Home%@", [XENResources imageSuffix]]}];
    }
    
    return items;
}

-(NSString*)preferencesKey {
    return @"slideToUnlockModeDirection";
}

-(int)defaultValue {
    return [XENResources slideToUnlockModeDirection];
}

// Base stuff
-(NSString*)headerTitle {
    return [XENResources localisedStringForKey:@"Unlock Mode" value:@"Unlock Mode"];
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/Unlock%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What is this?" value:@"What is this?"];
}

-(NSString*)footerBody {
    return [XENResources localisedStringForKey:@"The Unlock Mode controls the interaction used to unlock your device." value:@"The Unlock Mode controls the interaction used to unlock your device."];
}

-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return [[XENSNotifStylingController alloc] initWithStyle:UITableViewStyleGrouped];
}

@end
