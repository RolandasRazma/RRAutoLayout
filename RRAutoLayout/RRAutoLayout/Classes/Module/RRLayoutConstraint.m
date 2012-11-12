//
//  RRLayoutConstraint.m
//  RRAutoLayout
//
//  Copyright (c) 2012 Rolandas Razma <rolandas@razma.lt>
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "RRLayoutConstraint.h"


@implementation RRLayoutConstraint {
    __unsafe_unretained id  _firstItem;
    __unsafe_unretained id  _secondItem;

    RRLayoutPriority        _priority;
    CGFloat                 _constant;
    RRLayoutAttribute       _firstAttribute;
    RRLayoutAttribute       _secondAttribute;
    RRLayoutRelation        _relation;
    
    CGFloat                 _multiplier;
}


#pragma mark -
#pragma mark NSObject


+ (void)load {
    
    if( !NSClassFromString(@"NSLayoutConstraint") ){
        objc_registerClassPair(objc_allocateClassPair([RRLayoutConstraint class], "NSLayoutConstraint", 0));
    }
    
}


- (NSString *)description {
    NSString *firstAttributeOrientation = (( _firstAttribute == RRLayoutAttributeLeft || _firstAttribute == RRLayoutAttributeRight || _firstAttribute == RRLayoutAttributeLeading || _firstAttribute == RRLayoutAttributeTrailing || _firstAttribute == RRLayoutAttributeWidth || _firstAttribute == RRLayoutAttributeCenterX )?@"H":@"V");
 
    if( _firstItem && _secondItem ){        
        return [NSString stringWithFormat:@"<%@:%p %@: [%@:%p] [%@:%p] (%.f)>", NSStringFromClass([self class]), self, firstAttributeOrientation, NSStringFromClass([_firstItem class]), _firstItem, NSStringFromClass([_secondItem class]), _secondItem, self.constant];
    }else{
        return [NSString stringWithFormat:@"<%@:%p %@:[%@:%p(%.f)]>", NSStringFromClass([self class]), self, firstAttributeOrientation, NSStringFromClass([_firstItem class]), _firstItem, self.constant];
    }
}


#pragma mark -
#pragma mark NSCoding


- (id)initWithCoder:(NSCoder *)aDecoder {
    if( (self = [super init]) ){
        _priority = RRLayoutPriorityRequired;
        
        if ( [aDecoder containsValueForKey:@"NSFirstItem"] ){
            _firstItem = [aDecoder decodeObjectForKey:@"NSFirstItem"];
        }

        if ( [aDecoder containsValueForKey:@"NSFirstAttribute"] ){
            _firstAttribute = [aDecoder decodeIntegerForKey:@"NSFirstAttribute"];
        }

        if ( [aDecoder containsValueForKey:@"NSSecondItem"] ){
            _secondItem = [aDecoder decodeObjectForKey:@"NSSecondItem"];
        }

        if ( [aDecoder containsValueForKey:@"NSSecondAttribute"] ){
            _secondAttribute = [aDecoder decodeIntegerForKey:@"NSSecondAttribute"];
        }

        if ( [aDecoder containsValueForKey:@"NSPriority"] ){
            _priority = [aDecoder decodeIntegerForKey:@"NSPriority"];
        }

        if ( [aDecoder containsValueForKey:@"NSConstant"] ){
            _constant = [aDecoder decodeFloatForKey:@"NSConstant"];
        }

        if ( [aDecoder containsValueForKey:@"NSRelation"] ){
            _relation = [aDecoder decodeIntegerForKey:@"NSRelation"];
        }
        
        _multiplier = 1.0f;
    }
    return self;
}


#pragma mark -
#pragma mark RRLayoutConstraint


+ (id)constraintWithItem:(id)view1 attribute:(RRLayoutAttribute)attr1 relatedBy:(RRLayoutRelation)relation toItem:(id)view2 attribute:(RRLayoutAttribute)attr2 multiplier:(CGFloat)multiplier constant:(CGFloat)c {
    return [[self alloc] initWithItem: view1
                            attribute: attr1
                            relatedBy: relation
                               toItem: view2
                            attribute: attr2
                           multiplier: multiplier
                             constant: c];
}


- (id)initWithItem:(id)view1 attribute:(RRLayoutAttribute)attr1 relatedBy:(RRLayoutRelation)relation toItem:(id)view2 attribute:(RRLayoutAttribute)attr2 multiplier:(CGFloat)multiplier constant:(CGFloat)c {
    if( (self = [super init]) ){
        _priority       = RRLayoutPriorityRequired;
        _firstItem      = view1;
        _firstAttribute = attr1;
        _relation       = relation;
        _secondItem     = view2;
        _secondAttribute= attr2;
        _multiplier     = multiplier;
        _constant       = c;
    }
    return self;
}


@end


