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

#import "XENLaunchpadHeaderViewController.h"

@interface XENLaunchpadHeaderViewController ()

@end

@implementation XENLaunchpadHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.gridViewController viewDidLoad];
    [self.gridViewController _updateItemSize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)viewHeight {
    if (_contactCount == 0) {
        return _itemHeight;
    }
    
    CGFloat rows = ((CGFloat)_contactCount/(CGFloat)self.gridViewController.numberOfColumns);
    CGFloat height = ceilf(rows) * _itemHeight;
    
    return height;
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 1)];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 1337;
    
    // We will make use of Siri Suggestions' contacts block.
    
    // Favourite contacts are located at ~/Library/Preferences/com.apple.mobilephone.speeddial.plist
    // Is an array of dictionaries.
    // Each item goes to a CNFavoritesEntry, which can get a CNContact.
    // An array of these can then be passed to CNContactCustomDataSource.
    
    NSArray *entries = [[objc_getClass("CNFavorites") sharedInstance] entries];
    
    // Handle case where this array is empty.
    if (!entries || entries.count == 0) {
        self.noContactsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.noContactsLabel.text = [XENResources localisedStringForKey:@"No Favourite Contacts" value:@"No Favourite Contacts"];
        self.noContactsLabel.textColor = [UIColor whiteColor];
        self.noContactsLabel.textAlignment = NSTextAlignmentCenter;
        self.noContactsLabel.font = [UIFont systemFontOfSize:18];
        
        [self.view addSubview:self.noContactsLabel];
        
        _itemHeight = 60.0;
        
        self.view.frame = CGRectMake(0, 30, SCREEN_WIDTH, _itemHeight);
        self.noContactsLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH, _itemHeight);
        
        return;
    }
    
    // TODO: Handle a maximum number of speed dial items?
    
    NSMutableArray *contacts = [NSMutableArray array];
    CNContactStore *store = [[objc_getClass("CNContactStore") alloc] init];
    for (CNFavoritesEntry *entry in entries) {        
        CNContact *contact = entry.contactProperty.contact;
        
        // <CNContactFormatterSmartFetcher: 0x1628d57e0>
        // <CNAggregateKeyDescriptor: 0x1615789f0: kind=+[CNAvatarView descriptorForRequiredKeys]
        // <CNAggregateKeyDescriptor: 0x161595bf0: kind=+[CNQuickActionsManager descriptorForRequiredKeys]
        
        // NSArray *keys = @[@"namePrefix", @"iOSLegacyIdentifier", @"contactType", @"preferredForImage", @"emailAddresses", @"preferredForName", @"phoneNumbers", @"givenName", @"middleName", @"identifier", @"nameSuffix", @"linkIdentifier", @"familyName", @"thumbnailImageData"];
        
        // Init without keys specified to use all.
        
        // iOS 10 safe!
        CNContact *newContact = [store unifiedContactWithIdentifier:contact.identifier keysToFetch:@[@"namePrefix", @"iOSLegacyIdentifier", @"contactType", @"preferredForImage", @"emailAddresses", @"preferredFoName", @"phoneNumbers", @"givenName", @"middleName", @"identifier", @"nameSuffix", @"linkIdentifier", @"familyName", @"thumbnailImageData"] error:nil];
        
        // Note that if the contact does NOT have a valid phone number, we technically cannot use it.
        // Not overly sure why this is the case really.
        // Leads to an exception being thrown otherwise.
        
        if (newContact)
            [contacts addObject:newContact];
    }
    
    CNContactCustomDataSource *dataSource = [[objc_getClass("CNContactCustomDataSource") alloc] initWithContacts:contacts];
    
    CGFloat avatarSize = IS_IPAD ? 72 : 60;
    UIEdgeInsets avatarInsets = UIEdgeInsetsMake(9, 11, 3.5, 11);
    _itemHeight = avatarSize + avatarInsets.top + avatarInsets.bottom + (IS_IPAD ? 16.5 : 14.5); // for text.
    
    self.gridViewController = [[objc_getClass("CNContactGridViewController") alloc] initWithDataSource:dataSource];
    self.gridViewController.numberOfColumns = IS_IPAD ? 6 : 4;
    self.gridViewController.delegate = self;
    self.gridViewController.inlineActionsEnabled = YES;
    self.gridViewController.monogrammerStyle = 3;
    
    NSMutableDictionary *textAttributes = [NSMutableDictionary dictionary];
    [textAttributes setObject:[UIColor whiteColor] forKey:@"NSColor"];
    [textAttributes setObject:[UIFont systemFontOfSize:IS_IPAD ? 14 : 12] forKey:@"NSFont"];
    
    self.gridViewController.nameTextAttributes = textAttributes;
    
    // CNQuickCategoryAudioCall, CNQuickActionCategoryInstantMessage, CNQuickActionCategoryVideoCall, CNQuickActionCategoryMail
    
    // It appears all available actions boil down to a CNPropertyAction, or a subclass thereof.
    // To hook:
    // - CNPropertyAction
    // - CNPropertySendMessageAction
    // - CNPropertyFaceTimeAction
    // These end up passing through [[LSApplicationWorkspace defaultWorkspace] openURL:]
    // or                           [[UIApplication sharedApplication] openURL:withOptions:]
    NSArray *inlineActionCategories = @[@"audio-call", @"instant-message", @"video-call", @"mail"];
    
    self.gridViewController.inlineActionsCategories = inlineActionCategories;
    
    self.gridViewController.avatarSize = CGSizeMake(avatarSize, avatarSize);
    self.gridViewController.avatarMargins = avatarInsets;
    
    [self.view addSubview:self.gridViewController.view];
    
    // Frames!
    // We can calculate the view height based upon the number of columns, and the number of contacts.
    _contactCount = (int)contacts.count;
    
    CGFloat rows = ((CGFloat)_contactCount/self.gridViewController.numberOfColumns);
    CGFloat height = ceilf(rows) * _itemHeight;
    
    self.gridViewController.view.frame = CGRectMake(16, 0, SCREEN_WIDTH-32, height);
    self.gridViewController.view.clipsToBounds = NO;
    self.gridViewController.collectionView.frame = CGRectMake(0, 0, SCREEN_WIDTH-32, height);
    self.gridViewController.collectionView.clipsToBounds = NO;
    
    // iOS 10 tint colouring.
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
        self.gridViewController.view.tintColor = [UIColor whiteColor];
    }
    
    self.view.frame = CGRectMake(0, 30, SCREEN_WIDTH, height);
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self.gridViewController viewWillLayoutSubviews];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat rows = ((CGFloat)_contactCount/self.gridViewController.numberOfColumns);
    CGFloat height = ceilf(rows) * _itemHeight;
    
    self.gridViewController.view.frame = CGRectMake(16, 0, SCREEN_WIDTH-32, height);
    self.gridViewController.collectionView.frame = CGRectMake(0, 0, SCREEN_WIDTH-32, height);
    
    self.noContactsLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH, _itemHeight);
}

// delegates
-(void)gridViewController:(id)arg1 didPerformAction:(id)arg2 forContactAtIndex:(long long)arg3 withContactProperty:(id)arg4 {
    // Not sure if we even need this?
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat avatarSize = IS_IPAD ? 72 : 60;
    UIEdgeInsets avatarInsets = UIEdgeInsetsMake(9, 11, 3.5, 11);
    
    return CGSizeMake(avatarSize + avatarInsets.left + avatarInsets.right, _itemHeight);
}

@end
