/*
 *	Memory Monitor
 *
 *	Copyright © 2001-2002 Bernhard Baehr
 *
 *	main.m - main() of Memory Monitor
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


#import <AppKit/AppKit.h>

#import "CPUInfo.h"

int main (int argc, const char *argv[])
{
	// return (NSApplicationMain(argc, argv));
	int size = 24, i, j;
	CPUInfo *cpuInfo = [[CPUInfo alloc] initWithCapacity:size];
	CPUData cpuData;
	
	[cpuInfo refresh];
	for (j = 0; j < 48; j++) {
		for (i = 0; i < 1000000; ) {
			i++;
		}
		[cpuInfo refresh];
	}

	[cpuInfo startIterate];
	for (i = 0; [cpuInfo getNext:&cpuData]; i++) {
		NSLog(@"user: %e\n", cpuData.user);
		NSLog(@"sys: %e\n", cpuData.sys);
		NSLog(@"nice: %e\n", cpuData.nice);
		NSLog(@"idle: %e\n", cpuData.idle);
	}
	
	return 0;
}
