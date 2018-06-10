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

#import "XENLaunchpadColViewCell.h"
#import "XENPLaunchpadController.h"
#import "XENLaunchpadModalController.h"
#import "XENPResources.h"

#import <objc/runtime.h>

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

@implementation XENLaunchpadColViewCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)initialiseForIdentifier:(NSString*)identifier {
    self.opaque = NO;
    
    if ([identifier isEqualToString:@"<blank>"]) {
        // We need to initialise for the tappable cell to bring up stuff.
        self.isPlusCell = YES;
        
        self.identifer = identifier;
        
        self.contentImageView = [UIButton buttonWithType:UIButtonTypeCustom];
        self.contentImageView.backgroundColor = [UIColor clearColor];
        [(UIButton*)[self contentImageView] addTarget:self action:@selector(presentModalSelector:) forControlEvents:UIControlEventTouchUpInside];
        self.contentImageView.frame = CGRectMake(7, 7, 60*0.95, 60*0.95);
        //self.contentImageView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        
        UIImage *tapImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/LaunchpadTapIcon%@", [XENPResources imageSuffix]]];
        tapImage = [tapImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIImageView *tapImageView = [[UIImageView alloc] initWithImage:tapImage];
        tapImageView.backgroundColor = [UIColor clearColor];
        tapImageView.tintColor = [[UIApplication sharedApplication] keyWindow].tintColor;
        tapImageView.alpha = 0.5;
        
        [self.contentImageView addSubview:tapImageView];
        
        [self addSubview:self.contentImageView];
    } else {
        self.isPlusCell = NO;
        
        self.identifer = identifier;
        
        self.contentImageView = [[UIImageView alloc] initWithImage:[[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:identifier]];
        
        self.contentImageView.backgroundColor = [UIColor clearColor];
        self.contentImageView.frame = CGRectMake(7, 7, self.contentImageView.frame.size.width*0.95, self.contentImageView.frame.size.height*0.95);
        
        [self addSubview:self.contentImageView];
        
        // Deletion button
        self.deletionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.deletionButton.backgroundColor = [UIColor clearColor];
        self.deletionButton.frame = CGRectMake(0, 0, 25, 25);
        [self.deletionButton addTarget:self action:@selector(deleteButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *del = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/LaunchpadRemoveIcon%@", [XENPResources imageSuffix]]];
        del = [del imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIImageView *img = [[UIImageView alloc] initWithImage:del];
        img.frame = CGRectMake(0, 5, 20, 20);
        img.backgroundColor = [UIColor clearColor];
        img.tintColor = [[UIApplication sharedApplication] keyWindow].tintColor;
        
        [self.deletionButton addSubview:img];
        
        [self addSubview:self.deletionButton];
    }
}

-(void)presentModalSelector:(id)sender {
    // Show up the modal shit.
    NSLog(@"Trying to present modal controller");
    
    XENLaunchpadModalController *mc = [[XENLaunchpadModalController alloc] init];
    mc.delegate = self.delegate;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mc];
    
    [[XENPLaunchpadController sharedInstance].navigationController presentViewController:navController animated:YES completion:nil];
}

-(void)deleteButtonWasPressed:(id)sender {
    NSMutableArray *array = [[XENPResources getPreferenceKey:@"launchpadIdentifiers"] mutableCopy];
    if (!array)
        array = [@[@"com.apple.MobileSMS", @"com.apple.Preferences", @"com.apple.calculator", @"com.apple.camera", @"com.apple.Maps"] mutableCopy];
    
    [array removeObject:self.identifer];
    
    [XENPResources setPreferenceKey:@"launchpadIdentifiers" withValue:array];
    
    // Now, we fade ourselves out, and reload collection view.
    [UIView animateWithDuration:0.3 animations:^{
        self.contentImageView.alpha = 0.0;
        self.deletionButton.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.delegate refreshCollectionView];
    }];
}

-(void)prepareForReuse {
    [self.contentImageView removeFromSuperview];
    self.contentImageView = nil;
    
    [self.deletionButton removeFromSuperview];
    self.deletionButton = nil;
    
    self.identifer = nil;
}

@end
