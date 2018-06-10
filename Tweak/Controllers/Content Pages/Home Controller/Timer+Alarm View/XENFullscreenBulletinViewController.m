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

#import "XENFullscreenBulletinViewController.h"

@interface XENFullscreenBulletinViewController ()

@end
/*
 * Functions used in these methods:
 * -(void)setupWithFullscreenBulletinNotification:(id)notification title:(NSString*)title andSubtitle:(NSString*)subtitle
 * -(BOOL)canSnoozeBulletin
 * -(void)cancelButtonCallback:(id)sender
 * -(void)snoozeButtonCallback:(id)sender
*/

@implementation XENFullscreenBulletinViewController

-(void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view = view;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    
    // Load up our shit.
    // Need blur at bottom
    
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    _containerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_containerView];
    
    UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _effectView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
    _effectView.frame = _containerView.bounds;
    
    [_containerView addSubview:_effectView];
    
    self.titleLabel = [[XENLegibilityLabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH*0.05, 0, SCREEN_WIDTH*0.9, 140)];
    self.titleLabel.text = _notifTitle;
    self.titleLabel.textColor = [XENResources textColour];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:34];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.userInteractionEnabled = NO;
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = CGRectMake(SCREEN_WIDTH*0.05, 0, SCREEN_WIDTH*0.9, self.titleLabel.frame.size.height);
    [_effectView.contentView addSubview:self.titleLabel];
    
    /*CGSize size = [self.titleLabel.text boundingRectWithSize:self.titleLabel.bounds.size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName:self.titleLabel.font}
                                     context:nil].size;*/
    
    UIView *cancelView = [XENBlurBackedImageProvider alarmCancel];
    
    self.dismissButton = [XENReactiveButton buttonWithType:UIButtonTypeCustom];
    [self.dismissButton addTarget:self action:@selector(cancelButtonCallback:) forControlEvents:UIControlEventTouchUpInside];
    self.dismissButton.backgroundColor = [UIColor clearColor];
    self.dismissButton.frame = CGRectMake((SCREEN_WIDTH/2)-(cancelView.frame.size.width/2), /*self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height+80*/ self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height + 50, cancelView.frame.size.width, cancelView.frame.size.height);
    [self.dismissButton addSubview:cancelView];
    
    [_effectView.contentView addSubview:self.dismissButton];
    
    if ([self canSnoozeBulletin]) {
        UIView *snoozeView = [XENBlurBackedImageProvider alarmSnooze];
        
        self.snoozeButton = [XENReactiveButton buttonWithType:UIButtonTypeCustom];
        [self.snoozeButton addTarget:self action:@selector(snoozeButtonCallback:) forControlEvents:UIControlEventTouchUpInside];
        self.snoozeButton.backgroundColor = [UIColor clearColor];
        self.snoozeButton.frame = CGRectMake((SCREEN_WIDTH/2) - cancelView.frame.size.width - cancelView.frame.size.width/2, self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height + 50, cancelView.frame.size.width, cancelView.frame.size.height);
        self.dismissButton.frame = CGRectMake((SCREEN_WIDTH/2) + cancelView.frame.size.width/2, self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height + 50, cancelView.frame.size.width, cancelView.frame.size.height);
        [self.snoozeButton addSubview:snoozeView];
        
        [_effectView.contentView addSubview:self.snoozeButton];
    }
    
    _containerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.dismissButton.frame.origin.y + self.dismissButton.frame.size.height);
    _containerView.center = self.view.center;
}

-(void)setupWithFullscreenBulletinNotification:(id)notification title:(NSString*)title andSubtitle:(NSString*)subtitle {
    self.bulletinController = notification;
    
    if (!title) {
        title = [[self.bulletinController bulletinItem] title];
    }
    
    _notifTitle = (title ? title : @"Failed to load title");
    _subtitle = subtitle;
}

-(BOOL)canSnoozeBulletin {
    return [self.bulletinController.bulletinItem canSnooze];
}

#pragma mark Callbacks

-(void)cancelButtonCallback:(id)sender {
    [self.bulletinController performDismissAction];
}

-(void)snoozeButtonCallback:(id)sender {
    [self.bulletinController performSnoozeAction];
}

#pragma mark Handle rotation

-(void)rotateToOrient:(int)orientation {
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    // Resize title, subtitle, and relocate cancel/dismiss buttons
    self.titleLabel.frame = CGRectMake(SCREEN_WIDTH*0.05, 0, SCREEN_WIDTH*0.9, self.titleLabel.frame.size.height);
    
    self.dismissButton.frame = CGRectMake((SCREEN_WIDTH/2)-(self.dismissButton.frame.size.width/2), self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height + 50, self.dismissButton.frame.size.width, self.dismissButton.frame.size.height);
    
    if ([self canSnoozeBulletin]) {
        self.snoozeButton.frame = CGRectMake((SCREEN_WIDTH/2) - self.dismissButton.frame.size.width - self.dismissButton.frame.size.width/2, self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height + 50, self.dismissButton.frame.size.width, self.dismissButton.frame.size.height);
        self.dismissButton.frame = CGRectMake((SCREEN_WIDTH/2) + self.dismissButton.frame.size.width/2, self.titleLabel.frame.origin.y+self.titleLabel.frame.size.height + 50, self.dismissButton.frame.size.width, self.dismissButton.frame.size.height);
    }
    
    _containerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.dismissButton.frame.origin.y + self.dismissButton.frame.size.height);
    _containerView.center = self.view.center;
    
    _effectView.frame = _containerView.bounds;
}

#pragma mark Eh, shit from Apple

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
