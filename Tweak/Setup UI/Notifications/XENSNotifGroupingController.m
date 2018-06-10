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

#import "XENSNotifGroupingController.h"
#import "XENSMediaController.h"
#import "XENSContentPagesController.h"
#import "XENSetupWindow.h"

@interface XENSNotifGroupingController ()

@end

@implementation XENSNotifGroupingController

-(NSArray*)switchViewItems {
    BOOL stylishUI = [XENResources useXENNotificationUI];
    
    NSString *uiPath = @"";
    if (!stylishUI) {
        uiPath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/NotificationSwitch/Default_Notif%@", [XENResources imageSuffix]];
    } else {
        uiPath = [NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/NotificationSwitch/Bubble_Notif%@", [XENResources imageSuffix]];
    }
    
    NSArray *items = @[@{@"label":@"List", @"imagePath":uiPath},
                       @{@"label":@"Grouped", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/NotificationSwitch/Grouped_Notif%@", [XENResources imageSuffix]]}
                       
                       ];
    
    return items;
}

-(NSString*)preferencesKey {
    return @"useGroupedNotifications";
}

-(int)defaultValue {
    return [XENResources useGroupedNotifications];
}

// Base stuff
-(NSString*)headerTitle {
    return [XENResources localisedStringForKey:@"Notification Grouping" value:@"Notification Grouping"];
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/Grouped%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What does Grouped do?" value:@"What does Grouped do?"];
}

-(NSString*)footerBody {
    NSMutableString *normal = [[XENResources localisedStringForKey:@"Grouped sorts messages by their corresponding app, rather than displaying all in one list." value:@"Grouped sorts messages by their corresponding app, rather than displaying all in one list."] mutableCopy];
    
    // If Priority Hub is installed AND enabled, need to warn user that our grouping will take precendence.
    if ([XENResources isPriorityHubInstalledAndEnabled]) {
        NSString *appended = [XENResources localisedStringForKey:@"\n\nXen Lockscreen's Notification Grouping will override Priority Hub." value:@"\n\nXen Lockscreen's Notification Grouping will override Priority Hub."];
        
        [normal appendString:appended];
    }
    
    return normal;
}

-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    if ([XENSetupWindow sharedInstance].usingQuickSetup) {
        return [[XENSContentPagesController alloc] initWithStyle:UITableViewStyleGrouped];
    } else {
        return [[XENSMediaController alloc] initWithStyle:UITableViewStyleGrouped];
    }
}

-(void)userDidTapNextButton {
    // Set Priority Hub's settings too if appropriate.
    if ([XENResources isPriorityHubInstalledAndEnabled]) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
        [defaults setBool:NO forKey:@"enabled"];
    }
}

@end
