//
//  PIATweetListViewController.m
//  TwitterClient
//
//  Created by Ruslan Sazonov on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PIATweetListViewController.h"
#import <Twitter/Twitter.h>

@interface PIATweetListViewController ()

- (void)twitterDataUpdateStarted;
- (void)setupProfileInfo:(NSDictionary *)info;
- (void)updateTable;

@end

@implementation PIATweetListViewController

@synthesize composeTweetButton, homeTimelineButton, tableHeaderView, tableView,
tweetsCount, tweetsLabel, followingCount, followingLabel, followersCount, followersLabel, 
dataSource = _dataSource;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userTimelineUpdated:)
                                                 name:PIATweetsUserTimelineUpdatedNotification
                                               object:self.dataSource];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userProfileUpdated:)
                                                 name:PIATweetsUserProfileUpdatedNotification
                                               object:self.dataSource];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(twitterDataUpdateStarted) 
                                                 name:PIATweetsUpdateStartedNotification 
                                               object:self.dataSource];
    self.title = @"Loading data...";
    
    if (0 == [self.dataSource tweetCount]) {
        [self.dataSource getOwnTimeline];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PIATweetsUserTimelineUpdatedNotification 
                                                  object:self.dataSource];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PIATweetsUserProfileUpdatedNotification 
                                                  object:self.dataSource];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PIATweetsUpdateStartedNotification 
                                                  object:self.dataSource];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.composeTweetButton = nil;
    self.tableView = nil;
    self.tableHeaderView = nil;
    self.tweetsLabel = nil;
    self.tweetsCount = nil;
    self.followersLabel = nil;
    self.followersCount = nil;
    self.followingLabel = nil;
    self.followingCount = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource tweetCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica-neuve" size:10.0]];
    
    PIATweet *tweet = [self.dataSource tweetAtIndex:indexPath.row];

    cell.imageView.image = [tweet userPicture];
    cell.textLabel.text = [tweet name];
    cell.detailTextLabel.text = [tweet tweetText];
    
    return cell;
}

- (void)userTimelineUpdated:(NSNotification *)notification {
    NSLog(@"user timeline updated");
    [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
}

- (void)updateTable {
    [self.tableView reloadData];
}

- (void)userProfileUpdated:(NSNotification *)notification {
    NSLog(@"user profile updated");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.title = [NSString stringWithFormat:@"@%@", [notification.userInfo valueForKey:@"screen_name"]];
        [self setupProfileInfo:notification.userInfo];
    });
}

- (void)setupProfileInfo:(NSDictionary *)info {
    [self.tweetsLabel setEnabled:YES];
    [self.tweetsCount setEnabled:YES];
    [self.followersLabel setEnabled:YES];
    [self.followersCount setEnabled:YES];
    [self.followingLabel setEnabled:YES];
    [self.followingCount setEnabled:YES];
    [self.tweetsCount setText:[NSString stringWithFormat:@"%@", [info valueForKey:@"statuses_count"]]];
    [self.followersCount setText:[NSString stringWithFormat:@"%@", [info valueForKey:@"followers_count"]]];
    [self.followingCount setText:[NSString stringWithFormat:@"%@", [info valueForKey:@"friends_count"]]];
}

- (void)twitterDataUpdateStarted {
    NSLog(@"twitterDataUpdateStarted");
}

- (IBAction)returnToHomeTimelineAction:(UIBarButtonItem *)sender {
    [self.dataSource getOwnTimeline];
}

- (IBAction)composeTweetAction:(UIBarButtonItem *)sender {
    [self.tableView reloadData];
    if ([TWTweetComposeViewController canSendTweet]) {
        TWTweetComposeViewController *twitterViewController = [[TWTweetComposeViewController alloc] init];
        twitterViewController.completionHandler = ^(TWTweetComposeViewControllerResult result) { 
            if (result == TWTweetComposeViewControllerResultDone) {
                [self.dataSource getOwnTimeline];
                [self dismissModalViewControllerAnimated:YES];
            }
        };
        [self presentViewController:twitterViewController animated:YES completion:NULL];
    } else {
        UIAlertView *errorMessage = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                               message:@"Can`t send tweet. Try later." 
                                                              delegate:nil 
                                                     cancelButtonTitle:@"Ok" 
                                                     otherButtonTitles:nil];
        [errorMessage show];
    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"***start updating");
    NSString *selectedScreenName = [[self.dataSource tweetAtIndex:indexPath.row] screenName];
    [self.dataSource getUserTimeline:selectedScreenName];
}

@end
