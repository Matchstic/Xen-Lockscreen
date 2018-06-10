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

/*
 * Toggles on iOS 10 is very different affair to that on iOS 9.
 *
 * Each "page" of the CC is now dropped onto a UIScrollView so that we can vertically scroll through them.
 * The old statistics panel will remain in use, though we are required to build a wrapper around it to 
 * nicely match our new UI.
 */

/*
 Toggles pages:
 
 // System
 CCUIControlCenterPageContainerViewController
 - NCMaterialView
 - UIView (CCUISystemControlsPageViewController
 
 // Media
 CCUIControlCenterPageContainerViewController
 - NCMaterialView
 - MPUControlCenterMediaControlsViewController
 
 * Thus, it appears we're looking at a configurable number of CCUIControlCenterPageContainerViewController
 * loaded onto a CCUIImmediateTouchScrollView, in turn on top of CCUIControlCenterContainerView (CCUIControlCenterViewController)
 
 Where do we request the pages from? CCUIControlCenterViewController knows which pages are available, and how many.
 */

/*
 * As of 30/12/16, the Toggles shortcuts do NOT work well; this page is still visible over the top of the app?!
 */

#import "XENTogglesiOS10ViewController.h"
#import <objc/runtime.h>

@interface XENTogglesiOS10ViewController ()

@end

@implementation XENTogglesiOS10ViewController

-(void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.view = view;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 12345;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.scrollView setDelaysContentTouches:YES];
    [self.scrollView setAlwaysBounceVertical:YES];
    [self.scrollView setAlwaysBounceHorizontal:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setClipsToBounds:NO];
    self.scrollView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    
    [self.view addSubview:self.scrollView];
    
    self.ccController = [[objc_getClass("XENControlCenterViewController") alloc] init];
    [self.ccController loadView];
    [self.ccController viewDidLoad];
    
    NSArray *sorted = [self _sortedVisibleViewControllers];
    
    // View controllers should now be available.
    for (CCUIControlCenterPageContainerViewController *controller in sorted) {
        [self addChildViewController:controller];
        [self.scrollView addSubview:controller.view];
        
        controller.contentViewController.delegate = self.ccController;
    }
}

-(NSArray*)_sortedVisibleViewControllers {
    NSArray *sorted = [self.ccController sortedVisibleViewControllers];
    
    NSMutableArray *output = [NSMutableArray array];
    
    for (CCUIControlCenterPageContainerViewController *controller in sorted) {
        BOOL isAvailable = YES;
        
        // XXX: App Center compatibility.
        // We check the contentViewController property's class, and ignore if needed.
        
        if ([controller.contentViewController isKindOfClass:objc_getClass("ACAppSelectionPageViewController")] ||
            [controller.contentViewController isKindOfClass:objc_getClass("ACAppPageViewController")]) {
            isAvailable = NO;
        }
        
        if (isAvailable) {
            [output addObject:controller];
        }
    }
    
    return output;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // XXX: It's possible to get an exception here... How?
    @try {
        [self.ccController controlCenterWillBeginTransition];
        //self.ccController.revealPercentage = 1.0; // Removed for Cistem Aporino compatibility.
        [self.ccController controlCenterWillPresent];
        [self.ccController controlCenterWillFinishTransitionOpen:YES withDuration:0.0];
        [self.ccController controlCenterDidFinishTransition];
        [self.ccController viewWillAppear:animated];
    } @catch (NSException* e) {
        XENlog(@"Something went really wrong trying to load the CC pages... %@", e);
    }
    

    for (CCUIControlCenterPageContainerViewController *contr in [self _sortedVisibleViewControllers]) {
        @try {
            if ([contr.contentViewController respondsToSelector:@selector(controlCenterDidScrollToThisPage:)]) {
                [contr.contentViewController controlCenterDidScrollToThisPage:NO];
            }
        } @catch (NSException* e) {
            XENlog(@"Something went really wrong trying to do didScroll... %@", e);
        }
    }
    
    for (UIViewController *contr in self.childViewControllers) {
        // propogate appear message through children.
        [self propogateDownAppearFromController:contr];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    for (UIViewController *contr in self.childViewControllers) {
        // propogate appear message through children.
        [self propogateDownDisappearFromController:contr];
    }
}

-(void)_layoutScrollView {
    // Layout views for the scroll view as needed, and update content size.
    NSArray *sorted = [self _sortedVisibleViewControllers];
    
    UIEdgeInsets insets = [self.ccController _marginEdgeInsets];
    
    CGFloat yOrigin = 0;
    // View controllers should now be available.
    for (UIViewController *controller in [sorted copy]) {
        CGRect frame = [self.ccController _frameForChildViewController:controller];
        frame.size.width = self.scrollView.frame.size.width - insets.left - insets.right;
        
        controller.view.frame = CGRectMake(self.scrollView.frame.size.width/2 - frame.size.width/2, yOrigin, frame.size.width, frame.size.height);
        
        yOrigin += controller.view.frame.size.height + 10; // Final 10 acts as bottom inset.
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, yOrigin);
    
    CGFloat topInset = IS_IPAD ? 40 : 20;
    self.scrollView.contentInset = UIEdgeInsetsMake(topInset, 0, topInset, 0);
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.scrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self _layoutScrollView];
}

-(void)propogateDownDisappearFromController:(UIViewController*)contr {
    if (contr) {
        [contr viewWillDisappear:YES];
        [contr viewDidDisappear:YES];
        
        for (UIViewController *sub in contr.childViewControllers) {
            [self propogateDownDisappearFromController:sub];
        }
    }
}

-(void)propogateDownAppearFromController:(UIViewController*)contr {
    if (contr) {
        [contr viewWillAppear:YES];
        [contr viewDidAppear:YES];
        
        for (UIViewController *sub in contr.childViewControllers) {
            [self propogateDownAppearFromController:sub];
        }
    }
}

#pragma mark Inherited things

-(void)rotateToOrientation:(int)orient {
    self.scrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self _layoutScrollView];
}

-(void)resetForScreenOff {
}

-(void)resetViewForUnlock {
    [super resetViewForUnlock];
    
    [self.ccController controlCenterWillBeginTransition];
    [self.ccController controlCenterWillFinishTransitionOpen:NO withDuration:0.0];
    [self.ccController controlCenterDidFinishTransition];
    
    self.ccController = nil;
    
    for (UIViewController *contr in self.childViewControllers) {
        // propogate down through it's children.
        [self propogateDownDisappearFromController:contr];
        
        [contr removeFromParentViewController];
        [contr.view removeFromSuperview];
    }
}

-(BOOL)wantsBlurredBackground {
    return NO;
}

-(NSString*)name {
    return [XENResources localisedStringForKey:@"Toggles" value:@"Toggles"];
}

-(NSString*)uniqueIdentifier {
    return @"com.matchstic.toggles.ios10";
}

+(BOOL)supportsCurrentiOSVersion {
    return [UIDevice currentDevice].systemVersion.floatValue >= 10.0;
}

-(XENDeviceSupport)supportedDevices {
    return kSupportsAll;
}

@end
