//
//  BuildWithAntPlugin.m
//  BuildWithAnt
//
//  Created by Mark Lilback on 2/4/11.
//  Copyright 2011 Agile Monks, LLC. All rights reserved.
//

#import "BuildWithAntPlugin.h"


@implementation BuildWithAntPlugin
- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)yourBundle
{
	self = [super init];
	self.pluginController = aController;
	[self.pluginController registerActionWithTitle:@"Build With Ant" underSubmenuWithTitle:nil 
		target:self selector:@selector(buildWithAnt:) representedObject:nil keyEquivalent:@"$@k" 
		pluginName:self.name];
	NSString *path = [yourBundle pathForResource:@"correct" ofType:@"mp3"];
	_successSound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
	path = [yourBundle pathForResource:@"wrong" ofType:@"mp3"];
	_errorSound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
	return self;
}

-(void)dealloc
{
	[_successSound release];_successSound=nil;
	[_errorSound release];_errorSound=nil;
	self.pluginController=nil;
	[super dealloc];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	CodaTextView *tview = [self.pluginController focusedTextView:self];
	NSString *sitePath = [tview siteLocalPath];
	NSString *buildPath = [sitePath stringByAppendingPathComponent:@"WEB-INF"];
	NSString *buildFile = [buildPath stringByAppendingPathComponent:@"build.xml"];
	return [[NSFileManager defaultManager] fileExistsAtPath:buildFile];
}
-(NSString*)name
{
	return @"Build With Ant";
}

-(NSString*)parseErrors:(NSString*)xmlContent
{
	NSError *err=nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xmlContent options:0 error:&err] autorelease];
	if (err) {
		NSLog(@"error: %@", err);
		return xmlContent;
	}
	NSArray *nodes = [doc nodesForXPath:@"//target/task[@name='javac']/message" error:&err];
	NSMutableString *str = [NSMutableString stringWithFormat:@"<html><head><title>javac Errors</title><?head><body>"
		"<h1>javac reported the following:</h1>\n<pre>"];
	for (NSXMLNode *node in nodes) {
		[str appendFormat:@"%@\n", [node stringValue]];
	}
	[str appendFormat:@"</pre></body></html>\n"];
	return str;
}

-(IBAction)buildWithAnt:(id)sender
{
	CodaTextView *tview = [self.pluginController focusedTextView:self];
	NSString *sitePath = [tview siteLocalPath];
	NSString *buildPath = [sitePath stringByAppendingPathComponent:@"WEB-INF"];
	NSString *buildFile = [buildPath stringByAppendingPathComponent:@"build.xml"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:buildFile]) {
		NSBeep();
		return;
	}
	//build a task
	NSTask *task = [[NSTask alloc] init];
	NSPipe *outpipe = [NSPipe pipe];
	[task setStandardOutput:outpipe];
	NSMutableArray *args = [NSMutableArray array];
	[args addObject:@"-q"];
	[args addObject:@"-logger"];
	[args addObject:@"org.apache.tools.ant.XmlLogger"];
	[task setCurrentDirectoryPath:buildPath];
	[task setLaunchPath:@"/usr/bin/ant"];
	[task setArguments:args];
	[task launch];
	[task waitUntilExit];
	if (0 != [task terminationStatus]) {
		[_errorSound play];
		NSFileHandle *fh = [outpipe fileHandleForReading];
		NSData *d = [fh readDataToEndOfFile];
		NSString *str = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
		str = [self parseErrors:str];
		str = [NSString stringWithFormat:@"<pre>%@</pre>", str];
		[self.pluginController displayHTMLString:str];
	} else {
		[_successSound play];
	}
}

@synthesize pluginController=_pluginController;

@end
