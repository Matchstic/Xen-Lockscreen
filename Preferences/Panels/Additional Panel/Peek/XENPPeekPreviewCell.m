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

#import "XENPPeekPreviewCell.h"
#import "XENPResources.h"
#import <objc/runtime.h>

@interface CAFilter : NSObject
+(NSArray*)filterTypes;
+(CAFilter*)filterWithType:(NSString*)type;
+(CAFilter*)filterWithName:(NSString*)name;
@end

#define NOTIFICATION_ICON_SIZE 32
#define NOTIFICATION_COUNT_WIDTH 10
#define NOTIFICATION_UI_SPACING 8
#define NOTIFICATION_CELL_WIDTH (NOTIFICATION_ICON_SIZE + NOTIFICATION_UI_SPACING + NOTIFICATION_COUNT_WIDTH + 5)

@implementation XENPPeekPreviewCell

- (instancetype)initWithStyle:(int)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.font = [UIFont fontWithName:@".SFUIDisplay-Ultralight" size:87.5];
        _timeLabel.backgroundColor = [UIColor clearColor];
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];;
        if ([self timeIs24HourFormat])
            [dateFormat setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"HH:mm" options:0 locale:[NSLocale currentLocale]]];
        else
            [dateFormat setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"hh:mm" options:0 locale:[NSLocale currentLocale]]];
        
        _timeLabel.text = [dateFormat stringFromDate:[NSDate date]];
        
        [self.contentView addSubview:_timeLabel];
        
        _dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        _dateLabel.textColor = [UIColor whiteColor];
        _dateLabel.font = [UIFont fontWithName:@".SFUIText-Regular" size:18];
        _dateLabel.backgroundColor = [UIColor clearColor];
        
        NSDate *day = [NSDate date];
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"EEEEdMMMM" options:0 locale:[NSLocale currentLocale]]];
        NSString *string = [format stringFromDate:day];
        
        _dateLabel.text = string;
        
        [self.contentView addSubview:_dateLabel];
        
        _statusBar = [[UIStatusBar alloc] initWithFrame:CGRectZero showForegroundView:YES];
        [_statusBar requestStyle:2 animated:YES];
        [_statusBar setLegibilityStyle:0];
        [_statusBar setHomeItemsDisabled:YES];
        
        [self.contentView addSubview:_statusBar];
        
        _leftNotificationCell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, NOTIFICATION_CELL_WIDTH, NOTIFICATION_ICON_SIZE)];
        _leftNotificationCell.backgroundColor = [UIColor clearColor];
        
        UIImage *icon1Img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/CellIcons/Twitter%@", [XENPResources imageSuffix]]];
        
        UIImageView *icon1 = [[UIImageView alloc] initWithImage:icon1Img];
        icon1.frame = CGRectMake(0, 0, NOTIFICATION_ICON_SIZE, NOTIFICATION_ICON_SIZE);
        icon1.backgroundColor = [UIColor clearColor];
        
        [_leftNotificationCell addSubview:icon1];
        
        UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(NOTIFICATION_ICON_SIZE + NOTIFICATION_UI_SPACING, 0, NOTIFICATION_COUNT_WIDTH, NOTIFICATION_ICON_SIZE)];
        label1.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:21];
        label1.backgroundColor = [UIColor clearColor];
        label1.textColor = [UIColor whiteColor];
        label1.clipsToBounds = NO;
        label1.text = @"1";
        
        [_leftNotificationCell addSubview:label1];
        
        [self.contentView addSubview:_leftNotificationCell];
        
        _rightNotificationCell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, NOTIFICATION_CELL_WIDTH, NOTIFICATION_ICON_SIZE)];
        _rightNotificationCell.backgroundColor = [UIColor clearColor];
        
        UIImage *icon2Img = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/XenPrefs.bundle/CellIcons/Mail%@", [XENPResources imageSuffix]]];
        
        UIImageView *icon2 = [[UIImageView alloc] initWithImage:icon2Img];
        icon2.frame = CGRectMake(0, 0, NOTIFICATION_ICON_SIZE, NOTIFICATION_ICON_SIZE);
        icon2.backgroundColor = [UIColor clearColor];
        
        [_rightNotificationCell addSubview:icon2];
        
        UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(NOTIFICATION_ICON_SIZE + NOTIFICATION_UI_SPACING, 0, NOTIFICATION_COUNT_WIDTH, NOTIFICATION_ICON_SIZE)];
        label2.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:21];
        label2.backgroundColor = [UIColor clearColor];
        label2.textColor = [UIColor whiteColor];
        label2.clipsToBounds = NO;
        label2.text = @"2";
        
        [_rightNotificationCell addSubview:label2];
        
        [self.contentView addSubview:_rightNotificationCell];
        
        self.contentView.backgroundColor = [UIColor blackColor];
        CAFilter* filter = [CAFilter filterWithName:@"colorMonochrome"];
        [filter setValue:[NSNumber numberWithFloat:-0.2] forKey:@"inputBias"];
        [filter setValue:[NSNumber numberWithFloat:1] forKey:@"inputAmount"];
        self.contentView.layer.filters = [NSArray arrayWithObject:filter];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changedPreviewSettings) name:@"com.matchstic.xen/previewPeekUpdate" object:nil];
        
        [self changedPreviewSettings];
    }
    
    return self;
}

-(BOOL)timeIs24HourFormat {
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    BOOL is24Hour = amRange.location == NSNotFound && pmRange.location == NSNotFound;
    return is24Hour;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    // Return a custom cell height.
    return 240.f;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)changedPreviewSettings {
    NSLog(@"Peek settings changed");
    
    self.contentView.backgroundColor = ([XENPResources getPreferenceKey:@"peekEnabled"] ? [[XENPResources getPreferenceKey:@"peekEnabled"] boolValue] : NO) ? [UIColor blackColor] : [UIColor grayColor];
    
    _statusBar.hidden = ([XENPResources getPreferenceKey:@"peekShowStatusBar"] ? [[XENPResources getPreferenceKey:@"peekShowStatusBar"] boolValue] : YES) ? NO : YES;
    
    _leftNotificationCell.hidden = ([XENPResources getPreferenceKey:@"peekShowNotifications"] ? [[XENPResources getPreferenceKey:@"peekShowNotifications"] boolValue] : YES) ? NO : YES;
    _rightNotificationCell.hidden = ([XENPResources getPreferenceKey:@"peekShowNotifications"] ? [[XENPResources getPreferenceKey:@"peekShowNotifications"] boolValue] : YES) ? NO : YES;
    
    [self removeTimeView];
}

-(void)removeTimeView {
    // Remove time view.
    UIView *firstSubview = nil;
    for (UIView *vi in _statusBar.subviews) {
        if ([[vi class] isEqual:objc_getClass("UIStatusBarForegroundView")]) {
            firstSubview = vi;
            break;
        }
    }
    
    UIView *second = nil;
    for (UIView *vi in firstSubview.subviews) {
        if ([[vi class] isEqual:objc_getClass("UIStatusBarTimeItemView")]) {
            second = vi;
            break;
        }
    }
    
    [second removeFromSuperview];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    _statusBar.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, 20);
    _timeLabel.frame = CGRectMake(0, 40, self.contentView.bounds.size.width, 90);
    _dateLabel.frame = CGRectMake(0, 132, self.contentView.bounds.size.width, 20);
    _leftNotificationCell.frame = CGRectMake(self.contentView.bounds.size.width/2 - NOTIFICATION_CELL_WIDTH, 175, NOTIFICATION_CELL_WIDTH, NOTIFICATION_ICON_SIZE);
    _rightNotificationCell.frame = CGRectMake(self.contentView.bounds.size.width/2 + 20, 175, NOTIFICATION_CELL_WIDTH, NOTIFICATION_ICON_SIZE);
    
    // Remove time view.
    [self removeTimeView];
}

@end
