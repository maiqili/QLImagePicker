//
//  ViewController.m
//  QLImagePIcker
//
//  Created by maiqili on 15/10/30.
//  Copyright © 2015年 maiqili. All rights reserved.
//

#import "ViewController.h"
#import "QLImagePickerController.h"

@interface ViewController ()
<
QLImagePickerControllerDelegate,
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) NSMutableArray *selectedImages;//需要一个数组用于保存已选图片

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"添加", nil) style:UIBarButtonItemStylePlain target:self action:@selector(addImageButtonDidClick:)];
}

-(BOOL)prefersStatusBarHidden
{
    return NO;
}
#pragma mark - UITableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.selectedImages.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identerfiler = @"QLTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identerfiler];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identerfiler];
    }
    NSDictionary *iamgeDict = self.selectedImages[indexPath.row];
    cell.imageView.image = [iamgeDict objectForKey:UIImagePickerControllerOriginalImage];
    return cell;
}

#pragma mark - 私有

- (void)addImageButtonDidClick:(id)sender
{
    QLImagePickerController *vc = [[QLImagePickerController alloc] init];
    vc.seclectDictArray = self.selectedImages;
    vc.delegate = self;
    vc.hidesBottomBarWhenPushed = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
    
}

-(void)qLImagePickerController:(QLImagePickerController *)qLImagePickerController didFinishPickImageWithArray:(NSArray *)imageArray
{
    self.selectedImages = [NSMutableArray arrayWithArray:imageArray];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

-(void)qlImagePickerControllerDidCancel:(QLImagePickerController *)imagePickerController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
@end
