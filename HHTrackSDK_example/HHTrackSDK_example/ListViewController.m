//
//  ListViewController.m
//  HHTrackSDK_example
//
//  Created by 李俊 on 2022/6/15.
//

#import "ListViewController.h"
#import "DetailViewController.h"
#import <HHTrackSDK/HHTrackManager.h>

@interface ListViewController ()

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"列表";
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIButton *oneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    oneButton.frame = CGRectMake(40, 100, 80, 40);
    oneButton.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.8];
    [oneButton setTitle:@"按钮1" forState:UIControlStateNormal];
    [oneButton addTarget:self action:@selector(handleOneButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:oneButton];
    
    UIButton *twoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    twoButton.frame = CGRectMake(40, 160, 80, 40);
    twoButton.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.8];
    [twoButton setTitle:@"登出按钮" forState:UIControlStateNormal];
    [twoButton addTarget:self action:@selector(handleTwoButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:twoButton];
}

- (void)handleOneButtonTapped {
    DetailViewController *ctrl = [[DetailViewController alloc] init];
    [self.navigationController pushViewController:ctrl animated:YES];
}

- (void)handleTwoButtonTapped {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"user_id"];
    [[HHTrackManager sharedInstance] logout];
}

@end
