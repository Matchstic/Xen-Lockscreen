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

#import "XENSetupImportController.h"
#import "XENSetupWindow.h"
#import "XENSetupUnlockDirController.h"
#import "XENSNotifGroupingController.h"

@interface XENSetupImportController ()

@end

@implementation XENSetupImportController

-(NSString*)headerTitle {
    return @"Initial Setup";
}

-(NSString*)cellReuseIdentifier {
    return @"setupCell";
}

-(NSInteger)rowsToDisplay {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.matchstic.Convergance.plist"] ? 3 : 2;
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/Setup%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What does Quick Mode do?" value:@"What does Quick Mode do?"];
}

-(NSString*)footerBody {
    return [XENResources localisedStringForKey:@"Quick Mode applies settings similar to stock iOS, which can be changed later in the Settings app." value:@"Quick Mode applies settings similar to stock iOS, which can be changed later in the Settings app."];
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return [XENResources localisedStringForKey:@"Setup as New Install" value:@"Setup as New Install"];
            break;
        case 1:
            return [XENResources localisedStringForKey:@"Setup in Quick Mode" value:@"Setup in Quick Mode"];
            break;
        case 2:
            return [XENResources localisedStringForKey:@"Import from Convergance" value:@"Import from Convergance"];
            break;
            
        default:
            return @"";
            break;
    }
}

-(void)userDidSelectCellAtIndex:(NSInteger)index {
    // Setup as appropriate.
    
    switch (index) {
        case 0:
            // Full setup - can keep all current settings
            [XENResources setPreferenceKey:@"controllerIdentifiers" withValue:@[(IS_IPAD ? @"com.matchstic.toggles.ipad" : @"com.matchstic.toggles.iphone"), @"com.matchstic.home", @"com.matchstic.launchpad"] andPost:NO];
            [XENResources setPreferenceKey:@"shouldProvideCC" withValue:@NO andPost:NO];
            [XENResources setPreferenceKey:@"slideToUnlockModeDirection" withValue:@0 andPost:NO];
            [XENResources setPreferenceKey:@"useXENNotificationUI" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENResources setPreferenceKey:@"mediaStyle" withValue:[NSNumber numberWithInt:1] andPost:NO];
            [XENResources setPreferenceKey:@"hideSlideIndicators" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            [XENResources setPreferenceKey:@"useGroupedNotifications" withValue:[NSNumber numberWithBool:NO] andPost:YES];
            break;
            
        case 1:
            // Stock setup - configure notifications, media artwork and unlock direction automatically
            [XENSetupWindow sharedInstance].usingQuickSetup = YES;
            
            [XENResources setPreferenceKey:@"shouldProvideCC" withValue:@YES andPost:NO];
            [XENResources setPreferenceKey:@"slideToUnlockModeDirection" withValue:@0 andPost:NO];
            [XENResources setPreferenceKey:@"controllerIdentifiers" withValue:@[@"com.matchstic.home"] andPost:NO];
            [XENResources setPreferenceKey:@"useXENNotificationUI" withValue:[NSNumber numberWithBool:NO] andPost:NO];
            [XENResources setPreferenceKey:@"mediaStyle" withValue:[NSNumber numberWithInt:1] andPost:NO];
            [XENResources setPreferenceKey:@"hideSlideIndicators" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            [XENResources setPreferenceKey:@"useGroupedNotifications" withValue:[NSNumber numberWithBool:NO] andPost:YES];
            
            break;
            
        case 2: {
            // Convergance import - use old settings to populate new stuff.
            NSDictionary *convergance = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.matchstic.Convergance.plist"];
            
            // Go through settings we have, and apply based off Convergance's.
            
            [XENResources setPreferenceKey:@"controllerIdentifiers" withValue:@[(IS_IPAD ? @"com.matchstic.toggles.ipad" : @"com.matchstic.toggles.iphone"), @"com.matchstic.home", @"com.matchstic.launchpad"] andPost:NO];
            
            [XENResources setPreferenceKey:@"shouldProvideCC" withValue:@NO andPost:NO];
            
            [XENResources setPreferenceKey:@"slideToUnlockModeDirection" withValue:[NSNumber numberWithInt:1] andPost:NO];
            
            [XENResources setPreferenceKey:@"hideSlideIndicators" withValue:[NSNumber numberWithBool:([convergance objectForKey:@"hideSideGrabbers"] ? [[convergance objectForKey:@"hideSideGrabbers"] boolValue] : NO)] andPost:NO];
            
            [XENResources setPreferenceKey:@"hideClock" withValue:[NSNumber numberWithBool:([convergance objectForKey:@"showsClock"] ? ![[convergance objectForKey:@"showsClock"] boolValue] : NO)] andPost:NO];
            
            [XENResources setPreferenceKey:@"hideSlideIndicators" withValue:[NSNumber numberWithBool:([convergance objectForKey:@"hideSideGrabbers"] ? [[convergance objectForKey:@"hideSideGrabbers"] boolValue] : NO)] andPost:NO];
            
            int mediaStyle = ([convergance objectForKey:@"lockArtworkVariant"] ? [[convergance objectForKey:@"lockArtworkVariant"] intValue] : 1);
            if (mediaStyle == 0) {
                // Fullscreen
                mediaStyle = 2;
            } else if (mediaStyle == 1) {
                mediaStyle = 1;
            } else if (mediaStyle == 2) {
                mediaStyle = 1;
            } else {
                mediaStyle = 0;
            }
            
            [XENResources setPreferenceKey:@"mediaStyle" withValue:[NSNumber numberWithInt:mediaStyle] andPost:NO];
            
            [XENResources setPreferenceKey:@"launchpadRequiresPasscode" withValue:[NSNumber numberWithBool:([convergance objectForKey:@"launchpadSkipPasscode"] ? ![[convergance objectForKey:@"launchpadSkipPasscode"] boolValue] : NO)] andPost:NO];
            
            NSArray *defaultLaunchpad = @[@"com.apple.MobileSMS", @"com.apple.Preferences", @"com.apple.calculator", @"com.apple.camera", @"com.apple.Maps"];
            
            [XENResources setPreferenceKey:@"launchpadIdentifiers" withValue:([convergance objectForKey:@"launchpadAppNames"] ? [convergance objectForKey:@"launchpadAppNames"] : defaultLaunchpad) andPost:NO];
            
            [XENResources setPreferenceKey:@"launchpadIconSize" withValue:[NSNumber numberWithFloat:([convergance objectForKey:@"launchpadIconSize"] ? [[convergance objectForKey:@"launchpadIconSize"] floatValue] : 1.0)] andPost:NO];
            
            [XENResources setPreferenceKey:@"lockScreenIdleTime" withValue:[NSNumber numberWithDouble:([convergance objectForKey:@"lockscreenIdleTime"] ? [[convergance objectForKey:@"lockscreenIdleTime"] doubleValue] : 10.0)] andPost:NO];
            
            NSString *cvLockTheme = ([convergance objectForKey:@"lockTheme"] ? [convergance objectForKey:@"lockTheme"] : @"BLUR");
            if ([cvLockTheme isEqualToString:@"Default"]) {
                cvLockTheme = @"BLUR";
            }
            
            // Check if currently selected theme even exists still.
            
            NSString *xenThemeChecker = [NSString stringWithFormat:@"/Library/Application Support/Xen/Themes/%@/Info.plist", cvLockTheme];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:xenThemeChecker]) {
                cvLockTheme = @"BLUR";
            }
            
            [XENResources setPreferenceKey:@"useXENNotificationUI" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            [XENResources setPreferenceKey:@"useGroupedNotifications" withValue:[NSNumber numberWithBool:YES] andPost:NO];
            
            [XENResources setPreferenceKey:@"lockTheme" withValue:cvLockTheme andPost:YES];
            
            break;
        }
        default:
            break;
    }
    
    [XENResources reloadSettings];
}

// This will either be the user selected cell, or whatever is currently checkmarked.
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    switch (index) {
        case 0:
        case 2:
            // Full setup (Convergance populates defaults) - go to unlock direction
            return [[XENSetupUnlockDirController alloc] initWithStyle:UITableViewStyleGrouped];
            break;
            
        case 1:
            // Stock setup - go to notifications styling
            return [[XENSNotifGroupingController alloc] initWithStyle:UITableViewStyleGrouped];
            break;
            
        default:
            break;
    }
    
    return nil;
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    return YES;
}


@end
