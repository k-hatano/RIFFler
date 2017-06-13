//
//  MyDocument.h
//  RIFFler
//
//  Created by kenta on 10/05/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "ResizableView.h"
#import "ResizableTextView.h"

@interface MyDocument : NSDocument
{
	NSMutableArray *chunks;
	IBOutlet NSTreeController *tree;
	IBOutlet ResizableView *view;
	IBOutlet ResizableTextView *indexesView,*hexView,*asciiView;
	IBOutlet id progress;
	NSMutableString *indexes,*hex,*ascii;
	NSString *format;
	
	int endian,header;
}
- (IBAction)updateTextViews:(id)sender;
- (void)jumpAtSelectedChunk;

@end
