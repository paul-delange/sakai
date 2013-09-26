//
//  ParticipantsViewController.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ParticipantsViewController.h"
#import "ParticipantTableViewCell.h"
#import "AppDelegate.h"

#import <MobileCoreServices/MobileCoreServices.h>

#define kParticipantTableViewCellIdentifier (NSStringFromClass([ParticipantTableViewCell class]))

#define kSegueScannerPopover    @"ScannerSegue"
#define kSegueSettingsPopover   @"SettingsSegue"

@interface ParticipantsViewController () <UISearchBarDelegate, UISearchDisplayDelegate> {
    BOOL _canResignSearchBar;
}

@property (strong, nonatomic) UISearchDisplayController* searchController;
@property (weak, nonatomic) UIPopoverController* scanController;
@property (weak, nonatomic) UIPopoverController* settingsController;
@property (strong, nonatomic) NSFetchedResultsController* resultsController;

@end

@implementation ParticipantsViewController

- (IBAction) searchPushed: (id)sender {
    [self.scanController dismissPopoverAnimated: YES];
    [self.settingsController dismissPopoverAnimated: YES];
    
    UISearchBar* searchBar = [[UISearchBar alloc] initWithFrame: CGRectMake(0, 0, 160, 37)];
    searchBar.delegate = self;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeWords;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    
    UIBarButtonItem* expandedSearchBar = [[UIBarButtonItem alloc] initWithCustomView: searchBar];
    
    [self.navigationItem setRightBarButtonItems: @[self.settingsButton, self.codeButton, self.refreshButton, expandedSearchBar] animated: YES];
    
    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar: searchBar
                                                              contentsController: self];
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;
    self.searchController.delegate = self;
    
    [self.searchDisplayController setActive: YES animated: YES];
    [searchBar becomeFirstResponder];
}

- (IBAction) refreshPushed: (id)sender {
    [self.scanController dismissPopoverAnimated: YES];
    [self.settingsController dismissPopoverAnimated: YES];
    [self.searchController setActive: NO animated: YES];
    
    UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    activityIndicatorView.frame = CGRectMake(0, 0, 35, 35);
    [activityIndicatorView startAnimating];
    
    UIBarButtonItem* activityItem = [[UIBarButtonItem alloc] initWithCustomView: activityIndicatorView];
    
    [self.navigationItem setRightBarButtonItems: @[self.settingsButton, self.codeButton, activityItem, self.searchButton] animated: YES];
    
    [[self objectManager] getObjectsAtPath: kWebServiceListPath
                                parameters: nil
                                   success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                       [self.navigationItem setRightBarButtonItems: @[self.settingsButton, self.codeButton, self.refreshButton, self.searchButton] animated: YES];
                                   } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
                                       [self.navigationItem setRightBarButtonItems: @[self.settingsButton, self.codeButton, self.refreshButton, self.searchButton] animated: YES];
                                   }];
}

- (AppDelegate*) appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (RKObjectManager*) objectManager {
    NSURL* url = [NSURL URLWithString: @"http://www.imaios.com"];
    return [[self appDelegate] objectManagerWithBaseURL: url andEventName: @"I Rock"];
}

- (void) eventReset: (NSNotification*) notification {
    [self.settingsController dismissPopoverAnimated: YES];
    
    [[self appDelegate] showConnectionViewController];
}

#pragma mark - NSObject
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(eventReset:)
                                                     name: kApplicationResetNotification
                                                   object: nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: kApplicationResetNotification
                                                  object: nil];
}

#pragma mark - UIViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[self.settingsButton, self.codeButton, self.refreshButton, self.searchButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if( [identifier isEqualToString: kSegueScannerPopover] ) {
        
        //Check if we are already visible...
        if( [self.scanController isPopoverVisible] )
            return NO;
        
        //Check if we have a camera
#if TARGET_IPHONE_SIMULATOR
        return YES;
#else
        if([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            return YES;
        }
        else {
            //No camera available!!
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: ];
            [alert show];
            
            return NO;
        }
#endif
    }
    else if( [identifier isEqualToString: kSegueSettingsPopover] ) {
        return ![self.settingsController isPopoverVisible];
    }
    
    return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if( [segue isKindOfClass: [UIStoryboardPopoverSegue class]] ) {
        [self.searchController setActive: NO];
        
        UIStoryboardPopoverSegue* popoverSegue = (UIStoryboardPopoverSegue*)segue;
        if( [segue.identifier isEqualToString: kSegueScannerPopover] ) {
            [self.settingsController dismissPopoverAnimated: YES];
            popoverSegue.popoverController.popoverContentSize = CGSizeMake(320, 320);
            self.scanController = popoverSegue.popoverController;
        }
        else if( [segue.identifier isEqualToString: kSegueSettingsPopover] ) {
            [self.scanController dismissPopoverAnimated: YES];
            popoverSegue.popoverController.popoverContentSize = CGSizeMake(256, 320);
            self.settingsController = popoverSegue.popoverController;
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if( tableView == self.tableView ) {
        return [[self.resultsController sections] count];
    }
    else {
        return 10;
    }
}

#pragma mark UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if( tableView == self.tableView ) {
        id<NSFetchedResultsSectionInfo> sectioninfo = [[self.resultsController sections] objectAtIndex: section];
        return [sectioninfo numberOfObjects];
    }
    else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if( tableView == self.tableView ) {
        cell = [tableView dequeueReusableCellWithIdentifier: kParticipantTableViewCellIdentifier forIndexPath: indexPath];
    }
    else {
        cell = [self.tableView dequeueReusableCellWithIdentifier: kParticipantTableViewCellIdentifier];
    }
    
    //Do something incredible!!
    
    return cell;
}

#pragma mark - UISearchBarDelegate
- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton: YES animated: YES];
}

- (void) searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton: NO animated: YES];
    [self.searchController setActive: NO animated: YES];
    
    self.navigationItem.rightBarButtonItems = @[self.settingsButton, self.codeButton, self.refreshButton, self.searchButton];
}

- (BOOL) searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* before = searchBar.text;
    NSString* after = [searchBar.text stringByReplacingCharactersInRange: range withString: text];
    _canResignSearchBar = after.length > before.length;
    
    return YES;
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if( _canResignSearchBar && [searchText length] == 0 ) {
        [searchBar performSelector: @selector(resignFirstResponder)
                        withObject: nil
                        afterDelay: 0.01];
    }
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
}

@end
