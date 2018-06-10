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
#import "XENWeatherLayerFactory.h"
#import "XENWeatherBackgroundView.h"

@interface XENWeatherViewController : XENBaseViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    UIView *_tempBackgroundView;
    UILabel *_placeText;
    UILabel *_conditionText;
    UILabel *_temperatureText;
    UILabel *_todayText;
    UILabel *_todayHigh;
    UILabel *_todayLow;
    UIView *_topSeperator;
    UICollectionView *_hourCollectionView;
    UIView *_bottomSeperator;
    UITableView *_dayTableView;
    BOOL _setupForDisplay;
    BOOL _registeredForNotifications;
    NSTimer *_hourIntervalTimer;
    
    NSArray *_dayDataSource;
    NSArray *_hourDataSource;
}

@property (nonatomic, strong) XENWeatherBackgroundView *backgroundView;

// View management
-(void)configureViewForLock;
-(void)resetViewForUnlock;
-(void)resetViewForSettingsChange:(NSDictionary*)oldSettings :(NSDictionary*)newSettings;
-(void)notifyPreemptiveRemoval;
-(void)notifyPreemptiveAddition;

@end
