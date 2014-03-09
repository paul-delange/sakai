//
//  AppMenuButton.h
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AppMenuItem;

@interface AppMenuButton : UIButton

+ (instancetype) menuButtonWithItem: (AppMenuItem*) item andFrame: (CGRect) frame;

@property (assign, nonatomic) BOOL hasSeparator;

@end
