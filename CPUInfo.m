/*
 *	CPU History
 *	Christopher Bowns, 2008
 */
//  CPUInfo.m
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//
//  Modified by Christopher Bowns, starting 2008-1-1.

// #ifndef NSLOG_DEBUG
// #define NSLOG_DEBUG
// #endif

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
	self = [super init];

	unsigned i, j;

/* from Hosey's CPU Usage.app:
	We could get the number of processors the same way that we get the CPU usage info, but that allocates memory. */
	enum { miblen = 2U };
	int mib[miblen] = { CTL_HW, HW_NCPU };
	size_t sizeOfNumCPUs = sizeof(numCPUs);
	int status = sysctl(mib, miblen,
		   &numCPUs, &sizeOfNumCPUs,
		   NULL, /*newlen*/ 0U);
	if(status != 0) {
		numCPUs = 1; // It's either this, or premature death
		NSLog(@"%s error status, assuming one CPU", _cmd);
	}
	
	size = numItems; // set our size to numItems because that's array length
	
	// Allocate the cpu data matrix
	allcpudata = calloc(numCPUs, sizeof(CPUDataPtr));
	if (allcpudata == NULL) {
		NSLog (@"%s Failed to allocate buffer for CPUInfo", _cmd);
		return (nil);
	}
	for(i = 0; i < numCPUs; i++) {
		allcpudata[i] = calloc(numItems, sizeof(CPUData));
	}
	
	// Set up our data structure ptrs
	inptr = 0;
	outptr = -1;
	
	// set the lastProcessorInfo array so we can get to work when we call refresh:
	natural_t numProcessors_nobodyCares = 0U;
	kern_return_t err = host_processor_info(mach_host_self(),
	                                        PROCESSOR_CPU_LOAD_INFO,
	                                        (natural_t *)&numProcessors_nobodyCares,
	                                        (processor_info_array_t *)&lastProcessorInfo,
	                                        (mach_msg_type_number_t *)&numLastProcessorInfo);
	if(err != KERN_SUCCESS) {
		NSLog(@"%s failed to get cpu statistics", _cmd);
		// if we can't get this info, then we're toast. Exit gracefully.
		return (nil);
	}
	
	for(i = 0U; i < numCPUs; i++)
	{
		CPUDataPtr cpudata = allcpudata[i];
		for (j = 0U; j < numItems; j++)
		{
			cpudata[j].idle = 1.0;
		}
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
	processor_cpu_load_info_t processorInfo;
	natural_t numProcessors;
	mach_msg_type_number_t numProcessorInfo;
	unsigned i;

	kern_return_t err = host_processor_info(mach_host_self(),
	                                        PROCESSOR_CPU_LOAD_INFO,
	                                        (natural_t *)&numProcessors,
	                                        (processor_info_array_t *)&processorInfo,
	                                        (mach_msg_type_number_t *)&numProcessorInfo);
	if(err != KERN_SUCCESS) {
		NSLog(@"%s failed to get cpu statistics", _cmd); // Uh oh.
	}

	for(i = 0U; i < numCPUs; ++i) {
		// NB: numCPUs ought to be the same as numProcessors -- otherwise ...?
		assert(numCPUs == numProcessors);
		assert(numProcessorInfo == numProcessors * CPU_STATE_MAX);
		
		CPUDataPtr cpudata = allcpudata[i];
	
		unsigned int inUse, total, user, sys, nice, idle;
			
		user = processorInfo[i].cpu_ticks[CPU_STATE_USER] - lastProcessorInfo[i].cpu_ticks[CPU_STATE_USER];
		sys = processorInfo[i].cpu_ticks[CPU_STATE_SYSTEM] - lastProcessorInfo[i].cpu_ticks[CPU_STATE_SYSTEM];
		nice = processorInfo[i].cpu_ticks[CPU_STATE_NICE] - lastProcessorInfo[i].cpu_ticks[CPU_STATE_NICE];
		idle = processorInfo[i].cpu_ticks[CPU_STATE_IDLE] - lastProcessorInfo[i].cpu_ticks[CPU_STATE_IDLE];

		inUse = user + sys + nice;
		total = inUse + idle;
		
		cpudata[inptr].user = (double)user / (double)total;
		cpudata[inptr].sys = (double)sys / (double)total;
		cpudata[inptr].nice = (double)nice / (double)total;
		cpudata[inptr].idle = (double)idle / (double)total;
		#ifdef NSLOG_DEBUG
		NSLog(@"CPU %d: User: %.2f\n", i, cpudata[inptr].user);
		NSLog(@"CPU %d: Sys: %.2f\n", i, cpudata[inptr].sys);
		NSLog(@"CPU %d: Nice: %.2f\n", i, cpudata[inptr].nice);
		NSLog(@"CPU %d: Idle: %.2f\n", i, cpudata[inptr].idle);
		#endif
	}
	
	// deallocate the last one, since we don't want memory leaks.
	if(lastProcessorInfo) {
		size_t lastProcessorInfoSize = sizeof(integer_t) * numLastProcessorInfo;
		vm_deallocate(mach_task_self(), (vm_address_t)lastProcessorInfo, lastProcessorInfoSize);
	}

	lastProcessorInfo = processorInfo;
	numLastProcessorInfo = numProcessorInfo;
	
	if (++inptr >= size) // advance our data ptr
		inptr = 0;
}


- (void)startForwardIterate
{
	outptr = inptr;
}

- (void)startBackwardIterate
{
	outptr = (inptr - 1 < 0 ? size - 1 : inptr - 1);
}

- (BOOL)getNext:(CPUDataPtr)ptr forCPU:(unsigned)cpu
{
	if (outptr == -1)
		return (FALSE);
	*ptr = allcpudata[cpu][outptr++];
	if (outptr >= size)
		outptr = 0;
	if (outptr == inptr)
		outptr = -1;
	return (TRUE);
}

- (BOOL)getPrev:(CPUDataPtr)ptr forCPU:(unsigned)cpu
{
	if (outptr == -1)
		return (FALSE);
	*ptr = allcpudata[cpu][outptr--];
	if (outptr < 0)
		outptr = size - 1;
	if (outptr == inptr)
		outptr = -1;
	return (TRUE);
}

- (void)getCurrent:(CPUDataPtr)ptr forCPU:(unsigned)cpu
{
	*ptr = allcpudata[cpu][inptr ? inptr - 1 : size - 1];
}


- (void)getLast:(CPUDataPtr)ptr forCPU:(unsigned)cpu
{
	*ptr = allcpudata[cpu][inptr > 1 ? inptr - 2 : size + inptr - 2];
}


- (int)getSize
{
	return (size);
}

- (unsigned)numCPUs { return (numCPUs); }

@end
