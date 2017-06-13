//
//  ResizableView.m
//
//  Created by kenta on 10/05/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ResizableView.h"

@implementation ResizableView

- (BOOL)isResizable{
	return YES;
}

- (BOOL)isFlipped{
	return YES;
}

- (IBAction)updateSize:(id)sender{
	NSTextView* childView=[[self subviews] objectAtIndex:0];
	if(childView){
		while([childView frame].size.height>[self bounds].size.height){
			NSRect bnd=[self frame];
			bnd.size.height=[childView frame].size.height;
			[self setFrameSize:bnd.size];
			[childView display];
			[self display];
		}
	}
}

- (void)viewWillDraw{
	[self updateSize:self];
}

@end
