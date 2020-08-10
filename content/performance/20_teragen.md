 ---
title: Teragen test (HDFS vs. Ozone)
tags: ozone, perftest
date: 2020-08-09
---




## Test method

 * Deployed Ozone+Yarn and HDFS+Yarn (3.2.1) with k8s scripts
 * Executed teragen MR with 10G data
 * Using spinning disk
 * HCFS usage is measured with instrumented bytecode
   * Real time spent in `write` and `close` methods 
 * same storage is used for defaultFs (yarn data) and teragen data
 * FileSystem usage from the yarn userlog directory is checked (see note below)
 * One pipeline (3 datanodes) is used from both the HDFS and both Ozone

References:

 * [Ozone setup](https://github.com/elek/ozone-perf-env/tree/394876bd2011898c8346dcf36369cd6ee38d6bd0/teragen-ozone)
 * [HDFS setup](https://github.com/elek/ozone-perf-env/tree/394876bd2011898c8346dcf36369cd6ee38d6bd0/teragen-ozone)

Note: the usage of the store by `yarn jar` process is usually negligible:

```
Closing file system instance: 1982717463
   write.call: 133
   write.allTime: 16
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 1212
```

Therefore the usage of the mapreduce tasks is checked:

```
for i in `seq 0 2`; do  kubectl exec -it  yarn-nodemanager-$i -- find logs -name "stdout" -exec cat {} \; ; done
```

```
ROWS=$(numfmt --from=auto --to-unit=100 1G)
time yarn jar $MR_EXAMPLES_JAR teragen $ROWS $OUTPUTDIR
```

## Summary

All the tests are started with full clean deployment / setup

Write time (time spent in the `write` method of the DataOutputStream per containers)

| storage | write time (container1) ms | write time (container 2) ms |
|--|--|--|
| HDFS 1g  | 6392 | 6696
| Ozone 1g   | 23477 | 25648
| Ozone 1g   | 14390 | 14922
| Ozone 1g  | 17405 | 22249
| Ozone 10g   | 206103 | 215951
| Ozone 10g | 213687 | 212151
| HDFS 10g | 58280 | 61442

## Detailed test results


### HDFS + teragen + 1g

```
for i in `seq 0 2`; do  kubectl exec -it  yarn-nodemanager-$i -- find logs -name "stdout" -exec cat {} \; ; done
```

```
Closing file system instance: 230851935
   write.call: 10000913
   write.allTime: 6696
   hsync.call: 1
   hsync.allTime: 749
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
Closing file system instance: 167575615
   write.call: 10000913
   write.allTime: 6696
   hsync.call: 1
   hsync.allTime: 749
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
Closing file system instance: 972638534
   write.call: 10000913
   write.allTime: 6696
   hsync.call: 1
   hsync.allTime: 749
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
Closing file system instance: 1818807423
   write.call: 10000913
   write.allTime: 6392
   hsync.call: 1
   hsync.allTime: 756
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
Closing file system instance: 1750553898
   write.call: 10000913
   write.allTime: 6392
   hsync.call: 1
   hsync.allTime: 756
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
Closing file system instance: 1848946756
   write.call: 10000913
   write.allTime: 6392
   hsync.call: 1
   hsync.allTime: 756
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
```
### Ozone + teragen + 1GB

```
2020-08-10 12:24:23 INFO  Job:1658 - Job job_1597062159976_0001 completed successfully
2020-08-10 12:24:23 INFO  Job:1665 - Counters: 33
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=529614
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		O3FS: Number of bytes read=167
		O3FS: Number of bytes written=1000000000
		O3FS: Number of read operations=22
		O3FS: Number of large read operations=0
		O3FS: Number of write operations=4
	Job Counters
		Launched map tasks=2
		Other local map tasks=2
		Total time spent by all maps in occupied slots (ms)=86126
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=86126
		Total vcore-milliseconds taken by all map tasks=86126
		Total megabyte-milliseconds taken by all map tasks=88193024
	Map-Reduce Framework
		Map input records=10000000
		Map output records=10000000
		Input split bytes=167
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=1147
		CPU time spent (ms)=63820
		Physical memory (bytes) snapshot=984911872
		Virtual memory (bytes) snapshot=5277089792
		Total committed heap usage (bytes)=1662386176
		Peak Map Physical memory (bytes)=493924352
		Peak Map Virtual memory (bytes)=2638544896
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=21472776955442690
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=1000000000
real	1m11.225s
user	0m10.388s
sys	0m0.722s
```

And in the yarn job:


```
Closing file system instance: 1832802876
   write.call: 10001066
   write.allTime: 25648
   hsync.call: 1
   hsync.allTime: 40
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 53
Closing file system instance: 539036233
   write.call: 10001066
   write.allTime: 23477
   hsync.call: 1
   hsync.allTime: 3608
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 59
```
## Ozone + teragen + 1GB (repeated)

```
Closing file system instance: 1682810825
   write.call: 10001066
   write.allTime: 14390
   hsync.call: 1
   hsync.allTime: 44
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 66
Closing file system instance: 1218501023
   write.call: 10001066
   write.allTime: 14922
   hsync.call: 1
   hsync.allTime: 50
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 56
```

## Ozone + teragen + 1GB (repeated, again)

```
Closing file system instance: 1902012857
   write.call: 10001066
   write.allTime: 17405
   hsync.call: 1
   hsync.allTime: 6254
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 67
Closing file system instance: 1463799060
   write.call: 10001066
   write.allTime: 22249
   hsync.call: 1
   hsync.allTime: 3776
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 67
```

## Ozone teragen 10G


```
2020-08-10 12:46:05 INFO  Job:1658 - Job job_1597063173295_0001 completed successfully
2020-08-10 12:46:05 INFO  Job:1665 - Counters: 33
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=529616
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		O3FS: Number of bytes read=170
		O3FS: Number of bytes written=10000000000
		O3FS: Number of read operations=22
		O3FS: Number of large read operations=0
		O3FS: Number of write operations=4
	Job Counters
		Launched map tasks=2
		Other local map tasks=2
		Total time spent by all maps in occupied slots (ms)=642475
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=642475
		Total vcore-milliseconds taken by all map tasks=642475
		Total megabyte-milliseconds taken by all map tasks=657894400
	Map-Reduce Framework
		Map input records=100000000
		Map output records=100000000
		Input split bytes=170
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=5648
		CPU time spent (ms)=474380
		Physical memory (bytes) snapshot=1018052608
		Virtual memory (bytes) snapshot=5319036928
		Total committed heap usage (bytes)=1662386176
		Peak Map Physical memory (bytes)=510095360
		Peak Map Virtual memory (bytes)=2663591936
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=214760662691937609
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=10000000000
```

```
Closing file system instance: 504988492
   write.call: 100001066
   write.allTime: 206103
   hsync.call: 1
   hsync.allTime: 3
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 793
Closing file system instance: 1257412274
   write.call: 100001066
   write.allTime: 215951
   hsync.call: 1
   hsync.allTime: 3
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 62
```

# Ozone teragen 10G (repeated)

```
2020-08-10 12:59:49 INFO  Job:1658 - Job job_1597064005361_0001 completed successfully
2020-08-10 12:59:49 INFO  Job:1665 - Counters: 33
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=529616
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		O3FS: Number of bytes read=170
		O3FS: Number of bytes written=10000000000
		O3FS: Number of read operations=22
		O3FS: Number of large read operations=0
		O3FS: Number of write operations=4
	Job Counters
		Launched map tasks=2
		Other local map tasks=2
		Total time spent by all maps in occupied slots (ms)=650231
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=650231
		Total vcore-milliseconds taken by all map tasks=650231
		Total megabyte-milliseconds taken by all map tasks=665836544
	Map-Reduce Framework
		Map input records=100000000
		Map output records=100000000
		Input split bytes=170
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=5043
		CPU time spent (ms)=471420
		Physical memory (bytes) snapshot=1023459328
		Virtual memory (bytes) snapshot=5306605568
		Total committed heap usage (bytes)=1662386176
		Peak Map Physical memory (bytes)=513646592
		Peak Map Virtual memory (bytes)=2655428608
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=214760662691937609
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=10000000000
real	5m46.386s
user	0m11.439s
sys	0m0.982s
+ echo 'Test is Done'
```

```
Closing file system instance: 1613947276
   write.call: 100001066
   write.allTime: 212151
   hsync.call: 1
   hsync.allTime: 3
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 74
Closing file system instance: 13471622
   write.call: 100001066
   write.allTime: 213687
   hsync.call: 1
   hsync.allTime: 2
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 63
```

## HDFS teragen 10g

```
2020-08-10 13:13:54 INFO  Job:1658 - Job job_1597065019118_0001 completed successfully
2020-08-10 13:13:54 INFO  Job:1665 - Counters: 34
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=453742
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
		HDFS: Number of bytes read=170
		HDFS: Number of bytes written=10000000000
		HDFS: Number of read operations=12
		HDFS: Number of large read operations=0
		HDFS: Number of write operations=4
		HDFS: Number of bytes read erasure-coded=0
	Job Counters
		Launched map tasks=2
		Other local map tasks=2
		Total time spent by all maps in occupied slots (ms)=330786
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=330786
		Total vcore-milliseconds taken by all map tasks=330786
		Total megabyte-milliseconds taken by all map tasks=338724864
	Map-Reduce Framework
		Map input records=100000000
		Map output records=100000000
		Input split bytes=170
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=3001
		CPU time spent (ms)=367000
		Physical memory (bytes) snapshot=801095680
		Virtual memory (bytes) snapshot=5223550976
		Total committed heap usage (bytes)=1662386176
		Peak Map Physical memory (bytes)=404410368
		Peak Map Virtual memory (bytes)=2616754176
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=214760662691937609
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=10000000000
Closing file system instance: 1954865355
   write.call: 136
   write.allTime: 13
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 1613
Closing file system instance: 1891334787
   write.call: 136
   write.allTime: 13
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 1613
Closing file system instance: 261744080
   write.call: 136
   write.allTime: 13
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 1613

real	3m6.752s
user	0m7.570s
sys	0m0.667s
+ echo 'Test is Done'
```

```
Closing file system instance: 206420512
   write.call: 100000913
   write.allTime: 61442
   hsync.call: 1
   hsync.allTime: 2755
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
Closing file system instance: 1308614318
   write.call: 100000913
   write.allTime: 58280
   hsync.call: 1
   hsync.allTime: 394
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 24
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