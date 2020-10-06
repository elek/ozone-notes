---
title: HDFS vs Ozone with Freon HCFS write test 
tags: ozone, perftest
date: 2020-10-06
---

## Test method

 1. Start `ozone freon dfsg -s1024000 -n10000` with `-t 1` and `-t 10` with both HDFS and Ozone path
 2. CRC calculation is disabled on both side
 3. Memdisk is used for persistent on both side

 
## Results

Time of execution (reported by the metrics of freon) 

| test | HDFS | Ozone |
|--|--|--|
| 1 thread | 186s, 181s | 144s, 145s | 
| 10 threads | 18s,19s| 35s, 40s | 

https://github.com/elek/ozone-notes/tree/master/static/results/23_hcfs_write

## Analysis

Ozone 1 thread is measured with async-profile (with event=cpu and event=lock).

`lock` profile shows time spent in Ratis `SlidingWindow` which contains a lot of `syncrhonize`-d method.

## References
 
Ozone version: https://github.com/elek/hadoop-ozone/commit/bbf5d5e08a1c434cbe03ed05d4da912196196d0e

(upstream + HDDS-4285)

Deployment definition:

https://github.com/elek/ozone-perf-env/tree/master/hdfs-vs-ozone 

Last commit:

https://github.com/elek/ozone-perf-env/commit/de841ca4cd3c6d1ceb56d0deee72844a0290a98f

## Hardware

(physical machines, gru8)

```shell
VENDOR
	Manufacturer: Dell Inc.
	Product Name: PowerEdge R430
MEMORY
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
CPUs
	Version: Intel(R) Xeon(R) CPU E5-2630 v4 @ 2.20GHz
	Max Speed: 4000 MHz
	Core Enabled: 10
	Thread Count: 20
	Version: Intel(R) Xeon(R) CPU E5-2630 v4 @ 2.20GHz
	Max Speed: 4000 MHz
	Core Enabled: 10
	Thread Count: 20
DISKS
     NAME     SIZE TYPE FSTYPE MOUNTPOINT VENDOR   MODEL
     sda      1.8T disk                   ATA      ST2000NM0018-2F3
     ├─sda1 745.2G part xfs    /
     ├─sda2    10G part swap   [SWAP]
     └─sda3   1.1T part xfs    /var
     sdb      1.8T disk                   ATA      ST2000NM0018-2F3
     └─sdb1   1.8T part xfs    /data/1
     sdc      1.8T disk                   ATA      ST2000NM0018-2F3
     └─sdc1   1.8T part xfs    /data/2
     sdd      1.8T disk                   ATA      ST2000NM0018-2F3
     └─sdd1   1.8T part xfs    /data/3
```