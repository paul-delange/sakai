//
//  SettingsViewController.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "SettingsViewController.h"

#import "AdminLock.h"

#import "ChangePasswordTableViewCell.h"

#define INTERVAL_PICKER_ROW     2
#define PASSCODE_CHANGE_ROW     1

typedef NS_ENUM(NSUInteger, kTableViewItemType) {
    kTableViewItemTypePassword = 0,
    kTableViewItemTypeInterval,
    kTableViewItemTypeResults,
    kTableViewItemTypeDemo,
    //kTableViewItemTypePlaylist,       // -> leads to rejection : https://twitter.com/drbarnard/status/446027284747534336
    kTableViewItemTypeCredits,
    kTableViewItemTypeCount
};

NSString * NSUserDefaultsSlideShowIntervalKey = @"SlideshowInterval";

static inline NSString* NSStringFromNSTimeInterval(NSTimeInterval interval)
{
    if( interval <= 0 )
        return [NSString localizedStringWithFormat: NSLocalizedString(@"%d seconds", @""), 0];
    
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    
    if( minutes > 0 ) {
        if( seconds > 0 ) {
            return [NSString localizedStringWithFormat: NSLocalizedString(@"%dm%ds", @""), minutes, seconds];
        }
        else {
            return [NSString localizedStringWithFormat: NSLocalizedString(@"%d minutes", @""), minutes];
        }
    }
    else {
        return [NSString localizedStringWithFormat: NSLocalizedString(@"%d seconds", @""), seconds];
    }
}

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    BOOL    _showingIntervalPicker;
    BOOL    _showingPasscodeChange;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SettingsViewController

- (void) passwordChanged: (NSNotification*) notification {
    if( _showingPasscodeChange ) {
    
    [self.tableView beginUpdates];
    
    _showingPasscodeChange = NO;
    
    NSIndexPath* passcodeIndexPath = [NSIndexPath indexPathForRow: PASSCODE_CHANGE_ROW
                                                        inSection: 0];
    NSIndexPath* headerIndexPath = [NSIndexPath indexPathForRow: PASSCODE_CHANGE_ROW-1
                                                      inSection: 0];
    
    [self.tableView deleteRowsAtIndexPaths: @[passcodeIndexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    [self.tableView reloadRowsAtIndexPaths: @[headerIndexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    
    [self.tableView endUpdates];
    }
}

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(passwordChanged:)
                                                     name: kAdminLockPasswordChangedNotification
                                                   object: nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"Settings", @"");
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"" style: UIBarButtonItemStylePlain target: nil action: nil];
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {

    if( [identifier isEqualToString: @"PushResultSegue"] ) {
        NSManagedObjectContext* context = NSManagedObjectContextGetMainThreadContext();
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: @"Customer"];
        NSError* error;
        NSInteger count = [context countForFetchRequest: request error: &error];
        DLogError(error);
        
        if( count <= 0 ) {
            
            NSString* title = NSLocalizedString(@"Nobody has been counted", @"");
            NSString* msg = NSLocalizedString(@"Please first confirm an active slideshow has been displayed and that customers have come to see the display.", @"");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: msg
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            [alert show];
            
            return NO;
        }
        else {
            return YES;
        }
    }
    
    return [super shouldPerformSegueWithIdentifier: identifier sender: sender];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString* cellIdentifier;
    
    if( _showingIntervalPicker && indexPath.row == INTERVAL_PICKER_ROW ) {
        cellIdentifier = @"SlideShowPickerCellIdentifier";
    }
    else if( _showingPasscodeChange && indexPath.row == PASSCODE_CHANGE_ROW ) {
        cellIdentifier = @"ChangePasscodeCellIdentifier";
    }
    else {
        switch (indexPath.row) {
            case kTableViewItemTypeInterval:
                cellIdentifier = @"SlideShowIntervalCellIdentifier";
                break;
            case kTableViewItemTypeResults:
            case kTableViewItemTypeCredits:
            case kTableViewItemTypeDemo:
            //case kTableViewItemTypePlaylist:
                cellIdentifier = @"SettingsDisclosureCellIdentifier";
                break;
            case kTableViewItemTypePassword:
                cellIdentifier = @"SettingsPasscodeCellIdentifier";
            default:
                break;
        }
    }
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
    
    NSInteger item = indexPath.row;
    
    if( _showingIntervalPicker && item > INTERVAL_PICKER_ROW ) {
        item--;
    }
    else if( _showingPasscodeChange && item > PASSCODE_CHANGE_ROW ) {
        item--;
    }
    
    if( [cell.reuseIdentifier isEqualToString: @"SlideShowPickerCellIdentifier"] ) {
        UIPickerView* pickerView = (UIPickerView*)[cell viewWithTag: 99];
        NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey: NSUserDefaultsSlideShowIntervalKey];
        switch ((NSInteger)interval) {
            case 5:
                [pickerView selectRow: 0 inComponent: 0 animated: NO];
                break;
            case 10:
                [pickerView selectRow: 1 inComponent: 0 animated: NO];
                break;
            case 30:
                [pickerView selectRow: 2 inComponent: 0 animated: NO];
                break;
            case 60:
                [pickerView selectRow: 3 inComponent: 0 animated: NO];
                break;
            case 300:
                [pickerView selectRow: 4 inComponent: 0 animated: NO];
                break;
            default:
                break;
        }
    }
    
    if( [cell.reuseIdentifier isEqualToString: @"ChangePasscodeCellIdentifier"] ) {
        ChangePasswordTableViewCell* cast = (ChangePasswordTableViewCell*)cell;
        if( [AdminLock tryLock] ) {
            [cast.oldPasswordField becomeFirstResponder];
        }
        else {
            [cast.passwordField becomeFirstResponder];
        }
    }
    
    if( !_showingIntervalPicker && !_showingPasscodeChange ) {
    switch (item) {
        case kTableViewItemTypeInterval:
        {
            NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey: NSUserDefaultsSlideShowIntervalKey];
            cell.textLabel.text = NSLocalizedString(@"Slideshow Interval", @"");
            cell.detailTextLabel.text = NSStringFromNSTimeInterval(interval);
            break;
        }
        case kTableViewItemTypePassword:
        {
            cell.textLabel.text = NSLocalizedString(@"Password", @"");
            
            NSUInteger numberOfLetters = [AdminLock lockLength];
            
            if( numberOfLetters ) {
                UILabel* passwordLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, 160, 32.)];
                passwordLabel.backgroundColor = [UIColor clearColor];
                passwordLabel.textAlignment = NSTextAlignmentRight;
                
                NSMutableString* encodedString = [[NSMutableString alloc] initWithCapacity: numberOfLetters];
                for(NSUInteger i=0;i<numberOfLetters;i++) {
                    [encodedString appendString: @"*"];
                }
                
                passwordLabel.text = encodedString;
                passwordLabel.textColor = [UIColor grayColor];
                
                cell.accessoryView = passwordLabel;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            break;
        }
        case kTableViewItemTypeResults:
        {
            cell.textLabel.text = NSLocalizedString(@"View Statistics", @"");
            break;
        }
        case kTableViewItemTypeDemo:
        {
            cell.textLabel.text = NSLocalizedString(@"Recognition Demo", @"");
            break;
        }
        case kTableViewItemTypeCredits:
            cell.textLabel.text = NSLocalizedString(@"Credits", @"");
            break;
        /*case kTableViewItemTypePlaylist:
        {
            cell.textLabel.text = NSLocalizedString(@"Playlist", @"");
            break;
        } */
        default:
            break;
    }
    }
    
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = kTableViewItemTypeCount;
    
    if( _showingIntervalPicker || _showingPasscodeChange ) {
        return count + 1;
    }
    
    return count;
}

#pragma mark - UITableViewDelegate
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if( _showingIntervalPicker && indexPath.row == INTERVAL_PICKER_ROW )
        return 162.;
    else if( _showingPasscodeChange && indexPath.row == PASSCODE_CHANGE_ROW )
        return 168.;
    else
        return 44.;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = indexPath.row;
    
    if( _showingPasscodeChange ) {
        [tableView beginUpdates];
        
        _showingPasscodeChange = NO;
        
        NSIndexPath* pickerIndexPath = [NSIndexPath indexPathForRow: PASSCODE_CHANGE_ROW
                                                          inSection: indexPath.section];
        
        [self.tableView deleteRowsAtIndexPaths: @[pickerIndexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
        
        [tableView endUpdates];
        
        if( row >= PASSCODE_CHANGE_ROW )
            row--;
        
        if( row == PASSCODE_CHANGE_ROW-1 ) {
             [tableView deselectRowAtIndexPath: indexPath animated: YES];
        }
        else {
            [self tableView: tableView didSelectRowAtIndexPath: [NSIndexPath indexPathForRow: row inSection: indexPath.section]];
        }
        
        return;
    }
    
    if( _showingIntervalPicker ) {
        [tableView beginUpdates];
        
        _showingIntervalPicker = NO;
        
        NSIndexPath* pickerIndexPath = [NSIndexPath indexPathForRow: INTERVAL_PICKER_ROW
                                                          inSection: indexPath.section];
        
        [self.tableView deleteRowsAtIndexPaths: @[pickerIndexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
        
        [tableView endUpdates];
        
        if( row >= INTERVAL_PICKER_ROW)
            row--;
        
        if( row == INTERVAL_PICKER_ROW-1 ) {
            [tableView deselectRowAtIndexPath: indexPath animated: YES];
        }
        else {
            [self tableView: tableView didSelectRowAtIndexPath: [NSIndexPath indexPathForRow: row inSection: indexPath.section]];
        }
        
        return;
    }
    
    if( !_showingIntervalPicker && row == INTERVAL_PICKER_ROW - 1 ) {
        [tableView beginUpdates];
        
        NSIndexPath* pickerIndexPath = [NSIndexPath indexPathForRow: INTERVAL_PICKER_ROW
                                                          inSection: indexPath.section];
        _showingIntervalPicker = YES;
        [self.tableView insertRowsAtIndexPaths: @[pickerIndexPath] withRowAnimation: UITableViewRowAnimationFade];
        
        [tableView endUpdates];
    }
    else if( !_showingPasscodeChange && row == PASSCODE_CHANGE_ROW - 1 ) {
        [tableView beginUpdates];
        
        NSIndexPath* pickerIndexPath = [NSIndexPath indexPathForRow: PASSCODE_CHANGE_ROW
                                                          inSection: indexPath.section];
        _showingPasscodeChange = YES;
        [self.tableView insertRowsAtIndexPaths: @[pickerIndexPath] withRowAnimation: UITableViewRowAnimationFade];
        
        [tableView endUpdates];
    }
    else {
        switch (row) {
            case kTableViewItemTypePassword:
            {
                break;
            }
            case kTableViewItemTypeResults:
            {
                NSString* identifer = @"PushResultSegue";
                id sender = [tableView cellForRowAtIndexPath: indexPath];
                if( [self shouldPerformSegueWithIdentifier: identifer sender: sender] ) {
                    [self performSegueWithIdentifier: identifer sender: sender];
                }
                break;
            }
            case kTableViewItemTypeCredits:
            {
                NSString* identifier = @"PushCreditSegue";
                id sender = [tableView cellForRowAtIndexPath: indexPath];
                [self performSegueWithIdentifier: identifier sender: sender];
                break;
            }
            case kTableViewItemTypeDemo:
            {
                NSString* identifier = @"PushDemoSegue";
                id sender = [tableView cellForRowAtIndexPath: indexPath];
                [self performSegueWithIdentifier: identifier sender: sender];
                break;
            }
            /*case kTableViewItemTypePlaylist:
            {
                NSString *stringURL = @"photos-redirect:";
                NSURL *url = [NSURL URLWithString:stringURL];
                [[UIApplication sharedApplication] openURL: url];
            }*/
            default:
                break;
        }
    }
    
     [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

- (BOOL) tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView cellForRowAtIndexPath: indexPath];
    return cell.selectionStyle != UITableViewCellSelectionStyleNone;
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 5;
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    switch (row) {
        case 0:
            return [NSString stringWithFormat: NSLocalizedString(@"%d seconds", @""), 5];
        case 1:
            return [NSString stringWithFormat: NSLocalizedString(@"%d seconds", @""), 10];
        case 2:
            return [NSString stringWithFormat: NSLocalizedString(@"%d seconds", @""), 30];
        case 3:
            return [NSString stringWithFormat: NSLocalizedString(@"%d minutes", @""), 1];
        case 4:
            return [NSString stringWithFormat: NSLocalizedString(@"%d minutes", @""), 5];
        default:
            return @"";
    }
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    NSTimeInterval interval = 5;
    
    switch (row) {
        case 1:
            interval = 10;
            break;
        case 2:
            interval = 30;
            break;
        case 3:
            interval = 60;
            break;
        case 4:
            interval = 60 * 5;
            break;
        default:
            break;
    }
    
    [[NSUserDefaults standardUserDefaults] setDouble: interval forKey: NSUserDefaultsSlideShowIntervalKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView beginUpdates];
    
    NSIndexPath* pickerIndexPath = [NSIndexPath indexPathForRow: INTERVAL_PICKER_ROW
                                                      inSection: 0];
    _showingIntervalPicker = NO;
    [self.tableView deleteRowsAtIndexPaths: @[pickerIndexPath]
                          withRowAnimation: UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    [self.tableView reloadRowsAtIndexPaths: @[[NSIndexPath indexPathForRow: INTERVAL_PICKER_ROW-1
                                                                 inSection: 0]]
                          withRowAnimation: UITableViewRowAnimationFade];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 32.;
}

@end
