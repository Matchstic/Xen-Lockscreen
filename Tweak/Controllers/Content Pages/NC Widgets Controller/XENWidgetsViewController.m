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

/* Widget states
 * 0 - None
 * 1 - Connecting
 * 2 - Disconnecting
 * 3 - Inserting View
 * 4 - Snapshotting
 * 5 - Inserting snapshot
 */

#import "XENWidgetsViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface XENWidgetsViewController ()

@end

@interface UIViewController (Private)
-(int)_appearState;
@end

@implementation XENWidgetsViewController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.tag = 12345;
    self.view.backgroundColor = [UIColor clearColor];
    
    _noWidgets = NO;
    _isVisible = NO;
    
    // Row info comes from NC framework.
    [self setupObservers];
    
    if (_tableView) {
        [_tableView removeFromSuperview];
        _tableView = nil;
    }
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.clipsToBounds = YES;
    _tableView.contentInset = UIEdgeInsetsMake(20, 0, 20, 0);
    [_tableView registerClass:[XENWidgetCell class] forCellReuseIdentifier:@"ncWidgetCell"];
    [self.view addSubview:_tableView];
}

-(void)setupObservers {
    __block XENWidgetsViewController *weakself = self;
    
    [objc_getClass("NCDataSourceManager") requestSharedDataSourceManager:^(NCDataSourceManager *manager) {
        [manager addSnippetDataSourceChangeHandler:^(NSArray* arg1) {
            // Array of NCSnippetDataSource
        } forIdentifier:@"com.matchstic.xen.ncwidgets"];
        
        [manager addWidgetDataSourceChangeHandler:^(NSArray* arg1) {
            // Array of NCWidgetDataSource
            
            if (!_preOrderedDatums) {
                _preOrderedDatums = [NSMutableArray array];
            }
            
            for (NCWidgetDataSource *dataSource in arg1) {
                for (NSString *identifier in dataSource.widgetIdentifiers) {
                    NCWidgetDatum *datum = [dataSource widgetDatumWithIdentifier:identifier];
                    
                    SBWidgetRowInfo *rowInfo = [objc_getClass("SBWidgetRowInfo") infoWithRepresentedObject:datum];
            
                    [_preOrderedDatums addObject:rowInfo];
                }
            }
            
            // We now have ALL possible datums. Now, we only grab those that are enabled, then order them as appropriate.
            // Also, do a check as to whether we should show the battery widget.
            
            BOOL shouldShowBatteryDatum = NO;
            
            NSArray *connectedDevices = [[objc_getClass("BCBatteryDeviceController") sharedInstance] connectedDevices];
            shouldShowBatteryDatum = connectedDevices.count > 1;
            
            shouldShowBatteryDatum = NO;
            
            if (!_dataSource) {
                // All enabled items.
                _dataSource = [NSMutableArray array];
            } else {
                [_dataSource removeAllObjects];
            }
            
            for (SBWidgetRowInfo *rowinfo in _preOrderedDatums) {
                if (rowinfo.representedWidgetDatum.representedExtension.optedIn) {
                    [_dataSource addObject:rowinfo];
                    rowinfo.widget.delegate = weakself;
                } else if (shouldShowBatteryDatum && [rowinfo.identifier isEqualToString:@"com.apple.BatteryCenter.BatteryWidget"]) {
                    [_dataSource addObject:rowinfo];
                    rowinfo.widget.delegate = weakself;
                }
            }
            
            NSMutableArray *temporaryArray = [NSMutableArray arrayWithCapacity:_dataSource.count];
            
            #warning Potential iPad compatibility issues
            
            // Now, we need to order the array of enabled items.
            NSDictionary *archive = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/SpringBoard/TodayViewArchive.plist"];
            NSArray *ordered = [archive objectForKey:@"TodayGroup"];
            
            // TODO: Improve this efficiency.
            for (NSString *identifier in ordered) {
                for (SBWidgetRowInfo *rowinfo in _dataSource) {
                    if ([rowinfo.identifier isEqualToString:identifier]) {
                        [temporaryArray addObject:rowinfo];
                        break;
                    }
                }
            }
            
            if (shouldShowBatteryDatum) {
                // Handle battery datum ordering.
                for (SBWidgetRowInfo *rowinfo in _dataSource) {
                    if ([rowinfo.identifier isEqualToString:@"com.apple.BatteryCenter.BatteryWidget"]) {
                        [temporaryArray insertObject:rowinfo atIndex:0];
                        break;
                    }
                }
            }
            
            [_dataSource removeAllObjects];
            _dataSource = temporaryArray;
            temporaryArray = nil;
            
            // Strip out those without content
            _actualDataSource = [_dataSource mutableCopy];
            
            for (SBWidgetRowInfo *obj in _dataSource) {
                if (!obj.widget.hasContent) { // Also remove if widget doesn't have content now.
                    [_actualDataSource removeObject:obj];
                }
            }
            
            // Setup identifiers to infos.
            _identifiersToInfos = [NSMutableDictionary dictionary];
            
            for (SBWidgetRowInfo* info in _dataSource) {
                [_identifiersToInfos setObject:info forKey:[info identifier]];
            }
            
            // Finally, reload table view. (or not, as the case may be)
            [_tableView reloadData];
            
            if (_actualDataSource.count == 0) {
                [self showNoWidgetsUI];
            }
        } forIdentifier:@"com.matchstic.xen.ncwidgets"];
    }];
    
    /*[[objc_getClass("BCBatteryDeviceController") sharedInstance] addDeviceChangeHandler:^{
        [self _batteryDevicesDidChange:nil];
    } withIdentifier:@"com.matchstic.xen.ncwidgets"];*/
}

-(void)showNoWidgetsUI {
    // Show no widgets available UI.
    _noWidgets = YES;
    
    [_tableView removeFromSuperview];
    _tableView = nil;
    
    _vibrancy = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]]];
    _vibrancy.frame = self.view.bounds;
    
    [self.view addSubview:_vibrancy];
    
    _noWidgetsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, 100)];
    _noWidgetsLabel.font = [UIFont systemFontOfSize:20];
    _noWidgetsLabel.numberOfLines = 0;
    _noWidgetsLabel.text = [XENResources localisedStringForKey:@"No widgets available" value:@"No widgets available"];
    _noWidgetsLabel.textColor = [UIColor whiteColor];
    _noWidgetsLabel.textAlignment = NSTextAlignmentCenter;
    
    [_vibrancy.contentView addSubview:_noWidgetsLabel];
    
    _noWidgetsLabel.center = _vibrancy.center;
}

-(void)_batteryDevicesDidChange:(id)change {
    // Get battery widget (or not).
    
    BOOL shouldShowBatteryDatum = NO;
    
    NSArray *connectedDevices = [[objc_getClass("BCBatteryDeviceController") sharedInstance] connectedDevices];
    shouldShowBatteryDatum = connectedDevices.count > 1;
    
    SBWidgetRowInfo *batteryInfo = nil;
    
    for (SBWidgetRowInfo *info in _dataSource) {
        if ([info.identifier isEqualToString:@"com.apple.BatteryCenter.BatteryWidget"]) {
            batteryInfo = info;
            break;
        }
    }
    
    if (!batteryInfo) {
        return;
    }
    
    for (XENWidgetCell *cell in _tableView.visibleCells) {
        [cell prepareForReloadOfUI];
    }
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        // animation has finished
        for (XENWidgetCell *cell in _tableView.visibleCells) {
            [cell finishedReloadingUI];
        }
    }];
    
    [_tableView beginUpdates];
    
    if (shouldShowBatteryDatum && ![_actualDataSource containsObject:batteryInfo]) {
        // Insert at top.
        [_dataSource insertObject:batteryInfo atIndex:0];
        [_actualDataSource insertObject:batteryInfo atIndex:0];
        
        [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    } else if ([_actualDataSource containsObject:batteryInfo] && !shouldShowBatteryDatum) {
        int index = (int)[_actualDataSource indexOfObject:batteryInfo];
        
        [_dataSource removeObject:batteryInfo];
        [_actualDataSource removeObject:batteryInfo];
        
        [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [_tableView endUpdates];
    
    [CATransaction commit];
}

-(void)_callBlockOnAllVisibleWidgets:(void(^)(SBWidgetViewController*))block {
    for (XENWidgetCell *cell in _tableView.visibleCells) {
        block(cell.widgetController);
    }
}

-(void)_callBlockOnAllAvailableWidgets:(void(^)(SBWidgetViewController*))block {
    for (SBWidgetRowInfo *widget in _dataSource) {
        block(widget.widget);
    }
}

#pragma mark Inherited shit

+(BOOL)supportsCurrentiOSVersion {
    return [UIDevice currentDevice].systemVersion.floatValue < 10;
}

-(BOOL)wantsBlurredBackground {
    if (_noWidgets) {
        return YES;
    }
    
    return NO; // Each widget is blurred instead!
}

-(void)movingToControllerWithPercent:(CGFloat)percent {
    if (percent == 0.0 && _isVisible && !_isRotating) {
        // Not in controller
        _isVisible = NO;
        XENlog(@"Disconnecting widgets...");
        [self _callBlockOnAllAvailableWidgets:^(SBWidgetViewController* widget) {
            [self disconnectWidget:widget fully:YES withCompletion:nil];
        }];
    } else if (percent == 1.0 && !_isVisible) {
        // Will be in controller.
        _isVisible = YES;
        XENlog(@"Connecting widgets...");
        [self _callBlockOnAllVisibleWidgets:^(SBWidgetViewController* widget) {
            XENlog(@"%@", [widget widgetIdentifier]);
            [self connectWidget:widget];
        }];
    }
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.ncwidgets";
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"NC Widgets" value:@"NC Widgets"];
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(void)rotateToOrientation:(int)orient {
    _isRotating = YES;
    // Layout as appropriate
    _tableView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    _vibrancy.frame = self.view.bounds;
    _noWidgetsLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH/2, 100);
    _noWidgetsLabel.center = _vibrancy.center;
    
    _isRotating = NO;
}

-(void)resetViewForUnlock {
    XENlog(@"Resetting NC Widgets page for unlock.");
    
    for (SBWidgetRowInfo *info in _dataSource) {
        [self _actuallyDisconnectWidget:info.widget];
        info.widget.delegate = nil;
    }
    
    [_tableView removeFromSuperview];
    _tableView = nil;
    
    [_vibrancy removeFromSuperview];
    _vibrancy = nil;
    
    [_noWidgetsLabel removeFromSuperview];
    _noWidgetsLabel = nil;
    
    [_dataSource removeAllObjects];
    _dataSource = nil;
    
    [_actualDataSource removeAllObjects];
    _actualDataSource = nil;
    
    [_preOrderedDatums removeAllObjects];
    _preOrderedDatums = nil;
    
    [_identifiersToInfos removeAllObjects];
    _identifiersToInfos = nil;
    //_cancelHitWidgetTouchesAssertion = nil;
    
    if (_hackRetryTimer) {
        [_hackRetryTimer invalidate];
        _hackRetryTimer = nil;
    }
    
    _retryStart = 0;
    _isVisible = NO;
    _isResetting = NO;
    
    [objc_getClass("NCDataSourceManager") requestSharedDataSourceManager:^(NCDataSourceManager *manager) {
        [manager removeChangeHandlersWithIdentifier:@"com.matchstic.xen.ncwidgets"];
    }];
    
    //[[objc_getClass("BCBatteryDeviceController") sharedInstance] removeDeviceChangeHandlerWithIdentifier:@"com.matchstic.xen.ncwidgets"];
    
    [super resetViewForUnlock];
}

-(void)notifyUnlockWillBegin {
    // Hide all widgets so that they invalidate nicely.    
    for (SBWidgetRowInfo *info in _dataSource) {
        [self _actuallyDisconnectWidget:info.widget];
        info.widget.delegate = nil;
    }
}

-(void)willMoveToControllerAfterScrollingEnds {
    [self movingToControllerWithPercent:1.0];
}

#pragma mark SBWidgetViewControllerDelegate delegate

- (int)activeLayoutModeForWidget:(id)widget {
    return 0;
}

- (void)attemptReconnectionAfterUnanticipatedDisconnection:(SBWidgetViewController*)widget {
    
    [widget connectRemoteViewControllerWithCompletionHandler:^{
        // Connection stuff handled by delegate callback.
    }];
}

- (void)contentAvailabilityDidChangeForWidget:(SBWidgetViewController*)widget {
    // This is when a widget wants to be displayed again (or not, as the case may be).
    XENlog(@"CONTENT AVAILABILITY CHANGED FOR WIDGET: %@", widget);
    
    SBWidgetRowInfo *info = [_identifiersToInfos objectForKey:[widget widgetIdentifier]];
    
    for (XENWidgetCell *cell in _tableView.visibleCells) {
        [cell prepareForReloadOfUI];
    }
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        // animation has finished
        for (XENWidgetCell *cell in _tableView.visibleCells) {
            [cell finishedReloadingUI];
        }
    }];
    
    [_tableView beginUpdates];
    
    if (widget.hasContent && ![_actualDataSource containsObject:info]) {
        // Push into data.
        int index = (int)[_dataSource indexOfObject:info];
        
        for (int i = index - 1; i >= 0; i--) {
            SBWidgetRowInfo *precedingInfo = [_dataSource objectAtIndex:i];
            
            if ([_actualDataSource containsObject:precedingInfo]) {
                index = (int)[_actualDataSource indexOfObject:precedingInfo] + 1;
                break;
            } else if (i == 0) {
                // Well... There aren't any more to check against, and still borked.
                index = 0;
                break;
            }
        }
        
        // Push in at index.
        [_actualDataSource insertObject:info atIndex:index];
    } else if ([_actualDataSource containsObject:info] && !widget.hasContent) {
        // Remove from data.
        [_actualDataSource removeObject:info];
    }
    
    [_tableView endUpdates];
    
    [CATransaction commit];
}

- (/*NSExtension**/id)extensionForWidget:(SBWidgetViewController*)widget {
    SBWidgetRowInfo *info = [_identifiersToInfos objectForKey:[widget widgetIdentifier]];
    
    return info.representedWidgetDatum.representedExtension;
}

- (UIEdgeInsets)marginInsetsForWidget:(SBWidgetViewController*)widget {
    // These insets are typically defined by the widget, BUT we can mess with that a bit. :P
    return UIEdgeInsetsMake(0, 7.5, 0, 0);
}

- (CGSize)maxSizeForWidget:(SBWidgetViewController*)widget {
    return CGSizeMake(SCREEN_WIDTH - 15, SCREEN_HEIGHT);
}

- (void)remoteViewControllerDidConnectForWidget:(SBWidgetViewController*)remoteViewController {
    [remoteViewController hostWillPresent];
    [remoteViewController hostDidPresent];
    
    XENlog(@"DID CONNECT FOR %@", [remoteViewController widgetIdentifier]);
    
    [remoteViewController requestInsertionOfRemoteViewWithCompletionHandler:^{
        // No idea what the parameters coming into here are.
            
        [remoteViewController performUpdateWithCompletionHandler:^(NCUpdateResult result) {
            [remoteViewController viewDidLoad];
            
            [remoteViewController viewWillAppear:YES];
            [remoteViewController viewDidAppear:YES];
            
            XENlog(@"INSERT AND CONNECTED FOR %@", [remoteViewController widgetIdentifier]);
        }];
    }];
}

- (BOOL)shouldRequestWidgetRemoteViewControllers {
    if (_isResetting) {
        return NO;
    }
    
    return YES;
}

- (id)widget:(SBWidgetViewController*)widget didUpdatePreferredHeight:(CGFloat)height completion:(id)completion {
    SBWidgetRowInfo *info = [_identifiersToInfos objectForKey:[widget widgetIdentifier]];
    info.preferredViewHeight = height;
    
    for (XENWidgetCell *cell in _tableView.visibleCells) {
        [cell prepareForReloadOfUI];
    }
    
    [CATransaction begin];
    
    [CATransaction setCompletionBlock:^{
        // animation has finished
        for (XENWidgetCell *cell in _tableView.visibleCells) {
            [cell finishedReloadingUI];
        }
    }];
    
    // Update tableview's cell height from widget ID.
    [_tableView beginUpdates];
    [_tableView endUpdates];
    
    [CATransaction commit];
    
    int index = 0;
    for (SBWidgetRowInfo *infos in _actualDataSource) {
        if ([[infos identifier] isEqualToString:[widget widgetIdentifier]]) {
            break;
        }
        
        index++;
    }
    
    for (XENWidgetCell *cell in _tableView.visibleCells) {
        if ([cell.identifier isEqualToString:[widget widgetIdentifier]]) {
            // Re-layout bounds.
            cell.contentView.frame = CGRectMake(0, 0, SCREEN_WIDTH, [self tableView:_tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]]);
            
            [cell setNeedsLayout];
        }
    }
    
    return completion;
}

- (void)widget:(SBWidgetViewController*)widget requestsLaunchOfURL:(NSURL*)url {
    if (_tableView.isTracking || _tableView.isDecelerating || _tableView.isDragging || ![XENResources canWidgetsLaunchURL]) {
        //_cancelHitWidgetTouchesAssertion = [widget _cancelTouches];
        return; // No launching when scrolling.
    }
    
    // We can abuse the NC here.
    [[objc_getClass("SBNotificationCenterController") sharedInstance] widget:widget requestsLaunchOfURL:url];
}

- (BOOL)widgetShouldAttemptReconnectionAfterUnanticipatedDisconnection:(SBWidgetViewController*)widget {
    return YES;
}

#pragma mark UITableView delegate and data source.

-(NSArray*)dataSource {
    // All of type SBWidgetRowInfo.
    
    return _actualDataSource;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XENWidgetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ncWidgetCell"];
    if (!cell) {
        cell = [[XENWidgetCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:@"ncWidgetCell"];
    }
    
    //[cell readyWidgetForReuse];
    
    SBWidgetViewController *contr = [[self dataSource][indexPath.row] widget];
    [self addChildViewController:contr];
    
    [cell setupWithRowInfo:[self dataSource][indexPath.row] andDelegate:self];
    
    [cell finishedReloadingUI];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self dataSource].count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SBWidgetRowInfo *info = _actualDataSource[indexPath.row];
    
    CGFloat height = info.preferredViewHeight + 45;
    
    // 40 is the height of the title bar, and 5 is to compensate for insets.
    
    if (height == 45) {
        height = 85;
    } else {
        height += 5; // Accounts for some crap.
    }

    return height;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    SBWidgetRowInfo *info = _actualDataSource[indexPath.row];
    SBWidgetViewController *widget = info.widget;
    
    if (_isVisible)
        [self connectWidget:widget];
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    SBWidgetRowInfo *info = _actualDataSource[indexPath.row];
    SBWidgetViewController *widget = info.widget;
    
    if (!_tableView.isTracking && !_isRotating) {
        [self disconnectWidget:widget fully:NO withCompletion:nil];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    //if (_cancelHitWidgetTouchesAssertion) {
    //    _cancelHitWidgetTouchesAssertion = nil;
    //}
}

#pragma mark XENWidgetCellDelegate

-(void)disconnectWidget:(SBWidgetViewController*)widget fully:(BOOL)fully withCompletion:(void (^)(void))completion {
    if (widget.hasContent && widget.requestState != 0x4 && widget.requestState != 0x5 && widget.requestState != 0x2) {
        if (([widget _appearState] & !0x2) == 0x1) {
            [widget endAppearanceTransition];
        }
        
        [widget captureSnapshotWithCompletionHandler:^{
            [widget insertSnapshotWithCompletionHandler:^{
                if (fully) {
                    [self _actuallyDisconnectWidget:widget];
                }
            }];
        }];
    }
}

-(void)_actuallyDisconnectWidget:(SBWidgetViewController*)widget {
    [widget viewWillDisappear:YES];
    [widget viewDidDisappear:YES];
    
    [widget hostWillDismiss];
    [widget hostDidDismiss];
    
    [widget disconnectRemoteViewControllerWithCompletionHandler:^{
        XENlog(@"Removed widget: %@", [widget widgetIdentifier]);
        
        [widget viewWillDisappear:YES];
        [widget viewDidDisappear:YES];
    }];
}

-(void)connectWidget:(SBWidgetViewController*)widget {
    [widget viewWillAppear:YES];
    [widget viewDidAppear:YES];
    
    widget.delegate = self;
    
    [widget validateSnapshotViewForActiveLayoutMode];
    
    if (widget.requestState != 0x3) {
        [widget connectRemoteViewControllerWithCompletionHandler:^{
            // Post-connection work handled by delegate callback.
        }];
    }
}

-(UIBlurEffect*)widgetBlurEffect {
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
}

#pragma mark Memory shite.

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // TODO: If we ARE locked, eject any widgets that are currently loaded, but not displayed right now.
}

-(void)dealloc {
    
}

@end
