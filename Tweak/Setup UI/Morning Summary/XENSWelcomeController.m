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

#import "XENSWelcomeController.h"
#import "XENSetupFinalController.h"

@interface XENSWelcomeController ()

@end

@implementation XENSWelcomeController

-(NSString*)headerTitle {
    return [XENResources localisedStringForKey:@"Morning Summary" value:@"Morning Summary"];
}

-(NSString*)cellReuseIdentifier {
    return @"setupCell";
}

-(NSInteger)rowsToDisplay {
    return 2;
}

-(UIImage*)footerImage {
    UIImage *img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Xen/Setup/Morning%@", [XENResources imageSuffix]]];
    
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(NSString*)footerTitle {
    return [XENResources localisedStringForKey:@"What is Morning Summary?" value:@"What is Morning Summary?"];
}

-(NSString*)footerBody {
    return [XENResources localisedStringForKey:@"Morning Summary shows you details of the day ahead after waking up." value:@"Morning Summary shows you details of the day ahead after waking up."];
}

-(NSString*)titleForCellAtIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return [XENResources localisedStringForKey:@"Enable Morning Summary" value:@"Enable Morning Summary"];
            break;
        case 1:
            return [XENResources localisedStringForKey:@"Disable Morning Summary" value:@"Disable Morning Summary"];
            break;
            
        default:
            return @"";
            break;
    }
}

-(void)userDidSelectCellAtIndex:(NSInteger)index {
    // Setup as appropriate.
    BOOL val = (index == 0 ? YES : NO);
    
    [XENResources setPreferenceKey:@"welcomeController" withValue:[NSNumber numberWithBool:val] andPost:YES];
}

// This will either be the user selected cell, or whatever is currently checkmarked.
-(UIViewController*)controllerToSegueForIndex:(NSInteger)index {
    return [[XENSetupFinalController alloc] init];
}

-(BOOL)shouldSegueToNewControllerAfterSelectingCell {
    return YES;
}

@end
