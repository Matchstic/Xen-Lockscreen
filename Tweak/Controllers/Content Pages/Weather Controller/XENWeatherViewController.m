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

#import "XENWeatherViewController.h"
#import "IS2Weather.h"
#import "XENResources.h"
#import "XENWeatherSmallView.h"
#import "XENWeatherDayView.h"

#define COLLECTION @"xen.collectionReuse"
#define TABLE @"xen.tableReuse"

@interface XENWeatherViewController ()

@end

@interface IS2Weather (EH)
+(BOOL)isDay;
@end

@interface HourlyForecast : NSObject
@property (nonatomic) int conditionCode;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic) unsigned int eventType;
@property (nonatomic) int hourIndex;
@property (nonatomic) float percentPrecipitation;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, retain) WFTemperature *temperature;
@end

@interface DayForecast : NSObject

@property (nonatomic) unsigned int dayNumber;
@property (nonatomic) unsigned int dayOfWeek;
@property (nonatomic, copy) NSString *high;
@property (nonatomic) unsigned int icon;
@property (nonatomic, copy) NSString *low;

@end

@implementation XENWeatherViewController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    self.view.userInteractionEnabled = NO;
    
    // Background wallpaper
    self.backgroundView = [[XENWeatherBackgroundView alloc] initWithFrame:CGRectZero];
    self.backgroundView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.backgroundView.hidden = YES;
    self.backgroundView.alpha = 0.0;
    self.backgroundView.userInteractionEnabled = NO;
    [self.view addSubview:self.backgroundView];
    
    if (_placeText) {
        [_placeText removeFromSuperview];
        _placeText = nil;
    }
    
    
    _placeText = [[UILabel alloc] initWithFrame:CGRectZero];
    _placeText.font =  IS_IPAD ? [UIFont systemFontOfSize:40 weight:UIFontWeightLight] : [UIFont systemFontOfSize:30];
    
    NSString *placeholderText = [XENResources localisedStringForKey:@"Loading" value:@"Loading"];
    NSString *initialPlaceText = [objc_getClass("IS2Weather") currentLocation].length > 0 ? [objc_getClass("IS2Weather") currentLocation] : placeholderText;
    
    _placeText.text = initialPlaceText;
    _placeText.textAlignment = NSTextAlignmentCenter;
    _placeText.textColor = [UIColor whiteColor];
    
    [self.view addSubview:_placeText];
    
    if (_conditionText) {
        [_conditionText removeFromSuperview];
        _conditionText = nil;
    }
    
    NSString *initialConditionText = [objc_getClass("IS2Weather") currentConditionAsString].length > 0 ? [objc_getClass("IS2Weather") currentConditionAsString] : placeholderText;
    
    _conditionText = [[UILabel alloc] initWithFrame:CGRectZero];
    _conditionText.font = IS_IPAD ? [UIFont systemFontOfSize:25 weight:UIFontWeightLight] : [UIFont systemFontOfSize:15];
    _conditionText.text = initialConditionText;
    _conditionText.textAlignment = NSTextAlignmentCenter;
    _conditionText.textColor = [UIColor whiteColor];
    
    [self.view addSubview:_conditionText];
    
    if (_temperatureText) {
        [_temperatureText removeFromSuperview];
        _temperatureText = nil;
    }
    
    _temperatureText = [[UILabel alloc] initWithFrame:CGRectZero];
    _temperatureText.font = [UIFont systemFontOfSize:100 weight:UIFontWeightUltraLight];
    
    NSString *temp = [NSString stringWithFormat:@"%d", [objc_getClass("IS2Weather") currentTemperature]];
    NSString *degree = [[XENWeatherLayerFactory sharedInstance] weatherStringForString:@"DEGREE"];
    
    if (!temp) temp = @"";
    if (!degree) degree = @"";
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@""];
    NSDictionary * attributes = [NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:100 weight:UIFontWeightUltraLight] forKey:NSFontAttributeName];
    NSAttributedString * subString = [[NSAttributedString alloc] initWithString:temp attributes:attributes];
    [str appendAttributedString:subString];
    
    NSMutableDictionary * attributes2 = [NSMutableDictionary dictionaryWithObject:[UIFont systemFontOfSize:45 weight:UIFontWeightLight] forKey:NSFontAttributeName];
    [attributes2 setObject:[NSNumber numberWithInt:36] forKey:NSBaselineOffsetAttributeName];
    NSAttributedString * subString2 = [[NSAttributedString alloc] initWithString:degree attributes:attributes2];
    [str appendAttributedString:subString2];
    
    _temperatureText.attributedText = str;
    
    _temperatureText.textAlignment = NSTextAlignmentLeft;
    _temperatureText.textColor = [UIColor whiteColor];
    
    [self.view addSubview:_temperatureText];
    
    if (_todayText) {
        [_todayText removeFromSuperview];
        _todayText = nil;
    }
    
    _todayText = [[UILabel alloc] initWithFrame:CGRectZero];
    _todayText.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    _todayText.text = [[XENWeatherLayerFactory sharedInstance] weatherStringForString:@"TODAY"];
    _todayText.textAlignment = NSTextAlignmentCenter;
    _todayText.textColor = [UIColor whiteColor];
    
    [self.view addSubview:_todayText];
    
    if (_todayHigh) {
        [_todayHigh removeFromSuperview];
        _todayHigh = nil;
    }
    
    _todayHigh = [[UILabel alloc] initWithFrame:CGRectZero];
    _todayHigh.font = [UIFont systemFontOfSize:15];
    _todayHigh.text = [NSString stringWithFormat:@"%d", [objc_getClass("IS2Weather") highForCurrentDay]];
    _todayHigh.textAlignment = NSTextAlignmentRight;
    _todayHigh.textColor = [UIColor whiteColor];
    
    [self.view addSubview:_todayHigh];
    
    if (_todayLow) {
        [_todayLow removeFromSuperview];
        _todayLow = nil;
    }
    
    _todayLow = [[UILabel alloc] initWithFrame:CGRectZero];
    _todayLow.font = [UIFont systemFontOfSize:15];
    _todayLow.text = [NSString stringWithFormat:@"%d", [objc_getClass("IS2Weather") lowForCurrentDay]];
    _todayLow.textAlignment = NSTextAlignmentRight;
    _todayLow.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    [self.view addSubview:_todayLow];
    
    if (_topSeperator) {
        [_topSeperator removeFromSuperview];
        _topSeperator = nil;
    }
    
    _topSeperator = [[UIView alloc] initWithFrame:CGRectZero];
    _topSeperator.backgroundColor = [UIColor whiteColor];
    _topSeperator.alpha = 0.5;
    
    [self.view addSubview:_topSeperator];

    if (_hourCollectionView) {
        [_hourCollectionView removeFromSuperview];
        _hourCollectionView = nil;
    }
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(56, 96);
    layout.minimumInteritemSpacing = 0.0;
    layout.minimumLineSpacing = 0.0;
    
    _hourCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _hourCollectionView.showsHorizontalScrollIndicator = NO;
    _hourCollectionView.delegate = self;
    _hourCollectionView.dataSource = self;
    _hourCollectionView.alwaysBounceHorizontal = NO;
    _hourCollectionView.scrollsToTop = NO;
    _hourCollectionView.allowsSelection = NO;
    _hourCollectionView.delaysContentTouches = YES;
    _hourCollectionView.backgroundColor = [UIColor clearColor];
    [_hourCollectionView registerClass:[XENWeatherSmallView class] forCellWithReuseIdentifier:COLLECTION];
    
    [self.view addSubview:_hourCollectionView];
    
    if (_bottomSeperator) {
        [_bottomSeperator removeFromSuperview];
        _bottomSeperator = nil;
    }
    
    _bottomSeperator = [[UIView alloc] initWithFrame:CGRectZero];
    _bottomSeperator.backgroundColor = [UIColor whiteColor];
    _bottomSeperator.alpha = 0.5;
    
    [self.view addSubview:_bottomSeperator];
    
    if (_dayTableView) {
        [_dayTableView removeFromSuperview];
        _dayTableView = nil;
    }
    
    _dayTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _dayTableView.backgroundColor = [UIColor clearColor];
    _dayTableView.showsVerticalScrollIndicator = NO;
    _dayTableView.showsHorizontalScrollIndicator = NO;
    _dayTableView.pagingEnabled = NO;
    _dayTableView.alwaysBounceVertical = YES;
    _dayTableView.scrollsToTop = NO;
    _dayTableView.allowsSelection = NO;
    _dayTableView.delegate = self;
    _dayTableView.dataSource = self;
    _dayTableView.rowHeight = 30;
    _dayTableView.delaysContentTouches = YES;
    _dayTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_dayTableView registerClass:[XENWeatherDayView class] forCellReuseIdentifier:TABLE];
    
    [self.view addSubview:_dayTableView];
}

// Sunday is ALWAYS first
-(NSString*)getWeekdayString:(int)weekdayNumber {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Fetch the days of the week in words for the current language (Sunday to Saturday)
    NSArray *weekdaySymbols = calendar.weekdaySymbols;
    return weekdaySymbols[weekdayNumber-1];
}

-(void)updateData {
    int condition = [objc_getClass("IS2Weather") currentCondition];
    BOOL isDay = [self isDay];
    
    // handle switching animated background
    if ([XENResources weatherShowAnimatedWallpaper] && ![XENResources isLoadedInEditMode]) {
        [self.backgroundView transitionToCondition:condition isDay:isDay];
    }
    
    _placeText.text = [objc_getClass("IS2Weather") currentLocation];
    _conditionText.text = [objc_getClass("IS2Weather") currentConditionAsString];
    
    NSString *temp = [NSString stringWithFormat:@"%d", [objc_getClass("IS2Weather") currentTemperature]];
    NSString *degree = [[XENWeatherLayerFactory sharedInstance] weatherStringForString:@"DEGREE"];
    
    if (!temp) temp = @"";
    if (!degree) degree = @"";
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@""];
    
    NSDictionary * attributes = [NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:100 weight:UIFontWeightUltraLight] forKey:NSFontAttributeName];
    NSAttributedString * subString = [[NSAttributedString alloc] initWithString:temp attributes:attributes];
    [str appendAttributedString:subString];
    
    NSMutableDictionary * attributes2 = [NSMutableDictionary dictionaryWithObject:[UIFont systemFontOfSize:45 weight:UIFontWeightLight] forKey:NSFontAttributeName];
    [attributes2 setObject:[NSNumber numberWithInt:36] forKey:NSBaselineOffsetAttributeName];
    NSAttributedString * subString2 = [[NSAttributedString alloc] initWithString:degree attributes:attributes2];
    [str appendAttributedString:subString2];
    
    _temperatureText.attributedText = str;
    
    _todayLow.text = [NSString stringWithFormat:@"%d", [objc_getClass("IS2Weather") lowForCurrentDay]];
    _todayHigh.text = [NSString stringWithFormat:@"%d", [objc_getClass("IS2Weather") highForCurrentDay]];
    
    [self layoutHourScrollerSubviews];
    [self layoutDayScrollerSubviews];
    
    [self layoutForDataUpdate];
}

-(void)layoutHourScrollerSubviews {
    // Sort out hour scroller.
    NSMutableArray *array = [[objc_getClass("IS2Weather") hourlyForecastsForCurrentLocation] mutableCopy];
    [array insertObject:@"NOW" atIndex:0];
    _hourDataSource = array;
    
    [_hourCollectionView reloadData];
    
    _hourCollectionView.contentOffset = CGPointZero;
}

-(void)layoutDayScrollerSubviews {
    // Remove today if necessary
    NSMutableArray *array = [[objc_getClass("IS2Weather") dayForecastsForCurrentLocation] mutableCopy];
    
    CFAbsoluteTime at = CFAbsoluteTimeGetCurrent();
    CFTimeZoneRef tz = CFTimeZoneCopySystem();
    SInt32 WeekdayNumber = CFAbsoluteTimeGetDayOfWeek(at, tz);
    
    CFRelease(tz);
    
    // DayForecast; 1 = Sunday, 7 = Saturday
    // CF; 1 == Monday, 7 == Sunday
    
    WeekdayNumber += 1;
    if (WeekdayNumber == 8) {
        WeekdayNumber = 1;
    }
    
    // Ignore days that are already past from old data
    int checked = 0;
    for (DayForecast *forecast in array) {
        checked++;
        if (forecast.dayOfWeek == WeekdayNumber) {
            break;
        }
    }
    
    for (int i = 0; i < checked; i++) {
        [array removeObject:[array firstObject]];
    }
    
    _dayDataSource = array;
    [_dayTableView reloadData];
    
    _dayTableView.contentOffset = CGPointZero;
}

-(void)layoutForDataUpdate {
    CGFloat height = SCREEN_HEIGHT*0.115;
    CGRect rect = [XENResources boundedRectForFont:_placeText.font andText:_placeText.text width:SCREEN_WIDTH*0.8];
    _placeText.frame = CGRectMake(SCREEN_WIDTH/2 - (rect.size.width+10)/2, height, rect.size.width+10, rect.size.height);
    
    height += _placeText.frame.size.height + 5;
    
    rect = [XENResources boundedRectForFont:_conditionText.font andText:_conditionText.text width:SCREEN_WIDTH*0.8];
    _conditionText.frame = CGRectMake(SCREEN_WIDTH/2 - (rect.size.width+10)/2, height, rect.size.width+10, rect.size.height);
    
    height += _conditionText.frame.size.height;
    
    rect = [XENResources boundedRectForFont:_temperatureText.font andText:_temperatureText.text width:SCREEN_WIDTH*0.8];
    CGRect rect2 = [XENResources boundedRectForFont:[UIFont systemFontOfSize:45 weight:UIFontWeightLight] andText:[[XENWeatherLayerFactory sharedInstance] weatherStringForString:@"DEGREE"] width:SCREEN_WIDTH*0.8];
    _temperatureText.frame = CGRectMake(SCREEN_WIDTH/2 - rect.size.width/2 + rect2.size.width, height, rect.size.width, rect.size.height);
    
    height += _temperatureText.frame.size.height + SCREEN_HEIGHT*0.115 - 20;
    
    rect = [XENResources boundedRectForFont:_todayText.font andText:_todayText.text width:SCREEN_WIDTH*0.8];
    _todayText.frame = CGRectMake(20, height, rect.size.width+5, rect.size.height+5);
    
    // Today low/high
    rect = [XENResources boundedRectForFont:_todayLow.font andText:_todayLow.text width:SCREEN_WIDTH*0.8];
    _todayLow.frame = CGRectMake(SCREEN_WIDTH-20-rect.size.width, height, rect.size.width, rect.size.height+5);
    
    rect = [XENResources boundedRectForFont:_todayHigh.font andText:_todayHigh.text width:SCREEN_WIDTH*0.8];
    _todayHigh.frame = CGRectMake(SCREEN_WIDTH-50-rect.size.width, height, rect.size.width, rect.size.height+5);
    
    height += _todayText.frame.size.height + 5;
    
    _topSeperator.frame = CGRectMake(0, height, SCREEN_WIDTH, 0.5);
    
    height += 0.5;

    _hourCollectionView.frame = CGRectMake(0, height, SCREEN_WIDTH, 96);

    height += _hourCollectionView.frame.size.height;
    
    _bottomSeperator.frame = CGRectMake(0, height, SCREEN_WIDTH, 0.5);
    
    height += 0.5;
    
    _dayTableView.frame = CGRectMake(0, height, SCREEN_WIDTH, SCREEN_HEIGHT - height);
    
    height += _dayTableView.frame.size.height;
}

-(void)resetForScreenOff {
    _setupForDisplay = NO;
    self.backgroundView.hidden = YES;
}

-(void)setupBackground {
    // Hell fucking yes. Time to drop background view onto LS BEHIND the scroll view.
    if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
        UIView *superview = self.view.superview.superview;
        [superview insertSubview:self.backgroundView belowSubview:self.view.superview];
    } else {
        UIView *superview = self.view.superview.superview.superview;
        [superview insertSubview:self.backgroundView belowSubview:self.view.superview.superview];
    }
}

-(void)firedHourTimer:(id)sender {
    [_hourIntervalTimer invalidate];
    _hourIntervalTimer = nil;
    
    [self updateData];
    
    // Configure timer for another hour's time.
    int interval = [[self nextHourDate] timeIntervalSinceDate:[NSDate date]];
    _hourIntervalTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(firedHourTimer:) userInfo:nil repeats:NO];
}

- (NSDate*) nextHourDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components: NSCalendarUnitEra|NSCalendarUnitYear| NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour fromDate:[NSDate date]];
    [comps setHour: [comps hour]+1]; //NSDateComponents handles rolling over between days, months, years, etc
    return [calendar dateFromComponents:comps];
}

-(BOOL)isDay {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger hour = [components hour];
    
    return hour >= 6 && hour <= 18;
}

#pragma mark Inherited stuff

-(BOOL)wantsBlurredBackground {
    return ([XENResources weatherShowAnimatedWallpaper] ? NO : YES);
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.weather";
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"Weather" value:@"Weather"];
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

-(void)movingToControllerWithPercent:(CGFloat)percent {
    // Handle moving to controller for IS2 and the animated BG.
    if (percent > 0 && !_setupForDisplay) {
        _setupForDisplay = YES;
        
        if (![XENResources isLoadedInEditMode])
            [self setupBackground];
        
        // Make sure the background layer is ready to be displayed.
        self.backgroundView.hidden = NO;
        self.backgroundView.alpha = 0.0;
    }
    
    self.backgroundView.alpha = percent;
    
    if (percent == 0.0) {
        // Hide again
        _setupForDisplay = NO;
        self.backgroundView.hidden = YES;
    } else if (percent == 1.0) {
        // La fin.
        
    }
}

// View management
-(void)configureViewForLock {
    XENlog(@"Configuring Weather for lock.");
    
    [super configureViewForLock];
    
    // Re-add animated BG if appropriate.
    if ([XENResources weatherShowAnimatedWallpaper] && ![XENResources isLoadedInEditMode]) {
        [self.backgroundView transitionToCondition:[objc_getClass("IS2Weather") currentCondition] isDay:[self isDay]];
        self.backgroundView.hidden = NO;
    } else {
        self.backgroundView.hidden = YES;
    }
    
    // Ready ourselves by requesting a weather callback.
    if (!_registeredForNotifications) {
        [objc_getClass("IS2Weather") registerForWeatherUpdatesWithIdentifier:@"com.matchstic.xen.weather" andCallback:^{
            [self performSelectorOnMainThread:@selector(updateData) withObject:nil waitUntilDone:NO];
        }];
    
        [objc_getClass("IS2Weather") setWeatherUpdateTimeInterval:[XENResources weatherUpdateInterval] forRequester:@"com.matchstic.xen.weather"];
        
        _registeredForNotifications = YES;
    }
    
    [self layoutDayScrollerSubviews];
    [self layoutHourScrollerSubviews];
    [self layoutForDataUpdate];
    
    _setupForDisplay = NO;
}

-(void)resetViewForUnlock {
    XENlog(@"Resetting Weather for unlock.");
    [objc_getClass("IS2Weather") unregisterForUpdatesWithIdentifier:@"com.matchstic.xen.weather"];
    [objc_getClass("IS2Weather") removeRequesterForWeatherTimeInterval:@"com.matchstic.xen.weather"];
    _registeredForNotifications = NO;
    
    [self.backgroundView unloadLayers];
    
    [_hourIntervalTimer invalidate];
    _hourIntervalTimer = nil;
    
    self._debugIsReset = YES;
}

-(void)resetViewForSettingsChange:(NSDictionary*)oldSettings :(NSDictionary*)newSettings {
    // No need to data anything here!
}

-(void)notifyPreemptiveRemoval {
    // Remove animated background
    [self.backgroundView removeFromSuperview];
}

-(void)notifyPreemptiveAddition {
    // Show animated background.
    [self setupBackground];
}

#pragma mark UICollectionView delegate and data source

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _hourDataSource.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:COLLECTION forIndexPath:indexPath];
    if (!cell) {
        cell = [[XENWeatherSmallView alloc] initWithFrame:CGRectZero];
    }
    
    id item = [_hourDataSource objectAtIndex:indexPath.row];
    XENWeatherSmallView *cast = (XENWeatherSmallView*)cell;
    
    // Add NOW.
    if ([[item class] isSubclassOfClass:[NSString class]]) {
        [cast reuseWithConditionCode:[objc_getClass("IS2Weather") currentCondition] temperature:[NSString stringWithFormat:@"%d", [objc_getClass("IS2Weather") currentTemperature]] rain:[objc_getClass("IS2Weather") currentChanceOfRain] isDay:[self isDay] andHour:[[XENWeatherLayerFactory sharedInstance] weatherStringForString:@"NOW"] isNow:YES];
        [cast setForNow];
    } else {
        HourlyForecast *forecast = (HourlyForecast*)item;
        
        id temp = [forecast isKindOfClass:objc_getClass("WAHourlyForecast")] ? forecast.temperature : forecast.detail;
        
        [cast reuseWithConditionCode:forecast.conditionCode temperature:temp rain:forecast.percentPrecipitation isDay:[self isDay] andHour:forecast.time isNow:NO];
    }
    
    return cast;
}

#pragma mark UITableView deletage and data source.

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dayDataSource.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABLE forIndexPath:indexPath];
    if (!cell) {
        cell = [[XENWeatherDayView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TABLE];
    }
    
    DayForecast *forecast = [_dayDataSource objectAtIndex:indexPath.row];
    
    XENWeatherDayView *cast = (XENWeatherDayView*)cell;
    
    [cast reuseWithWeekday:[self getWeekdayString:forecast.dayOfWeek] condition:forecast.icon high:forecast.high andLow:forecast.low];
    
    return cast;
}

#pragma mark View related shenanigans

-(void)rotateToOrientation:(int)orient {
    self.backgroundView.frame = self.view.bounds;
    
    [self layoutForDataUpdate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    // Completely kill UI. Doesn't matter if this leads to a lag on lock.
    if (![XENResources isCurrentlyLocked]) {
        XENlog(@"Killing Weather controller due to memory pressure. Will rebuild on next lock.");
        
        [_tempBackgroundView removeFromSuperview];
        _tempBackgroundView = nil;
        
        [_placeText removeFromSuperview];
        _placeText = nil;
        
        [_conditionText removeFromSuperview];
        _conditionText = nil;
        
        [_todayText removeFromSuperview];
        _todayText = nil;
        
        [_todayHigh removeFromSuperview];
        _todayHigh = nil;
        
        [_todayLow removeFromSuperview];
        _todayLow = nil;
        
        [_topSeperator removeFromSuperview];
        _topSeperator = nil;
        
        [_hourCollectionView removeFromSuperview];
        _hourCollectionView = nil;
        
        [_bottomSeperator removeFromSuperview];
        _bottomSeperator = nil;
        
        [_dayTableView removeFromSuperview];
        _dayTableView = nil;
        
        if (self.isViewLoaded) {
            for (UIView *view in self.view.subviews) {
                [view removeFromSuperview];
            }
            
            [self.view removeFromSuperview];
            self.view = nil;
        }
    }
}

-(void)dealloc {
    
}


@end
