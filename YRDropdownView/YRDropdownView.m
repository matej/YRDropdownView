//
//  YRDropdownView.m
//  YRDropdownViewExample
//
//  Created by Eli Perkins on 1/27/12.
//  Copyright (c) 2012 One Mighty Roar. All rights reserved.
//

#import "YRDropdownView.h"
#import <QuartzCore/QuartzCore.h>


#define HORIZONTAL_PADDING 10.0f
#define VERTICAL_PADDING 10.0f
#define ACCESSORY_PADDING 5.0f
#define TITLE_FONT_SIZE 15.0f
#define DETAIL_FONT_SIZE 11.0f
#define ANIMATION_DURATION 0.5f
#define FADE_IN_ANIMATION_DURATION 0.1f
#define FADE_OUT_ANIMATION_DURATION 0.3f


@implementation UILabel (YRDropdownView)

- (void)sizeToFitFixedWidth:(CGFloat)fixedWidth {
	CGRect frame = self.frame;
	frame.size.width = fixedWidth;
	self.frame = frame;
	self.lineBreakMode = NSLineBreakByWordWrapping;
	self.numberOfLines = 0;
	[self sizeToFit];
}

@end


@interface YRDropdownView () {
	UILabel *_titleLabel;
	UILabel *_detailLabel;
}

@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, assign) BOOL shouldAnimate;
@property (nonatomic, assign) CGFloat dropdownHeight;
@property (nonatomic, assign, readonly) CGFloat statusBarOffset;

+ (UIImageView *)imageViewWithImage:(UIImage *)image;

@end


@implementation YRDropdownView

static YRDropdownView *__currentDropdown = nil;
static NSMutableArray *__viewQueue = nil;
static BOOL __isRtl = NO;
static BOOL __isQueuing = NO;

#pragma mark - Class Accessors

+ (void)toggleRtl:(BOOL)rtl
{
	__isRtl = rtl;
}

+ (void)toggleQueuing:(BOOL)queuing
{
	__isQueuing = queuing;
}

#pragma mark - Accessors

- (UILabel *)titleLabel
{
	if (!_titleLabel) {
		_titleLabel = [[UILabel alloc] init];
		_titleLabel.font = [UIFont boldSystemFontOfSize:TITLE_FONT_SIZE];
		_titleLabel.adjustsFontSizeToFitWidth = NO;
		_titleLabel.opaque = NO;
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.textColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
		if (__isRtl) {
			_titleLabel.textAlignment = self.detailLabel.textAlignment = NSTextAlignmentRight;
		}
		[self addSubview:_titleLabel];
		[self setNeedsLayout];
	}
	return _titleLabel;
}

- (UILabel *)detailLabel
{
	if (!_detailLabel) {
		_detailLabel = [[UILabel alloc] init];
		_detailLabel.font = [UIFont systemFontOfSize:DETAIL_FONT_SIZE];
		_detailLabel.numberOfLines = 0;
		_detailLabel.adjustsFontSizeToFitWidth = NO;
		_detailLabel.opaque = NO;
		_detailLabel.backgroundColor = [UIColor clearColor];
		_detailLabel.textColor = [UIColor colorWithWhite:0.f alpha:0.5f];;
		if (__isRtl) {
			_detailLabel.textAlignment = self.detailLabel.textAlignment = NSTextAlignmentRight;
		}
		[self addSubview:_detailLabel];
		[self setNeedsLayout];
	}
	return _detailLabel;
}

- (void)setAccessoryView:(UIView *)accessoryView {
	if (accessoryView != _accessoryView) {
		[_accessoryView removeFromSuperview];
		_accessoryView = accessoryView;
		if (_accessoryView) {
			[self addSubview:_accessoryView];
		}
		[self setNeedsLayout];
	}
}

#pragma mark - Initializers
- (id)init
{
	return [self initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		// Gentle shadow settings. Path will be set up live, in [layoutSubviews]
		BOOL isRetina = [UIScreen mainScreen].scale >= 2;
		// Hairline
		self.layer.shadowOffset = CGSizeMake(0.f, isRetina ? 0.5f : 1.f);
		self.layer.shadowRadius = 0.0f;
		self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
		self.layer.shadowOpacity = 0.5f;
		self.backgroundColor = [UIColor colorWithRed:1.f green:.84f blue:0.16f alpha:0.95f];
		// Hide on tap
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
		[self addGestureRecognizer:tap];
	}
	return self;
}

#pragma mark - Class methods

+ (UIImageView *)imageViewWithImage:(UIImage *)image
{
	UIImageView *imageView = nil;
	if (image) {
		imageView = [[UIImageView alloc] initWithImage:image];
	}
	return imageView;
}

+ (YRDropdownView *)dropdownInView:(UIView *)view title:(NSString *)title detail:(NSString *)detail accessoryView:(UIView *)accessoryView animated:(BOOL)animated
{
	YRDropdownView *dropdown = [[self alloc] initWithFrame:CGRectMake(0, 0, view.bounds.size.width, 44)];

	if ((__viewQueue && [__viewQueue count] > 0) || (__isQueuing && __currentDropdown)) {
		if (!__viewQueue) __viewQueue = [NSMutableArray array];
		[__viewQueue addObject:dropdown];
	} else {
		[__currentDropdown hide:__currentDropdown.shouldAnimate];
		__currentDropdown = dropdown;
	}

	if (title) {
		dropdown.titleLabel.text = title;
	}
	if (detail) {
		dropdown.detailLabel.text = detail;
	}
	if (accessoryView) {
		dropdown.accessoryView = accessoryView;
	}

	dropdown.shouldAnimate = animated;
	dropdown.parentView = view;

	return dropdown;
}

+ (YRDropdownView *)dropdownInView:(UIView *)view title:(NSString *)title detail:(NSString *)detail image:(UIImage *)image animated:(BOOL)animated
{
	UIImageView *accessoryView = [self imageViewWithImage:image];
	return [self dropdownInView:view title:title detail:detail accessoryView:accessoryView animated:animated];
}

+ (BOOL)hideDropdownInView:(UIView *)view
{
	return [YRDropdownView hideDropdownInView:view animated:YES];
}

+ (BOOL)hideDropdownInView:(UIView *)view animated:(BOOL)animated
{
	if (__currentDropdown) {
		[__currentDropdown hide:animated];
		return YES;
	}

	UIView *viewToRemove = nil;
	for (UIView *v in [view subviews]) {
		if ([v isKindOfClass:[YRDropdownView class]]) {
			viewToRemove = v;
		}
	}
	if (viewToRemove != nil) {
		YRDropdownView *dropdown = (YRDropdownView *)viewToRemove;
		[dropdown hide:animated];
		return YES;
	} else {
		return NO;
	}
}

+ (void)presentDropdown:(YRDropdownView *)dropdownView
{
	if (dropdownView == nil) {
		return;
	}
	if (__currentDropdown != nil && __currentDropdown != dropdownView) {
		return;
	}
	__currentDropdown = dropdownView;

	[dropdownView.parentView addSubview:dropdownView];
	[dropdownView show:dropdownView.shouldAnimate];
	if (dropdownView.hideAfter != 0.0)
	{
		[dropdownView performSelector:@selector(hideWithAnimation:) withObject:@(dropdownView.shouldAnimate) afterDelay:dropdownView.hideAfter+ANIMATION_DURATION];
	}
	[[NSNotificationCenter defaultCenter] addObserver:dropdownView selector:@selector(flipViewToOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[dropdownView flipViewToOrientation:nil];
}

+ (BOOL)isCurrentlyShowing
{
	return __currentDropdown != nil;
}

#pragma mark - Showing and Hiding

- (void)show:(BOOL)animated
{
	if(animated)
	{
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		BOOL rotatedY = orientation == UIInterfaceOrientationPortraitUpsideDown && !self.hasViewCoordinates;
		int rotated = self.hasViewCoordinates?0:(orientation == UIInterfaceOrientationLandscapeLeft ? 1 : (orientation == UIInterfaceOrientationLandscapeRight ? 2 : 0));
		if (orientation != UIInterfaceOrientationPortrait) [self layoutSubviews];
		CGRect originalRc = self.frame;
		self.frame = CGRectMake(
								originalRc.origin.x+(rotated==1?-originalRc.size.width:(rotated==2?originalRc.size.width:0)),
								originalRc.origin.y+(rotated?0:(rotatedY?originalRc.size.height:-originalRc.size.height)),
								originalRc.size.width,
								originalRc.size.height);
		self.alpha = 0;

		[UIView animateWithDuration:FADE_IN_ANIMATION_DURATION
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^{
							 self.alpha = 1.0;
						 }
						 completion:nil];

		[UIView animateWithDuration:ANIMATION_DURATION
							  delay:0.0
			 usingSpringWithDamping:1.f
			  initialSpringVelocity:1.f
							options:0 animations:^{
								self.frame = originalRc;
							} completion:nil];
	}
}

- (void)hide:(BOOL)animated
{
	[self hideWithAnimation:@(animated)];
}

- (void)hideWithAnimation:(NSNumber *)animated
{
	if ([animated boolValue])
	{
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		BOOL rotatedY = orientation == UIInterfaceOrientationPortraitUpsideDown && !self.hasViewCoordinates;
		int rotated = self.hasViewCoordinates ? 0 : (orientation == UIInterfaceOrientationLandscapeLeft ? 1 : (orientation == UIInterfaceOrientationLandscapeRight ? 2 : 0));

		[UIView animateWithDuration:FADE_OUT_ANIMATION_DURATION
							  delay:0.
							options:UIViewAnimationOptionCurveEaseInOut
						 animations:^{
							 self.alpha = 0.0;
						 }
						 completion:nil];

		[UIView animateWithDuration:ANIMATION_DURATION
							  delay:0.0
			 usingSpringWithDamping:1.f
			  initialSpringVelocity:1.f
							options:0 animations:^{
								CGRect f = self.frame;
								f.origin.x = f.origin.x + (rotated==1 ? -f.size.width : (rotated==2 ? f.size.width : 0));
								f.origin.y = f.origin.y + (rotated ? 0 : (rotatedY ? f.size.height : -f.size.height));
								self.frame = f;
							} completion:^(BOOL finished) {
								[self done];
							}];
	}
	else
	{
		self.alpha = 0.0f;
		[self done];
	}
}

- (void)done
{
	[self removeFromSuperview];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if (__viewQueue.count && __currentDropdown == self) // no need for nil check
	{
		__currentDropdown = __viewQueue[0];
		[__viewQueue removeObjectAtIndex:0];
		[YRDropdownView presentDropdown:__currentDropdown];
	}
	else
	{
		__currentDropdown = nil;
	}
}

#pragma mark - Gesures

- (void)viewTapped:(UITapGestureRecognizer *)tapRecognizer {
	if (self.tapBlock) {
		dispatch_async(dispatch_get_main_queue(), self.tapBlock);
	}
	[self hide:self.shouldAnimate];
}

#pragma mark - Layout

- (void)layoutSubviews
{
	CGRect bounds = self.bounds;
	bounds.origin.y += self.statusBarOffset;
	bounds.size.height -= self.statusBarOffset;
	CGRect availableBounds = CGRectInset(bounds, HORIZONTAL_PADDING, VERTICAL_PADDING);

	CGRect accessoryFrame = CGRectZero;
	CGRect titleFrame = CGRectZero;
	CGRect detailFrame = CGRectZero;

	BOOL hasAccessory = !!_accessoryView;
	BOOL hasTitle = [_titleLabel.text length] > 0;
	BOOL hasDetail = [_detailLabel.text length] > 0;

	if (hasAccessory) {
		// Compute accesory frame
		accessoryFrame = self.accessoryView.frame;
		if (__isRtl) {
			accessoryFrame.origin.x = CGRectGetMaxX(availableBounds) - accessoryFrame.size.width;
		} else {
			accessoryFrame.origin.x = availableBounds.origin.x;
		}
		accessoryFrame.origin.y = availableBounds.origin.y;
		_accessoryView.frame = accessoryFrame;
		// Adjust remaining available space
		availableBounds.size.width -= accessoryFrame.size.width + HORIZONTAL_PADDING + ACCESSORY_PADDING;
		if (!__isRtl) {
			availableBounds.origin.x += accessoryFrame.size.width + HORIZONTAL_PADDING + ACCESSORY_PADDING;
		}
	}

	if (hasTitle) {
		// Compute title frame
		[_titleLabel sizeToFitFixedWidth:availableBounds.size.width];
		titleFrame = CGRectMake(availableBounds.origin.x,
								availableBounds.origin.y - 4,
								availableBounds.size.width,
								_titleLabel.frame.size.height);
		// Match the accesssory height, if there's no details text and the accessory is larger
		if (hasAccessory && !hasDetail && titleFrame.size.height < accessoryFrame.size.height) {
			titleFrame.size.height = accessoryFrame.size.height;
		}
		// Adjust remaining available space
		availableBounds.origin.y = CGRectGetMaxY(titleFrame);
		availableBounds.size.height -= CGRectGetHeight(titleFrame);
	}
	_titleLabel.frame = titleFrame;


	if (hasDetail) {
		// Compute detail frame
		[_detailLabel sizeToFitFixedWidth:availableBounds.size.width];
		detailFrame = CGRectMake(availableBounds.origin.x,
								 availableBounds.origin.y,
								 availableBounds.size.width,
								 _detailLabel.frame.size.height);
		// Match the accesssory height, if there's no title text and the accessory is larger
		if (hasAccessory && !hasTitle && detailFrame.size.height < accessoryFrame.size.height) {
			detailFrame.size.height = accessoryFrame.size.height;
		}
		// Adjust remaining available space
		availableBounds.origin.y = CGRectGetMaxY(detailFrame);
		availableBounds.size.height -= CGRectGetHeight(detailFrame);
	}
	_detailLabel.frame = detailFrame;


	CGFloat dropdownHeight = availableBounds.origin.y + VERTICAL_PADDING;
	dropdownHeight = MAX(dropdownHeight, CGRectGetMaxY(_accessoryView.frame) + VERTICAL_PADDING);
	self.dropdownHeight = dropdownHeight;

	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL rotated = UIInterfaceOrientationIsLandscape(orientation) && !self.hasViewCoordinates;

	CGRect frame = self.frame;
	[self setFrame:CGRectMake(frame.origin.x, frame.origin.y, rotated ? dropdownHeight : frame.size.width, rotated ? frame.size.height : dropdownHeight)];

	[self flipViewToOrientation:nil];
}

- (void)flipViewToOrientation:(NSNotification *)notification
{
	if (!__currentDropdown.hasViewCoordinates) {
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

		if (!self.dropdownHeight) return;
		CGFloat angle = 0.0;
		CGRect newFrame = self.window.bounds;
		CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;

		switch (orientation) {
			case UIInterfaceOrientationPortraitUpsideDown:
				angle = M_PI;
				newFrame.origin.y = newFrame.size.height - self.dropdownHeight;
				newFrame.size.height = self.dropdownHeight;
				break;
			case UIInterfaceOrientationLandscapeLeft:
				angle = - M_PI / 2.0f;
				newFrame.size.width = self.dropdownHeight;
				break;
			case UIInterfaceOrientationLandscapeRight:
				angle = M_PI / 2.0f;
				newFrame.origin.x = newFrame.size.width - self.dropdownHeight;
				newFrame.size.width = self.dropdownHeight;
				break;
			default: // as UIInterfaceOrientationPortrait
				angle = 0.0;
				newFrame.size.height = self.dropdownHeight;
				newFrame.size.width = statusBarSize.width;
				break;
		}
		self.transform = CGAffineTransformMakeRotation(angle);
		self.frame = newFrame;
	}
}

- (CGFloat)statusBarOffset {
	if (!__currentDropdown.isView) {
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
		if (self.hasViewCoordinates) {
			return statusBarSize.height;
		} else {
			if (UIInterfaceOrientationIsPortrait(orientation)) {
				return statusBarSize.height;
			} else {
				return statusBarSize.width;
			}

		}
	}
	return 0.f;
}

- (BOOL)hasViewCoordinates
{
	// On iOS 8+ UIWindow coordinates behave the same as UIView coordinates
	if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedDescending) {
		return YES;
	}
	return self.isView;
}

- (BOOL)isView
{
	return ![self.parentView isKindOfClass:[UIWindow class]];
}

@end
