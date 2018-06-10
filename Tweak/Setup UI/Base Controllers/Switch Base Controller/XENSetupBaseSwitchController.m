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

#import "XENSetupBaseSwitchController.h"
#import "XENSetupSwitchTableCell.h"

@interface XENSetupBaseSwitchController ()

@end

@implementation XENSetupBaseSwitchController

#pragma mark Inheritable overrides


-(NSArray*)switchViewItems {
    return [NSArray array];
}

-(NSString*)cellReuseIdentifier {
    return @"switchSetupCell";
}

-(BOOL)shouldDisplayNextButton {
    return YES;
}

-(NSString*)preferencesKey {
    return @"";
}

-(int)defaultValue {
    return 0;
}

#pragma mark Main stuff

-(instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _currentlyCheckmarkedCell = 0;
        
        [self.tableView registerClass:[XENSetupSwitchTableCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
    }
    
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [[self navigationItem].rightBarButtonItem setEnabled:YES];
}

-(NSInteger)rowsToDisplay {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 200.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XENSetupSwitchTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellReuseIdentifier] forIndexPath:indexPath];
    if (!cell) {
        cell = [[XENSetupSwitchTableCell alloc] initWithStyle:tableView.style reuseIdentifier:[self cellReuseIdentifier]];
    }
    
    [cell setupWithItems:[self switchViewItems] preferencesKey:[self preferencesKey] andDefaultValue:[self defaultValue]];
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
