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

#import "XENSMediaController.h"
#import "XENSContentPagesController.h"
#import "XENSetupWindow.h"

@interface XENSMediaController ()

@end

@implementation XENSMediaController

-(NSArray*)switchViewItems {
    return @[@{@"label":@"None", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/MediaSwitch/None%@", [XENResources imageSuffix]]},
             @{@"label":@"Square", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/MediaSwitch/Square%@", [XENResources imageSuffix]]},
             @{@"label":@"Fullscreen", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/MediaSwitch/Fullscreen%@", [XENResources imageSuffix]]},
             @{@"label":@"Combined", @"imagePath":[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/MediaSwitch/Combined%@", [XENResources imageSuffix]]}
             ];
}

-(NSString*)preferencesKey {
    return @"mediaStyle";
}

-(int)defaultValue {
    return [XENResources mediaArtworkStyle];
}

// Base stuff
-(NSString*)headerTitle {
    return [XENResources localisedStringForKey:@"Music Artwork" value:@"Music Artwork"];
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/Music%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What's the difference?" value:@"What's the difference?"];
}

-(NSString*)footerBody {
    return [XENResources localisedStringForKey:@"Fullscreen Music Artwork will display the current track's artwork as your wallpaper." value:@"Fullscreen Music Artwork will display the current track's artwork as your wallpaper."];
}

-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return [[XENSContentPagesController alloc] initWithStyle:UITableViewStyleGrouped];
}

/*-(void)userDidSelectCellAtIndex:(NSInteger)index {
    // DEBUG ONLY.
    [XENSetupWindow finishSetupMode];
}*/

@end
