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

#import "XENCalendarTopViewCell.h"

@implementation XENCalendarTopViewCell

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, CELL_WIDTH, CELL_HEIGHT)];
    
    if (self) {
        // Initialise labels
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.backgroundColor = [UIColor clearColor];
        _button.frame = CGRectMake(0, 20, CELL_WIDTH, CELL_WIDTH);
        
        [_button addTarget:self action:@selector(buttonDidTap:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_button];
        
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CELL_WIDTH, CELL_WIDTH)];
        _numberLabel.font = [UIFont systemFontOfSize:(IS_IPAD ? 25 : 20)];
        _numberLabel.textColor = [UIColor whiteColor];
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        _numberLabel.userInteractionEnabled = NO;
        
        [_button addSubview:_numberLabel];
        
        _dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CELL_WIDTH, 25)];
        _dayLabel.font = [UIFont systemFontOfSize:(IS_IPAD ? 20 : 10) weight:UIFontWeightLight];
        _dayLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        if (IS_IPAD)
            _dayLabel.textAlignment = NSTextAlignmentLeft;
        else
            _dayLabel.textAlignment = NSTextAlignmentCenter;
        _dayLabel.userInteractionEnabled = NO;
        
        [self addSubview:_dayLabel];
        
        // handle for if is iPad.
        [self configureFramesForIpad];
    }
    
    return self;
}

-(void)setupWithDate:(NSDate*)date {
    // Set values to labels.
    self.date = date;
    
    if (IS_IPAD) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:date];
        NSArray *dayLetters = [[NSCalendar currentCalendar] shortWeekdaySymbols];
        NSInteger dayNumber = [components day];
        
        _numberLabel.text = [NSString stringWithFormat:@"%ld", (long)dayNumber];
        _dayLabel.text = [dayLetters objectAtIndex:[components weekday]-1];
    } else {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:date];
        NSArray *dayLetters = [[NSCalendar currentCalendar] veryShortWeekdaySymbols];
        NSInteger dayNumber = [components day];
    
        _numberLabel.text = [NSString stringWithFormat:@"%ld", (long)dayNumber];
        _dayLabel.text = [dayLetters objectAtIndex:[components weekday]-1];
    }
    
    CGRect rect = [XENResources boundedRectForFont:_dayLabel.font andText:_dayLabel.text width:self.bounds.size.width];
    _dayLabel.frame = CGRectMake(0, 0, self.bounds.size.width, rect.size.height+2);
    
    // Handle for if iPad.
    [self configureFramesForIpad];
}

-(void)setAlpha:(CGFloat)alpha {
    _numberLabel.alpha = alpha;
}

-(void)configureFramesForIpad {
    if (!IS_IPAD) {
        return;
    }
    
    CGFloat maxDayWidth = CELL_HEIGHT + 5;
    _dayLabel.frame = CGRectMake(maxDayWidth, 0, CELL_WIDTH - maxDayWidth, CELL_HEIGHT);
    _button.frame = CGRectMake(0, 0, CELL_WIDTH, CELL_HEIGHT);
    _numberLabel.frame = CGRectMake(0, 0, CELL_HEIGHT, CELL_HEIGHT);
    
    [_button addSubview:_dayLabel];
}

-(void)buttonDidTap:(id)sender {
    [self.delegate didTapCellWithTag:self.tag];
}

-(void)dealloc {
    self.date = nil;
    
    [_button removeFromSuperview];
    _button = nil;
    
    [_numberLabel removeFromSuperview];
    _numberLabel = nil;
    
    [_dayLabel removeFromSuperview];
    _dayLabel = nil;
}

@end
