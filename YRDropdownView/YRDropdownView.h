//
//  YRDropdownView.h
//  YRDropdownViewExample
//
//  Created by Eli Perkins on 1/27/12.
//  Copyright (c) 2012 One Mighty Roar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


typedef void (^YRTapBlock)(void);


@interface YRDropdownView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, strong) UIView *accessoryView;
@property (nonatomic, assign) float hideAfter;
@property (nonatomic, copy) YRTapBlock tapBlock;

+ (YRDropdownView *)dropdownInView:(UIView *)view
                             title:(NSString *)title
                            detail:(NSString *)detail
                             image:(UIImage *)image
                          animated:(BOOL)animated;

+ (YRDropdownView *)dropdownInView:(UIView *)view
                             title:(NSString *)title
                            detail:(NSString *)detail
                     accessoryView:(UIView *)view
                          animated:(BOOL)animated;

+ (BOOL)hideDropdownInView:(UIView *)view;
+ (BOOL)hideDropdownInView:(UIView *)view animated:(BOOL)animated;
+ (BOOL)isCurrentlyShowing;
+ (void)presentDropdown:(YRDropdownView *)dropdownView;
+ (void)toggleRtl:(BOOL)rtl;
+ (void)toggleQueuing:(BOOL)queuing;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (void)flipViewToOrientation:(NSNotification *)notification;

@end
