//
//  ViewController.h
//  TestDemo
//
//  Created by Ketan on 28/01/15.
//  Copyright (c) 2015 Ketan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSString *strPageNo;
@property (strong, nonatomic) NSMutableArray *arrUsers;
@property (strong, nonatomic) IBOutlet UITableView *tblUsers;
@property (strong, nonatomic) IBOutlet UIView *vwTblFooter;
@property (strong, nonatomic) IBOutlet UILabel *lblLoadInfo;

@end

@interface UserDetails : NSObject

@property (strong, nonatomic) NSString *strUserName;
@property (strong, nonatomic) NSString *strUserPhotoUrl;

@end

@interface UserCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *ivUserPhoto;
@property (strong, nonatomic) IBOutlet UILabel *lblUserName;

@end