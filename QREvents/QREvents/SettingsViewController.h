//
//  SettingsViewController.h
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kSettingsTableCellTypeCreate = 0,
    kSettingsTableCellTypeReset,
    kSettingsTableCellTypeCount
} kSettingsTableCellType;

@interface SettingsViewController : UITableViewController

@property (copy, nonatomic) void(^dismiss)(kSettingsTableCellType reason);

@end
