//
//  ViewController.m
//  HHTrackSDK_example
//
//  Created by 李俊 on 2022/6/14.
//

#import "ViewController.h"
#import <HHTrackSDK/HHTrackManager.h>
#import "ListViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"首页";
    
    [[HHTrackManager sharedInstance] track:@"LoginButtonClick" properties:nil];
    
    UIButton *oneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    oneButton.frame = CGRectMake(40, 100, 80, 40);
    oneButton.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.8];
    [oneButton setTitle:@"按钮1" forState:UIControlStateNormal];
    [oneButton addTarget:self action:@selector(handleOneButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:oneButton];
    
    UIButton *twoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    twoButton.frame = CGRectMake(40, 160, 80, 40);
    twoButton.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.8];
    [twoButton setTitle:@"按钮2" forState:UIControlStateNormal];
    [twoButton addTarget:self action:@selector(handleTwoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:twoButton];
    
    NSMutableDictionary *mDict = @{
        @"userType": @0
    }.mutableCopy;
    [mDict addEntriesFromDictionary:@{
        @"userType": @10
    }];
    NSLog(@"%@", mDict);
}

- (void)handleOneButtonTapped {
    [[HHTrackManager sharedInstance] login:@"1024"];
    [[HHTrackManager sharedInstance] track:@"LoginResult" properties:@{
        @"account": @"13866739321",
        @"login_method": @"手机号一键登录",
        @"is_quick_login": @1,
        @"is_success": @1,
        @"fail_reason": @"",
    }];
}

- (void)handleTwoButtonTapped {
    ListViewController *listCtrl = [[ListViewController alloc] init];
    [self.navigationController pushViewController:listCtrl animated:YES];
}

@end
