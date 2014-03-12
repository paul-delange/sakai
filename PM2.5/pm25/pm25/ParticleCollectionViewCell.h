//
//  ParticleCollectionViewCell.h
//  pm25
//
//  Created by Paul De Lange on 12/03/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, kParticleBorderMask) {
    kParticleBorderMaskTop =    1 << 0,
    kParticleBorderMaskRight =  1 << 1,
    kParticleBorderMaskBottom = 1 << 2,
    kParticleBorderMaskLeft =   1 << 3
};

@interface ParticleCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *particleNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *particleValueLabel;
@property (assign, nonatomic) kParticleBorderMask   borderMask;

@end
