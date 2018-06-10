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

#import "XENSetupFinalController.h"
#import "XENSetupWindow.h"

@interface XENSetupFinalController ()

@end

@implementation XENSetupFinalController

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _finishedFauxUI = NO;
    
    self.headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    self.headerLabel.text = [XENResources localisedStringForKey:@"Final Touches" value:@"Final Touches"];
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.textColor = [UIColor blackColor];
    self.headerLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightLight];
    
    [self.view addSubview:self.headerLabel];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.doneButton setTitle:[XENResources localisedStringForKey:@"Get Started" value:@"Get Started"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.titleLabel.font = [UIFont systemFontOfSize:26];
    self.doneButton.hidden = YES;
    self.doneButton.alpha = 0.0;
    
    [self.view addSubview:self.doneButton];
    
    CGFloat centraliserWidth = SCREEN_WIDTH*0.8;
    self.tickCentraliser = [[UIView alloc] initWithFrame:CGRectMake(0, 0, centraliserWidth, 220)];
    
    [self.view addSubview:self.tickCentraliser];
    
    self.viewSettings = [[XENSFinalTickView alloc] initWithFrame:CGRectZero];
    [self.viewSettings setupWithText:[XENResources localisedStringForKey:@"Applying your settings" value:@"Applying your settings"]];
    
    [self.tickCentraliser addSubview:self.viewSettings];
    
    self.viewPages = [[XENSFinalTickView alloc] initWithFrame:CGRectZero];
    [self.viewPages setupWithText:[XENResources localisedStringForKey:@"Loading Content Pages" value:@"Loading Content Pages"]];
    
    [self.tickCentraliser addSubview:self.viewPages];
    
    self.viewCoffee = [[XENSFinalTickView alloc] initWithFrame:CGRectZero];
    [self.viewCoffee setupWithText:[XENResources localisedStringForKey:@"Taking a coffee break" value:@"Taking a coffee break"]];
    
    [self.tickCentraliser addSubview:self.viewCoffee];
    
    self.viewCleaningUp = [[XENSFinalTickView alloc] initWithFrame:CGRectZero];
    [self.viewCleaningUp setupWithText:[XENResources localisedStringForKey:@"Cleaning up" value:@"Cleaning up"]];
    
    [self.tickCentraliser addSubview:self.viewCleaningUp];
}

-(void)doneButtonWasPressed:(id)sender {
    [XENSetupWindow finishSetupMode];
}

-(void)reconfigureContentPages {
    [XENSetupWindow relayoutXenForSetupFinished];
    [self.viewPages transitionToBegin];
    [self.viewPages performSelector:@selector(transitionToTick) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(drinkingACoffee) withObject:nil afterDelay:1.5];
}

-(void)applySettings {
    [self.viewSettings transitionToBegin];
    [self.viewSettings performSelector:@selector(transitionToTick) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(reconfigureContentPages) withObject:nil afterDelay:1.0];
}

-(void)drinkingACoffee {
    [self.viewCoffee transitionToBegin];
    [self.viewCoffee performSelector:@selector(transitionToTick) withObject:nil afterDelay:2.0];
    [self performSelector:@selector(cleaningUp) withObject:nil afterDelay:2.5];
}

-(void)cleaningUp {
    [self.viewCleaningUp transitionToBegin];
    [self.viewCleaningUp performSelector:@selector(transitionToTick) withObject:nil afterDelay:1.0];
    [self performSelector:@selector(transitionToWelcome) withObject:nil afterDelay:2.0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.viewPages reset];
    [self.viewSettings reset];
    [self.viewCoffee reset];
    [self.viewCleaningUp reset];
    
    _finishedFauxUI = NO;
    
    CGFloat yOrigin = self.navigationController.navigationBar.frame.size.height + [XENSetupWindow sharedInstance].bar.frame.size.height;
    self.headerLabel.frame = CGRectMake(0, yOrigin, self.view.frame.size.width, 50);
    self.headerLabel.text = [XENResources localisedStringForKey:@"Final Touches" value:@"Final Touches"];
    
    self.tickCentraliser.hidden = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self applySettings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews {
    CGFloat yOrigin = self.navigationController.navigationBar.frame.size.height + [XENSetupWindow sharedInstance].bar.frame.size.height;
    
    if (_finishedFauxUI) {
        yOrigin = self.view.frame.size.height/2 - 50;
        
        self.headerLabel.frame = CGRectMake(0, yOrigin, self.view.frame.size.width, 50);
        self.doneButton.frame = CGRectMake(0, self.view.frame.size.height/2 + 20, self.view.frame.size.width, 30);
    } else {
        self.headerLabel.frame = CGRectMake(0, yOrigin, self.view.frame.size.width, 50);
        
        CGFloat centraliserWidth = SCREEN_WIDTH*0.8;
        if (IS_IPAD) {
            centraliserWidth = SCREEN_WIDTH*0.4;
        }
        
        CGFloat longestText = 0;
        CGFloat settingsLength = [XENResources getSizeForText:self.viewSettings.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        CGFloat pagesLength = [XENResources getSizeForText:self.viewPages.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        CGFloat coffeeLength = [XENResources getSizeForText:self.viewCoffee.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        CGFloat cleaningLength = [XENResources getSizeForText:self.viewCleaningUp.textLabel.text maxWidth:centraliserWidth - 40 font:self.viewSettings.textLabel.font.fontName fontSize:20].width;
        
        if (settingsLength > longestText) {
            longestText = settingsLength;
        }
        
        if (pagesLength > longestText) {
            longestText = pagesLength;
        }
        
        if (coffeeLength > longestText) {
            longestText = coffeeLength;
        }
        
        if (cleaningLength > longestText) {
            longestText = cleaningLength;
        }
        
        self.tickCentraliser.frame = CGRectMake(0, 0, longestText + 40, 220);
        
        self.tickCentraliser.center = CGPointMake(self.view.frame.size.width/2 + 10, self.view.frame.size.height/2);
        
        // Each view is 40px, gap of 20px.
        self.viewSettings.frame = CGRectMake(0, 0, self.tickCentraliser.frame.size.width, 40);
        self.viewPages.frame = CGRectMake(0, 60, self.tickCentraliser.frame.size.width, 40);
        self.viewCoffee.frame = CGRectMake(0, 120, self.tickCentraliser.frame.size.width, 40);
        self.viewCleaningUp.frame = CGRectMake(0, 180, self.tickCentraliser.frame.size.width, 40);
    }
}

-(void)transitionToWelcome {
    _finishedFauxUI = YES;
    
    self.doneButton.hidden = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.headerLabel.alpha = 0.0;
        self.viewSettings.alpha = 0.0;
        self.viewPages.alpha = 0.0;
        self.viewCoffee.alpha = 0.0;
        self.viewCleaningUp.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.viewSettings.hidden = YES;
        self.viewPages.hidden = YES;
        self.viewCleaningUp.hidden = YES;
        self.viewCoffee.hidden = YES;
        self.tickCentraliser.hidden = YES;
        
        self.headerLabel.text = [XENResources localisedStringForKey:@"Welcome to Xen Lockscreen" value:@"Welcome to Xen Lockscreen"];
        
        self.headerLabel.frame = CGRectMake(0, self.view.frame.size.height/2 - 50, self.view.frame.size.width, 50);
        self.doneButton.frame = CGRectMake(0, self.view.frame.size.height/2 + 20, self.view.frame.size.width, 30);
        
        [UIView animateWithDuration:0.3 animations:^{
            self.headerLabel.alpha = 1.0;
            self.doneButton.alpha = 1.0;
        }];
    }];
}

-(void)dealloc {
    [self.headerLabel removeFromSuperview];
    self.headerLabel = nil;
    
    [self.doneButton removeFromSuperview];
    self.doneButton = nil;
}

@end
