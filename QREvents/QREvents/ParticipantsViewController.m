//
//  ParticipantsViewController.m
//  QREvents
//
//  Created by Paul De Lange on 25/09/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "ParticipantsViewController.h"
#import "SettingsViewController.h"
#import "ScannerViewController.h"
#import "CreateViewController.h"
#import "PeekabooViewController.h"

#import "ParticipantTableViewCell.h"
#import "EventSummaryView.h"

#import "AppDelegate.h"

#import "Participant.h"
#import "Event.h"

#import <MobileCoreServices/MobileCoreServices.h>

#define kParticipantTableViewCellIdentifier (NSStringFromClass([ParticipantTableViewCell class]))

#define kSegueSettingsPopover   @"SettingsSegue"
#define kSegueCreate            @"CreateSegue"

@interface ParticipantsViewController () <UISearchBarDelegate, UISearchDisplayDelegate, NSFetchedResultsControllerDelegate> {
    BOOL _canResignSearchBar;
    
    __strong NSArray* _searchResults;
    NSString* _participantCodeToPassOn;
    
    dispatch_source_t _refreshTimer;
    
    Event* _event;
}

@property (strong, nonatomic) UISearchDisplayController* searchController;
@property (weak, nonatomic) UIPopoverController* scanController;
@property (weak, nonatomic) UIPopoverController* settingsController;
@property (strong, nonatomic) NSFetchedResultsController* resultsController;

@end

@implementation ParticipantsViewController

- (IBAction) unwindCreate: (UIStoryboardSegue*)sender {
    [self dismissViewControllerAnimated: YES
                             completion: nil];
}

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
    if(![self objectManager])
        return;
    
    [self.scanController dismissPopoverAnimated: YES];
    [self.settingsController dismissPopoverAnimated: YES];
    [self.searchController setActive: NO animated: YES];
    
    UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    activityIndicatorView.frame = CGRectMake(0, 0, 35, 35);
    [activityIndicatorView startAnimating];
    
    UIBarButtonItem* activityItem = [[UIBarButtonItem alloc] initWithCustomView: activityIndicatorView];
    
    [self.navigationItem setRightBarButtonItems: @[self.settingsButton, self.codeButton, activityItem, self.searchButton] animated: YES];
    
/*#if USING_PARSE_DOT_COM
    NSDictionary* params = @{@"$relatedTo" : @{ @"object" : @{ @"__type" : @"Pointer", @"className" : @"Event", @"objectId" : _event.primaryKey}, @"key" : @"event"}};
    NSData* parsed = [NSJSONSerialization dataWithJSONObject: params options: 0 error: nil];
    NSString* where = [[NSString alloc] initWithData: parsed encoding: NSUTF8StringEncoding];
    NSString* path = [NSString stringWithFormat: @"%@?where=%@", kWebServiceListPath, [where stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
#else*/
    NSString* path = kWebServiceListPath;
//#endif
    
    [[self objectManager] getObjectsAtPath: path
                                parameters: nil
                                   success: ^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                       [self.navigationItem setRightBarButtonItems: @[self.settingsButton, self.codeButton, self.refreshButton, self.searchButton] animated: YES];
                                   } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
                                       [self.navigationItem setRightBarButtonItems: @[self.settingsButton, self.codeButton, self.refreshButton, self.searchButton] animated: YES];
                                   }];
}

- (IBAction)cameraTogglePushed:(id)sender {
    AppDelegate* delegate = [self appDelegate];
    PeekabooViewController* splitViewController = (PeekabooViewController*)delegate.window.rootViewController;
    
    [splitViewController togglePeekingController: sender];
    
    ScannerViewController* scannerVC = (ScannerViewController*)splitViewController.masterViewController;
    scannerVC.manuallyAddParticipant = ^(NSString* participantCode) {
        [self.scanController dismissPopoverAnimated: YES];
        _participantCodeToPassOn = participantCode;
        [self performSegueWithIdentifier: kSegueCreate sender: nil];
    };
    scannerVC.scannedParticipant = ^(Participant* participant) {
        NSIndexPath* indexPath = [self.resultsController indexPathForObject: participant];
        [self.tableView selectRowAtIndexPath: indexPath
                                    animated: YES
                              scrollPosition: UITableViewScrollPositionTop];
        
        
        double delayInSeconds = 3.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.tableView deselectRowAtIndexPath: indexPath animated: YES];
        });
    };
    
}

- (AppDelegate*) appDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (RKObjectManager*) objectManager {
    return [[self appDelegate] objectManager];
}

- (void) eventReset: (NSNotification*) notification {
    _resultsController = nil;
    [self.settingsController dismissPopoverAnimated: YES];
    
    if( ![self objectManager] ) {
        [[self appDelegate] showConnectionViewController];
    }
    else {
        __autoreleasing NSError* error;
        [self.resultsController performFetch: &error];
        NSAssert(!error, @"Error fetching results: %@", error);
        
        [self refreshPushed: nil];
    }
    
    [self.tableView reloadData];
}

- (NSFetchedResultsController*) resultsController {
    if( !_resultsController ) {
        if( [self objectManager] ) {
            NSManagedObjectContext* context = [self objectManager].managedObjectStore.mainQueueManagedObjectContext;
            
            NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([Participant class])];
            
            [fetchRequest setSortDescriptors: @[[NSSortDescriptor sortDescriptorWithKey: @"affiliation" ascending: YES],    //Group by department
                                                [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES]]];         //Then alphabetically
            
            [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"primaryKey != nil"]];   //TODO: change this to the event pointer
            
            _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest
                                                                     managedObjectContext: context
                                                                       sectionNameKeyPath: @"company"
                                                                                cacheName: nil];
            _resultsController.delegate = self;
            
            
            EventSummaryView* summaryView = (EventSummaryView*)self.navigationItem.titleView;
            summaryView.event = [Event currentEvent];
        }
    }
    
    return _resultsController;
}

- (void) configureCell: (ParticipantTableViewCell*) cell atIndexPath: (NSIndexPath*) indexPath forSearch: (BOOL) isSearch {
    NSParameterAssert([cell isKindOfClass: [ParticipantTableViewCell class]]);
    
    Participant* participant;
    
    if( isSearch ) {
        NSUInteger index = indexPath.row;
        participant = [_searchResults objectAtIndex: index];
    }
    else {
        participant = [self.resultsController objectAtIndexPath: indexPath];
    }
    
    cell.nameLabel.text = participant.name;
    cell.organizationLabel.text = participant.affiliation;
}

#pragma mark - NSObject
- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(eventReset:)
                                                     name: kApplicationResetNotification
                                                   object: nil];
        
        _refreshTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_refreshTimer, DISPATCH_TIME_NOW, 60 * 2 * NSEC_PER_SEC, DISPATCH_TIME_FOREVER);
        dispatch_source_set_event_handler(_refreshTimer, ^{
            [self refreshPushed: self.refreshButton];
        });
    }
    return self;
}

- (void) dealloc {
    dispatch_source_cancel(_refreshTimer);
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: kApplicationResetNotification
                                                  object: nil];
}

#pragma mark - UIViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItems = @[self.settingsButton, self.codeButton, self.refreshButton, self.searchButton];
    
    
    EventSummaryView* summaryView = [[EventSummaryView alloc] initWithFrame: CGRectMake(0, 0, 150, 44)];
    self.navigationItem.titleView = summaryView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if( [identifier isEqualToString: kSegueSettingsPopover] ) {
        return ![self.settingsController isPopoverVisible];
    }
    
    return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if( [segue isKindOfClass: [UIStoryboardPopoverSegue class]] ) {
        [self.searchController setActive: NO];
        
        UIStoryboardPopoverSegue* popoverSegue = (UIStoryboardPopoverSegue*)segue;
        if( [segue.identifier isEqualToString: kSegueSettingsPopover] ) {
            [self.scanController dismissPopoverAnimated: YES];
            popoverSegue.popoverController.popoverContentSize = CGSizeMake(256, 320);
            self.settingsController = popoverSegue.popoverController;
            
            SettingsViewController* settingsVC = (SettingsViewController*)segue.destinationViewController;
            settingsVC.dismiss = ^(kSettingsTableCellType reason) {
                [self.settingsController dismissPopoverAnimated: YES];
                
                switch (reason) {
                    case kSettingsTableCellTypeCreate:
                    {
                        [self performSegueWithIdentifier: kSegueCreate sender: nil];
                        break;
                    }
                    default:
                        break;
                }
            };
        }
    }
    else {
        if( [segue.identifier isEqualToString: kSegueCreate] ) {
            UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
            CreateViewController* createVC = (CreateViewController*)navController.viewControllers.lastObject;
            createVC.participantCode = _participantCodeToPassOn;
            _participantCodeToPassOn = nil;
        }
        else if([segue.identifier isEqualToString: kSegueConnectModal] ) {
            
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if( tableView == self.tableView ) {
        return [[self.resultsController sections] count];
    }
    else {
        return 1;
    }
}

- (NSArray*) sectionIndexTitlesForTableView:(UITableView *)tableView {
    if( tableView == self.tableView ) {
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
    else {
        return nil;
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if( tableView == self.tableView ) {
        id<NSFetchedResultsSectionInfo> info = [[self.resultsController sections] objectAtIndex: section];
        return [info name];
    }
    else {
        return nil;
    }
}

- (NSInteger) tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if( tableView == self.tableView ) {
        NSInteger localizedIndex = [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
        NSArray *localizedIndexTitles = [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
        
        for(int currentLocalizedIndex = localizedIndex; currentLocalizedIndex > 0; currentLocalizedIndex--) {
            for(int frcIndex = 0; frcIndex < [[self.resultsController sections] count]; frcIndex++) {
                id<NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:frcIndex];
                NSString *indexTitle = sectionInfo.indexTitle;
                if([indexTitle isEqualToString: [localizedIndexTitles objectAtIndex:currentLocalizedIndex]]) {
                    return frcIndex;
                }
            }
        }
    }
    
    /* or
     NSInteger section = 0;
     for (id <NSFetchedResultsSectionInfo> sectionInfo in [_fetchedResultsController sections]) {
     if ([sectionInfo.indexTitle compare:title] >= 0)
     break;
     section++;
     }
     return section;
     */
    
    return 0;
    
}

#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if( tableView == self.tableView ) {
        id<NSFetchedResultsSectionInfo> sectioninfo = [[self.resultsController sections] objectAtIndex: section];
        return [sectioninfo numberOfObjects];
    }
    else {
        return _searchResults.count;
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
    
    [self configureCell: (ParticipantTableViewCell*)cell atIndexPath: indexPath forSearch: tableView != self.tableView];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
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
    else {
        if( searchText.length ) {
            NSFetchRequest* request = [self.resultsController.fetchRequest copy];
            NSPredicate* notNilPredicate = request.predicate;
            NSParameterAssert(notNilPredicate);
            
            NSPredicate* searchTermPredicate = [NSPredicate predicateWithFormat: @"name CONTAINS[cd] %@", searchText];
            
            [request setPredicate: [NSCompoundPredicate andPredicateWithSubpredicates: @[notNilPredicate, searchTermPredicate]]];
            
            NSManagedObjectContext* context = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
            
            __autoreleasing NSError* error;
            _searchResults = [context executeFetchRequest: request error: &error];
            NSAssert(!error, @"Error occurred while searching the results: %@", error);
            return;
        }
    }
    
    _searchResults = nil;
}

#pragma mark - NSFetchedResultsController
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell: (ParticipantTableViewCell*)[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath: indexPath
                      forSearch: NO];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    
    Event* event = [Event currentEvent];
    
}

@end
