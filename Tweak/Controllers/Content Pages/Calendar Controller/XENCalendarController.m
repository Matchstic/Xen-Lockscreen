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

#import "XENCalendarController.h"
#import "XENCalendarTableViewCell.h"

#define PAGE_DOTS_OFFSET (!IS_IPAD && [XENResources calendarMode] == 2 ? 10 : 0)

@interface XENCalendarController ()

@end

@interface IS2Calendar : NSObject
+ (void)registerForCalendarNotificationsWithIdentifier:(NSString *)identifier andCallback:(void ( ^ ) ( void ))callbackBlock;
+ (void)unregisterForNotificationsWithIdentifier:(NSString *)identifier;
+ (NSArray *)calendarEntriesBetweenStartTime:(NSDate *)startTime andEndTime:(NSDate *)endTime;
@end

@interface UITableView (Private)
- (void)_setDrawsSeparatorAtTopOfSections:(BOOL)arg1;
@end

@implementation XENCalendarController

#pragma View stuff

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    self.view.clipsToBounds = YES;
    
    _viewState = 0;
    
    if (_topView) {
        [_topView removeFromSuperview];
        _topView = nil;
    }
    
    _topView = [[XENCalendarTopView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT*0.25 + 20 + PAGE_DOTS_OFFSET)];
    _topView.delegate = self;
    
    [self.view addSubview:_topView];
    
    if (_vibrancy) {
        [_vibrancy removeFromSuperview];
        _vibrancy = nil;
    }
    
    _vibrancy = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]]];
    _vibrancy.frame = CGRectMake(0, _topView.frame.origin.y + _topView.frame.size.height, SCREEN_WIDTH, SCREEN_HEIGHT*0.75 - 20 - PAGE_DOTS_OFFSET);
    if (![XENResources blurredBackground])
        _vibrancy.alpha = 0.95;
    
    [self.view addSubview:_vibrancy];
    
    if (_seperator) {
        [_seperator removeFromSuperview];
        _seperator = nil;
    }
    
    _seperator = [[XENTintedView alloc] initWithFrame:CGRectMake(0, 1, _vibrancy.bounds.size.width, 1)];
    _seperator.backgroundColor = [UIColor whiteColor];
    
    [_vibrancy.contentView addSubview:_seperator];
    
    if (_items) {
        [_items removeAllObjects];
        _items = nil;
    }
    
    _items = [[objc_getClass("IS2Calendar") calendarEntriesBetweenStartTime:[NSDate date] andEndTime:[self dateForEndOfDay:[NSDate date]]] mutableCopy];
    
    for (EKEvent *event in [_items copy]) {
        if ([[NSDate date] timeIntervalSinceDate:[event endDate]] > 0) {
            [_items removeObject:event];
        }
    }
    
    if (_tableView) {
        [_tableView removeFromSuperview];
        _tableView = nil;
    }
    
    // Things like the table view go onto the vibrancy view.
    if ([XENResources calendarMode] != 1) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _vibrancy.frame.origin.y, (IS_IPAD && [XENResources calendarMode] == 2 ? SCREEN_WIDTH/2 : SCREEN_WIDTH), _vibrancy.frame.size.height) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorColor = [UIColor clearColor];
        [_tableView registerClass:[XENCalendarTableViewCell class] forCellReuseIdentifier:@"calendarCell"];
    
        if (_noEventsLabel) {
            [_noEventsLabel removeFromSuperview];
            _noEventsLabel = nil;
        }
    
        _noEventsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        
        // Do positioning.
        if ([XENResources calendarMode] == 0) {
            _noEventsLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
        } else if ([XENResources calendarMode] == 2) {
            if (IS_IPAD) {
                _noEventsLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH/2, 30);
            } else {
                _noEventsLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
            }
        }
        
        _noEventsLabel.text = [XENResources localisedStringForKey:@"No Events" value:@"No Events"];
        _noEventsLabel.font = [UIFont systemFontOfSize:18];
        _noEventsLabel.textAlignment = NSTextAlignmentCenter;
        _noEventsLabel.textColor = [UIColor whiteColor];
        _noEventsLabel.hidden = (_items.count > 0);
    
        [_vibrancy.contentView addSubview:_noEventsLabel];
    
        [self.view addSubview:_tableView];
    }
    
    // Can now do Agenda stuff.
    if ([XENResources calendarMode] != 0) {
        _agendaTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        
        // Deal with positioning.
        if ([XENResources calendarMode] == 1) {
            // Only have Agenda.
            _agendaTableView.frame = CGRectMake(0, _vibrancy.frame.origin.y, SCREEN_WIDTH, _vibrancy.frame.size.height);
        } else if ([XENResources calendarMode] == 2 && IS_IPAD) {
            _agendaTableView.frame = CGRectMake(SCREEN_WIDTH/2, _vibrancy.frame.origin.y, SCREEN_WIDTH/2, _vibrancy.frame.size.height);
        } else if ([XENResources calendarMode] == 2) {
            _agendaTableView.frame = CGRectMake(SCREEN_WIDTH, _vibrancy.frame.origin.y, SCREEN_WIDTH, _vibrancy.frame.size.height);
        }
        
        _agendaTableView.delegate = self;
        _agendaTableView.dataSource = self;
        _agendaTableView.backgroundColor = [UIColor clearColor];
        _agendaTableView.showsVerticalScrollIndicator = NO;
        _agendaTableView.separatorColor = [UIColor clearColor];
        _agendaTableView.tag = 1;
        [_agendaTableView registerClass:[XENCalendarTableViewCell class] forCellReuseIdentifier:@"agendaCell"];
    
        // Reload Agenda items.
        [self reloadAgendaItems];
    
        [self.view addSubview:_agendaTableView];
        
        _noAgendaLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        
        // Do positioning.
        if ([XENResources calendarMode] == 1) {
            _noAgendaLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
        } else if ([XENResources calendarMode] == 2) {
            if (IS_IPAD) {
                _noAgendaLabel.frame = CGRectMake(SCREEN_WIDTH/2, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH/2, 30);
            } else {
                _noAgendaLabel.frame = CGRectMake(SCREEN_WIDTH, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
            }
        }
        
        _noAgendaLabel.text = [XENResources localisedStringForKey:@"No Upcoming Events" value:@"No Upcoming Events"];
        _noAgendaLabel.font = [UIFont systemFontOfSize:18];
        _noAgendaLabel.textAlignment = NSTextAlignmentCenter;
        _noAgendaLabel.textColor = [UIColor whiteColor];
        _noAgendaLabel.hidden = (_agendaSections.count > 0);
        
        [_vibrancy.contentView addSubview:_noAgendaLabel];
    }
    
    // Vertical seperator (iPad only)
    if (IS_IPAD && [XENResources calendarMode] == 2) {
        _verticalSeperator = [[XENTintedView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2, 1, 1, _vibrancy.frame.size.height)];
        _verticalSeperator.backgroundColor = [UIColor whiteColor];
        
        [_vibrancy.contentView addSubview:_verticalSeperator];
    }
    
    [self setupSignificantTimer];
}

-(void)setupSignificantTimer {
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [gregorian components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear) fromDate:[NSDate date]];
    NSInteger theDay = [todayComponents day];
    NSInteger theMonth = [todayComponents month];
    NSInteger theYear = [todayComponents year];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:theDay];
    [components setMonth:theMonth];
    [components setYear:theYear];
    NSDate *thisDate = [gregorian dateFromComponents:components];
    
    // now build a NSDate object for the next day
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:1];
    NSDate *nextDate = [gregorian dateByAddingComponents:offsetComponents toDate:thisDate options:0];
    
    _significantChangeTimer = [NSTimer scheduledTimerWithTimeInterval:[nextDate timeIntervalSinceDate:[NSDate date]] target:self selector:@selector(handleSignificantTimeChange:) userInfo:nil repeats:NO];
}

-(void)handleSignificantTimeChange:(id)sender {
    [_topView handleSignificantTimeChange];
    
    // Reload as appropriate
    [self switchToDate:[NSDate date]];
    
    [self setupSignificantTimer];
    
    // Reload Agenda items.
    if ([XENResources calendarMode] != 0) {
        [self reloadAgendaItems];
    }
}

-(void)topViewScrollViewMovedToOffset:(CGFloat)x {
    // Adjust the agenda and main table view locations.
    _tableView.frame = CGRectMake(-x, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height);
    _agendaTableView.frame = CGRectMake(SCREEN_WIDTH-x, _agendaTableView.frame.origin.y, _agendaTableView.frame.size.width, _agendaTableView.frame.size.height);
    _noEventsLabel.frame = CGRectMake(-x, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
    _noAgendaLabel.frame = CGRectMake(SCREEN_WIDTH-x, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
    
    if (x == 0) {
        _viewState = 0;
    } else if (x == SCREEN_WIDTH) {
        _viewState = 1;
    }
}

-(void)reloadAgendaItems {
    MutableOrderedDictionary *newItems = [MutableOrderedDictionary dictionary];
    NSMutableArray *newSections = [NSMutableArray array];
    
    // Need to get date in $days away.
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    
    // now build a NSDate object for the day in a while.
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:[XENResources calendarDaysInAdvance]-1];
    NSDate *newdate = [gregorian dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];
    
    NSMutableArray *temp = [[objc_getClass("IS2Calendar") calendarEntriesBetweenStartTime:[NSDate date] andEndTime:[self dateForEndOfDay:newdate]] mutableCopy];
    
    NSArray *dayLetters = [[NSCalendar currentCalendar] weekdaySymbols];
    
    for (EKEvent *event in [temp copy]) {
        if ([[NSDate date] timeIntervalSinceDate:[event endDate]] > 0) {
            [temp removeObject:event];
        } else {
            // Work out what day it is.
            NSDate *startdate = [event startDate];
            
            // Since we might be dealing with multi-day events, need to adjust the startdate.
            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:startdate];
            NSDateComponents *difference = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:[NSDate date]];
            
            NSInteger daysBetween = [components day] - [difference day];
            
            NSInteger offset = 0;
            if (daysBetween < 0) {
                startdate = [NSDate date];
                offset = -daysBetween- 2;
            }
            
            components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitWeekday fromDate:startdate];
            difference = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:[event endDate]];
            
            daysBetween = [difference day] - [components day];
            NSInteger count = 0;
            
            while (count <= daysBetween) {
                // Get next date, and find its components.
                components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:startdate];
                
                NSInteger index = [components weekday]-1;
                if (index < 0) index = 0;
                NSString *section = [dayLetters objectAtIndex:index];
                
                NSMutableArray *array = [[newItems objectForKey:section] mutableCopy];
                if (!array) {
                    array = [NSMutableArray array];
                }
                
                if ([event isAllDay]) {
                    [array insertObject:event atIndex:0];
                } else {
                    [array addObject:event];
                }
                [newItems setObject:array forKey:section];
                
                if (![newSections containsObject:[NSNumber numberWithInteger:[components weekday]]]) {
                    [newSections addObject:[NSNumber numberWithInteger:[components weekday]]];
                }
                
                // Job done, clean up for next pass.
                
                count++;
                
                if (count + offset > [XENResources calendarDaysInAdvance]) {
                    break;
                } else {
                    // Update date.
                    startdate = [self tomorrowForDate:startdate];
                }
            }
        }
    }
    
    if (newItems.count == 0) {
        // Well, shit. No events.
        _agendaSections = newSections;
        _agendaItems = newItems;
        
        if (_agendaSections.count == 0) {
            _noAgendaLabel.hidden = NO;
            _noAgendaLabel.alpha = 0.0;
            
            [UIView animateWithDuration:0.3 animations:^{
                _noAgendaLabel.alpha = 1.0;
            }];
        }
        
        return;
    }
    
    // XXX: Don't forget, Sunday is ALWAYS classed as day 0 of the week.
    
    // At this point, we order the sections.
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:[NSDate date]];
    NSInteger todayWeekday = [today weekday];
    
    // Order by merge sort, and then cut-paste the numbers before the current weekday.
    newSections = [[self mergeSort:newSections] mutableCopy];
    
    int index = (int)[newSections indexOfObject:[NSNumber numberWithInteger:todayWeekday]];
    int count = 0;
    for (NSNumber *num in [newSections copy]) {
        if (count >= index) break;
        
        [newSections removeObjectAtIndex:count];
        [newSections addObject:num]; // Drop at end.
        
        count++;
    }
    
    // Then, we can assign strings to the dates as we go through.
    for (NSNumber *num in [newSections copy]) {
        NSInteger index = [num integerValue]-1;
        if (index < 0) index = 0;
        NSString *section = [dayLetters objectAtIndex:index];
        
        [newSections replaceObjectAtIndex:[newSections indexOfObject:num] withObject:section];
    }
    
    // Happy days!
    
    if (_agendaSections.count > 0) {
        [UIView animateWithDuration:0.3 animations:^{
            _noAgendaLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            _noAgendaLabel.hidden = YES;
        }];
    }
    
    _agendaItems = newItems;
    _agendaSections = newSections;
    [_agendaTableView reloadData];
    
    [self setupAgendaTimer];
}

- (NSArray *)mergeSort:(NSArray *)array {
    
    if (array.count == 1) {
        return array;
    }
    
    // Split array in two
    NSInteger firstHalfCount = array.count/2;
    NSInteger secondHalfCount = array.count - firstHalfCount;
    NSArray *arrayOne = [array subarrayWithRange:NSMakeRange(0, firstHalfCount)];
    NSArray *arrayTwo = [array subarrayWithRange:NSMakeRange(firstHalfCount, secondHalfCount)];
    
    // Recursively split until we have one element in each
    NSArray *sortedFirst = [self mergeSort:arrayOne];
    NSArray *sortedSecond = [self mergeSort:arrayTwo];
    
    // Merge together
    NSArray *merged = [self mergeFirstArray:sortedFirst withSecondArray:sortedSecond];
    
    // Return merged
    return merged;
}

- (NSArray *)mergeFirstArray:(NSArray *)firstArray withSecondArray:(NSArray *)secondArray {
    
    NSMutableArray *mergedArray = [NSMutableArray array];
    
    NSInteger firstIndex = 0;
    NSInteger secondIndex = 0;
    
    // Merge elements
    while (firstIndex < firstArray.count && secondIndex < secondArray.count) {
        // Merge
        NSNumber *firstItem = firstArray[firstIndex];
        NSNumber *secondItem = secondArray[secondIndex];
        if (firstItem.integerValue < secondItem.integerValue) {
            [mergedArray addObject:firstItem];
            firstIndex++;
        } else {
            [mergedArray addObject:secondItem];
            secondIndex++;
        }
    }
    
    // Add any elements left over (they will already be sorted)
    while (firstIndex < firstArray.count) {
        [mergedArray addObject:firstArray[firstIndex]];
        firstIndex++;
    }
    
    // Add any elements left over (they will already be sorted)
    while (secondIndex < secondArray.count) {
        [mergedArray addObject:secondArray[secondIndex]];
        secondIndex++;
    }
    
    return mergedArray;
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

-(NSDate*)dateForEndOfDay:(NSDate*)date {
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
    [components setHour:23];
    [components setMinute:59];
    return [gregorian dateFromComponents:components];
}

-(void)setupEventTimer {
    [_nextEventTimer invalidate];
    _nextEventTimer = nil;
    
    for (EKEvent *event in _items) {
        if (![event isAllDay]) {
            NSTimeInterval interval = [[event endDate] timeIntervalSinceDate:[NSDate date]];
            
            _nextEventTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(handleNextEventTimer:) userInfo:nil repeats:NO];
            _nextExpiringEvent = event;
            
            break;
        }
    }
}

-(void)handleNextEventTimer:(id)sender {
    // Which event just expired?
    int index = (int)[_items indexOfObject:_nextExpiringEvent];
    
    [_tableView beginUpdates];
    [_items removeObjectAtIndex:index];
    [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    [_tableView endUpdates];
    
    [self setupEventTimer];
}

-(void)setupAgendaTimer {
    [_nextAgendaTimer invalidate];
    _nextAgendaTimer = nil;
    
    if (_agendaItems.count == 0) {
        return; // No point doing anything.
    }
    
    // Find event with earliest endDate.
    EKEvent *event1 = nil;
    NSDate *earliest = nil;
    NSString *section = nil;
    
    for (NSString *sec in _agendaSections) {
        for (EKEvent *event in [_agendaItems  objectForKey:sec]) {
            if (![event isAllDay]) {
                if (earliest) {
                    NSTimeInterval interval = [[event endDate] timeIntervalSinceDate:earliest];
                    if (interval < 0) {
                        earliest = [event endDate];
                        event1 = event;
                        section = sec;
                    }
                } else {
                    earliest = [event endDate];
                    event1 = event;
                    section = sec;
                }
            }
        }
    }
    
    NSTimeInterval interval = [earliest timeIntervalSinceDate:[NSDate date]];
    
    _nextAgendaTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(handleNextAgendaTimer:) userInfo:nil repeats:NO];
    _nextExpiringAgenda = event1;
    _nextAgendaSection = section;
}

-(void)handleNextAgendaTimer:(id)sender {
    // Which event just expired?
    NSUInteger section = [_agendaSections indexOfObject:_nextAgendaSection];
    NSUInteger row = [[_agendaItems objectForKey:_nextAgendaSection] indexOfObject:_nextExpiringAgenda];
    
    if (!_agendaTableView || self._debugIsReset || section != NSNotFound || row != NSNotFound) {
        return; // DO NOTHING FOR CRYING OUT LOUD.
    }
    
    @try {
        [_agendaTableView beginUpdates];
    
        NSMutableArray *array = [[_agendaItems objectForKey:_nextAgendaSection] mutableCopy];
        if (!array) {
            array = [NSMutableArray array];
        }
    
        [array removeObject:_nextExpiringAgenda];
        if (array && _nextAgendaSection)
            [_agendaItems setObject:array forKey:_nextAgendaSection];
    
        if (array.count == 0) {
            [_agendaSections removeObject:_nextAgendaSection];
        }
    
        [_agendaTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:section]] withRowAnimation:UITableViewRowAnimationTop];
        [_agendaTableView endUpdates];
    } @catch (NSException *e) {
        // WTF. Just reload data.
        [_agendaTableView reloadData];
    }
    
    [self setupAgendaTimer];
}

#pragma mark XENCalendarTopViewDelegate

-(void)switchToDate:(NSDate *)date {
    // Switch table view out to this date.
    NSMutableArray *newPaths = [NSMutableArray array];
    int oldCount = (int)_items.count;
    
    NSMutableArray *newItems = [[objc_getClass("IS2Calendar") calendarEntriesBetweenStartTime:date andEndTime:[self dateForEndOfDay:date]] mutableCopy];
    
    for (EKEvent *event in [newItems copy]) {
        if ([[NSDate date] timeIntervalSinceDate:[event endDate]] > 0) {
            [newItems removeObject:event];
        }
    }
    
    for (int i = 0; i < newItems.count; i++) {
        [newPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    NSMutableArray *oldpaths = [NSMutableArray array];
    for (int i = 0; i < _items.count; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        
        if (![newItems containsObject:path]) {
            [oldpaths addObject:path];
        }
    }
    
    [_tableView beginUpdates];
    _items = newItems;
    [_tableView deleteRowsAtIndexPaths:oldpaths withRowAnimation:UITableViewRowAnimationTop];
    [_tableView insertRowsAtIndexPaths:newPaths withRowAnimation:UITableViewRowAnimationTop];
    [_tableView endUpdates];
    
    if (_items.count == 0 && oldCount != 0) {
        _noEventsLabel.hidden = NO;
        _noEventsLabel.alpha = 0.0;
        
        [UIView animateWithDuration:0.3 animations:^{
            _noEventsLabel.alpha = 1.0;
        }];
    } else if (oldCount == 0 && _items.count > 0) {
        [UIView animateWithDuration:0.3 animations:^{
            _noEventsLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            _noEventsLabel.hidden = YES;
        }];
    }
    
    [self setupEventTimer];
}

#pragma mark UITableView delegate

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1) {
        XENCalendarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"agendaCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[XENCalendarTableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"agendaCell"];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        
        // Adjust.
        NSString *section = _agendaSections[indexPath.section];
        [cell setupWithEvent:[_agendaItems objectForKey:section][indexPath.row]];
        
        [cell showSeparator:indexPath.row+1 != [[_agendaItems objectForKey:section] count]];
        
        return cell;
    } else {
        XENCalendarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"calendarCell" forIndexPath:indexPath];
        if (!cell) {
            cell = [[XENCalendarTableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"calendarCell"];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        [cell setupWithEvent:_items[indexPath.row]];
        
        [cell showSeparator:indexPath.row+1 != _items.count];
        
        return cell;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView.tag == 1) {
        return [_agendaItems allKeys].count;
    } else {
        return 1;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 1) {
        NSString *sec = _agendaSections[section];
        return [[_agendaItems objectForKey:sec] count];
    } else {
        return _items.count;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 1) {
        return UITableViewAutomaticDimension;
    } else {
        return 0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView.tag == 1) {
        return UITableViewAutomaticDimension;
    } else {
        return 0.01f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView.tag == 1) {
        return [UIView new];
    } else {
        return [UIView new];
    }
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 1) {
        return _agendaSections[section];
    } else {
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1) {
        return CAL_CELL_HEIGHT;
    } else {
        return CAL_CELL_HEIGHT;
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1) {
        return CAL_CELL_HEIGHT;
    } else {
        return CAL_CELL_HEIGHT;
    }
}

#pragma mark Inherited stuff

-(BOOL)wantsBlurredBackground {
    return YES;
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.calendar";
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"Calendar" value:@"Calendar"];
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(void)rotateToOrientation:(int)orient {
    _topView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT*0.25 + 20 + PAGE_DOTS_OFFSET);
    _vibrancy.frame = CGRectMake(0, _topView.frame.origin.y + _topView.frame.size.height, SCREEN_WIDTH, SCREEN_HEIGHT*0.75 - 20 - PAGE_DOTS_OFFSET);
    
    _tableView.frame = CGRectMake(0, _vibrancy.frame.origin.y, (IS_IPAD && [XENResources calendarMode] == 2 ? SCREEN_WIDTH/2 : SCREEN_WIDTH), _vibrancy.frame.size.height);
    _seperator.frame = CGRectMake(0, 1, _vibrancy.bounds.size.width, 1);
    
    if ([XENResources calendarMode] == 0) {
        _noEventsLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
    } else if ([XENResources calendarMode] == 2) {
        if (IS_IPAD) {
            _noEventsLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH/2, 30);
        } else if (_viewState == 1) {
            _noEventsLabel.frame = CGRectMake(-SCREEN_WIDTH, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
        } else {
            _noEventsLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
        }
    }
    
    // Do positioning.
    if ([XENResources calendarMode] == 1) {
        _noAgendaLabel.frame = CGRectMake(0, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
    } else if ([XENResources calendarMode] == 2) {
        if (IS_IPAD) {
            _noAgendaLabel.frame = CGRectMake(SCREEN_WIDTH/2, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH/2, 30);
        } else {
            _noAgendaLabel.frame = CGRectMake(SCREEN_WIDTH, _vibrancy.bounds.size.height/2 - 15, SCREEN_WIDTH, 30);
        }
    }
    
    // Deal with positioning.
    if ([XENResources calendarMode] == 1) {
        // Only have Agenda.
        _agendaTableView.frame = CGRectMake(0, _vibrancy.frame.origin.y, SCREEN_WIDTH, _vibrancy.frame.size.height);
    } else if ([XENResources calendarMode] == 2 && IS_IPAD) {
        _agendaTableView.frame = CGRectMake(SCREEN_WIDTH/2, _vibrancy.frame.origin.y, SCREEN_WIDTH/2, _vibrancy.frame.size.height);
    } else if ([XENResources calendarMode] == 2) {
        if (_viewState == 1) {
            _agendaTableView.frame = CGRectMake(0, _vibrancy.frame.origin.y, SCREEN_WIDTH, _vibrancy.frame.size.height);
            _tableView.frame = CGRectMake(-SCREEN_WIDTH, _vibrancy.frame.origin.y, SCREEN_WIDTH, _vibrancy.frame.size.height);
        } else {
            _agendaTableView.frame = CGRectMake(SCREEN_WIDTH, _vibrancy.frame.origin.y, SCREEN_WIDTH, _vibrancy.frame.size.height);
            _tableView.frame = CGRectMake(0, _vibrancy.frame.origin.y, SCREEN_WIDTH, _vibrancy.frame.size.height);
        }
    }
    
    // iPad only.
    if ([XENResources calendarMode] == 2) {
        _verticalSeperator.frame = CGRectMake(SCREEN_WIDTH/2, 1, 1, _vibrancy.frame.size.height);
    }
    
}

-(void)resetForScreenOff {
    
}

-(void)resetViewForUnlock {
    [_significantChangeTimer invalidate];
    _significantChangeTimer = nil;
    
    [_nextEventTimer invalidate];
    _nextEventTimer = nil;
    
    [_nextAgendaTimer invalidate];
    _nextAgendaTimer = nil;
    
    [_topView removeFromSuperview];
    _topView = nil;
    
    [_vibrancy removeFromSuperview];
    _vibrancy = nil;
    
    [_seperator removeFromSuperview];
    _seperator = nil;
    
    [_tableView removeFromSuperview];
    _tableView = nil;
    
    [_agendaTableView removeFromSuperview];
    _agendaTableView = nil;
    
    [_noEventsLabel removeFromSuperview];
    _noEventsLabel = nil;
    
    [_noAgendaLabel removeFromSuperview];
    _noAgendaLabel = nil;
    
    [_verticalSeperator removeFromSuperview];
    _verticalSeperator = nil;
    
    [_items removeAllObjects];
    _items = nil;
    
    [_agendaItems removeAllObjects];
    _agendaItems = nil;
    
    [_agendaSections removeAllObjects];
    _agendaSections = nil;
    
    _nextExpiringEvent = nil;
    
    [super resetViewForUnlock];
}

-(void)dealloc {
    if (self.isViewLoaded)
        for (UIView *view in self.view.subviews) {
            [view removeFromSuperview];
        }
    
    [_significantChangeTimer invalidate];
    _significantChangeTimer = nil;
    
    [_nextEventTimer invalidate];
    _nextEventTimer = nil;
    
    [_nextAgendaTimer invalidate];
    _nextAgendaTimer = nil;
}

#pragma mark UINavigation shit

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
