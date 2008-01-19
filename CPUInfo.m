//
//  CPUInfo.m
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//
//  Modified by Christopher Bowns, starting 2007-1-1.

#ifndef NSLOG_DEBUG
#define NSLOG_DEBUG
#endif

#import "CPUInfo.h"

#include <sys/types.h>
//sqrtf, ceilf
#include <math.h>
//sysctl and its parameters
#include <sys/sysctl.h>
//errno, strerror
#include <sys/errno.h>
#include <string.h>

@implementation CPUInfo

/*
	Accomplishes:
		inits cpudata, inptr, outptr
		retrieves lastProcessorInfo for refresh method to go to town.
	
	if cannot get processor info, returns nil.
*/
- (CPUInfo *) initWithCapacity:(unsigned)numItems
{
	
	/*
		from CPU usage
	*/	
	//We could get the number of processors the same way that we get the CPU usage info, but that allocates memory.
/*	enum { miblen = 2U };
	int mib[miblen] = { CTL_HW, HW_NCPU };
	size_t sizeOfNumCPUs = sizeof(numCPUs);
	int status = sysctl(mib, miblen,
		   &numCPUs, &sizeOfNumCPUs,
*/		   /*newp*/ // NULL, /*newlen*/ 0U);
//	if(status != 0) {
		numCPUs = 1; // TODO we're going to assume one CPU for the moment.
//		NSLog(@"%s error status, assuming one CPU", _cmd);
//	}
	
	
	
	
	
	
	self = [super init];
	
	size = numItems;
	cpudata = calloc(numItems, sizeof(CPUData));
	if (cpudata == NULL) {
		NSLog (@"%s Failed to allocate buffer for CPUInfo", _cmd);
		return (nil);
	}
	// Set up our data structure ptrs
	inptr = 0;
	outptr = -1;
	
	// set the lastProcessorInfo array so we can get to work when we call refresh:
	kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, (natural_t *)&numProcessors_nobodyCares, (processor_info_array_t *)&lastProcessorInfo, (mach_msg_type_number_t *)&numLastProcessorInfo);
	if(err != KERN_SUCCESS) {
		NSLog(@"%s failed to get cpu statistics", _cmd);
		
		// if we can't get this info, then we're toast. Exit gracefully.
		return (nil);
	}
	
	return (self);
}


/*
	Assumptions:
		init has run.
		lastProcessorInfo and numLastProcessorInfo contain valid data from prior refresh of CPU info
	Accomplishes:
		retrieves current data
		calculates avg cpu load over last period
		updates cpudata array with info
		deallocates old numLastProcInfo and lastProcessorInfo and set ptrs to new data
*/
- (void)refresh
{
	processor_info_array_t processorInfo;
	natural_t numProcessors_nobodyCares = 0U;
	mach_msg_type_number_t numProcessorInfo;

	kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, (natural_t *)&numProcessors_nobodyCares, (processor_info_array_t *)&processorInfo, (mach_msg_type_number_t *)&numProcessorInfo);
	if(err != KERN_SUCCESS) {
		NSLog(@"%s failed to get cpu statistics", _cmd);
	}
	
	/*
		TODO make this multicore. First, we're gonna need a multicore machine to test it on.
	*/
	// for(unsigned i = 0U; i < numCPUs; ++i)
	
	unsigned int inUse, total, user, sys, nice, idle;
		
	user = processorInfo[CPU_STATE_USER] - lastProcessorInfo[CPU_STATE_USER];
	sys = processorInfo[CPU_STATE_SYSTEM] - lastProcessorInfo[CPU_STATE_SYSTEM];
	nice = processorInfo[CPU_STATE_NICE] - lastProcessorInfo[CPU_STATE_NICE];
	idle = processorInfo[CPU_STATE_IDLE] - lastProcessorInfo[CPU_STATE_IDLE];

	inUse = user + sys + nice;
	total = inUse + idle;
	
	cpudata[inptr].user = (double)user / (double)total;
	cpudata[inptr].sys = (double)sys / (double)total;
	cpudata[inptr].nice = (double)nice / (double)total;
	cpudata[inptr].idle = (double)idle / (double)total;
	
	
	// deallocate the last one, since we don't want memory leaks.
	/*
		TODO refresh: test in Shark / malloc debug: this DOES leak if we take this dealloc out, right?
	*/
	if(lastProcessorInfo) {
		size_t lastProcessorInfoSize = sizeof(integer_t) * numLastProcessorInfo;
		vm_deallocate(mach_task_self(), (vm_address_t)lastProcessorInfo, lastProcessorInfoSize);
	}

	lastProcessorInfo = processorInfo;
	numLastProcessorInfo = numProcessorInfo;
	
	if (++inptr >= size) // advance our data ptr
		inptr = 0;
}


- (void)startIterate
{
	outptr = inptr;
}


- (BOOL)getNext:(CPUDataPtr)ptr
{
	if (outptr == -1)
		return (FALSE);
	*ptr = cpudata[outptr++];
	if (outptr >= size)
		outptr = 0;
	if (outptr == inptr)
		outptr = -1;
	return (TRUE);
}


- (void)getCurrent:(CPUDataPtr)ptr
{
	*ptr = cpudata[inptr ? inptr - 1 : size - 1];
}


- (void)getLast:(CPUDataPtr)ptr
{
	*ptr = cpudata[inptr > 1 ? inptr - 2 : size + inptr - 2];
}


- (int)getSize
{
	return (size);
}

@end