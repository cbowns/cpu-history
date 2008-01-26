/*
 *	CPU History
 *	Christopher Bowns, 2008
 *	
 *	Formerly: Memory Monitor, by Bernhard Baehr
 *
 *	Copyright © 2001-2003 Bernhard Baehr
 *
 *	MainController.h - Main Application Controller Class
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


#import <Cocoa/Cocoa.h>
// import "MemInfo.h"
#import "CPUInfo.h"
#import "Preferences.h"
#import "TranslucentView.h"
#import "TranslucentWindow.h"


@interface MainController : NSObject
{
	Preferences			*preferences;	// the preferences
	// MemInfo			*memInfo;		// memory usage data buffer
	CPUInfo				*cpuInfo; 		//cpu usage data buffer
	NSTimer				*timer;			// timer for icon refreshs
	NSImage				*displayImage;	// image to be displayed (with text)
	NSImage				*graphImage;	// image of the graph (w/o text) for updates
	NSImage				*iconImage;		// dock icon image
	TranslucentView		*view;			// view for the graph window
	TranslucentWindow	*window;		// window for the graph
	NSString			*frameName;		// current name for saving the window position
}

- (void)showPreferences:(id)sender;
- (void)showAboutBox:(id)sender;

@end
