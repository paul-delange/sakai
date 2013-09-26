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

typedef enum {
    kSettingsTableCellTypeReset = 0,
    kSettingsTableCellTypeCount
} kSettingsTableCellType;

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
            cell.textLabel.text = NSLocalizedString(@"初期化", @"");
            break;
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
            NSString* title = NSLocalizedString(@"初期化しますか？", @"");
            NSString* msg = NSLocalizedString(@"すべてのデータを除去して、ログイン画面にもどりますか？", @"");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: msg
                                                           delegate: self
                                                  cancelButtonTitle: NSLocalizedString(@"キャンセル", @"")
                                                  otherButtonTitles: NSLocalizedString(@"はい", @""), nil];
            alert.tag = kAlertViewTagConfirmReset;
            [alert show];
            
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
