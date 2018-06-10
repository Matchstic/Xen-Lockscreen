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

#import "XENCalendarTableViewCell.h"

@implementation XENCalendarTableViewCell

-(void)initialiseIfNeeded {
    if (!_effectView) {
        _effectView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]]];
        
        [self.contentView addSubview:_effectView];
    }
    
    if (!_timeStart) {
        _timeStart = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeStart.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        _timeStart.text = @"";
        _timeStart.textAlignment = NSTextAlignmentCenter;
        _timeStart.textColor = [UIColor whiteColor];
        
        [self.contentView addSubview:_timeStart];
    }
    
    if (!_timeEnd) {
        _timeEnd = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeEnd.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        _timeEnd.text = @"";
        _timeEnd.textAlignment = NSTextAlignmentCenter;
        _timeEnd.textColor = [UIColor whiteColor];
        
        [_effectView.contentView addSubview:_timeEnd];
    }
    
    if (!_colour) {
        if ([XENResources calendarShowColours]) {
            _colour = [[UIView alloc] initWithFrame:CGRectZero];
            [self.contentView addSubview:_colour];
        } else {
            _colour = [[XENTintedView alloc] initWithFrame:CGRectZero];
            [_effectView.contentView addSubview:_colour];
        }
    }
    
    if (!_eventTitle) {
        _eventTitle = [[UILabel alloc] initWithFrame:CGRectZero];
        _eventTitle.font = [UIFont systemFontOfSize:15];
        _eventTitle.text = @"";
        _eventTitle.textAlignment = NSTextAlignmentLeft;
        _eventTitle.textColor = [UIColor whiteColor];
        _eventTitle.numberOfLines = 1;
        
        [self.contentView addSubview:_eventTitle];
    }
    
    if (!_location) {
        _location = [[UILabel alloc] initWithFrame:CGRectZero];
        _location.font = [UIFont systemFontOfSize:15];
        _location.text = @"";
        _location.textAlignment = NSTextAlignmentLeft;
        _location.textColor = [UIColor whiteColor];
        _location.numberOfLines = 1;
        
        [_effectView.contentView addSubview:_location];
    }
    
    if (!_separator) {
        _separator = [[XENTintedView alloc] initWithFrame:CGRectZero];
        
        [_effectView.contentView addSubview:_separator];
    }
}

-(NSString*)formattedTextFromDate:(NSDate*)date {
    NSDateFormatter *formatter = [XENResources sharedDateFormatter];
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    BOOL is24Hour = amRange.location == NSNotFound && pmRange.location == NSNotFound;
    
    if (is24Hour) {
        formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"HH:mm" options:0 locale:[NSLocale currentLocale]];
    } else {
        formatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hh:mm" options:0 locale:[NSLocale currentLocale]];
    }
    
    return [formatter stringFromDate:date];
}

-(void)setupWithEvent:(EKEvent *)event {
    [self initialiseIfNeeded];
    
    _eventTitle.text = [event title];
    _location.text = [event location];
    
    // We also MUST take into account the days these events are on, as cells will be re-used in
    // the Agenda UI too.
    
    if (event.isAllDay) {
        _timeStart.text = [XENResources localisedStringForKey:@"all-day" value:@"all-day"];
        _timeEnd.text = @"";
    } else {
        // Correctly render text.
        _timeStart.text = [self formattedTextFromDate:[event startDate]];
        _timeEnd.text = [self formattedTextFromDate:[event endDate]];
    }
    
    self.endDate = [event endDate];
    
    if ([XENResources calendarShowColours])
        _colour.backgroundColor = [UIColor colorWithCGColor:[event calendar].CGColor];
}

-(void)showSeparator:(BOOL)show {
    _separator.hidden = !show;
}

-(void)layoutSubviews {
    CGFloat leftInset = 0;
    CGFloat width = SCREEN_WIDTH;
    
    if (IS_IPAD && orient3 > 2 && [XENResources calendarMode] != 2) {
        leftInset = SCREEN_WIDTH * 0.125;
        width = SCREEN_WIDTH * 0.75;
    }
    
    _effectView.frame = CGRectMake(0, 0, SCREEN_WIDTH, CAL_CELL_HEIGHT);
    
    CGFloat timeMargin = 0;
    
    timeMargin += 12.5 + (![_timeEnd.text isEqualToString:@""] ? 17.5 : 0);
    timeMargin = (CAL_CELL_HEIGHT/2)-(timeMargin/2);
    
    CGRect one = [XENResources boundedRectForFont:_timeStart.font andText:_timeStart.text width:80];
    CGRect two = [XENResources boundedRectForFont:_timeEnd.font andText:_timeEnd.text width:80];
    
    CGFloat timeWidth = (one.size.width > two.size.width ? one.size.width : two.size.width);
    CGRect alldayWidth = [XENResources boundedRectForFont:_timeEnd.font andText:[XENResources localisedStringForKey:@"all-day" value:@"all-day"] width:80];
    alldayWidth.size.width += 2;
    timeWidth = (alldayWidth.size.width > timeWidth ? alldayWidth.size.width : timeWidth);
    
    _timeStart.frame = CGRectMake(20 + leftInset, timeMargin, timeWidth, 12.5);
    _timeEnd.frame = CGRectMake(20 + leftInset, timeMargin+12.5 + 5, timeWidth, 12.5);
    
    _colour.frame = CGRectMake(20+timeWidth+10 + leftInset, 5, 1, CAL_CELL_HEIGHT-10);
    
    // Handle other text heights
    CGFloat eventMargin = 0;
    CGFloat eventTextHeight = 17;
    eventMargin += eventTextHeight + (![_location.text isEqualToString:@""] ? eventTextHeight+5 : 0);
    eventMargin = (CAL_CELL_HEIGHT/2)-(eventMargin/2);
    
    _eventTitle.frame = CGRectMake(_colour.frame.origin.x + 11, eventMargin, width - _colour.frame.origin.x - 5 - 20, eventTextHeight);
    _location.frame = CGRectMake(_eventTitle.frame.origin.x, _eventTitle.frame.origin.y+_eventTitle.frame.size.height+5, _eventTitle.frame.size.width, _eventTitle.frame.size.height);
    
    _separator.frame = CGRectMake(20 + leftInset, _effectView.bounds.size.height-2, width-20, 1);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    // Do nothing!
}

-(void)dealloc {
    self.endDate = nil;
    
    [_eventTitle removeFromSuperview];
    _eventTitle = nil;
    
    [_location removeFromSuperview];
    _location = nil;
    
    [_timeStart removeFromSuperview];
    _timeStart = nil;
    
    [_timeEnd removeFromSuperview];
    _timeEnd = nil;
    
    [_colour removeFromSuperview];
    _colour = nil;
    
    [_effectView removeFromSuperview];
    _effectView = nil;
    
    [_separator removeFromSuperview];
    _separator = nil;
}

@end
