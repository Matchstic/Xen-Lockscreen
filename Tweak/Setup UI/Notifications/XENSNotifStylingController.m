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

#import "XENSNotifStylingController.h"
#import "XENSetupWindow.h"
#import "XENSNotifGroupingController.h"

@interface XENSNotifStylingController ()

@end

@implementation XENSNotifStylingController

-(NSArray*)switchViewItems {
    return @[@{@"label":@"Stock", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/NotificationSwitch/Default_Notif%@", [XENResources imageSuffix]]},
             @{@"label":@"Custom", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/NotificationSwitch/Bubble_Notif%@", [XENResources imageSuffix]]}
             
             ];
}

-(NSString*)preferencesKey {
    return @"useXENNotificationUI";
}

-(int)defaultValue {
    return [XENResources useXENNotificationUI];
}

// Base stuff
-(NSString*)headerTitle {
    return [XENResources localisedStringForKey:@"Notification Styling" value:@"Notification Styling"];
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/NotifStyle%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What's the difference?" value:@"What's the difference?"];
}

-(NSString*)footerBody {
    return [XENResources localisedStringForKey:@"Custom styling renders notification text on a blurred area, rather than a darkened blur over the entire background." value:@"Custom styling renders notification text on a blurred area, rather than a darkened blur over the entire background."];
}

-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return [[XENSNotifGroupingController alloc] initWithStyle:UITableViewStyleGrouped];
}

@end
