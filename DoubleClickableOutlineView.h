//
//  DoubleClickableOutlineView.h
//
//  Created by kenta on 10/08/03.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyDocument.h"

@interface DoubleClickableOutlineView : NSOutlineView {
	IBOutlet id owner;
}

- (void)doubleClicked:(id)sender;

@end
