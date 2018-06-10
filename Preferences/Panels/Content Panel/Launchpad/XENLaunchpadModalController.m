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

#import "XENLaunchpadModalController.h"
#import "XENPLaunchpadController.h"
#import "XENPResources.h"

enum {
    ALApplicationIconSizeSmall = 29,
    ALApplicationIconSizeLarge = 59
};
typedef NSUInteger ALApplicationIconSize;

@interface ALApplicationList : NSObject {
@private
    NSMutableDictionary *cachedIcons;
}

+ (ALApplicationList *)sharedApplicationList;

@property (nonatomic, readonly) NSDictionary *applications;
- (NSDictionary *)applicationsFilteredUsingPredicate:(NSPredicate *)predicate;
- (id)valueForKeyPath:(NSString *)keyPath forDisplayIdentifier:(NSString *)displayIdentifier;
- (id)valueForKey:(NSString *)keyPath forDisplayIdentifier:(NSString *)displayIdentifier;
- (CGImageRef)copyIconOfSize:(ALApplicationIconSize)iconSize forDisplayIdentifier:(NSString *)displayIdentifier;
- (UIImage *)iconOfSize:(ALApplicationIconSize)iconSize forDisplayIdentifier:(NSString *)displayIdentifier;
- (BOOL)hasCachedIconOfSize:(ALApplicationIconSize)iconSize forDisplayIdentifier:(NSString *)displayIdentifier;

@end

@interface XENLaunchpadModalController ()

@end

static NSInteger DictionaryTextComparator(id a, id b, void *context)
{
    return [[(__bridge NSDictionary *)context objectForKey:a] localizedCaseInsensitiveCompare:[(__bridge NSDictionary *)context objectForKey:b]];
}

@implementation XENLaunchpadModalController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isSystemApplication = TRUE"];
    self.dataSourceSystem = (OrderedDictionary*)[[ALApplicationList sharedApplicationList] applicationsFilteredUsingPredicate:pred];
    self.dataSourceSystem = (OrderedDictionary*)[self trimDataSource:self.dataSourceSystem];
    self.dataSourceSystem = [self sortedDictionary:self.dataSourceSystem];
    
    NSLog(@"*** System keys:\n%@", self.dataSourceSystem);
    
    NSPredicate *predi = [NSPredicate predicateWithFormat:@"isSystemApplication = FALSE"];
    self.dataSourceUser = (OrderedDictionary*)[[ALApplicationList sharedApplicationList] applicationsFilteredUsingPredicate:predi];
    self.dataSourceUser = (OrderedDictionary*)[self trimDataSource:self.dataSourceUser];
    self.dataSourceUser = [self sortedDictionary:self.dataSourceUser];
    
    // Table view.
    _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _table.rowHeight = 50;
    _table.allowsMultipleSelection = NO;
    _table.allowsSelection = YES;
    _table.dataSource = self;
    _table.delegate = self;
    
    [_table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tablecell"];
    
    [self.view addSubview:_table];
    
    // That's all folks.
    [_table reloadData];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Cancel button.
    if ([self respondsToSelector:@selector(navigationItem)]) {
        [[self navigationItem] setTitle:[XENPResources localisedStringForKey:@"Applications" value:@"Applications"]];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:[XENPResources localisedStringForKey:@"Cancel" value:@"Cancel"] style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
        [[self navigationItem] setLeftBarButtonItem:cancel];
    }
}

-(void)viewDidLayoutSubviews {
    _table.frame = self.view.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)cancel:(id)sender {
    // Just hide our modal controller.
    [[XENPLaunchpadController sharedInstance].navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.dataSourceSystem count];
    else
        return [self.dataSourceUser count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Initialise cells.
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"tablecell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"tablecell"];
    
    NSString *indentifier;
    NSString *displayName;
    if (indexPath.section == 0) {
        // Get data from system data source
        indentifier = [self.dataSourceSystem keyAtIndex:indexPath.row];
        displayName = [self.dataSourceSystem objectForKey:indentifier];
        
        cell.imageView.image = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:indentifier];
        cell.textLabel.text = displayName;
    } else {
        // Get data from user data source
        indentifier = [self.dataSourceUser keyAtIndex:indexPath.row];
        displayName = [self.dataSourceUser objectForKey:indentifier];
        
        cell.imageView.image = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:indentifier];
        cell.textLabel.text = displayName;
    }
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return [XENPResources localisedStringForKey:@"System" value:@"System"];
    else
        return [XENPResources localisedStringForKey:@"User" value:@"User"];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *indentifier;
    if (indexPath.section == 0) {
        // In system data source
        NSLog(@"System");
        NSArray *keys = [self.dataSourceSystem allKeys];
        indentifier = [keys objectAtIndex:indexPath.row];
    } else {
        // In user data source
        NSLog(@"User");
        NSArray *keys = [self.dataSourceUser allKeys];
        indentifier = [keys objectAtIndex:indexPath.row];
    }
    
    NSLog(@"Identifier == %@", indentifier);
    
    // Save into plist.
    NSMutableArray *array = [[XENPResources getPreferenceKey:@"launchpadIdentifiers"] mutableCopy];
    if (!array)
        array = [@[@"com.apple.MobileSMS", @"com.apple.Preferences", @"com.apple.calculator", @"com.apple.camera", @"com.apple.Maps"] mutableCopy];
    
    [array addObject:indentifier];
    
    [XENPResources setPreferenceKey:@"launchpadIdentifiers" withValue:array];
    
    // Reload collection view.
    [self.delegate refreshCollectionView];
    
    [self cancel:nil];
}

-(NSDictionary*)trimDataSource:(NSDictionary*)dataSource {
    NSMutableDictionary *mutable = [dataSource mutableCopy];
    
    NSArray *bannedIdentifiers = [[NSArray alloc] initWithObjects:
                                  @"com.apple.AdSheet",
                                  @"com.apple.AdSheetPhone",
                                  @"com.apple.AdSheetPad",
                                  @"com.apple.DataActivation",
                                  @"com.apple.DemoApp",
                                  @"com.apple.fieldtest",
                                  @"com.apple.iosdiagnostics",
                                  @"com.apple.iphoneos.iPodOut",
                                  @"com.apple.TrustMe",
                                  @"com.apple.WebSheet",
                                  @"com.apple.springboard",
                                  @"com.apple.purplebuddy",
                                  @"com.apple.datadetectors.DDActionsService",
                                  @"com.apple.FacebookAccountMigrationDialog",
                                  @"com.apple.iad.iAdOptOut",
                                  @"com.apple.ios.StoreKitUIService",
                                  @"com.apple.TextInput.kbd",
                                  @"com.apple.MailCompositionService",
                                  @"com.apple.mobilesms.compose",
                                  @"com.apple.quicklook.quicklookd",
                                  @"com.apple.ShoeboxUIService",
                                  @"com.apple.social.remoteui.SocialUIService",
                                  @"com.apple.WebViewService",
                                  @"com.apple.gamecenter.GameCenterUIService",
                                  @"com.apple.appleaccount.AACredentialRecoveryDialog",
                                  @"com.apple.CompassCalibrationViewService",
                                  @"com.apple.WebContentFilter.remoteUI.WebContentAnalysisUI",
                                  @"com.apple.PassbookUIService",
                                  @"com.apple.uikit.PrintStatus",
                                  @"com.apple.Copilot",
                                  @"com.apple.MusicUIService",
                                  @"com.apple.AccountAuthenticationDialog",
                                  @"com.apple.MobileReplayer",
                                  @"com.apple.SiriViewService",
                                  @"com.apple.TencentWeiboAccountMigrationDialog",
                                  @"com.apple.AskPermissionUI",
                                  @"com.apple.Diagnostics",
                                  @"com.apple.GameController",
                                  @"com.apple.HealthPrivacyService",
                                  @"com.apple.InCallService",
                                  @"com.apple.mobilesms.notification",
                                  @"com.apple.PhotosViewService",
                                  @"com.apple.PreBoard",
                                  @"com.apple.PrintKit.Print-Center",
                                  @"com.apple.SharedWebCredentialViewService",
                                  @"com.apple.share",
                                  @"com.apple.CoreAuthUI",
                                  @"com.apple.webapp",
                                  @"com.apple.webapp1",
                                  @"com.apple.family",
                                  @"com.apple.social.SLGoogleAuth",
                                  @"com.apple.appleseed.FeedbackAssistant",
                                  @"com.apple.CloudKit.ShareBear",
                                  @"com.apple.Diagnostics.Mitosis",
                                  @"com.apple.Home.HomeUIService",
                                  @"com.apple.iCloudDriveApp",
                                  @"com.apple.SafariViewService",
                                  @"com.apple.ServerDocuments",
                                  @"com.apple.social.SLYahooAuth",
                                  @"com.apple.StoreDemoViewService",
                                  nil];
    
    for (NSString *key in bannedIdentifiers) {
        [mutable removeObjectForKey:key];
    }
    
    // Load up identifiers already set.
    NSMutableArray *array = [[XENPResources getPreferenceKey:@"launchpadIdentifiers"] mutableCopy];
    if (!array)
        array = [@[@"com.apple.MobileSMS", @"com.apple.Preferences", @"com.apple.calculator", @"com.apple.camera", @"com.apple.Maps"] mutableCopy];
    
    for (NSString *key in array)
        [mutable removeObjectForKey:key];
    
    return mutable;
}

-(OrderedDictionary*)sortedDictionary:(OrderedDictionary*)dict {
    NSArray *sortedValues;
    OrderedDictionary *mutable = [OrderedDictionary dictionary];
    
    sortedValues = [[dict allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (NSString *value in sortedValues) {
        // Get key for value.
        NSString *key = [[dict allKeysForObject:value] objectAtIndex:0];
        
        [mutable setObject:value forKey:key];
    }
    
    return mutable;
}

@end
