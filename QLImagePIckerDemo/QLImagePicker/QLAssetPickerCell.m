//
//  QLAssetPickerCell.m
//  QLImagePIcker
//
//  Created by maiqili on 15/10/30.
//  Copyright (c) 2015年 maiqili. All rights reserved.
//

#import "QLAssetPickerCell.h"

@interface QLAssetPickerCell()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIImageView *selectedIcon;

@end

@implementation QLAssetPickerCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:self.imageView];
        
        self.selectedIcon = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - 24, 0, 24, 24)];
        self.selectedIcon.image = [UIImage imageNamed:@"QL_ImagePicker_unselect"];
        [self.contentView addSubview:self.selectedIcon];
        
    }
    
    return self;
}

- (void)setThumbnailWithUIImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self updataSelectStatus:selected];
    
}

- (void)updataSelectStatus:(BOOL)selected
{
    if (selected) {
        self.selectedIcon.image = [UIImage imageNamed:@"QL_ImagePicker_select"];
    }else{
        self.selectedIcon.image = [UIImage imageNamed:@"QL_ImagePicker_unselect"];
    }
}
@end
