//
//  PIATwitterDataSource.m
//  TwitterClient
//
//  Created by Ruslan Sazonov on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PIATwitterDataSource.h"
#import "PIATweet.h"
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>

NSString * const PIATweetsUserTimelineUpdatedNotification = @"PIATweetsUserTimelineUpdatedNotification";
NSString * const PIATweetsUserProfileUpdatedNotification = @"PIATweetsUserProfileUpdatedNotification";
NSString * const PIATweetsUpdateStartedNotification = @"PIATweetsUpdateStartedNotification";

@interface PIATwitterDataSource ()

@property (nonatomic, strong) NSString *currentScreenName;

- (void)handleApiRequestData:(NSDictionary *)data requestType:(NSString *)type;
- (void)performTwitterApiRequestForScreenName:(NSString *)screenName apiUrl:(NSString *)apiUrl;
- (void)getUserProfileForScreenName:(NSString *)screenName;
- (void)getTimelineForScreenName:(NSString *)screenName;
- (void)getHomeTimeline:(NSString *)screenName;
- (void)getDataForScreenName:(NSString *)screenName isHomeTimeline:(BOOL)isHome;
- (void)saveScreenNameToUserDefaults;

@end

@implementation PIATwitterDataSource

@synthesize currentScreenName, tweetSet, userProfile;

- (id)init {
    self = [super init];
    if (self) {
        [self saveScreenNameToUserDefaults];
        tweetSet = [NSMutableArray array];
        userProfile = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)getOwnTimeline {
    [self getDataForScreenName:self.currentScreenName isHomeTimeline:YES];
}

- (void)getUserTimeline:(NSString *)screenName {
    [self getDataForScreenName:screenName isHomeTimeline:NO];
}

- (void)getDataForScreenName:(NSString *)screenName isHomeTimeline:(BOOL)isHome {
    [[NSNotificationCenter defaultCenter] postNotificationName:PIATweetsUpdateStartedNotification 
                                                        object:self];
    
    dispatch_group_t network_tasks_group = dispatch_group_create();
    dispatch_group_async(network_tasks_group, dispatch_get_global_queue(0, 0), ^{
        //Grab user profile data
        [self getUserProfileForScreenName:screenName];
    });
    dispatch_group_async(network_tasks_group, dispatch_get_global_queue(0, 0), ^{
        //Grab timeline data for a given screen_name
        if (isHome) {
            [self getHomeTimeline:screenName];
        } else {
            [self getTimelineForScreenName:screenName];
        }
    });
    dispatch_group_notify(network_tasks_group, dispatch_get_global_queue(0, 0), ^{
        //Data grabbing complete notification. Reciever ViewController must catch it and perform UI update)
//        [[NSNotificationCenter defaultCenter] postNotificationName:PIATweetsUpdatedNotification 
//                                                            object:self];
    });
     
}

- (void)getUserProfileForScreenName:(NSString *)screenName {
    NSString *requestUrl = @"http://api.twitter.com/1/users/show.json"; 
    [self performTwitterApiRequestForScreenName:screenName apiUrl:requestUrl];
}

- (void)getHomeTimeline:(NSString *)screenName {
    NSString *requestUrl = @"http://api.twitter.com/1/statuses/home_timeline.json";   
    [self performTwitterApiRequestForScreenName:screenName apiUrl:requestUrl];
}

- (void)getTimelineForScreenName:(NSString *)screenName {
    NSString *requestUrl = @"http://api.twitter.com/1/statuses/user_timeline.json";  
    [self performTwitterApiRequestForScreenName:screenName apiUrl:requestUrl];
}

- (NSMutableDictionary *)readUserProfile {
    return [self userProfile];
}

- (void)performTwitterApiRequestForScreenName:(NSString *)screenName apiUrl:(NSString *)apiUrl {
    NSURL *requestUrl = [NSURL URLWithString:apiUrl]; 
    NSDictionary *requestParams = [NSDictionary dictionaryWithObjectsAndKeys:screenName, @"screen_name", @"10", @"count", nil];
    NSString *requestType = [requestUrl.pathComponents objectAtIndex:2];
    
    TWRequest *request = [[TWRequest alloc]
                          initWithURL:requestUrl
                          parameters:requestParams
                          requestMethod:TWRequestMethodGET];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *accounts = [accountStore accountsWithAccountType:accountType];
    
#warning - handle empty acc set
    request.account = [accounts objectAtIndex:0];
    
    [request performRequestWithHandler:^(NSData *responseData,
                                         NSHTTPURLResponse *urlResponse,
                                         NSError *error) {
        
        NSError *jsonError = nil;
        NSJSONSerialization *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];

        NSDictionary *responseDict = (NSDictionary *)jsonResponse;
        
        if (!jsonError) {
            [self handleApiRequestData:responseDict requestType:requestType];
        } else {
            NSLog(@"%@", [jsonError localizedDescription]);
        }
    }];
}

- (void)handleApiRequestData:(NSDictionary *)data requestType:(NSString *)type {
    if ([type isEqualToString:@"users"]) {
        [self.userProfile setValue:[data valueForKey:@"screen_name"] 
                            forKey:@"screen_name"];
        [self.userProfile setValue:[data valueForKey:@"statuses_count"] 
                            forKey:@"statuses_count"];
        [self.userProfile setValue:[data valueForKey:@"followers_count"] 
                            forKey:@"followers_count"];
        [self.userProfile setValue:[data valueForKey:@"friends_count"] 
                            forKey:@"friends_count"];
        [self.userProfile setValue:[data valueForKey:@"id_str"] 
                            forKey:@"id_str"];
        [self.userProfile setValue:[data valueForKey:@"name"] 
                            forKey:@"name"];
        [self.userProfile setValue:[data valueForKey:@"profile_image_url"] 
                            forKey:@"profile_image_url"];

        [[NSNotificationCenter defaultCenter] postNotificationName:PIATweetsUserProfileUpdatedNotification 
                                                            object:self 
                                                          userInfo:(NSDictionary *)self.userProfile];
    } else if ([type isEqualToString:@"statuses"]) {
        [self.tweetSet removeAllObjects];

        for (NSDictionary *tweetDict in data) {
            PIATweet *tweet = [[PIATweet alloc] init];
            NSDictionary *userData = [tweetDict valueForKey:@"user"];
            
            NSURL *userPictureUrl = [NSURL URLWithString:[userData valueForKey:@"profile_image_url"]];
            UIImage *userPicture = [UIImage imageWithData:[NSData dataWithContentsOfURL:userPictureUrl]];
            
            tweet.name = [userData valueForKey:@"name"];
            tweet.screenName = [userData valueForKey:@"screen_name"];
            tweet.userPicture = userPicture;
            tweet.tweetText = [tweetDict valueForKey:@"text"];
            
            [self.tweetSet addObject:tweet];
//            NSLog(@"tweet: %@", tweet.tweetText);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PIATweetsUserTimelineUpdatedNotification
                                                            object:self];
    }
    
}

- (NSString *)currentScreenName {
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"twitterHandle"];
}

- (void)saveScreenNameToUserDefaults {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
            if(accountsArray == nil && [accountsArray count] == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Twitter Accounts"
                                                                message:@"There are no Twitter accounts configured. You can add or create a Twitter account in Settings."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
            
                ACAccount *twitterAccount = [accountsArray objectAtIndex:0];
                [[NSUserDefaults standardUserDefaults] setValue:twitterAccount.username forKey:@"twitterHandle"];
            }
        }
    }];
}

- (NSInteger)tweetCount {
    return [self.tweetSet count];
}

- (NSUInteger)indexOfTweet:(PIATweet *)recipe {
    return [self.tweetSet indexOfObject:recipe];
}

- (PIATweet *)tweetAtIndex:(NSInteger)index {
    return [self.tweetSet objectAtIndex:index];
}

@end