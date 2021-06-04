---
title: Netty based replication vs GRPC based one
tags: ozone, perftest
date: 2021-06-04
---

## Goal / method

Closed container replication uses a GRPC based protocol to replication containers as `tar.gz` files. This suffers from a back-pressure problem: when compression it is turned out that server pushes the chunks so fast that the memory of the GRPC Netty server became full.

The goal in this test was:

1. Create a test where we can test maximum local throughput
2. Identify the memory leak
3. Compare the GRPC based streaming with a Netty based streaming (if Netty is faster, it can be more reasonable to switch to pure Netty instead of refactoring the GRPC protocol to support back-pressure)


**The test**

New freon tests were developed, which can be started locally on one node.

**Testing GRPC based replication**:

 * Server side of replication service is extended with a new implementation of `ContainerReplicationSource`. Original implementation streams the content of a container directory as one `tar.gz` file but this test implementation simply generates binary data (without any IO!) 
 * Client side is extended with a new implementation of `ContainerReplicator`. Original implementation downloads the container to a `/tmp/..` temporary directory and copies it to the final destination and import it to the db. New implementation simply saves the data to `/tmp/...` and deletes the file after that. 

**Testing Netty based replication**:

This Freon test in each (!) iteration:

1. starts new replication server
2. replicate one container from the source directory to a destination directory
3. close server/client

In the next iteration the destination directory (same container) is used as a source and copied (over network) to a new directory (again) 

`tmp` dir was a mounted `tmpfs` mount in both cases.

## Results

| protocol | Container size | read io | streaming method | threads |  replication speed | full bandwidth 
|---|---|---|---|---|---|---
| Netty | 5 GB | included | direct | 1 | 1350 MB / s | 1138 MB / s
| Netty | 5 GB | included | buffered | 1 | 915 MB/s | 775 MB / s
| Netty | 5 GB | included | buffered | 5 | 848 MB/s | 3205 MB / s
| Netty | 5 GB | included | buffered | 10 | 612 MB/s | 5102 MB / s
| GRPC | 1 GB | excluded | buffered | 1 | 493 MB/s | 609 MB / s
| GRPC | 1 GB | excluded | buffered | 10 | 341 MB/s | 2439 MB / s

Notes:

 * Please note that the time can be measured in two different ways. 
    * We have metrics which measures the time of the copy of one container (This is called `replication speed` above). This number is always related to one single copy on one single thread.
    * We can measure the full bandwidth with dividing the moved data size by the seconds. This includes all the overhead of generating initial data, starting/stopping services in each iteration, ... (This calculation is called `full bandwidth`) 

Summary:

 * Netty based streaming provides at least 2x performance (and supports back-pressure)
 * 5.1 GB / s full bandwidth can be achieved with Netty server + 10 clients
 * Direct copy on netty side is better but it doesn't support TLS

## References

Hardware profile:

```
MEMORY
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
CPUs
	Version: Intel(R) Xeon(R) Gold 6132 CPU @ 2.60GHz
	Max Speed: 4000 MHz
	Core Enabled: 14
	Thread Count: 28
	Version: Intel(R) Xeon(R) Gold 6132 CPU @ 2.60GHz
	Max Speed: 4000 MHz
	Core Enabled: 14
	Thread Count: 28
DISKS
     NAME      SIZE TYPE FSTYPE MOUNTPOINT   VENDOR   
     sda       7.3T disk xfs    /data/disk1  HGST      
     sdb       7.3T disk xfs    /data/disk2  HGST      
     sdc       7.3T disk xfs    /data/disk3  HGST      
     sdd       7.3T disk xfs    /data/disk4  HGST      
     sde       7.3T disk xfs    /data/disk5  HGST      
     sdf       7.3T disk xfs    /data/disk6  HGST      
     sdg       7.3T disk xfs    /data/disk7  HGST      
     sdh       7.3T disk xfs    /data/disk8  HGST      
     sdi       7.3T disk xfs    /data/disk9  HGST      
     sdj       7.3T disk xfs    /data/disk10 HGST      
     sdk       7.3T disk xfs    /data/disk11 HGST      
     sdl       7.3T disk xfs    /data/disk12 HGST      
     sdm       7.3T disk xfs    /data/disk13 HGST      
     sdn       7.3T disk xfs    /data/disk14 HGST      
     sdo       7.3T disk xfs    /data/disk15 HGST      
     sdp       7.3T disk xfs    /data/disk16 HGST      
     sdq       7.3T disk xfs    /data/disk17 HGST      
     sdr       7.3T disk xfs    /data/disk18 HGST      
     sds       7.3T disk xfs    /data/disk19 HGST      
     sdt       7.3T disk xfs    /data/disk20 HGST      
     sdu       7.3T disk xfs    /data/disk21 HGST      
     sdv       7.3T disk xfs    /data/disk22 HGST      
     sdw       7.3T disk xfs    /data/disk23 HGST      
     sdx       7.3T disk xfs    /data/disk24 HGST      
     sdy       7.3T disk xfs    /data/disk25 HGST      
     sdz       7.3T disk xfs    /data/disk26 HGST      
     sdaa      7.3T disk xfs    /data/disk27 HGST      
     sdab      7.3T disk xfs    /data/disk28 HGST      
     sdac      7.3T disk xfs    /data/disk29 HGST      
     sdad      7.3T disk xfs    /data/disk30 HGST      
     sdae      7.3T disk xfs    /data/disk31 HGST      
     sdaf      7.3T disk xfs    /data/disk32 HGST      
     sdag      7.3T disk xfs    /data/disk33 HGST      
     sdah      7.3T disk xfs    /data/disk34 HGST      
     sdai      7.3T disk xfs    /data/disk35 HGST      
     sdaj      7.3T disk xfs    /data/disk36 HGST      
     sdak      7.3T disk xfs    /data/disk37 HGST      
     sdal      7.3T disk xfs    /data/disk38 HGST      
     sdam      7.3T disk xfs    /data/disk39 HGST      
     sdan      7.3T disk xfs    /data/disk40 HGST      
     sdao      7.3T disk xfs    /data/disk41 HGST      
     sdap      7.3T disk xfs    /data/disk42 HGST      
     sdaq      7.3T disk xfs    /data/disk43 HGST      
     sdar      7.3T disk xfs    /data/disk44 HGST      
     sdas      7.3T disk xfs    /data/disk45 HGST      
     sdat      7.3T disk xfs    /data/disk46 HGST      
     sdau      7.3T disk xfs    /data/disk47 HGST      
     sdav      7.3T disk xfs    /data/disk48 HGST      
     sdaw    446.1G disk                     DRAID
     ├─sdaw1   1.9G part xfs    /boot                 
     ├─sdaw2   1.9G part swap   [SWAP]                
     └─sdaw3 442.3G part xfs    /
```

**All test used `tmpfs` for disk IO**

Code:

 * [GRPC test](https://github.com/elek/ozone/tree/f89592201ebcfd97543547ee6439078f14ebcbe9)
 * [Netty test](https://github.com/elek/ozone/tree/f63233165ebd50a89ae37bb52a584ec25368b607)

## Problems

Grpc doesn't support back-pressure and we have very simple workflow. When the new container (5G) is requested the FULL container is streamed back immediately. This can be reproduced easily with the branch of the *GRPC test* with using 5G container size AND turning off the compression (GZ compression is a natural throttling):

```
	Exception in thread "grpc-default-executor-0" org.apache.ratis.thirdparty.io.netty.util.internal.OutOfDirectMemoryError: failed to allocate 2097152 byte(s) of direct memory (used: 3651141911, max: 3652190208)
	at org.apache.ratis.thirdparty.io.netty.util.internal.PlatformDependent.incrementMemoryCounter(PlatformDependent.java:802)
	at org.apache.ratis.thirdparty.io.netty.util.internal.PlatformDependent.allocateDirectNoCleaner(PlatformDependent.java:731)
	at org.apache.ratis.thirdparty.io.netty.buffer.PoolArena$DirectArena.allocateDirect(PoolArena.java:632)
	at org.apache.ratis.thirdparty.io.netty.buffer.PoolArena$DirectArena.newChunk(PoolArena.java:607)
	at org.apache.ratis.thirdparty.io.netty.buffer.PoolArena.allocateNormal(PoolArena.java:202)
	at org.apache.ratis.thirdparty.io.netty.buffer.PoolArena.tcacheAllocateNormal(PoolArena.java:186)
	at org.apache.ratis.thirdparty.io.netty.buffer.PoolArena.allocate(PoolArena.java:136)
	at org.apache.ratis.thirdparty.io.netty.buffer.PoolArena.allocate(PoolArena.java:126)
  ```

For more details please consult with https://issues.apache.org/jira/browse/HDDS-5188

Netty does have a direct stream approach where the source files can be directly streamed without reading it to the memory on Java side. This is extremly fast (see the *direct stream* results) but not supported in TLS. (To do TLS encryption the file should be read to the memory)

``` java
ChannelFuture nextFuture = ctx.writeAndFlush(new DefaultFileRegion(file.toFile(), 0, fileSize));
```

The SSL compatible version uses buffer, but still supports back pressure:

```java
ChannelFuture nextFuture = ctx.writeAndFlush(new ChunkedFile(file.toFile())));
```

## Detailed results

### Netty, direct stream (no ssl), one thread

```
./ozone freon strmg -t 1 -n 100
```

```
6/1/21, 7:27:31 AM =============================================================

-- Timers ----------------------------------------------------------------------
streaming
             count = 100
         mean rate = 0.23 calls/second
     1-minute rate = 0.24 calls/second
     5-minute rate = 0.23 calls/second
    15-minute rate = 0.21 calls/second
               min = 3361.97 milliseconds
               max = 4053.50 milliseconds
              mean = 3698.21 milliseconds
            stddev = 190.19 milliseconds
            median = 3695.45 milliseconds
              75% <= 3891.21 milliseconds
              95% <= 3998.56 milliseconds
              98% <= 3998.56 milliseconds
              99% <= 3998.56 milliseconds
            99.9% <= 3998.56 milliseconds


Total execution time (sec): 439
Failures: 0
Successful executions: 100
```

### Netty, buffered stream, one thread

```
./ozone freon strmg -t 1 -n 100
```


```
6/1/21, 7:59:04 AM =============================================================

-- Timers ----------------------------------------------------------------------
streaming
             count = 100
         mean rate = 0.16 calls/second
     1-minute rate = 0.15 calls/second
     5-minute rate = 0.14 calls/second
    15-minute rate = 0.08 calls/second
               min = 4086.37 milliseconds
               max = 7535.74 milliseconds
              mean = 5462.03 milliseconds
            stddev = 985.35 milliseconds
            median = 4991.12 milliseconds
              75% <= 6595.91 milliseconds
              95% <= 7164.12 milliseconds
              98% <= 7450.92 milliseconds
              99% <= 7450.92 milliseconds
            99.9% <= 7460.92 milliseconds


Total execution time (sec): 645
Failures: 0
Successful executions: 100
```

### Netty, buffered stream, 5 threads

```
./ozone freon strmg -t 5 -n 100
```

```
6/1/21, 8:06:54 AM =============================================================

-- Timers ----------------------------------------------------------------------
streaming
             count = 100
         mean rate = 0.67 calls/second
     1-minute rate = 0.66 calls/second
     5-minute rate = 0.26 calls/second
    15-minute rate = 0.10 calls/second
               min = 4593.77 milliseconds
               max = 7816.80 milliseconds
              mean = 5891.29 milliseconds
            stddev = 899.41 milliseconds
            median = 5541.54 milliseconds
              75% <= 6679.99 milliseconds
              95% <= 7582.51 milliseconds
              98% <= 7619.06 milliseconds
              99% <= 7816.80 milliseconds
            99.9% <= 7816.80 milliseconds


Total execution time (sec): 156
Failures: 0
Successful executions: 100
```

## Netty, buffered stream, 10 threads

```
./ozone freon strmg -t 10 -n 100
```


```
6/1/21, 8:14:11 AM =============================================================

-- Timers ----------------------------------------------------------------------
streaming
             count = 100
         mean rate = 1.10 calls/second
     1-minute rate = 0.91 calls/second
     5-minute rate = 0.29 calls/second
    15-minute rate = 0.11 calls/second
               min = 5231.08 milliseconds
               max = 8641.47 milliseconds
              mean = 6746.27 milliseconds
            stddev = 885.65 milliseconds
            median = 6608.68 milliseconds
              75% <= 7556.51 milliseconds
              95% <= 8220.80 milliseconds
              98% <= 8346.96 milliseconds
              99% <= 8587.91 milliseconds
            99.9% <= 8641.47 milliseconds


Total execution time (sec): 98
Failures: 0
Successful executions: 100
```

## GRPC, one thread (1GB!)

```
./ozone freon -Dhdds.datanode.replication.work.dir=/tmp/ozone-streaming css -n100 -t1
```


```
-- Timers ----------------------------------------------------------------------
stream-container
             count = 100
         mean rate = 0.61 calls/second
     1-minute rate = 0.60 calls/second
     5-minute rate = 0.49 calls/second
    15-minute rate = 0.43 calls/second
               min = 1497.51 milliseconds
               max = 2259.07 milliseconds
              mean = 1632.60 milliseconds
            stddev = 89.55 milliseconds
            median = 1621.36 milliseconds
              75% <= 1674.75 milliseconds
              95% <= 1812.28 milliseconds
              98% <= 1848.99 milliseconds
              99% <= 1848.99 milliseconds
            99.9% <= 2259.07 milliseconds


Total execution time (sec): 164
Failures: 0
Successful executions: 100
```

## GRPC, 5 threads (1GB!)

```
./ozone freon -Dhdds.datanode.replication.work.dir=/tmp/ozone-streaming css -n100 -t5
```

```
6/2/21, 2:11:34 AM =============================================================

-- Timers ----------------------------------------------------------------------
stream-container
             count = 100
         mean rate = 2.43 calls/second
     1-minute rate = 1.69 calls/second
     5-minute rate = 1.17 calls/second
    15-minute rate = 1.06 calls/second
               min = 1803.27 milliseconds
               max = 4037.96 milliseconds
              mean = 2026.75 milliseconds
            stddev = 292.93 milliseconds
            median = 1989.70 milliseconds
              75% <= 2050.04 milliseconds
              95% <= 2171.61 milliseconds
              98% <= 3245.13 milliseconds
              99% <= 3298.03 milliseconds
            99.9% <= 4037.96 milliseconds


Total execution time (sec): 41
Failures: 0
Successful executions: 100
```

## GRPC, 10 threads (1GB!)

```
./ozone freon -Dhdds.datanode.replication.work.dir=/tmp/ozone-streaming css -n100 -t10
```

```
6/2/21, 2:13:13 AM =============================================================

-- Timers ----------------------------------------------------------------------
stream-container
             count = 100
         mean rate = 3.32 calls/second
     1-minute rate = 2.44 calls/second
     5-minute rate = 1.95 calls/second
    15-minute rate = 1.85 calls/second
               min = 2337.06 milliseconds
               max = 5199.46 milliseconds
              mean = 2929.32 milliseconds
            stddev = 527.70 milliseconds
            median = 2818.80 milliseconds
              75% <= 2894.44 milliseconds
              95% <= 4458.88 milliseconds
              98% <= 4710.28 milliseconds
              99% <= 4901.65 milliseconds
            99.9% <= 5199.46 milliseconds


Total execution time (sec): 30
Failures: 0
Successful executions: 100
```
