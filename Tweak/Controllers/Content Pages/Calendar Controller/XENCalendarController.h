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

#import "XENBaseViewController.h"
#import "XENCalendarTopView.h"
#import "XENTintedView.h"
#import "OrderedDictionary.h"

@interface XENCalendarController : XENBaseViewController <XENCalendarTopViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    XENCalendarTopView *_topView;
    NSTimer *_nextEventTimer;
    NSTimer *_significantChangeTimer;
    UIVisualEffectView *_vibrancy;
    XENTintedView *_seperator;
    UITableView *_tableView;
    NSMutableArray *_items;
    UILabel *_noEventsLabel;
    
    id _nextExpiringEvent;
    id _nextExpiringAgenda;
    NSString *_nextAgendaSection;
    
    // iPad only, kinda.
    UITableView *_agendaTableView;
    MutableOrderedDictionary *_agendaItems;
    NSMutableArray *_agendaSections;
    UIView *_verticalSeperator;
    UILabel *_noAgendaLabel;
    NSTimer *_nextAgendaTimer;
    int _viewState;
}

-(void)resetViewForUnlock;

@end
