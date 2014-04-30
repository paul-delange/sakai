//
//  UIPromptTextField.m
//  CustomerCounter
//
//  Created by Paul de Lange on 30/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "UIPromptTextField.h"

@interface UIPromptTextField ()

@property (weak) UILabel* promptLabel;

@end

@implementation UIPromptTextField

- (void) setPrompt:(NSString *)prompt {
    _prompt = [prompt copy];
    self.promptLabel.text = prompt;
    
    if( [prompt length] ) {
        self.textColor = [UIColor redColor];
        self.rightViewMode = UITextFieldViewModeAlways;
    }
    else {
        self.textColor = [UIColor blackColor];
        self.rightViewMode = UITextFieldViewModeNever;
    }
}

- (void) commonInit {
    UILabel* label = [[UILabel alloc] initWithFrame: CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.adjustsFontSizeToFitWidth = YES;
    label.font = [UIFont systemFontOfSize: 9];
    label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentRight;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    
    self.rightView = label;
    self.rightViewMode = UITextFieldViewModeNever;
    
    self.promptLabel = label;
    
    self.prompt = @"";
}

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        [self commonInit];
    }
    return self;
}

#pragma mark - UIView
- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if( self ) {
        [self commonInit];
    }
    return self;
}

#pragma mark - UITextField
- (CGRect) rightViewRectForBounds:(CGRect)bounds {
    const CGFloat inset = 3.;
    CGRect insetRect = CGRectInset(bounds, inset, inset);
    CGFloat width = MAX(CGRectGetWidth(insetRect) * 0.3, 50);
    return CGRectMake(CGRectGetWidth(bounds)-width - inset, inset, width, CGRectGetHeight(insetRect));
}

@end
