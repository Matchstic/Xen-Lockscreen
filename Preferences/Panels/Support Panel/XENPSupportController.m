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

#import "XENPSupportController.h"
#import <sys/utsname.h>
#import <libMobileGestalt.h>
#include <sys/stat.h>
#import <libGitHubIssues.h>
#include <spawn.h>

extern char **environ;

@interface XENPSupportController ()

@end

@implementation XENPSupportController

-(id)specifiers {
    if (_specifiers == nil) {
        NSMutableArray *testingSpecs = [self loadSpecifiersFromPlistName:@"Support" target:self];
        
        _specifiers = testingSpecs;
        _specifiers = [self localizedSpecifiersForSpecifiers:_specifiers];
    }
    
    return _specifiers;
}

-(NSArray *)localizedSpecifiersForSpecifiers:(NSArray *)s {
    int i;
    for (i=0; i<[s count]; i++) {
        if ([[s objectAtIndex: i] name]) {
            [[s objectAtIndex: i] setName:[[self bundle] localizedStringForKey:[[s objectAtIndex: i] name] value:[[s objectAtIndex: i] name] table:nil]];
        }
        if ([[s objectAtIndex: i] titleDictionary]) {
            NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
            for(NSString *key in [[s objectAtIndex: i] titleDictionary]) {
                [newTitles setObject: [[self bundle] localizedStringForKey:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] value:[[[s objectAtIndex: i] titleDictionary] objectForKey:key] table:nil] forKey: key];
            }
            [[s objectAtIndex: i] setTitleDictionary: newTitles];
        }
    }
    
    return s;
}

-(void)openInTwitter:(id)sender {
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/_Matchstic"];
    if ([app canOpenURL:tweetbot])
        [app openURL:tweetbot];
    else {
        NSURL *twitterapp = [NSURL URLWithString:@"twitter:///user?screen_name=_Matchstic"];
        if ([app canOpenURL:twitterapp])
            [app openURL:twitterapp];
        else {
            NSURL *twitterweb = [NSURL URLWithString:@"http://twitter.com/_Matchstic"];
            [app openURL:twitterweb];
        }
    }
}

-(void)openInCydia:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/com.matchstic.xen"]];
}

-(void)composeSupportEmail:(id)sender {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *machineName = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    
    NSString *messageBody = [NSString stringWithFormat:@"%@ %@ :: %@", machineName, [[UIDevice currentDevice] systemVersion], (NSString*)CFBridgingRelease(MGCopyAnswer(kMGUniqueDeviceID))];
    NSArray *toRecipents = [NSArray arrayWithObject:@"matt@incendo.ws"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:@"Xen Feedback"];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    NSString *temporaryDirectory = [UIDevice currentDevice].systemVersion.floatValue < 11 ? @"/tmp" : NSTemporaryDirectory();
    NSString *dpkgLogPath = [temporaryDirectory stringByAppendingString:@"/dpkgl.log"];
    
    // We also want the dpkg log
    pid_t pid;
    char *argv[] = {
        "/usr/bin/dpkg",
        "-l",
        (char*)[[@">" stringByAppendingString:dpkgLogPath] UTF8String],
        NULL
    };
    
    posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
    waitpid(pid, NULL, 0);
    
    [mc addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/dpkgl.log"] mimeType:@"text/plain" fileName:@"dpkgl.txt"];
    
    // Present mail view controller on screen
    [self.navigationController presentViewController:mc animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)openGitHubIssues:(id)sender {
    GIRootViewController *rootModal = [[GIRootViewController alloc] init];
    
    [GIRootViewController registerClientID:@"604b0348c13943dc28fd" andSecret:@"a885c24a81a98d2dae25f64274a267b8f1188daf"];
    [GIRootViewController registerCurrentRepositoryName:@"Xen-Lockscreen" andOwner:@"Matchstic"];
    
    [self.navigationController presentViewController:rootModal animated:YES completion:nil];
}

@end
