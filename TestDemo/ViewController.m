//
//  ViewController.m
//  TestDemo
//
//  Created by Ketan on 28/01/15.
//  Copyright (c) 2015 Ketan. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

#define WEBURL @"http://ios-test-project.herokuapp.com/me/follower?pageNo="
#define CELLID @"UserCellId"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - ViewController Method

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.arrUsers = [[NSMutableArray alloc] init];
    [self setTitleAndInfo];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                      target:self
                                      action:@selector(barBtnTrashClicked:)];
    self.navigationItem.leftBarButtonItem = barButtonItem;
    barButtonItem = nil;
    barButtonItem = [[UIBarButtonItem alloc]
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                     target:self
                     action:@selector(fetchUsersFromServer)];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    UINib *cellNib = [UINib nibWithNibName:@"UserCell" bundle:nil];
    [self.tblUsers registerNib:cellNib forCellReuseIdentifier:CELLID];
    self.tblUsers.tableFooterView = self.vwTblFooter;
    
    [self fetchUsersFromServer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Other Method

- (void)setTitleAndInfo
{
    self.strPageNo = self.strPageNo ? self.strPageNo : @"1";
    self.title = [NSString stringWithFormat:@"Users: %ld", (long)self.arrUsers.count];
    self.lblLoadInfo.text = [NSString stringWithFormat:@"Loading from page %ld",
                             (long)self.strPageNo.integerValue];
}

- (void)barBtnTrashClicked:(UIBarButtonItem *)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DemoApp"
                                                    message:@"Do you want to remove all cached images?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = 999;
    [alert show];
}

- (void)fetchUsersFromServer
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSSet *setContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",
                              @"application/json", @"application/x-www-form-urlencoded", nil];
    manager.responseSerializer.acceptableContentTypes = setContentTypes;
    
    [manager GET:[NSString stringWithFormat:@"%@%@", WEBURL, self.strPageNo]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if ([[self validateObject:responseObject] isKindOfClass:[NSArray class]])
         {
             for (id obj in responseObject)
             {
                 if ([obj isKindOfClass:[NSDictionary class]])
                 {
                     UserDetails *user = [UserDetails new];
                     user.strUserName = [self validateObject:[obj objectForKey:@"user_name"]];
                     user.strUserPhotoUrl = [self validateObject:[obj objectForKey:@"user_image"]];
                     [self.arrUsers addObject:user];
                 }
             }
             
             self.navigationItem.rightBarButtonItem.enabled = NO;
             self.strPageNo = [NSString stringWithFormat:@"%ld", (long)self.strPageNo.integerValue + 1];
             [self setTitleAndInfo];
             [self.tblUsers reloadData];
         }
     }
         failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         [[[UIAlertView alloc] initWithTitle:@"AFNetworking"
                                     message:error.localizedDescription
                                    delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil] show];
         self.navigationItem.rightBarButtonItem.enabled = YES;
     }];
}

- (id)validateObject:(id)obj
{
    if (obj && (![obj isEqual:[NSNull null]]))
        return obj;
    return @"";
}

#pragma mark - UITableViewDataSource Method

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arrUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserCell *userCell = [tableView dequeueReusableCellWithIdentifier:CELLID forIndexPath:indexPath];
    UserDetails *userDetails = [self.arrUsers objectAtIndex:indexPath.row];
    
    userCell.lblUserName.text = userDetails.strUserName.capitalizedString;
    [[WebImageHelper sharedManager] loadImageWithStrUrl:userDetails.strUserPhotoUrl
                                           forImageView:userCell.ivUserPhoto
                                              queueName:"UserImageQueue"
                                      completionHandler:^(UIImage *image, NSError *error) {
                                          if (!image || error)
                                              NSLog(@"\nImage: %@\n%@\n", image, error.localizedDescription);
                                      }];
    
    return userCell;
}

#pragma mark - UITableViewDelegate Method

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.row + 1) >= self.arrUsers.count)
        [self fetchUsersFromServer];
}

#pragma mark - UIAlertViewDelegate Method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView.tag == 999) && (buttonIndex == 1))
        [[WebImageHelper sharedManager] emptyWebImageHelperCachesDirectory];
}

@end

@interface UserDetails ()

@end

@implementation UserDetails

@end

@interface UserCell ()

@end

@implementation UserCell

@end
