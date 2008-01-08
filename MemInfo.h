/*
 *	Memory Monitor
 *
 *	Copyright © 2001-2002 Bernhard Baehr
 *
 *	MemInfo.h - Memory Usage History Container Class
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
#import <mach/mach.h>
#import <mach/mach_types.h>


typedef struct vmdata {
	double	wired;
	double	active;
	double	inactive;
	double	free;
	int	pageins;
	int	pageouts;
}	VMData, *VMDataPtr;


@interface MemInfo : NSObject
{
	int			size;
	int			inptr;
	int			outptr;
	VMDataPtr		vmdata;
	vm_statistics_data_t	lastvmstat;
}

- (MemInfo *)initWithCapacity:(unsigned)numItems;
- (void)refresh;
- (void)startIterate;
- (BOOL)getNext:(VMDataPtr)ptr;
- (void)getCurrent:(VMDataPtr)ptr;
- (void)getLast:(VMDataPtr)ptr;
- (int)getSize;

@end
