//
//  RRLayoutConstraint.h
//  RRAutoLayout
//
//  Created by Rolandas Razma on 10/11/2012.
//  Copyright (c) 2012 Rolandas Razma. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, RRLayoutAttribute) {
    RRLayoutAttributeLeft           = 1,
    RRLayoutAttributeRight,
    RRLayoutAttributeTop,
    RRLayoutAttributeBottom,
    RRLayoutAttributeLeading,
    RRLayoutAttributeTrailing,
    RRLayoutAttributeWidth,
    RRLayoutAttributeHeight,
    RRLayoutAttributeCenterX,
    RRLayoutAttributeCenterY,
    RRLayoutAttributeBaseline,
    
    RRLayoutAttributeNotAnAttribute = 0
};


typedef NS_ENUM(NSInteger, RRLayoutRelation) {
    RRLayoutRelationLessThanOrEqual     = -1,
    RRLayoutRelationEqual               = 0,
    RRLayoutRelationGreaterThanOrEqual  = 1,
};


enum {
    RRLayoutPriorityRequired            = 1000, // a required constraint.  Do not exceed this.
    RRLayoutPriorityDefaultHigh         = 750,  // this is the priority level with which a button resists compressing its content.
    RRLayoutPriorityDefaultLow          = 250,  // this is the priority level at which a button hugs its contents horizontally.
    RRLayoutPriorityFittingSizeLevel    = 50,   // When you send -[UIView systemLayoutSizeFittingSize:], the size fitting most closely to the target size (the argument) is computed.  UILayoutPriorityFittingSizeLevel is the priority level with which the view wants to conform to the target size in that computation.  It's quite low.  It is generally not appropriate to make a constraint at exactly this priority.  You want to be higher or lower.
}; typedef float RRLayoutPriority;


@interface RRLayoutConstraint : NSObject

@property (nonatomic)           RRLayoutPriority priority;
@property (readonly, assign)    id firstItem;
@property (readonly)            RRLayoutAttribute firstAttribute;
@property (readonly)            RRLayoutRelation relation;
@property (readonly, assign)    id secondItem;
@property (readonly)            RRLayoutAttribute secondAttribute;
@property (readonly)            CGFloat multiplier;
@property (nonatomic)           CGFloat constant;

+ (id)constraintWithItem:(id)view1 attribute:(RRLayoutAttribute)attr1 relatedBy:(RRLayoutRelation)relation toItem:(id)view2 attribute:(RRLayoutAttribute)attr2 multiplier:(CGFloat)multiplier constant:(CGFloat)c;

@end
