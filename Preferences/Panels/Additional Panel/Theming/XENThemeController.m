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

#import "XENThemeController.h"
#import "XENPResources.h"

#define cellIdentifier @"XENThemeCell"

@interface XENPThemeController ()
@end

@implementation XENPThemeController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self buildCurrentSpecifiers];
        
        NSMutableArray *legacy = [self buildLegacySpecifiers];
        
        if (legacy.count > 0) {
            // Drop in a header to modern, and combine.
            PSSpecifier* groupSpecifier = [PSSpecifier groupSpecifierWithName:[XENPResources localisedStringForKey:@"Modern" value:@"Modern"]];
            [testingSpecs insertObject:groupSpecifier atIndex:0];
            
            [testingSpecs addObjectsFromArray:legacy];
        }
        
        // Finished messing with specifiers
        _specifiers = testingSpecs;
    }
    
    return _specifiers;
}

-(NSMutableArray*)buildCurrentSpecifiers {
    _modern = [NSMutableArray array];
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSString *string in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Application Support/Xen/Themes" error:nil]) {
        PSSpecifier *spe = [self specifierForThemeAtFilePath:[NSString stringWithFormat:@"/Library/Application Support/Xen/Themes/%@", string]];
        
        [array addObject:spe];
        
        [_modern addObject:[NSString stringWithFormat:@"/Library/Application Support/Xen/Themes/%@", string]];
    }
    
    return array;
}

-(NSMutableArray*)buildLegacySpecifiers {
    _legacy = [NSMutableArray array];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/Convergance/Themes" isDirectory:nil]) {
        // Build specifiers.
        NSMutableArray *array = [NSMutableArray array];
        
        PSSpecifier* groupSpecifier = [PSSpecifier groupSpecifierWithName:[XENPResources localisedStringForKey:@"Legacy" value:@"Legacy"]];
        [array addObject:groupSpecifier];
        
        for (NSString *string in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Application Support/Convergance/Themes" error:nil]) {
            PSSpecifier *spe = [self specifierForThemeAtFilePath:[NSString stringWithFormat:@"/Library/Application Support/Convergance/Themes/%@", string]];
            
            [array addObject:spe];
            
            [_legacy addObject:[NSString stringWithFormat:@"/Library/Application Support/Convergance/Themes/%@", string]];
        }
        
        return array;
    } else {
        return [NSMutableArray array];
    }
}

-(PSSpecifier*)specifierForThemeAtFilePath:(NSString*)filePath {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist", filePath]];
    
    PSSpecifier *spe = [PSSpecifier preferenceSpecifierNamed:dict[@"name"] target:self set:nil get:nil detail:nil cell:PSLinkCell edit:nil];
    [spe setProperty:[NSNumber numberWithBool:YES] forKey:@"enabled"];
    
    return spe;
}

-(void)viewWillAppear:(BOOL)view {
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENPResources localisedStringForKey:@"Theming" value:@"Theming"]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Table view shit.

-(CGFloat)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.contentView.alpha = 1.0;
    cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = YES;
    cell.imageView.alpha = 1.0;
    
    NSString *imageName = @"";
    NSString *title = @"TITLE";
    NSString *subtitle = @"SUBTITLE";
    
    NSString *filePath = @"";
    switch (indexPath.section) {
        case 0:
            filePath = [_modern objectAtIndex:indexPath.row];
            break;
        case 1:
        default:
            filePath = [_legacy objectAtIndex:indexPath.row];
            break;
    }
    
    // Setup icon, and subtitle.
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Info.plist", filePath]];
    title = dict[@"name"];
    subtitle = dict[@"author"];
    imageName = [NSString stringWithFormat:@"%@/%@%@", filePath, dict[@"thumbnailImage"], [XENPResources imageSuffix]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:imageName]) {
        // Fallback to @2x.
        imageName = [NSString stringWithFormat:@"%@/%@@2x.png", filePath, dict[@"thumbnailImage"]];
    }
    
    NSString *currentTheme = ([XENPResources getPreferenceKey:@"lockTheme"] ? [XENPResources getPreferenceKey:@"lockTheme"] : @"BLUR");
    
    UIImage *cellImage = [UIImage imageWithContentsOfFile:imageName];
    cell.imageView.image = cellImage;
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = subtitle;
    cell.detailTextLabel.numberOfLines = 2;
    
    // If selected, give the disclosure indicator, else none.
    if ([currentTheme isEqualToString:[filePath lastPathComponent]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Set the current cell to selected, and update preferences.
    NSString *newTheme = @"";
    switch (indexPath.section) {
        case 0: {
            NSString *filePath = [_modern objectAtIndex:indexPath.row];
            newTheme = [filePath lastPathComponent];
            [XENPResources setPreferenceKey:@"themeIsLegacy" withValue:[NSNumber numberWithBool:NO]];
            break;
        }
        case 1:
        default: {
            NSString *filePath = [_legacy objectAtIndex:indexPath.row];
            newTheme = [filePath lastPathComponent];
            [XENPResources setPreferenceKey:@"themeIsLegacy" withValue:[NSNumber numberWithBool:YES]];
            break;
        }
    }
    
    [XENPResources setPreferenceKey:@"lockTheme" withValue:newTheme];
    
    for (UITableViewCell *cell2 in self.table.visibleCells) {
        cell2.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

@end
