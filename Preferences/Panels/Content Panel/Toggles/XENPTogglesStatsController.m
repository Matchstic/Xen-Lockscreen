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

#import "XENPTogglesStatsController.h"
#import "XENPResources.h"

#define cellIdentifier @"com.matchstic.statscell"

@interface XENPTogglesStatsController ()

@end

@implementation XENPTogglesStatsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)view {
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENPResources localisedStringForKey:@"Statistics" value:@"Statistics"]];
    }
}

-(void)viewWillLayoutSubviews {
    self.tableView.frame = self.view.frame;
}

-(void)loadView {
    // Load up our data sources.
    _enabledStats = [[XENPResources getPreferenceKey:@"togglesStatsPanels"] mutableCopy];
    if (!_enabledStats) {
        _enabledStats = [@[@"kCPU", @"kRAM", @"kStorage", @"kUpload", @"kDownload"] mutableCopy];
    }
    
    _disabledStats = [[XENPResources getPreferenceKey:@"disabledTogglesStatsPanels"] mutableCopy];
    if (!_disabledStats) {
        _disabledStats = [NSMutableArray array];
    }
    
    [super loadView];
    
    // Setup our tableview.
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = YES;
    
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    [self.tableView reloadData];
}

-(NSString*)titleForItem:(NSString*)string {
    if ([string isEqualToString:@"kCPU"]) {
        return [XENPResources localisedStringForKey:@"CPU Activity" value:@"CPU Activity"];
    } else if ([string isEqualToString:@"kRAM"]) {
        return [XENPResources localisedStringForKey:@"RAM Free" value:@"RAM Free"];
    } else if ([string isEqualToString:@"kStorage"]) {
        return [XENPResources localisedStringForKey:@"Storage Available" value:@"Storage Available"];
    } else if ([string isEqualToString:@"kUpload"]) {
        return [XENPResources localisedStringForKey:@"Upload Speed" value:@"Upload Speed"];
    } else if ([string isEqualToString:@"kDownload"]) {
        return [XENPResources localisedStringForKey:@"Download Speed" value:@"Download Speed"];
    } else {
        return [XENPResources localisedStringForKey:@"None" value:@"None"];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    int result = 0;
    
    switch (section) {
        case 0:
            result = (int)_enabledStats.count;
            break;
        case 1:
        default:
            result = (int)_disabledStats.count;
            break;
    }
    
    if (result == 0) result = 1;
    
    return result;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellAccessoryNone;
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // Configure the cell...
    NSString *image;
    NSString *item;
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0 && _enabledStats.count == 0)
                item = @"none";
            else
                item = [_enabledStats objectAtIndex:indexPath.row];
            break;
            
        case 1:
            if (indexPath.row == 0 && _disabledStats.count == 0)
                item = @"none";
            else
                item = [_disabledStats objectAtIndex:indexPath.row];
        default:
            break;
    }
    
    cell.textLabel.text = [self titleForItem:item];
    
    image = [NSString stringWithFormat:@"/Library/Application Support/Xen/Themes/BLUR/Toggles/%@@2x.png", item];
    cell.imageView.image = [UIImage imageWithContentsOfFile:image];
    
    if ([item isEqualToString:@"none"]) {
        cell.textLabel.enabled = NO;
    } else {
        cell.textLabel.enabled = YES;
    }
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *result = @"";
    switch (section) {
        case 0:
            result = [XENPResources localisedStringForKey:@"Enabled" value:@"Enabled"];
            break;
        case 1:
        default:
            result = [XENPResources localisedStringForKey:@"Disabled" value:@"Disabled"];
            break;
    }
    return result;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    // Save out as appropriate.
    NSMutableArray *fromArray = (fromIndexPath.section == 0 ? _enabledStats : _disabledStats);
    NSMutableArray *toArray = (toIndexPath.section == 0 ? _enabledStats : _disabledStats);
    NSString *item = [fromArray objectAtIndex:fromIndexPath.row];
    
    // TODO: Handle index for if 'none' is displayed!
    int index = (int)toIndexPath.row;
    if (toArray.count == 0) {
        index = 0;
    }
    
    [fromArray removeObject:item];
    [toArray insertObject:item atIndex:index];
    
    if (toArray.count == 1 || fromArray.count == 0) {
        // Remove/hide 'none' row?
        [tableView reloadData];
    }
    
    [XENPResources setPreferenceKey:@"togglesStatsPanels" withValue:_enabledStats];
    [XENPResources setPreferenceKey:@"disabledTogglesStatsPanels" withValue:_disabledStats];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    int count = (int)(indexPath.section == 0 ? _enabledStats.count : _disabledStats.count);
    
    // Handle 'none'
    if (indexPath.row == 0 && count == 0) {
        return NO;
    }
    
    return YES;
}

@end
