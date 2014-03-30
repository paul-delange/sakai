//
//  RankingViewController.m
//  pm25
//
//  Created by Paul de Lange on 30/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "RankingViewController.h"

#import "RankingTableViewCell.h"

NSString* const NSUserDefaultsLastUpdatedRankingKey =  @"ranking.last.update.data";
NSString* const NSUserDefaultsLastUpdatedRankingDateKey =  @"ranking.last.update.date";

@interface RankingViewController () <UITableViewDataSource> {
    NSURLSessionDataTask*   _dataTask;
}

@property (copy, nonatomic) NSArray* data;

@end

@implementation RankingViewController

- (void) fetchRankingForLimit: (NSUInteger) limit {
    
    [_dataTask cancel];
    
    NSString* dataPath = [NSString stringWithFormat: @"http://api.airtrack.info/data/ranking?max=%d", limit];
    NSURL* dataURL = [NSURL URLWithString: dataPath];
    
    _dataTask = [[NSURLSession sharedSession] dataTaskWithURL: dataURL
                                            completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if( !error ) {
#if DEBUG
                                                    NSLog(@"Response: %@", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
#endif
                                                    id object = [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];
                                                    if( [object isKindOfClass: [NSArray class]] ) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            self.data = object;
                                                            
                                                            [[NSUserDefaults standardUserDefaults] setObject: object forKey: NSUserDefaultsLastUpdatedRankingKey];
                                                            [[NSUserDefaults standardUserDefaults] setObject: [NSDate date]
                                                                                                      forKey: NSUserDefaultsLastUpdatedRankingDateKey];
                                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                                            
                                                            [self.refreshControl endRefreshing];
                                                        });
                                                    }
                                                }
                                            }];
    
    [_dataTask resume];
}

- (void) setData:(NSArray *)data {
    _data = [data copy];
    [self.tableView reloadData];
}

#pragma mark - Actions
- (IBAction) refreshPushed:(UIRefreshControl*)sender {
    [self fetchRankingForLimit: 25];
}

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        NSArray* oldData = [[NSUserDefaults standardUserDefaults] objectForKey: NSUserDefaultsLastUpdatedRankingKey];
        if( oldData )
            _data = [oldData copy];
    }
    
    return self;
}

#pragma mark - UIViewController
- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.refreshControl.tintColor = [UIColor whiteColor];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"Refreshing...", @"")
                                                                     attributes: @{
                                                                                   NSForegroundColorAttributeName : [UIColor whiteColor]
                                                                                   }];
    [self.refreshControl addTarget: self action: @selector(refreshPushed:) forControlEvents: UIControlEventValueChanged];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
 
    [self refreshPushed: self.refreshControl];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RankingTableViewCell* cell = (RankingTableViewCell*)[tableView dequeueReusableCellWithIdentifier: @"RankingCellIdentifer" forIndexPath: indexPath];
    
    NSDictionary* ranking = self.data[indexPath.item];
    
    cell.rankingLabel.text = ranking[@"rank"];
    cell.pmLabel.text = ranking[@"pm25"];
    cell.locationLabel.text = ranking[@"name"];
    cell.prefectureLabel.text = ranking[@"pref"];
    
    NSInteger rank = [ranking[@"rank"] integerValue];
    switch (rank) {
        case 1:
            cell.rankingLabel.textColor = [UIColor colorWithRed: 216/255. green: 159/255. blue: 18/255. alpha: 1.];
            break;
        case 2:
            cell.rankingLabel.textColor = [UIColor colorWithRed: 194/255. green: 194/255. blue: 194/255. alpha: 1.];
            break;
        case 3:
            cell.rankingLabel.textColor = [UIColor colorWithRed: 180/255. green: 92/255. blue: 22/255. alpha: 1.];
            break;
        default:
            cell.rankingLabel.textColor = [UIColor whiteColor];
            break;
    }
    
    return cell;
}

/*- (NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSDate* updateDate = [[NSUserDefaults standardUserDefaults] objectForKey: NSUserDefaultsLastUpdatedRankingDateKey];
    
    if( updateDate ) {
        NSString* format = NSLocalizedString(@"Updated: %@", @"");
        return [NSString stringWithFormat: format, [NSDateFormatter localizedStringFromDate: updateDate
                                                                                                        dateStyle: NSDateFormatterMediumStyle
                                                                                                        timeStyle: NSDateFormatterShortStyle]];
    }
    else {
        return NSLocalizedString(@"Refreshing...", @"");
    }
}*/

@end
