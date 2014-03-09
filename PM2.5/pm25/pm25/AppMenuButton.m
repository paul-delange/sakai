//
//  AppMenuButton.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AppMenuButton.h"

#import "AppMenuItem.h"

@interface AppMenuButton ()

@property (weak) UIView* separator;

@end

@implementation AppMenuButton

+ (instancetype) menuButtonWithItem:(AppMenuItem *)item andFrame:(CGRect)frame {
    AppMenuButton* itemView = [AppMenuButton buttonWithType: UIButtonTypeCustom];
    itemView.frame = frame;
    itemView.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.75];
    itemView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [itemView setImage: item.image forState: UIControlStateNormal];
    [itemView setImageEdgeInsets: UIEdgeInsetsMake(8, CGRectGetWidth(itemView.frame)-item.image.size.width-20, 8, 8)];
    [itemView setTitle: item.title forState: UIControlStateNormal];
    [itemView setTitleColor: [UIColor lightGrayColor] forState: UIControlStateHighlighted];
    //[itemView setTitleColor: [UIColor lightGrayColor] forState: UIControlStateDisabled];
    itemView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    itemView.adjustsImageWhenDisabled = NO;
    
    return itemView;
}

- (void) setHasSeparator:(BOOL)hasSeparator {
    if( _hasSeparator != hasSeparator ) {
        _hasSeparator = hasSeparator;
        
        if( hasSeparator ) {
        UIView* separator = [[UIView alloc] initWithFrame: CGRectZero];
        separator.backgroundColor = [UIColor whiteColor];
        separator.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview: separator];
        
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[separator]|"
                                                                          options: 0
                                                                          metrics: nil
                                                                            views: NSDictionaryOfVariableBindings(separator)]];
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:[separator(==1)]|"
                                                                          options: 0
                                                                          metrics: nil
                                                                            views: NSDictionaryOfVariableBindings(separator)]];
            self.separator = separator;
        }
        else {
            [self.separator removeFromSuperview];
        }
    }
}

@end
