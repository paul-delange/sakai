//
//  SettingsViewController.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "SettingsViewController.h"

#import "AppDelegate.h"

#define  kAlertViewTagConfirmReset   7162

#define  kTableViewCellIdentifier       @"SettingsTableViewCell"

@interface SettingsViewController () <UIAlertViewDelegate>

@end

@implementation SettingsViewController

- (AppDelegate*) appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kSettingsTableCellTypeCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kTableViewCellIdentifier forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case kSettingsTableCellTypeReset:
            cell.textLabel.text = NSLocalizedString(@"Reset", @"");
            break;
        case kSettingsTableCellTypeViewMode:
        {
            BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey: kUserPreferenceViewModeKey];
            if( val )
                cell.textLabel.text = NSLocalizedString(@"Exit View Mode", @"");
            else
                cell.textLabel.text = NSLocalizedString(@"Enter View Mode", @"");
            
            break;
        }
        case kSettingsTableCellTypeCreate:
            cell.textLabel.text = NSLocalizedString(@"Add a participant", @"");
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    switch (indexPath.row) {
        case kSettingsTableCellTypeReset:
        {
            NSString* title = NSLocalizedString(@"Are you sure?", @"");
            NSString* msg = NSLocalizedString(@"This will remove all event data and return you to the event login screen.", @"");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: msg
                                                           delegate: self
                                                  cancelButtonTitle: NSLocalizedString(@"Cancel", @"")
                                                  otherButtonTitles: NSLocalizedString(@"OK", @""), nil];
            alert.tag = kAlertViewTagConfirmReset;
            [alert show];
            
            break;
        }
        case kSettingsTableCellTypeViewMode:
        {
            BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey: kUserPreferenceViewModeKey];
            val = !val;
            
            [[NSUserDefaults standardUserDefaults] setBool: val forKey: kUserPreferenceViewModeKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if( self.dismiss ) {
                self.dismiss(kSettingsTableCellTypeViewMode);
            }
            else {
                [tableView reloadRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
            }
            
            break;
        }
        case kSettingsTableCellTypeCreate:
        {
            if( self.dismiss )
                self.dismiss(kSettingsTableCellTypeCreate);
            
            break;
        }
        default:
            break;
    }
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case kAlertViewTagConfirmReset:
        {
            if( alertView.cancelButtonIndex != buttonIndex ) {
                //Start reset
                [[self appDelegate] reset];
            }
            break;
        }
        default:
            break;
    }
}

@end
