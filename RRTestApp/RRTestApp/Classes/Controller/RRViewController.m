//
//  RRViewController.m
//  RRTestApp
//
//  Created by Rolandas Razma on 10/11/2012.
//  Copyright (c) 2012 Rolandas Razma. All rights reserved.
//

#import "RRViewController.h"


@implementation RRViewController {
    __weak IBOutlet UIView *_testView01;    
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidUnload {
    _testView01 = nil;
    
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}


- (BOOL)shouldAutorotate {
    return YES;
}


- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


@end
