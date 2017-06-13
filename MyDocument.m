//
//  MyDocument.m
//  RIFFler
//
//  Created by kenta on 10/05/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
		indexes=[[NSMutableString alloc] init];
		ascii=[[NSMutableString alloc] init];
		hex=[[NSMutableString alloc] init];
		format=[[NSString alloc] init];
		chunks=[[NSMutableArray alloc] init];
		header=0;
    }
    return self;
}

- (void)dealloc
{
	[indexes release];
	[ascii release];
	[hex release];
	[format release];
	[chunks release];
	[super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    [self updateTextViews:self];
	[view updateSize:self];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    int i,j,dataLength=[data length],depth=0,bytes[8],location[8],padding=1;
	unsigned int ui,uj;
	unsigned char chr,blk[5]={0,0,0,0,0},cts[5]={0,0,0,0,0};
	char str[5]={0,0,0,0,0};
	NSString *block,*chunkName;
	NSMutableArray *arrays[8],*children;
	
	for(i=0;i<dataLength;i+=16){
		[indexes appendFormat:@"%08X\n",i];
	}
	
	for(i=0;i<dataLength;i+=16){
		for(j=0;j<16;j++){
			if(i+j>=dataLength) break;
			[data getBytes:&chr range:NSMakeRange(i+j,1)];
			[hex appendFormat:@"%02X ",chr];
			if(chr>=0x20&&chr<=0x7F) [ascii appendFormat:@"%c",chr];
			else [ascii appendString:@"."];
		}
		[hex appendString:@"\n"];
		[ascii appendString:@"\n"];
	}
	
	endian=0;
	ui=0;
	while (endian==0) {
		[data getBytes:&blk range:NSMakeRange(ui+4,4)];
		uj=blk[0]*0x1000000+blk[1]*0x10000+blk[2]*0x100+blk[3];
		ui+=8+((uj+1)/2)*2;
		if(ui==dataLength){
			padding=1;
			endian=1;
		}
		if(ui>dataLength) break;
	}
	
	ui=0;
	while (endian==0) {
		[data getBytes:&blk range:NSMakeRange(ui+4,4)];
		uj=blk[0]*0x1000000+blk[1]*0x10000+blk[2]*0x100+blk[3];
		ui+=8+uj;
		if(ui==dataLength){
			padding=0;
			endian=1;
		}
		if(ui>dataLength) break;
	}
	
	ui=0;
	while (endian==0) {
		[data getBytes:&blk range:NSMakeRange(ui+4,4)];
		uj=blk[3]*0x1000000+blk[2]*0x10000+blk[1]*0x100+blk[0];
		ui+=8+((uj+1)/2)*2;
		if(ui==dataLength){
			padding=1;
			endian=2;
		}
		if(ui>dataLength) break;
	}
	
	ui=0;
	while (endian==0) {
		[data getBytes:&blk range:NSMakeRange(ui+4,4)];
		uj=blk[3]*0x1000000+blk[2]*0x10000+blk[1]*0x100+blk[0];
		ui+=8+uj;
		if(ui==dataLength){
			padding=0;
			endian=2;
		}
		if(ui>dataLength) break;
	}
	
	if(endian==1){
		[format release];
		format=[[NSString alloc] initWithFormat:@"%@, %d %@",NSLocalizedString(@"FormatBigEndian",nil),dataLength,NSLocalizedString(@"UnitBytes",nil)];
	}else if(endian==2){
		[format release];
		format=[[NSString alloc] initWithFormat:@"%@, %d %@",NSLocalizedString(@"FormatLittleEndian",nil),dataLength,NSLocalizedString(@"UnitBytes",nil)];
	}else{
		return NO;
	}
	
	arrays[0]=chunks;
	depth=0;
	location[0]=0;
	if(endian==1||endian==2){
		i=0;
		while(i<dataLength){
			[data getBytes:&str range:NSMakeRange(i,4)];
			block=[NSString stringWithCString:str];
			[data getBytes:&blk range:NSMakeRange(i+4,4)];
			if(endian==1) j=blk[0]*0x1000000+blk[1]*0x10000+blk[2]*0x100+blk[3];
			if(endian==2) j=blk[3]*0x1000000+blk[2]*0x10000+blk[1]*0x100+blk[0];
			if([block isEqualToString:@"FORM"]||[block isEqualToString:@"LIST"]||[block isEqualToString:@"CAT "]||[block isEqualToString:@"RIFF"]){
				[data getBytes:&cts range:NSMakeRange(i+8,4)];
				bytes[depth]=j;
				children=[NSMutableArray array];
				arrays[depth+1]=children;
				chunkName=[NSString stringWithFormat:@"%s / %s ( %d %@ )",str,cts,j,NSLocalizedString(@"UnitBytes",nil)];
				[arrays[depth] addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:chunkName,children,[NSNumber numberWithInt:i],[NSNumber numberWithInt:j],nil]
																	 forKeys:[NSArray arrayWithObjects:@"name",@"children",@"location",@"bytes",nil]]];
				depth++;
				i+=12;
				location[depth]=i;
			}else{
				children=nil;
				chunkName=[NSString stringWithFormat:@"%s ( %d %@ )",str,j,NSLocalizedString(@"UnitBytes",nil)];
				[arrays[depth] addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:chunkName,[NSNumber numberWithInt:i],[NSNumber numberWithInt:j],nil]
																	 forKeys:[NSArray arrayWithObjects:@"name",@"location",@"bytes",nil]]];
				if(padding==1)	i+=((j+1)/2)*2+8;
				else			i+=j+8;
				while(depth>0&&location[depth]+bytes[depth-1]-4<=i){
					depth--;
				}
			}
		}
	}
	
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (IBAction)updateTextViews:(id)sender{
	[indexesView setString:indexes];
	[[indexesView textStorage] setFont:[NSFont fontWithName:@"Monaco" size:10.0f]];
	[hexView setString:hex];
	[[hexView textStorage] setFont:[NSFont fontWithName:@"Monaco" size:10.0f]];
	[asciiView setString:ascii];
	[[asciiView textStorage] setFont:[NSFont fontWithName:@"Monaco" size:10.0f]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification{
	id chunk=[[tree selectedObjects] objectAtIndex:0];
	int gLoc=[[chunk objectForKey:@"location"] intValue];
	int gBytes=[[chunk objectForKey:@"bytes"] intValue]+8;
	int rBef=gLoc/16;
	int rAft=(gLoc+gBytes)/16-gLoc/16;
	[progress setHidden:NO];
	[progress display];
	[[indexesView textStorage] setAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor colorWithDeviceWhite:0.95f alpha:1.0f],[NSFont fontWithName:@"Monaco" size:10.0f],nil]
																		 forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,NSFontAttributeName,nil]]
									   range:NSMakeRange(0, [[indexesView textStorage] length])];
	[[indexesView textStorage] setAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor blackColor],[NSFont fontWithName:@"Monaco" size:10.0f],nil]
																		 forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,NSFontAttributeName,nil]]
									   range:NSMakeRange((gLoc/16)*9,(gLoc+gBytes+15)/16*9-(gLoc/16)*9)];
	
	[[hexView textStorage] setAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor colorWithDeviceWhite:0.95f alpha:1.0f],[NSFont fontWithName:@"Monaco" size:10.0f],nil]
																	 forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,NSFontAttributeName,nil]]
								   range:NSMakeRange(0, [[hexView textStorage] length])];
	[[hexView textStorage] setAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor blackColor],[NSFont fontWithName:@"Monaco" size:10.0f],nil]
																	 forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,NSFontAttributeName,nil]]
								   range:NSMakeRange(gLoc*3+rBef,gBytes*3+rAft)];
	[[asciiView textStorage] setAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor colorWithDeviceWhite:0.95f alpha:1.0f],[NSFont fontWithName:@"Monaco" size:10.0f],nil]
																	   forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,NSFontAttributeName,nil]]
									 range:NSMakeRange(0, [[asciiView textStorage] length])];
	[[asciiView textStorage] setAttributes:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSColor blackColor],[NSFont fontWithName:@"Monaco" size:10.0f],nil]
																	   forKeys:[NSArray arrayWithObjects:NSForegroundColorAttributeName,NSFontAttributeName,nil]]
									 range:NSMakeRange(gLoc+rBef,gBytes+rAft)];
	[view setNeedsDisplay:YES];
	header=gLoc*3+rBef;
	[progress setHidden:YES];
}

- (void)jumpAtSelectedChunk{
	[hexView setSelectedRange:NSMakeRange(header,0)];
	[hexView centerSelectionInVisibleArea:self];
}

@end
