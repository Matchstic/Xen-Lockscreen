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

#import <UIKit/UIKit.h>
#import "AYVibrantButton.h"
#import "XENTintedView.h"

#warning Private methods used here; EKBBTodayProvider, BBBulletinRequest

// BBBulletinRequest is fine up to iOS 10, need to verify EKBB

@interface BBBulletinRequest : NSObject
@property (nonatomic, strong) NSString *message;
@end

@interface EKBBTodayProvider : NSObject
- (BBBulletinRequest*)_createUpcomingEventBulletin;
- (BBBulletinRequest*)_createBirthdayBulletin;
@end

@protocol XENWelcomeControllerDelegate <NSObject>
-(void)hideWelcomeController;
@end

@interface XENWelcomeController : UIViewController <UIScrollViewDelegate> {
    UILabel *_greeting;
    UIImageView *_weatherIcon;
    UILabel *_weatherText;
    UIImageView *_calendarIcon;
    UILabel *_calendarText;
    UILabel *_birthdayText;
    UIImageView *_notificationIcon;
    UILabel *_notificationText;
    AYVibrantButton *_notificationButton;
    UIVisualEffectView *_effectView;
    UIView *_outerContentView;
    UIScrollView *_innerContentView;
    XENTintedView *_topScrollBar;
    XENTintedView *_bottomScrollBar;
    
    int _notifCount;
    NSTimer *_greetingTimer;
}

@property (nonatomic, strong) EKBBTodayProvider *todayProvider;
@property (nonatomic, weak) id<XENWelcomeControllerDelegate> delegate;

-(void)prepareForDisplay;
-(void)prepareForHiding;
-(void)setInitialNotifCount:(int)count;
-(void)didRecieveNewNotification;
-(void)didRemoveNotification;
-(void)rotateToOrient:(int)orient;
-(void)setAlpha:(CGFloat)alpha;

@end
