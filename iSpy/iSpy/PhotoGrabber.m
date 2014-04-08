//
//  PhotoGrabber.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "PhotoGrabber.h"

#define API_KEY             @"613bec6ad2f2e365d1935529da6ab39d"

#define kUserDefaultsCurrentBackgroundPhotoURL      @"CurrentBackgroundPhotoURL"

@implementation PhotoGrabber

+ (NSString*) photoDirectoryURL {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.lastObject;
}

+ (void) setPhoto: (UIImage*) image {
    NSString* newImagePath = [[self photoDirectoryURL] stringByAppendingPathComponent: @"background.png"];
    NSString* currentImageName = [[NSUserDefaults standardUserDefaults] stringForKey: kUserDefaultsCurrentBackgroundPhotoURL];
    
    NSData* data = UIImagePNGRepresentation(image);
    
    [data writeToFile: newImagePath atomically: YES];
    [[NSFileManager defaultManager] removeItemAtPath: currentImageName
                                               error: nil];
    [[NSUserDefaults standardUserDefaults] setObject: @"background.png" forKey: kUserDefaultsCurrentBackgroundPhotoURL];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (UIImage*) getPhotoForTag: (NSString*) tag withCompletionHandler: (kPhotoGrabberCompleted) completion {
    
    NSString* currentImageName = [[NSUserDefaults standardUserDefaults] stringForKey: kUserDefaultsCurrentBackgroundPhotoURL];
    
    //NSString* imagePath = [[self photoDirectoryURL] stringByAppendingPathComponent: PHOTO_FILE_NAME];
    
    if( tag ) {
        
        //Update the image
        NSString* listPathFormat = @"https://api.flickr.com/services/rest/?api_key=%@&method=flickr.photos.search&format=json&nojsoncallback=1&extras=o_dims&accuracy=16&safe_search=1&content_type=1&media=photos&tags=%@&sort=interestingness-desc";
        NSString* listPath = [NSString stringWithFormat: listPathFormat, API_KEY, tag];
        NSURL* listURL = [NSURL URLWithString: listPath];
        NSURLRequest* listRequest = [NSURLRequest requestWithURL: listURL];
        [NSURLConnection sendAsynchronousRequest: listRequest
                                           queue: [NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   BOOL isDownloadingPhoto = NO;
                                   
                                   
                                   id listObject = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: nil];
                                   NSString* status = listObject[@"stat"];
                                   if( [status isEqualToString: @"ok"] ) {
                                       NSDictionary* rootObject = listObject[@"photos"];
                                       NSMutableArray* photos = rootObject[@"photo"];
                                       
                                       NSUInteger count = [photos count];
                                       for (NSUInteger i = 0; i < count; ++i) {
                                           // Select a random element between i and end of array to swap with.
                                           NSInteger nElements = count - i;
                                           NSInteger n = arc4random_uniform(nElements) + i;
                                           [photos exchangeObjectAtIndex:i withObjectAtIndex:n];
                                       }
                                       
                                       CGFloat minWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
                                       CGFloat minHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
                                       
                                       for(NSDictionary* photo in photos) {
                                           CGFloat width = [photo[@"o_width"] floatValue];
                                           CGFloat height = [photo[@"o_height"] floatValue];
                                           
                                           if( width >= minWidth && height >= minHeight ){
                                               NSString* photoPathFormat = @"http://farm%@.staticflickr.com/%@/%@_%@.jpg";
                                               NSString* photoPath = [NSString stringWithFormat: photoPathFormat, photo[@"farm"], photo[@"server"], photo[@"id"], photo[@"secret"]];
                                               
                                               if( ![photoPath.lastPathComponent isEqualToString: currentImageName] ) {
                                                   isDownloadingPhoto = YES;
                                                   
                                                   NSURL* photoURL = [NSURL URLWithString: photoPath];
                                                   NSURLRequest* photoRequest = [NSURLRequest requestWithURL: photoURL];
                                                   [NSURLConnection sendAsynchronousRequest: photoRequest
                                                                                      queue: [NSOperationQueue mainQueue]
                                                                          completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                                                              UIImage* image = [UIImage imageWithData: data];
                                                                              if( image ) {
                                                                                  NSString* newImagePath = [[self photoDirectoryURL] stringByAppendingPathComponent: photoPath.lastPathComponent];
                                                                                  
                                                                                  NSString* oldImagePath = [[self photoDirectoryURL] stringByAppendingPathComponent: currentImageName];
                                                                                  
                                                                                  [data writeToFile: newImagePath atomically: YES];
                                                                                  [[NSFileManager defaultManager] removeItemAtPath: oldImagePath
                                                                                                                             error: nil];
                                                                                  [[NSUserDefaults standardUserDefaults] setObject: newImagePath.lastPathComponent forKey: kUserDefaultsCurrentBackgroundPhotoURL];
                                                                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                  
                                                                                  if( completion ) {
                                                                                      completion(image, nil);
                                                                                  }
                                                                              }
                                                                          }];
                                                   
                                                  
                                               }
                                                break;
                                               
                                           }
                                       }
                                   }
                                   
                                   if( !isDownloadingPhoto && completion) {
                                       NSString* imagePath = [[self photoDirectoryURL] stringByAppendingPathComponent: currentImageName];
                                       completion([UIImage imageWithContentsOfFile: imagePath], nil);
                                   }
                               }];
    }
    
    if( currentImageName ) {
        NSString* imagePath = [[self photoDirectoryURL] stringByAppendingPathComponent: currentImageName];
        return [UIImage imageWithContentsOfFile: imagePath];
    }
    else
        return nil;
}

@end
