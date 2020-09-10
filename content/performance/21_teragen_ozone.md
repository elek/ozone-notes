---
title: Ozone teragen fixes
tags: ozone, perftest
date: 2020-08-12
---

## Test definition

Executing terage with Ozone vs HDFS and default settings. The measurement proves that HDDS-4119 (and RATIS-1042) fixes almost all the performance problems related to limited number of mappers.

## Results

| test | overall time | write time / container |
|--|--|--|
| base run | 5m56.154s | 193322 / 213265 |
| memdisk  | 4m16.507s | 123432 / 122818 |
| memdisk + 92 mappers | 1m21.629s | ~ 4000 | 
| memdisk + 2 mappers + freon | 4m11.554s |  120016 / ... |
| memdisk + 2 mappers + patchfix  | 1m39.091s | without byteman | 


## Detailed results

### Teragen 10g - base run

```
real	5m56.154s
user	0m12.142s
sys	0m0.957s
+ echo 'Test is Done'
```

```
Closing file system instance: 508487439
   write.call: 100001066
   write.allTime: 193322
   hsync.call: 1
   hsync.allTime: 1
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 70
Closing file system instance: 1928802676
   write.call: 100001066
   write.allTime: 213265
   hsync.call: 1
   hsync.allTime: 1
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 90
```

Number of chunk write requets (during 10g test):

```
csm_metrics_write_chunk_num_ops = 2395
om_metrics_num_create_file = 14
```

### Teragen 10g - using memdisk

```
real    4m16.507s
user    0m11.623s
sys     0m0.864s
+ echo 'Test is Done'
```

```
Closing file system instance: 1199373551
   write.call: 100001066
   write.allTime: 123432
   hsync.call: 1
   hsync.allTime: 3
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 69
Closing file system instance: 1365750726
   write.call: 100001066
   write.allTime: 122818
   hsync.call: 1
   hsync.allTime: 3
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 59
```
## Teragen 10g + memdisk + 92 mappers

```
2020-08-11 11:56:58 INFO  Job:1665 - Counters: 34
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=24362510
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		O3FS: Number of bytes read=7893
		O3FS: Number of bytes written=10000000000
		O3FS: Number of read operations=1012
		O3FS: Number of large read operations=0
		O3FS: Number of write operations=184
	Job Counters
		Killed map tasks=1
		Launched map tasks=92
		Other local map tasks=92
		Total time spent by all maps in occupied slots (ms)=1045972
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=1045972
		Total vcore-milliseconds taken by all map tasks=1045972
		Total megabyte-milliseconds taken by all map tasks=1071075328
	Map-Reduce Framework
		Map input records=100000000
		Map output records=100000000
		Input split bytes=7893
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=31348
		CPU time spent (ms)=1109570
		Physical memory (bytes) snapshot=44309745664
		Virtual memory (bytes) snapshot=243148140544
		Total committed heap usage (bytes)=76469764096
		Peak Map Physical memory (bytes)=492118016
		Peak Map Virtual memory (bytes)=2656796672
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=214760662691937609
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=10000000000
```

```
real	1m21.629s
user	0m10.058s
sys	0m0.693s
```

Typical mapper output:

```
Closing file system instance: 1392432801
   write.call: 2174978
   write.allTime: 4039
   hsync.call: 1
   hsync.allTime: 79
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 49
```

```
csm_metrics_write_chunk_num_ops = 2401
om_metrics_num_create_file = 104
```
### memdisk + 2 mappers + freon

For this a one thread freon process has been started in the background:

```
ozone freon  ockg -n1000000 -t1
```

```
real	4m11.554s
user	0m11.139s
sys	0m0.848s
```

```
Closing file system instance: 306367949
   write.call: 100001066
   write.allTime: 120016
   hsync.call: 1
   hsync.allTime: 3
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 52
```

## Hardware (physical machines, gru8)

```shell
VENDOR
	Manufacturer: Dell Inc.
	Product Name: Precision 5530
MEMORY
	Size: 16384 MB
CPUs
	Version: Intel(R) Core(TM) i7-8850H CPU @ 2.60GHz
	Max Speed: 4300 MHz
	Core Enabled: 6
	Thread Count: 12
DISKS
     NAME          SIZE TYPE  FSTYPE      MOUNTPOINT VENDOR MODEL
     nvme0n1     476.9G disk                                Micron 2200S NVMe 512GB
     ├─nvme0n1p1   512M part  vfat        /boot
     ├─nvme0n1p2    16G part  swap        [SWAP]
     └─nvme0n1p3 460.4G part  crypto_LUKS
       └─root    460.4G crypt ext4        /
```
