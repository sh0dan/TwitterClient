//
//  PIATwitterDataSourceProto.h
//  TwitterClient
//
//  Created by Ruslan Sazonov on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const PIATweetsUpdateStartedNotification;
extern NSString * const PIATweetsUserTimelineUpdatedNotification;
extern NSString * const PIATweetsUserProfileUpdatedNotification;

@class PIATweet;
@protocol PIATwitterDataSourceProto <NSObject>

- (void)getOwnTimeline;
- (void)getUserTimeline:(NSString *)screenName;
- (NSMutableDictionary *)readUserProfile;

- (NSInteger)tweetCount;
- (NSUInteger)indexOfTweet:(PIATweet *)recipe;
- (PIATweet *)tweetAtIndex:(NSInteger)index;

@end
