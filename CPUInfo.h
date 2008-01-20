//
//  CPUInfo.h
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//
//  Modified by Christopher Bowns, starting 2008-1-1.

#import <Cocoa/Cocoa.h>

#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>

typedef struct cpudata {
	double user;
	double sys;
	double nice;
	double idle;
} CPUData, *CPUDataPtr;

@interface CPUInfo : NSObject {
	processor_info_array_t lastProcessorInfo;
	mach_msg_type_number_t numLastProcessorInfo;
	unsigned numCPUs;
	CPUDataPtr cpudata;
	int size;
	int inptr;
	int outptr;
}

- (CPUInfo *)initWithCapacity:(unsigned)numItems;
- (void)refresh;
- (void)startIterate;
- (BOOL)getNext:(CPUDataPtr)ptr;
- (void)getCurrent:(CPUDataPtr)ptr;
- (void)getLast:(CPUDataPtr)ptr;
- (int)getSize;

@end
