//
//  PIATwitterDataSource.h
//  TwitterClient
//
//  Created by Ruslan Sazonov on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PIATwitterDataSourceProto.h"

@interface PIATwitterDataSource : NSObject <PIATwitterDataSourceProto>

@property (nonatomic, strong) NSMutableArray *tweetSet;
@property (nonatomic, strong) NSMutableDictionary *userProfile;

@end
