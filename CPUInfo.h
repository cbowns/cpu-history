/*
 *	CPU History
 *	Christopher Bowns, 2008
 */
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
	processor_cpu_load_info_t lastProcessorInfo;
	mach_msg_type_number_t numLastProcessorInfo;
	unsigned numCPUs;
	CPUDataPtr *allcpudata;
	int size;
	int inptr;
	int outptr;
}

- (CPUInfo *)initWithCapacity:(unsigned)numItems;
- (void)refresh;
- (unsigned)numCPUs;
- (void)startForwardIterate;
- (void)startBackwardIterate;
- (BOOL)getNext:(CPUDataPtr)ptr forCPU:(unsigned)cpu;
- (BOOL)getPrev:(CPUDataPtr)ptr forCPU:(unsigned)cpu;
- (void)getCurrent:(CPUDataPtr)ptr forCPU:(unsigned)cpu;
- (void)getLast:(CPUDataPtr)ptr forCPU:(unsigned)cpu;
- (int)getSize;

@end
