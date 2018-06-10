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

#import "XENSPeekController.h"
#import "XENSWelcomeController.h"

@interface XENSPeekController ()

@end

@implementation XENSPeekController

-(NSString*)headerTitle {
    return [XENResources localisedStringForKey:@"Peek" value:@"Peek"];
}

-(NSString*)cellReuseIdentifier {
    return @"setupCell";
}

-(NSInteger)rowsToDisplay {
    return 2;
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/Peek%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What is Peek?" value:@"What is Peek?"];
}

-(NSString*)footerBody {
    return [XENResources localisedStringForKey:@"Peek allows you to check the lockscreen by raising your phone to wake it." value:@"Peek allows you to check the lockscreen by raising your phone to wake it."];
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return [XENResources localisedStringForKey:@"Enable Peek" value:@"Enable Peek"];
            break;
        case 1:
            return [XENResources localisedStringForKey:@"Disable Peek" value:@"Disable Peek"];
            break;
            
        default:
            return @"";
            break;
    }
}

-(void)userDidSelectCellAtIndex:(NSInteger)index {
    // Setup as appropriate.
    BOOL val = (index == 0 ? YES : NO);
    
    [XENResources setPreferenceKey:@"peekEnabled" withValue:[NSNumber numberWithBool:val] andPost:YES];
}

// This will either be the user selected cell, or whatever is currently checkmarked.
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return [[XENSWelcomeController alloc] initWithStyle:UITableViewStyleGrouped];
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    return YES;
}

@end
