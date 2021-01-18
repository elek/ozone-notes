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
| HDFS 100g | 629369 | 608952
| Ozone 100g | 2147281 | 2265617 
 
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

### HDFS teragen 100g

```
2020-08-10 13:45:33 INFO  Job:1665 - Counters: 34
        File System Counters
                FILE: Number of bytes read=0
                FILE: Number of bytes written=453744
                FILE: Number of read operations=0
                FILE: Number of large read operations=0
                FILE: Number of write operations=0
                HDFS: Number of bytes read=170
                HDFS: Number of bytes written=100000000000
                HDFS: Number of read operations=12
                HDFS: Number of large read operations=0
                HDFS: Number of write operations=4
                HDFS: Number of bytes read erasure-coded=0
        Job Counters
                Launched map tasks=2
                Other local map tasks=2
                Total time spent by all maps in occupied slots (ms)=3239818
                Total time spent by all reduces in occupied slots (ms)=0
                Total time spent by all map tasks (ms)=3239818
                Total vcore-milliseconds taken by all map tasks=3239818
                Total megabyte-milliseconds taken by all map tasks=3317573632
        Map-Reduce Framework
                Map input records=1000000000
                Map output records=1000000000
                Input split bytes=170
                Spilled Records=0
                Failed Shuffles=0
                Merged Map outputs=0
                GC time elapsed (ms)=26175
                CPU time spent (ms)=3589840
                Physical memory (bytes) snapshot=820944896
                Virtual memory (bytes) snapshot=5226774528
                Total committed heap usage (bytes)=1662386176
                Peak Map Physical memory (bytes)=414384128
                Peak Map Virtual memory (bytes)=2615463936
        org.apache.hadoop.examples.terasort.TeraGen$Counters
                CHECKSUM=2147523228284173905
        File Input Format Counters
                Bytes Read=0
        File Output Format Counters
                Bytes Written=100000000000
Closing file system instance: 1419064127
   write.call: 136
   write.allTime: 15
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 1595
Closing file system instance: 1353362805
   write.call: 136
   write.allTime: 15
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 1595
Closing file system instance: 107196537
   write.call: 136
   write.allTime: 15
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 1595
real    27m42.886s
user    0m11.830s
sys     0m1.657s
+ echo 'Test is Done'
```

```
Closing file system instance: 2001066279
   write.call: 1000000913
   write.allTime: 629369
   hsync.call: 1
   hsync.allTime: 1084
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 16
Closing file system instance: 1118880563
   write.call: 1000000913
   write.allTime: 608952
   hsync.call: 1
   hsync.allTime: 3956
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 25
```
### Ozone teragen 100g

```
2020-08-10 15:48:00 INFO  Job:1665 - Counters: 33
        File System Counters
                FILE: Number of bytes read=0
                FILE: Number of bytes written=529618
                FILE: Number of read operations=0
                FILE: Number of large read operations=0
                FILE: Number of write operations=0
                O3FS: Number of bytes read=170
                O3FS: Number of bytes written=100000000000
                O3FS: Number of read operations=22
                O3FS: Number of large read operations=0
                O3FS: Number of write operations=4
        Job Counters
                Launched map tasks=2
                Other local map tasks=2
                Total time spent by all maps in occupied slots (ms)=6608801
                Total time spent by all reduces in occupied slots (ms)=0
                Total time spent by all map tasks (ms)=6608801
                Total vcore-milliseconds taken by all map tasks=6608801
                Total megabyte-milliseconds taken by all map tasks=6767412224
        Map-Reduce Framework
                Map input records=1000000000
                Map output records=1000000000
                Input split bytes=170
                Spilled Records=0
                Failed Shuffles=0
                Merged Map outputs=0
                GC time elapsed (ms)=52496
                CPU time spent (ms)=4623900
                Physical memory (bytes) snapshot=1104211968
                Virtual memory (bytes) snapshot=5326680064
                Total committed heap usage (bytes)=1662386176
                Peak Map Physical memory (bytes)=553197568
                Peak Map Virtual memory (bytes)=2667528192
        org.apache.hadoop.examples.terasort.TeraGen$Counters
                CHECKSUM=2147523228284173905
        File Input Format Counters
                Bytes Read=0
        File Output Format Counters
                Bytes Written=100000000000
Closing file system instance: 1630037457
   write.call: 140
   write.allTime: 427
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 2256
Closing file system instance: 1696070956
   write.call: 140
   write.allTime: 427
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 2256
Closing file system instance: 1452133155
   write.call: 140
   write.allTime: 427
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 2256

real    57m19.698s
user    0m19.862s
sys     0m3.223s
```

```
Closing file system instance: 2028187228
   write.call: 1000001066
   write.allTime: 2265617
   hsync.call: 1
   hsync.allTime: 2
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 144
Closing file system instance: 155390713
   write.call: 1000001066
   write.allTime: 2147281
   hsync.call: 1
   hsync.allTime: 1
   hflush.call: 0
   hflush.allTime: 0
   close.call: 4
   close.allTime: 142
```

## Hardware (physical machines, gru8)

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