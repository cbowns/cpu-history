/*
 *	CPU History
 *	Christopher Bowns, 2008
 *	
 *	Formerly: Memory Monitor, by Bernhard Baehr
 *
 *	Copyright © 2001-2003 Bernhard Baehr
 *
 *	Preferences.m - Preferences Controller Class
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program; if not, write to the Free Software
 *	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


#import "Preferences.h"


@implementation Preferences


+ (NSMutableDictionary *)defaultPreferences
{
	return ([[NSMutableDictionary alloc] initWithObjectsAndKeys:
		[[NSColor greenColor] colorWithAlphaComponent:1.0], USER_COLOR_KEY,
		[[NSColor redColor] colorWithAlphaComponent:1.0], SYS_COLOR_KEY,
		[[NSColor blueColor] colorWithAlphaComponent:1.0], NICE_COLOR_KEY,
		[[NSColor blackColor] colorWithAlphaComponent:1.0], IDLE_COLOR_KEY,
		
		
		[NSNumber numberWithInt:10], UPDATE_FREQUENCY_KEY,	/* unit is 1/10 second */
		[NSNumber numberWithBool:NO], SHOW_GRAPH_WINDOW_KEY,
		[NSNumber numberWithBool:NO], GRAPH_WINDOW_ON_TOP_KEY,
		[NSNumber numberWithInt:128], GRAPH_WINDOW_SIZE_KEY,
		[NSNumber numberWithFloat:1.0], DOCK_ICON_SIZE_KEY,
		[NSNumber numberWithInt:4], BAR_WIDTH_SIZE_KEY,
		[NSNumber numberWithFloat:4.0], GRAPH_SPACER_WIDTH,
		nil]);
}


- (id)init
{
#define SCANCOLOR(key)	\
	if ((obj = [defaults objectForKey:key])) { \
		a = transparency; \
		sscanf ([obj cString], "%f %f %f %f", &r, &g, &b, &a); \
		obj = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a]; \
		[currentSettings setObject:obj forKey:key]; \
	}
#define GETNUMBER(key)	\
	if ((obj = [defaults objectForKey:key])) \
		[currentSettings setObject:obj forKey:key];

	id	obj;
	float	r, g, b, a, transparency = 0.0;

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	self = [super init];
        currentSettings = [Preferences defaultPreferences];
	// transparency = 1.0;			/* paging was drawn without transparency in version 1.1 */

	SCANCOLOR (USER_COLOR_KEY);
	SCANCOLOR (SYS_COLOR_KEY);
	SCANCOLOR (NICE_COLOR_KEY);
	SCANCOLOR (IDLE_COLOR_KEY);
	GETNUMBER (UPDATE_FREQUENCY_KEY);
	GETNUMBER (SHOW_GRAPH_WINDOW_KEY);
	GETNUMBER (GRAPH_WINDOW_ON_TOP_KEY);
	GETNUMBER (GRAPH_WINDOW_SIZE_KEY);
	GETNUMBER (DOCK_ICON_SIZE_KEY);
	GETNUMBER (BAR_WIDTH_SIZE_KEY);
	GETNUMBER (GRAPH_SPACER_WIDTH);
	transparency = obj ? [obj floatValue] : 0.8;	/* global transparency setting of version 1.1 */
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
	return (self);
}


- (void)showUpdateFrequency:(int)freq
{
	[updateFrequency setStringValue:[NSString
		localizedStringWithFormat:NSLocalizedString(@"every\n%.1f sec.", @""), freq / 10.0]];
}


- (void)adjustGraphWindowControls
{	
	id	obj;
	
	BOOL enabled = [[currentSettings objectForKey:SHOW_GRAPH_WINDOW_KEY] boolValue];
	NSColor *color = enabled ? [NSColor controlTextColor] : [NSColor controlHighlightColor];
	NSEnumerator *enumerator = [[graphWindowOptionsView subviews] objectEnumerator];
	
	while ((obj = [enumerator nextObject])) {
		if ([obj isMemberOfClass:[NSTextField class]])
			[obj setTextColor:color];
		else
			[obj setEnabled:enabled];
	}
}


- (IBAction)showPreferences:(id)sender
{
	double	freq;
	
	if (! panel) {
		if ([NSBundle loadNibNamed:@"Preferences" owner:self])
			[panel center];
		else {
			NSLog (@"Failed to load Preferences.nib");
			return;
		}
	}
	
	[userColor setColor:[currentSettings objectForKey:USER_COLOR_KEY]];
	[sysColor setColor:[currentSettings objectForKey:SYS_COLOR_KEY]];
	[niceColor setColor:[currentSettings objectForKey:NICE_COLOR_KEY]];
	[idleColor setColor:[currentSettings objectForKey:IDLE_COLOR_KEY]];

	freq = [[currentSettings objectForKey:UPDATE_FREQUENCY_KEY] floatValue];
	[self showUpdateFrequency:(int)freq];
	[updateFrequencySlider setFloatValue:1000.0 * log(freq)];
	[showGraphWindow setState:[[currentSettings objectForKey:SHOW_GRAPH_WINDOW_KEY] boolValue]];
	[graphWindowOnTop setState:[[currentSettings objectForKey:GRAPH_WINDOW_ON_TOP_KEY] boolValue]];
	[graphWindowSize setFloatValue:[[currentSettings objectForKey:GRAPH_WINDOW_SIZE_KEY] floatValue]];
	[dockIconSizeSlider setFloatValue:[[currentSettings objectForKey:DOCK_ICON_SIZE_KEY] floatValue]];
	[barWidthSlider setFloatValue:[[currentSettings objectForKey:BAR_WIDTH_SIZE_KEY] floatValue]];
	[graphSpacerSlider setFloatValue:[[currentSettings objectForKey:GRAPH_SPACER_WIDTH] floatValue]];
	[self adjustGraphWindowControls];
	[panel makeKeyAndOrderFront:nil];
}


- (IBAction)revertToDefaults:(id)sender
{
	[currentSettings release];
	currentSettings = [Preferences defaultPreferences];
	[self showPreferences:sender];
	[[NSNotificationCenter defaultCenter] postNotificationName:PREFERENCES_CHANGED object:nil];
}


- (void)savePreferences
{
	id		obj;
	float		r, g, b, a;
	NSString	*key;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSEnumerator *enumerator = [currentSettings keyEnumerator];

	while ((key = [enumerator nextObject])) {
		obj = [currentSettings objectForKey:key];
		if ([obj isKindOfClass:[NSColor class]]) {
			[[obj colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"]
				getRed:&r green:&g blue:&b alpha:&a];
			[obj release];
			obj = [NSString stringWithFormat:@"%f %f %f %f", r, g, b, a];
		}
		[defaults setObject:obj forKey:key];
	}
}


- (id)objectForKey:(id)key
{
	return ([currentSettings objectForKey:key]);
}


- (IBAction)preferencesChanged:(id)sender
{
	int	freq;

	[currentSettings setObject:[userColor color] forKey:USER_COLOR_KEY];
	[currentSettings setObject:[sysColor color] forKey:SYS_COLOR_KEY];
	[currentSettings setObject:[niceColor color] forKey:NICE_COLOR_KEY];
	[currentSettings setObject:[idleColor color] forKey:IDLE_COLOR_KEY];

	freq = exp([updateFrequencySlider doubleValue] / 1000.0);	/* 1..600 == 0.1 sec. to 1 min. */
	[self showUpdateFrequency:freq];
	[currentSettings setObject:[NSNumber numberWithInt:freq] forKey:UPDATE_FREQUENCY_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[showGraphWindow state]] forKey:SHOW_GRAPH_WINDOW_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[graphWindowOnTop state]] forKey:GRAPH_WINDOW_ON_TOP_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[graphWindowSize intValue]] forKey:GRAPH_WINDOW_SIZE_KEY];
	[currentSettings setObject:[NSNumber numberWithFloat:[dockIconSizeSlider floatValue]] forKey:DOCK_ICON_SIZE_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[barWidthSlider intValue]] forKey:BAR_WIDTH_SIZE_KEY];
	[currentSettings setObject:[NSNumber numberWithFloat:[graphSpacerSlider floatValue]] forKey:GRAPH_SPACER_WIDTH];
	[self adjustGraphWindowControls];
	[[NSNotificationCenter defaultCenter] postNotificationName:PREFERENCES_CHANGED object:nil];
}


- (int)windowNumber
{
	return (panel ? [panel windowNumber] : 0);
}


@end
