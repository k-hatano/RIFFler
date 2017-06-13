//
//  DoubleClickableOutlineView.m
//
//  Created by kenta on 10/08/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DoubleClickableOutlineView.h"

@implementation DoubleClickableOutlineView

- (void)awakeFromNib{
	[self setDoubleAction:@selector(doubleClicked:)];
}

- (void)doubleClicked:(id)sender{
	[owner jumpAtSelectedChunk];
}

@end
