//
//  PIATweet.h
//  TwitterClient
//
//  Created by Ruslan Sazonov on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PIATweet : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *screenName;
@property (nonatomic, strong) NSString *tweetText;
@property (nonatomic, strong) UIImage *userPicture;

@end
