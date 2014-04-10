//
//  SearchResult.h
//  AppWorld
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SearchResult : NSObject

@property (strong) UIImage* thumb;
@property (copy) NSString* thumbnailPath;
@property (assign) float averageRating;

@end
