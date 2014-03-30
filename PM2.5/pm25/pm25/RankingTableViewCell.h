//
//  RankingTableViewCell.h
//  pm25
//
//  Created by Paul de Lange on 30/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RankingTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *rankingLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *prefectureLabel;
@property (weak, nonatomic) IBOutlet UILabel *pmLabel;

@end
