//
//  SearchScene.h
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class SearchScene;

@protocol  SearchSceneDelegate <NSObject>
@optional
- (void) searchScene: (SearchScene*) scene didSelectObjectIndex: (NSUInteger) index;
- (void) searchScene: (SearchScene*) searchScene didSelectUserAtIndex: (NSUInteger) index;

@end


@protocol SearchSceneDataSource <NSObject>
@required
- (NSUInteger) numberOfObjectsInSearchScene: (SearchScene*) scene;
- (SKNode*) searchScene: (SearchScene*) scene nodeForObjectAtIndex: (NSUInteger) index;

@end

@interface SearchScene : SKScene

@property (weak) id<SearchSceneDelegate> delegate;
@property (weak) id<SearchSceneDataSource> dataSource;

//- (void) addResult: (SearchResult*) result AtPosition: (CGPoint) location;

#pragma mark - Inserting, Deleting, and Moving Objects
- (void) beginUpdates;
- (void) endUpdates;
- (void) insertObjectAtIndex: (NSUInteger) index;
- (void) deleteObjectAtIndex: (NSUInteger) index;
- (void) moveObjectAtIndex: (NSUInteger) fromIndex toIndex: (NSUInteger) toIndex;

#pragma mark - Reloading the Search Scene
- (void) reloadData;


@end
