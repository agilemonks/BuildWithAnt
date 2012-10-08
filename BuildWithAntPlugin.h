//
//  BuildWithAntPlugin.h
//  BuildWithAnt
//
//  Created by Mark Lilback on 2/4/11.
//  Copyright 2011 Agile Monks, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CodaPlugInsController.h"

@interface BuildWithAntPlugin : NSObject<CodaPlugIn> {
	CodaPlugInsController *_pluginController;
	NSSound *_successSound, *_errorSound;
}
@property (nonatomic, retain) CodaPlugInsController *pluginController;
-(IBAction)buildWithAnt:(id)sender;
@end
