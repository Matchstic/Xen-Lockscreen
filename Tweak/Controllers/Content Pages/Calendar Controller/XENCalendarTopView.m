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

#import "XENCalendarTopView.h"

@implementation XENCalendarTopView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _cells = [NSMutableArray array];
        
        NSDate *date = [NSDate date];
        for (int i = 0; i < [XENResources calendarDaysInAdvance]; i++) {
            XENCalendarTopViewCell *cell = [[XENCalendarTopViewCell alloc] initWithFrame:CGRectZero];
            cell.delegate = self;
            
            [cell setupWithDate:date];
            date = [self tomorrowForDate:date];
            cell.tag = i;
            
            [_cells addObject:cell];
            
            if ([XENResources calendarMode] == 1) {
                cell.alpha = 0.5;
            }
            
            [self addSubview:cell];
        }
        
        _currentlySelectedCell = 0;
        
        if (IS_IPAD) {
            _redCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CELL_HEIGHT, CELL_HEIGHT)];
            _redCircle.layer.cornerRadius = CELL_HEIGHT/2;
        } else {
            _redCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CELL_WIDTH, CELL_WIDTH)];
            _redCircle.layer.cornerRadius = CELL_WIDTH/2;
        }
        
        _redCircle.backgroundColor = [UIColor colorWithRed:1.0 green:0.19 blue:0.19 alpha:1.0]; // TODO: Correct this,
        if ([XENResources calendarMode] == 1) {
            _redCircle.hidden = YES;
        }
        
        [self insertSubview:_redCircle atIndex:0];
        
        _dayText = [[UILabel alloc] initWithFrame:CGRectZero];
        _dayText.font = [UIFont systemFontOfSize:(IS_IPAD ? 22 : 18)];
        _dayText.text = @"";
        _dayText.textAlignment = NSTextAlignmentCenter;
        _dayText.textColor = [UIColor whiteColor];
        
        [self addSubview:_dayText];
        
        if ([XENResources calendarMode] != 0) {
            _agendaText = [[UILabel alloc] initWithFrame:CGRectZero];
            _agendaText.font = _dayText.font;
            _agendaText.text = [XENResources localisedStringForKey:@"Agenda" value:@"Agenda"];
            _agendaText.textAlignment = NSTextAlignmentCenter;
            _agendaText.textColor = [UIColor whiteColor];
        
            [self addSubview:_agendaText];
        }
        
        if ([XENResources calendarMode] == 2 && !IS_IPAD) {
            // Need the scroll view to switch between Agenda and Per Day.
            _tableScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
            _tableScrollView.delegate = self;
            _tableScrollView.showsHorizontalScrollIndicator = NO;
            _tableScrollView.backgroundColor = [UIColor clearColor];
            _tableScrollView.pagingEnabled = YES;
            
            [self addSubview:_tableScrollView];
            
            [_tableScrollView addSubview:_agendaText];
            [_tableScrollView addSubview:_dayText];
            
            // Also need the page indicators.
            _dotsView = [[UIPageControl alloc] initWithFrame:CGRectZero];
            _dotsView.numberOfPages = 2;
            _dotsView.currentPage = 0;
            _dotsView.backgroundColor = [UIColor clearColor];
            _dotsView.alpha = 0.5;
            _dotsView.userInteractionEnabled = NO;
            
            [self addSubview:_dotsView];
            
            // Setup for default page.
            _page = 0;
        }
        
        [self updateTodayTextWithDate:[NSDate date]];
        [self didTapCellWithTag:0];
    }
    
    return self;
}

-(void)handleSignificantTimeChange {
    NSDate *date = [NSDate date];
    
    for (XENCalendarTopViewCell *cell in _cells) {
        [cell setupWithDate:date];
        date = [self tomorrowForDate:date];
    }
    
    // Handle red circle
    _currentlySelectedCell -= 1;
    if (_currentlySelectedCell < 0) _currentlySelectedCell = 0;
    
    [UIView animateWithDuration:0.15 animations:^{
        _redCircle.center = [self redCircleCenterForTag:_currentlySelectedCell];
    }];
    
    // Update today text
    XENCalendarTopViewCell *cell = [_cells objectAtIndex:_currentlySelectedCell];
    [self updateTodayTextWithDate:cell.date];
}

-(void)updateTodayTextWithDate:(NSDate*)date {
    NSDateFormatter *_dateFormatter = [XENResources sharedDateFormatter];
    _dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEEdMMMM" options:0 locale:[NSLocale currentLocale]];
    
    _dayText.text = [_dateFormatter stringFromDate:date];
    [self setNeedsLayout];
}

-(NSDate*)tomorrowForDate:(NSDate*)date {
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [gregorian components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:date];
    NSInteger theDay = [todayComponents day];
    NSInteger theMonth = [todayComponents month];
    NSInteger theYear = [todayComponents year];
    
    // now build a NSDate object for yourDate using these components
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:theDay];
    [components setMonth:theMonth];
    [components setYear:theYear];
    NSDate *thisDate = [gregorian dateFromComponents:components];
    
    // now build a NSDate object for the next day
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    return [gregorian dateByAddingComponents:offsetComponents toDate:thisDate options:0];
}

-(CGPoint)redCircleCenterForTag:(int)tag {
    XENCalendarTopViewCell *cell = [_cells objectAtIndex:tag];
    
    if (IS_IPAD) {
        return [cell convertPoint:CGPointMake(CELL_HEIGHT/2, CELL_HEIGHT/2) toView:self];
    } else {
        return [cell convertPoint:CGPointMake(cell.frame.size.width/2, CELL_WIDTH) toView:self];
    }
}

-(void)didTapCellWithTag:(NSInteger)tag {
    if (_currentlySelectedCell == tag) {
        // No need to change anything!
        return;
    }
    
    _currentlySelectedCell = (int)tag;
    XENCalendarTopViewCell *cell = [_cells objectAtIndex:tag];
    
    // Move red circle.
    [UIView animateWithDuration:0.15 animations:^{
        _redCircle.center = [self redCircleCenterForTag:_currentlySelectedCell];
    }];
    
    // Handle updating main scroll view in delegate.
    NSDate *date = cell.date;
    [self.delegate switchToDate:date];
    [self updateTodayTextWithDate:date];
}

-(void)reset {
    _redCircle.center = [self redCircleCenterForTag:_currentlySelectedCell];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout cells correctly, and also red circle.
    int count = (int)_cells.count;
    
    CGFloat width = 0;
    
    CGFloat cellwidths = CELL_WIDTH * count;
    CGFloat margin = (self.bounds.size.width - cellwidths) / (count+1);
    
    width += margin;
    
    // Work out margin from top, need to layout day text first.
    CGRect rect = [XENResources boundedRectForFont:_dayText.font andText:_dayText.text width:self.bounds.size.width];
    
    CGFloat marginTop = (self.bounds.size.height - (CELL_HEIGHT + 20 + rect.size.height + 5))/2 + 20;
    
    for (XENCalendarTopViewCell *cell in _cells) {
        cell.frame = CGRectMake(width, marginTop, CELL_WIDTH, CELL_HEIGHT);
        width += margin + CELL_WIDTH;
    }
    
    // We get SCREEN_HEIGHT*0.25 + 20 for our bounds.
    // Will come in as the usual value.
    // Calculate a nice centering for the text.
    
    CGFloat marginText = self.bounds.size.height - marginTop - CELL_HEIGHT - 10;
    marginText /= 2;
    marginText -= rect.size.height+5;
    marginText += marginTop + CELL_HEIGHT + 10;
    
    _dayText.frame = CGRectMake(0, marginText, self.bounds.size.width, rect.size.height+5);
    _tableScrollView.frame = CGRectMake(0, marginText, self.bounds.size.width, rect.size.height+5);
    _tableScrollView.contentSize = CGSizeMake(self.bounds.size.width*2, rect.size.height+5);
    [_tableScrollView setContentOffset:CGPointMake(_page == 0 ? 0 : self.bounds.size.width, 0) animated:NO];
    _dotsView.frame = CGRectMake(0, self.bounds.size.height - 15, self.bounds.size.width, 10);
    [_dotsView setCurrentPage:_page];
    
    _redCircle.center = [self redCircleCenterForTag:_currentlySelectedCell];
    
    // Configure everything as needed for the different calendar modes that are possible
    switch ([XENResources calendarMode]) {
        case 0:
            // per day
            _agendaText.hidden = YES;
            break;
        case 1:
            // agenda
            _dayText.hidden = YES;
            _agendaText.frame = _dayText.frame;
            break;
        case 2:
            // combined
            if (IS_IPAD) {
                _dayText.frame = CGRectMake(0, marginText, self.bounds.size.width/2, rect.size.height+5);
                _agendaText.frame = CGRectMake(self.bounds.size.width/2, marginText, self.bounds.size.width/2, rect.size.height+5);
            } else {
                _agendaText.frame = CGRectMake(self.bounds.size.width, 0, self.bounds.size.width, rect.size.height+5);
                _dayText.frame = CGRectMake(0, 0, self.bounds.size.width, rect.size.height+5);
            }
            break;
            
        default:
            break;
    }
    
    [self setNeedsDisplay];
}

-(void)dealloc {
    for (XENCalendarTopViewCell *cell in _cells) {
        [cell removeFromSuperview];
    }
    
    [_cells removeAllObjects];
    _cells = nil;
    
    _currentlySelectedCell = nil;
    
    [_redCircle removeFromSuperview];
    _redCircle = nil;
    
    [_dayText removeFromSuperview];
    _dayText = nil;
}

#pragma mark UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentX = scrollView.contentOffset.x;
    
    [self.delegate topViewScrollViewMovedToOffset:contentX];
    
    // Also, need to update the page dots.
    
    // We're going between 0 and SCREEN_WIDTH for x.
    CGFloat alpha = contentX/scrollView.frame.size.width;
    alpha = 1.0 - alpha; // Need it inverted.
    
    _redCircle.alpha = alpha; // This can go fully transparent
    
    if (alpha < 0.35) {
        alpha = 0.35;
    }
    
    for (XENCalendarTopViewCell *cell in _cells) {
        [cell setAlpha:alpha];
    }
    
    if (contentX == 0) {
        for (XENCalendarTopViewCell *cell in _cells) {
            cell.userInteractionEnabled = YES;
        }
        
        [_dotsView setCurrentPage:0];
        _page = 0;
    } else if (contentX == scrollView.frame.size.width) {
        for (XENCalendarTopViewCell *cell in _cells) {
            cell.userInteractionEnabled = NO;
        }
        
        [_dotsView setCurrentPage:1];
        _page = 1;
    }
}

@end
