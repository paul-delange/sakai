//
//  Animation.h
//  App Stream
//
//  Created by de Lange Paul on 5/9/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

@interface Animation : NSObject

+ (instancetype) animationWithKeyPath: (NSString*) keyPath;

@property (nonatomic, strong) id fromValue;
@property (nonatomic, strong) id toValue;

@end
