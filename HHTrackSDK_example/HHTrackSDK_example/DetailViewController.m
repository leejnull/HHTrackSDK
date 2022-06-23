//
//  DetailViewController.m
//  HHTrackSDK_example
//
//  Created by 李俊 on 2022/6/15.
//

#import "DetailViewController.h"
#import <HHTrackSDK/HHTrackManager.h>

@interface DetailViewController ()

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"详情";
    self.view.backgroundColor = UIColor.brownColor;
    
    UIButton *oneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    oneButton.frame = CGRectMake(40, 100, 80, 40);
    oneButton.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.8];
    [oneButton setTitle:@"强刷按钮" forState:UIControlStateNormal];
    [oneButton addTarget:self action:@selector(handleOneButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:oneButton];
}

- (void)handleOneButtonTapped {
    [[HHTrackManager sharedInstance] flush];
}

@end
