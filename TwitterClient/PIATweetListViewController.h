//
//  PIATweetListViewController.h
//  TwitterClient
//
//  Created by Ruslan Sazonov on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PIATweet.h"
#import "PIATwitterDataSourceProto.h"
//#import "PIATwitterDataSource.h"
//#import "PIATweetListDelegate.h"

@interface PIATweetListViewController : UIViewController <UITableViewDelegate, UITableViewDelegate>

//DataSource
@property (nonatomic, strong) id <PIATwitterDataSourceProto> dataSource;

//UI
@property (nonatomic, strong) IBOutlet UIBarButtonItem *composeTweetButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *homeTimelineButton;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *tableHeaderView;
@property (nonatomic, strong) IBOutlet UILabel *tweetsLabel;
@property (nonatomic, strong) IBOutlet UILabel *followersLabel;
@property (nonatomic, strong) IBOutlet UILabel *followingLabel;
@property (nonatomic, strong) IBOutlet UILabel *tweetsCount;
@property (nonatomic, strong) IBOutlet UILabel *followersCount;
@property (nonatomic, strong) IBOutlet UILabel *followingCount;

- (void)userTimelineUpdated:(NSNotification *)notification;
- (void)userProfileUpdated:(NSNotification *)notification;
- (IBAction)composeTweetAction:(UIBarButtonItem *)sender;
- (IBAction)returnToHomeTimelineAction:(UIBarButtonItem *)sender;

@end
