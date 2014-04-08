//
//  SearchScene.h
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class SearchResult;

@interface SearchScene : SKScene

- (void) addResult: (SearchResult*) result AtPosition: (CGPoint) location;

@end
