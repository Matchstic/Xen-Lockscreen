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
#import "XENWidgetCell.h"

#warning Private methods used here; BCBatteryDeviceController, NCDataSourceManager, SBWidgetRowInfo, SBWidgetViewControllerDelegate, SBNotificationCenterController

// In theory, works up to 9.3.3

@interface SBTodayViewController : UIViewController
- (void)hostDidDismiss;
- (void)hostDidPresent;
- (void)hostWillDismiss;
- (void)hostWillPresent;
- (void)_enableWidgetsWithIdentifiers:(id)identifiers completion:(id)completion;
- (id)_orderedEnabledInterfaceItems;
@end

@interface SBNotificationCenterLayoutViewController : UIViewController
@property(assign, nonatomic) id<SBWidgetViewControllerDelegate> widgetDelegate;
- (id)initForNotificationCenterLayoutMode:(int)notificationCenterLayoutMode;
- (SBTodayViewController*)_todayViewControllerCreateIfNecessary:(BOOL)necessary;
- (void)_repopulateWidgetHandlingViewController:(SBTodayViewController*)controller;
-(NSMutableDictionary *)xen_identifiersToDatums;
@end

@interface XENWidgetsViewController : XENBaseViewController <SBWidgetViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, XENWidgetCellDelegate> {
    UITableView *_tableView;
    NSMutableArray *_dataSource; // Ordered array of the enabled items
    NSMutableArray *_actualDataSource; // Ordered array of enabled items with content
    NSMutableArray *_preOrderedDatums; // All possible items
    NSMutableDictionary *_identifiersToInfos;
    
    id _cancelHitWidgetTouchesAssertion;
    
    NSTimer *_hackRetryTimer;
    time_t _retryStart;
    
    BOOL _noWidgets;
    UIVisualEffectView *_vibrancy;
    UILabel *_noWidgetsLabel;
    
    BOOL _isResetting;
    BOOL _isVisible;
    BOOL _isRotating;
}

@end
