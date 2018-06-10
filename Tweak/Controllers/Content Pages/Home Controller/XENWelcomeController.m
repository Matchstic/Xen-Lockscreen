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

#import "XENWelcomeController.h"
#import "XENTouchPassThroughView.h"

@interface XENWelcomeController ()

@end

#define welcome_width (SCREEN_WIDTH*0.8)
#define fontSize (16 + (IS_IPAD ? 3 : 0))
#define animateDuration 0.3

// The UI itself will be on a scrolling region, and will need that if we go beyond the size of the notifications box.
// Therefore, content region size =< notifications.height - greeting.height - dismiss.height - padding.
// We handle this mostly in -layoutSubviews - just keep adding items to scrollview content view, set content size, and then
// set frame. That should in theory handle that.

@interface IS2Weather : NSObject
+(void)registerForWeatherUpdatesWithIdentifier:(NSString*)identifier andCallback:(void (^)(void))callbackBlock;
+(void)unregisterForUpdatesWithIdentifier:(NSString*)identifier;
+(NSString*)naturalLanguageDescription;
@end

@implementation XENWelcomeController

-(void)loadView {
    // Load up welcome view
    self.view = (UIView*)[[XENTouchPassThroughView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.backgroundColor = [UIColor clearColor];
    
    UIVibrancyEffect *effect = [UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    _effectView.frame = CGRectZero;
    _effectView.tag = 1337;
    
    //[self.view addSubview:_effectView];
    
    _outerContentView = [[UIView alloc] initWithFrame:CGRectZero];
    _outerContentView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:_outerContentView];
    
    /*
     AYVibrantButton *_notificationButton;
    */
    
    CGFloat textAlpha = 0.65;
    
    _greeting = [[UILabel alloc] initWithFrame:CGRectZero];
    _greeting.font = [UIFont systemFontOfSize:26 + (IS_IPAD ? 10 : 0) weight:UIFontWeightLight];
    _greeting.text = @"";
    _greeting.userInteractionEnabled = NO;
    _greeting.textAlignment = NSTextAlignmentCenter;
    _greeting.numberOfLines = 0;
    _greeting.textColor = [UIColor whiteColor];
    _greeting.alpha = textAlpha;
    
    //[_effectView.contentView addSubview:_greeting];
    [_outerContentView addSubview:_greeting];
    
    _innerContentView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _innerContentView.showsVerticalScrollIndicator = NO;
    _innerContentView.showsHorizontalScrollIndicator = NO;
    _innerContentView.delegate = self;
    
    //[_effectView.contentView addSubview:_innerContentView];
    [_outerContentView addSubview:_innerContentView];
    
    _topScrollBar = [[XENTintedView alloc] initWithFrame:CGRectZero];
    _topScrollBar.hidden = YES;
    _topScrollBar.alpha = 0.0;
    _topScrollBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.35];
    
    //[_effectView.contentView addSubview:_topScrollBar];
    [_outerContentView addSubview:_topScrollBar];
    
    _bottomScrollBar = [[XENTintedView alloc] initWithFrame:CGRectZero];
    _bottomScrollBar.hidden = YES;
    _bottomScrollBar.alpha = 0.0;
    _bottomScrollBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.35];
    
    //[_effectView.contentView addSubview:_bottomScrollBar];
    [_outerContentView addSubview:_bottomScrollBar];
    
    UIImage *weatherImage = [XENResources themedImageWithName:@"Welcome/WeatherIcon"];
    weatherImage = [weatherImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    _weatherIcon = [[UIImageView alloc] initWithImage:weatherImage];
    _weatherIcon.userInteractionEnabled = NO;
    
    [_effectView.contentView addSubview:_weatherIcon];
    //[_innerContentView addSubview:_weatherIcon];
    
    _weatherText = [[UILabel alloc] initWithFrame:CGRectZero];
    _weatherText.font = [UIFont systemFontOfSize:fontSize];
    _weatherText.text = @"";
    _weatherText.numberOfLines = 0;
    _weatherText.userInteractionEnabled = NO;
    _weatherText.textAlignment = NSTextAlignmentCenter;
    _weatherText.textColor = [UIColor whiteColor];
    _weatherText.alpha = textAlpha;
    
    //[_effectView.contentView addSubview:_weatherText];
    [_innerContentView addSubview:_weatherText];
    
    self.todayProvider = [[objc_getClass("EKBBTodayProvider") alloc] init];
    
    UIImage *calendarImage = [XENResources themedImageWithName:@"Welcome/CalendarIcon"];
    calendarImage = [calendarImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    _calendarIcon = [[UIImageView alloc] initWithImage:calendarImage];
    _calendarIcon.userInteractionEnabled = NO;
    
    [_effectView.contentView addSubview:_calendarIcon];
    //[_innerContentView addSubview:_calendarIcon];
    
    _calendarText = [[UILabel alloc] initWithFrame:CGRectZero];
    _calendarText.font = [UIFont systemFontOfSize:fontSize];
    _calendarText.text = @"";
    _calendarText.numberOfLines = 0;
    _calendarText.userInteractionEnabled = NO;
    _calendarText.textAlignment = NSTextAlignmentCenter;
    _calendarText.textColor = [UIColor whiteColor];
    _calendarText.alpha = textAlpha;
    
    //[_effectView.contentView addSubview:_calendarText];
    [_innerContentView addSubview:_calendarText];
    
    _birthdayText = [[UILabel alloc] initWithFrame:CGRectZero];
    _birthdayText.font = [UIFont systemFontOfSize:fontSize];
    _birthdayText.text = @"";
    _birthdayText.numberOfLines = 0;
    _birthdayText.userInteractionEnabled = NO;
    _birthdayText.textAlignment = NSTextAlignmentCenter;
    _birthdayText.textColor = [UIColor whiteColor];
    _birthdayText.alpha = textAlpha;
    
    //[_effectView.contentView addSubview:_birthdayText];
    [_innerContentView addSubview:_birthdayText];
    
    UIImage *notifImage = [XENResources themedImageWithName:@"Welcome/NotificationIcon"];
    notifImage = [notifImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    _notificationIcon = [[UIImageView alloc] initWithImage:notifImage];
    _notificationIcon.userInteractionEnabled = NO;
    
    [_effectView.contentView addSubview:_notificationIcon];
    //[_innerContentView addSubview:_notificationIcon];
    
    _notificationText = [[UILabel alloc] initWithFrame:CGRectZero];
    _notificationText.font = [UIFont systemFontOfSize:fontSize];
    _notificationText.text = @"";
    _notificationText.numberOfLines = 0;
    _notificationText.userInteractionEnabled = NO;
    _notificationText.textAlignment = NSTextAlignmentCenter;
    _notificationText.textColor = [UIColor whiteColor];
    _notificationText.alpha = textAlpha;
    
    //[_effectView.contentView addSubview:_notificationText];
    [_innerContentView addSubview:_notificationText];
    
    [_innerContentView addSubview:_effectView];
    
    // TODO: Notification button
    _notificationButton = [[AYVibrantButton alloc] initWithFrame:CGRectZero style:AYVibrantButtonStyleInvert];
    _notificationButton.vibrancyEffect = effect;
    _notificationButton.text = [XENResources localisedStringForKey:@"Dismiss" value:@"Dismiss"];
    _notificationButton.font = [UIFont systemFontOfSize:fontSize];
    [_notificationButton addTarget:self action:@selector(didTapDismissButton:) forControlEvents:UIControlEventTouchUpInside];
    
    //[_effectView addSubview:_notificationButton];
    [_outerContentView addSubview:_notificationButton];
    
    [self relayoutViews];
}

-(CGRect)boundedRectForFont:(UIFont*)font andText:(NSString*)text {
    if (!text || !font) {
        return CGRectZero;
    }
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:font}];
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){welcome_width, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    return rect;
}

-(void)relayoutViews {
    CGFloat height = 0;
    CGFloat innerHeight = 0;
    
    UIView *notifView = nil;
    @try {
        notifView = [XENResources notificationListView].subviews[0];
    } @catch (NSException *e) {
        notifView = nil;
    }
    
    CGFloat notificationViewHeight = notifView.frame.size.height;
    
    CGRect rect = [self boundedRectForFont:_greeting.font andText:_greeting.text];
    _greeting.frame = CGRectMake(welcome_width/2 - (rect.size.width+10)/2, height, rect.size.width+10, rect.size.height);
    
    height += _greeting.frame.size.height + 20;
    
    _weatherIcon.frame = CGRectMake(welcome_width/2 - (_weatherIcon.frame.size.width/2), innerHeight, _weatherIcon.frame.size.width, _weatherIcon.frame.size.height);
    
    height += _weatherIcon.frame.size.height + 10;
    innerHeight += _weatherIcon.frame.size.height + 10;
    
    rect = [self boundedRectForFont:_weatherText.font andText:_weatherText.text];
    //rect.size.width += 6;
    _weatherText.frame = CGRectMake(welcome_width/2 - rect.size.width/2, innerHeight, rect.size.width, rect.size.height);
    
    height += _weatherText.frame.size.height + 20;
    innerHeight += _weatherText.frame.size.height + 20;
    
    if (![_calendarText.text isEqualToString:@""] || ![_birthdayText.text isEqualToString:@""]) {
        _calendarIcon.hidden = NO;
        _calendarIcon.frame = CGRectMake(welcome_width/2 - (_calendarIcon.frame.size.width/2), innerHeight, _calendarIcon.frame.size.width, _calendarIcon.frame.size.height);
        
        height += _calendarIcon.frame.size.height + 10;
        innerHeight += _calendarIcon.frame.size.height + 10;
    } else {
        _calendarIcon.hidden = YES;
    }
    
    if (![_calendarText.text isEqualToString:@""]) {
        rect = [self boundedRectForFont:_calendarText.font andText:_calendarText.text];
        //rect.size.width += 6;
        _calendarText.frame = CGRectMake(welcome_width/2 - rect.size.width/2, innerHeight, rect.size.width, rect.size.height);
    
        height += _calendarText.frame.size.height + (![_birthdayText.text isEqualToString:@""] ? 10 : 20);
        innerHeight += _calendarText.frame.size.height + (![_birthdayText.text isEqualToString:@""] ? 10 : 20);
    } else {
        _calendarText.frame = CGRectZero;
    }
    
    if (![_birthdayText.text isEqualToString:@""]) {
        rect = [self boundedRectForFont:_birthdayText.font andText:_birthdayText.text];
        //rect.size.width += 6;
        _birthdayText.frame = CGRectMake(welcome_width/2 - rect.size.width/2, innerHeight, rect.size.width, rect.size.height);
    
        height += _birthdayText.frame.size.height + 20;
        innerHeight += _birthdayText.frame.size.height + 20;
    }
    
    if (![_notificationText.text isEqualToString:@""]) {
        _notificationIcon.hidden = NO;
        _notificationIcon.frame = CGRectMake(welcome_width/2 - (_notificationIcon.frame.size.width/2), innerHeight, _notificationIcon.frame.size.width, _notificationIcon.frame.size.height);
    
        height += _notificationIcon.frame.size.height + 10;
        innerHeight += _notificationIcon.frame.size.height + 10;
    
        rect = [self boundedRectForFont:_notificationText.font andText:_notificationText.text];
        //rect.size.width += 6;
        _notificationText.frame = CGRectMake(welcome_width/2 - rect.size.width/2, innerHeight, rect.size.width, rect.size.height);
    
        height += _notificationText.frame.size.height + 20;
        innerHeight += _notificationText.frame.size.height + 20;
    } else {
        _notificationIcon.hidden = YES;
    }
    
    height += 10;
    
    rect = [self boundedRectForFont:[UIFont systemFontOfSize:fontSize] andText:[XENResources localisedStringForKey:@"Dismiss" value:@"Dismiss"]];
    _notificationButton.frame = CGRectMake(welcome_width/2 - (rect.size.width+40)/2, height, rect.size.width+40, rect.size.height+15);
    
    height += _notificationButton.frame.size.height + 10;
    
    BOOL largerThanNotifs = NO;
    
    // Now, we handle the scrollview's sizing, and re-locate the dismiss button as needed.
    if (height > notificationViewHeight) {
        largerThanNotifs = YES;
        
        CGFloat heightForScroll = notificationViewHeight - (_greeting.frame.size.height + 20) - (_notificationButton.frame.size.height + 20) - 10;
        
        // Force scrolling.
        _innerContentView.contentSize = CGSizeMake(welcome_width, innerHeight);
        _innerContentView.frame = CGRectMake(0, _greeting.frame.size.height + 20, welcome_width, heightForScroll);
        [_innerContentView setContentOffset:CGPointMake(0, 0) animated:YES];
        
        // Add in the "scroll bars" to give fancy looking scroll region.
        _topScrollBar.hidden = NO;
        _topScrollBar.alpha = 0.0;
        _bottomScrollBar.hidden = NO;
        _bottomScrollBar.alpha = 1.0;
        
        _topScrollBar.frame = CGRectMake(0, _innerContentView.frame.origin.y - 1, welcome_width, 1);
        _bottomScrollBar.frame = CGRectMake(0, _innerContentView.frame.origin.y + _innerContentView.frame.size.height, welcome_width, 1);
        
        CGFloat dismissY = notificationViewHeight - (_notificationButton.frame.size.height + 10);
        
        // Reposition the dismiss button.
        _notificationButton.frame = CGRectMake(welcome_width/2 - (rect.size.width+40)/2, dismissY, rect.size.width+40, rect.size.height+15);
    } else {
        // No need to reposition anything.
        _innerContentView.contentSize = CGSizeMake(welcome_width, innerHeight);
        _innerContentView.frame = CGRectMake(0, _greeting.frame.size.height + 20, welcome_width, innerHeight);
        
        _topScrollBar.hidden = YES;
        _bottomScrollBar.hidden = YES;
    }
    
    _effectView.frame = CGRectMake(0, 0, welcome_width, innerHeight);
    
    if (largerThanNotifs) {
        //_effectView.frame = CGRectMake(SCREEN_WIDTH/2 - welcome_width/2, notifView.frame.origin.y - 25, welcome_width, notificationViewHeight);
        _outerContentView.frame = CGRectMake(SCREEN_WIDTH/2 - welcome_width/2, notifView.frame.origin.y - 25, welcome_width, notificationViewHeight);
    } else {
        //_effectView.frame = CGRectMake(SCREEN_WIDTH/2 - welcome_width/2, SCREEN_HEIGHT/2 - height/2 + 10, welcome_width, height);
        _outerContentView.frame = CGRectMake(SCREEN_WIDTH/2 - welcome_width/2, SCREEN_HEIGHT/2 - height/2 + 10, welcome_width, height);
        
        // Re-center.
        //_effectView.center = CGPointMake(SCREEN_WIDTH/2, notifView.center.y - 25);
        _outerContentView.center = CGPointMake(SCREEN_WIDTH/2, notifView.center.y - 25);
    }
}

-(void)setInitialNotifCount:(int)count {
    _notifCount = count;
}

-(void)didRecieveNewNotification {
    _notifCount++;
    
    [self setNotifText];
    [UIView animateWithDuration:animateDuration animations:^{
        [self relayoutViews];
    }];
}

-(void)setNotifText {
    NSString *notifText;
    if (_notifCount == 0) {
        notifText = @"";
    } else if (_notifCount == 1) {
        notifText = [XENResources localisedStringForKey:@"You have 1 new notification." value:@"You have 1 new notification."];
    } else {
        notifText = [NSString stringWithFormat:[XENResources localisedStringForKey:@"You have %d new notifications." value:@"You have %d new notifications."], _notifCount];
    }
    
    _notificationText.text = notifText;
}

-(void)didRemoveNotification {
    _notifCount--;
    
    [self setNotifText];
    [UIView animateWithDuration:animateDuration animations:^{
        [self relayoutViews];
    }];
}

-(void)didTapDismissButton:(id)sender {
    [self.delegate hideWelcomeController];
}

-(void)prepareForDisplay {
    // IS2 will handle mutliple calls of this.
    [objc_getClass("IS2Weather") registerForWeatherUpdatesWithIdentifier:@"com.matchstic.xen.welcome" andCallback:^{
        _weatherText.text = [objc_getClass("IS2Weather") naturalLanguageDescription];
        [UIView animateWithDuration:animateDuration animations:^{
            [self relayoutViews];
        }];
    }];
    
    _greetingTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateGreetingText:) userInfo:nil repeats:YES];
    [self updateGreetingText:nil];
    
    // Anything else as needed, like calendar.
    _weatherText.text = [objc_getClass("IS2Weather") naturalLanguageDescription];
    
    _calendarText.text = [self.todayProvider _createUpcomingEventBulletin].message;
    if (!_calendarText.text) {
        _calendarText.text = @"";
    }
    
    _birthdayText.text = [self.todayProvider _createBirthdayBulletin].message;
    if (!_birthdayText.text) {
        _birthdayText.text = @"";
    }
    
    NSString *notifText;
    if (_notifCount == 0) {
        notifText = @"";
    } else if (_notifCount == 1) {
        notifText = [XENResources localisedStringForKey:@"You have 1 new notification." value:@"You have 1 new notification."];
    } else {
        notifText = [NSString stringWithFormat:[XENResources localisedStringForKey:@"You have %d new notifications." value:@"You have %d new notifications."], _notifCount];
    }
    
    _notificationText.text = notifText;
    
    [self relayoutViews];
    
    self.view.hidden = NO;
    self.view.alpha = 1.0;
}

-(void)updateGreetingText:(id)sender {
    // Where in the day are we?
    
    NSDate *date = [NSDate date];
    NSInteger hour = 0;
    NSInteger minute = 0;
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    [currentCalendar getHour:&hour minute:&minute second:NULL nanosecond:NULL fromDate:date];

    NSString *text = @"";
    if (hour < 12) {
        text = [XENResources localisedStringForKey:@"Good Morning" value:@"Good Morning"];
    } else if (hour < 18) {
        text = [XENResources localisedStringForKey:@"Good Afternoon" value:@"Good Afternoon"];
    } else {
        text = [XENResources localisedStringForKey:@"Good Evening" value:@"Good Evening"];
    }
    
    _greeting.text = text;
}

-(void)prepareForHiding {
    [objc_getClass("IS2Weather") unregisterForUpdatesWithIdentifier:@"com.matchstic.xen.welcome"];
    [_greetingTimer invalidate];
    _greetingTimer = nil;
}

-(void)rotateToOrient:(int)orient {
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    [self relayoutViews];
}

-(void)setAlpha:(CGFloat)alpha {
    _greeting.alpha = alpha;
    _weatherIcon.alpha = alpha;
    _weatherText.alpha = alpha;
    _calendarIcon.alpha = alpha;
    _calendarText.alpha = alpha;
    _birthdayText.alpha = alpha;
    _notificationIcon.alpha = alpha;
    _notificationText.alpha = alpha;
    _notificationButton.alpha = alpha;
}

#pragma mark UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // based off content offset, hide/show scroll bars.
    
    BOOL shouldShowTopBar = scrollView.contentOffset.y > 0;
    BOOL shouldShowBottomBar = scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.frame.size.height) - 10;

    _topScrollBar.alpha = (shouldShowTopBar ? 1.0 : 0.0);
    _bottomScrollBar.alpha = (shouldShowBottomBar ? 1.0 : 0.0);
}

-(void)viewDidLayoutSubviews {
    // Setup after orientation shit
    [self relayoutViews];
}

-(void)dealloc {
    [self prepareForHiding];
    
    for (UIView *view in _effectView.contentView.subviews) {
        [view removeFromSuperview];
    }
}

@end
