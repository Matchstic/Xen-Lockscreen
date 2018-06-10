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

#import "XENLaunchpadDataSource.h"
#include <dlfcn.h>

#warning Private methods used here; SBApplication, SBApplicationController, SBAppViewStatusBarDescriptor, SBUIController, BackBoardServices
/*
 * Functions used in these methods:
 * -(void)requestAnimationToBundleIdentifier:(NSString*)bundleIdentifier
 */

// In theory works up to 9.3.3.

@interface XBApplicationSnapshot : NSObject

@property (nonatomic) long long contentType; // GeneratedDefault=1, SceneContent=0, StaticDefault=2
@property (getter=isExpired, nonatomic, readonly) bool expired;
@property (nonatomic, readonly) bool fileExists;
@property (getter=isFullScreen, nonatomic) bool fullScreen;
@property (nonatomic, readonly) bool hasFullSizedContent;
@property (nonatomic) long long imageOrientation;
@property (nonatomic) double imageScale;
@property (nonatomic) long long interfaceOrientation;
@property (nonatomic, readonly, copy) NSString *path; // !
@property (nonatomic) CGSize referenceSize; /// !
@property (nonatomic, copy) NSString *requiredOSVersion;

@end

@interface XBApplicationSnapshotGroup : NSObject
- (NSSet*)snapshots;
@end

@interface XBApplicationSnapshotManifestImpl : NSObject
- (NSArray*)_allSnapshotGroups; // iOS 10.
- (NSArray*)allSnapshots; // iOS 9
@end

@interface XBApplicationSnapshotManifest : NSObject
@property (nonatomic, readonly) XBApplicationSnapshotManifestImpl *manifestImpl;
@end

@interface SBApplication (Splashboard)
- (XBApplicationSnapshotManifest*)_snapshotManifest;
@end

@interface SBDashBoardViewController (AppLaunch)
- (void)_activateAppBelowDashBoard:(id)arg1 withActions:(id)arg2;
@end

@interface SBWorkspaceApplication : NSObject
+ (id)entityForApplication:(id)arg1;
@end

@implementation XENLaunchpadDataSource

+(XENLaunchpadDataSource*)sharedInstance {
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

-(UIView*)iconImageForBundleIdentifier:(NSString*)bundleIdentifier {
    return [XENResources iconImageViewForBundleIdentifier:bundleIdentifier];
}

-(void)resetSnapshotCache {
    [cachedIdentifiersToPaths removeAllObjects];
}

-(UIView*)snapshotImageForBundleIdentifier:(NSString*)identifier {
    UIView *testImage = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH)];
    testImage.layer.masksToBounds = YES;
    
    // Hold up! We can include Launchpad preview theming here!
    // First, ask XENResources whether there is a possible image we can use
    // This will always be portrait.
    NSString *previewEndString = @"";
    if (IS_IPAD) {
        previewEndString = @"ipad";
    } else if (SCREEN_MAX_LENGTH < 568) {
        previewEndString = @"480";
    } else if (SCREEN_MAX_LENGTH < 667) {
        previewEndString = @"568";
    } else {
        previewEndString = @"667";
    }
    
    UIImage *img = [XENResources themedImageWithName:[NSString stringWithFormat:@"Launchpad/Previews/%@-%@", identifier, previewEndString]];
    if (img) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        imgView.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        [testImage addSubview:imgView];
        
        return testImage;
    }
    
    /*
     * We will make use of SplashBoard.framework's snapshot paths ourselves.
     * Whilst this does leave more potential to break on iOS versions, it does mean we can
     * easily handle snapshot images going forwards; no worries about Apple view weirdness.
     *
     * Note that the comparison against reference size may not be valid when using tweaks 
     * such as Upscale.
     */
    
    // First though, check if we have already cached this identifier.
    if (!cachedIdentifiersToPaths) {
        cachedIdentifiersToPaths = [NSMutableDictionary dictionary];
    }
    
    img = [cachedIdentifiersToPaths objectForKey:identifier];
    if (img) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        imgView.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        [testImage addSubview:imgView];
        
        XENlog(@"Loaded snapshot from cache!");
        
        return testImage;
    }
    
    NSString *path = [self _pathForIdentifier:identifier];
    XENlog(@"Found path: %@", path);
    
    img = [UIImage imageWithContentsOfFile:path];
    
    if (img) {
        XENlog(@"Cached image!");
        [cachedIdentifiersToPaths setObject:img forKey:identifier];
        
        UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
        imgView.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        [testImage addSubview:imgView];
        
        return testImage;
    }
    
    // Fallback if the image couldn't be loaded...
    SBApplication *application = [(SBApplicationController *)[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:identifier];
    id sceneId = [application mainSceneID];
    //id screen = [application _screenFromSceneID:sceneId];
    id statusBarDescriptor = [objc_getClass("SBAppViewStatusBarDescriptor") statusBarDescriptorWithForceHidden:YES];
    
    @try {
        UIView *snapshot = [objc_getClass("SBUIController") zoomViewForApplication:application sceneID:sceneId interfaceOrientation:1 statusBarDescriptor:statusBarDescriptor decodeImage:YES];
        snapshot.frame = CGRectMake(0, 0, SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
        [testImage addSubview:snapshot];
    } @catch (NSException *e) {
        testImage.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    
    return testImage;
}

-(NSString*)_pathForIdentifier:(NSString*)identifier {
    // Not cached, so retrieve it!
    SBApplication *application = [(SBApplicationController *)[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:identifier];
    XBApplicationSnapshotManifestImpl *manImpl = [application _snapshotManifest].manifestImpl;
    
    NSSet *snapshots = nil;
    if ([manImpl respondsToSelector:@selector(_allSnapshotGroups)]) {
        snapshots = [[[manImpl _allSnapshotGroups] firstObject] snapshots];
    } else if ([manImpl respondsToSelector:@selector(allSnapshots)]) {
        snapshots = [[[manImpl allSnapshots] firstObject] snapshots];
    }
    
    CGSize referenceSizeMatch = CGSizeMake(SCREEN_MIN_LENGTH, SCREEN_MAX_LENGTH);
    int scaleMatch = [UIScreen mainScreen].scale;
    NSSet *filteredForSceneContent = [snapshots objectsPassingTest:^(XBApplicationSnapshot *snapshot, BOOL *output) {
        if (CGSizeEqualToSize(snapshot.referenceSize, referenceSizeMatch) && snapshot.imageScale == scaleMatch && snapshot.interfaceOrientation == 1 && !snapshot.expired && snapshot.fileExists &&
            snapshot.contentType == 0) {
            return YES;
        }
        
        return NO;
    }];
    
    NSSet *filteredForGeneratedDefault = [snapshots objectsPassingTest:^(XBApplicationSnapshot *snapshot, BOOL *output) {
        if (CGSizeEqualToSize(snapshot.referenceSize, referenceSizeMatch) && snapshot.imageScale == scaleMatch && snapshot.interfaceOrientation == 1 && !snapshot.expired && snapshot.fileExists &&
            snapshot.contentType == 1) {
            return YES;
        }
        
        return NO;
    }];
    
    NSSet *filteredForStaticDefault = [snapshots objectsPassingTest:^(XBApplicationSnapshot *snapshot, BOOL *output) {
        if (CGSizeEqualToSize(snapshot.referenceSize, referenceSizeMatch) && snapshot.imageScale == scaleMatch && snapshot.interfaceOrientation == 1 && !snapshot.expired && snapshot.fileExists &&
            snapshot.contentType == 2) {
            return YES;
        }
        
        return NO;
    }];
    
    // Now, retrieve the snapshot we want.
    XBApplicationSnapshot *outputSnapshot = [filteredForSceneContent anyObject];
    
    if (!outputSnapshot) {
        outputSnapshot = [filteredForGeneratedDefault anyObject];
    }
    
    if (!outputSnapshot) {
        outputSnapshot = [filteredForStaticDefault anyObject];
    }
    
    // We 100% have a snapshot now, as there will always be a default image available.
    
    // return it.
    return outputSnapshot.path;
}

-(NSArray*)availableBundleIdentifiers {
    // TODO: Filter out applications that are not available any longer on this user's device.
    return [XENResources enabledLaunchpadIdentifiers];
}

-(void)requestAnimationToBundleIdentifier:(NSString*)bundleIdentifier {
    // Is passcode is enabled - can query XENResources for that - we create a new app launch thing like for notifications
    // and then ask to present the passcode.
    if ([XENResources requirePasscodeForLaunchpad]) {
        
        if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
            BBBulletin *bulletin = [[objc_getClass("BBBulletin") alloc] init];
            bulletin.title = @"";
            bulletin.message = @"";
            bulletin.bulletinID = @"com.matchstic.xen.launchpad";
            bulletin.date = [NSDate date];
            bulletin.clearable = YES;
            bulletin.defaultAction = [objc_getClass("BBAction") actionWithLaunchBundleID:bundleIdentifier callblock:nil];
        
            SBLockScreenActionContextFactory *factory = [objc_getClass("SBLockScreenActionContextFactory") sharedInstance];
            SBLockScreenActionContext *ctx = [factory lockScreenActionContextForBulletin:bulletin withOrigin:0 pluginActionsAllowed:YES];
        
            [XENResources setLockscreenActionContext:ctx];
        
            // That will effectively unlock the device though too...
            [XENResources _showPasscode];
        } else {
            // Handle for iOS 10...
            
        }
    } else {
        void *handle = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY);
        void (*BKSDisplaySetSecureMode)(BOOL value) = (void (*)(BOOL))dlsym(handle, "BKSDisplaySetSecureMode");
    
        BKSDisplaySetSecureMode(NO);
    
        if ([UIDevice currentDevice].systemVersion.floatValue < 10) {
            SBCCShortcutModule *shortcutModule = [[[objc_getClass("XENShortcutModule") class] alloc] init];
        
            if ([shortcutModule respondsToSelector:@selector(activateAppWithDisplayID:url:)]) {
                [shortcutModule activateAppWithDisplayID:bundleIdentifier url:nil];
            } else if ([shortcutModule respondsToSelector:@selector(activateAppWithDisplayID:url:unlockIfNecessary:)]) {
                XENlog(@"Trying to activate...");
                [shortcutModule activateAppWithDisplayID:bundleIdentifier url:nil unlockIfNecessary:NO];
            }
        } else {
            SBApplication *application = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
            
            SBWorkspaceApplication *entity = [objc_getClass("SBWorkspaceApplication") entityForApplication:application];
            
            SBDashBoardViewController *vc = [XENResources lsViewController];
            [vc _activateAppBelowDashBoard:entity withActions:nil];
        }
    }
}

@end
