---
tags: ozone, perftest
---

# Ozone Performance #11: Teragen HDFS vs Ozone

Date: 2020-02-24
Docker image: elek/ozone-dev:HDDS-2717-cmdw
Ozone master:

Hadoop version:

```
Hadoop 3.2.1
Source code repository https://gitbox.apache.org/repos/asf/hadoop.git -r b3cbbb467e22ea829b3808f4b7b01d07e0bf3842
Compiled by rohithsharmaks on 2019-09-10T15:56Z
Compiled with protoc 2.5.0
From source with checksum 776eaf9eee9c0ffc370bcbc1888737
This command was run using /opt/hadoop/share/hadoop/common/hadoop-common-3.2.1.jar
```

Ozone version:

```
Source code repository git@github.com:apache/hadoop-ozone.git -r 980b7cfb7c7c62b7e4ba440326aa161d56fd8894
Compiled by elek on 2020-02-25T10:44Z
Compiled with protoc 2.5.0
From source with checksum 168b297d33a1aa1017f5f37be7141171

Using HDDS 0.5.0-SNAPSHOT
Source code repository git@github.com:apache/hadoop-ozone.git -r 980b7cfb7c7c62b7e4ba440326aa161d56fd8894
Compiled by elek on 2020-02-25T10:44Z
Compiled with protoc 2.5.0
From source with checksum 303920db6dcfc0701fd78bfff799e65
```

## Environment

 * 6 Dell PowerEdge R430
 * e5-2630 v4 @ 2.2Ghz
 * 128GB Ram
 * 4-2TB disks

Provisioned with kubernetes


## HDFS Teragen (10G, 2 mapper)

Elapsed: 	1mins, 3sec 

```
2020-02-25 10:18:35 INFO  Job:1665 - Counters: 34
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=452532
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
		Total time spent by all maps in occupied slots (ms)=111444
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=111444
		Total vcore-milliseconds taken by all map tasks=111444
		Total megabyte-milliseconds taken by all map tasks=114118656
	Map-Reduce Framework
		Map input records=100000000
		Map output records=100000000
		Input split bytes=170
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=525
		CPU time spent (ms)=131430
		Physical memory (bytes) snapshot=741711872
		Virtual memory (bytes) snapshot=5216288768
		Total committed heap usage (bytes)=1662386176
		Peak Map Physical memory (bytes)=382902272
		Peak Map Virtual memory (bytes)=2609102848
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=214760662691937609
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=10000000000
```

## Ozone Teragen (10G, 2 mapper)

Elapsed: 	3mins, 25sec 
 
```
2020-02-25 11:31:10 INFO  Job:1665 - Counters: 33
	File System Counters
		FILE: Number of bytes read=0
		FILE: Number of bytes written=528560
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
		Total time spent by all maps in occupied slots (ms)=366500
		Total time spent by all reduces in occupied slots (ms)=0
		Total time spent by all map tasks (ms)=366500
		Total vcore-milliseconds taken by all map tasks=366500
		Total megabyte-milliseconds taken by all map tasks=375296000
	Map-Reduce Framework
		Map input records=100000000
		Map output records=100000000
		Input split bytes=170
		Spilled Records=0
		Failed Shuffles=0
		Merged Map outputs=0
		GC time elapsed (ms)=3379
		CPU time spent (ms)=1092570
		Physical memory (bytes) snapshot=1001512960
		Virtual memory (bytes) snapshot=5360386048
		Total committed heap usage (bytes)=1662386176
		Peak Map Physical memory (bytes)=503775232
		Peak Map Virtual memory (bytes)=2686590976
	org.apache.hadoop.examples.terasort.TeraGen$Counters
		CHECKSUM=214760662691937609
	File Input Format Counters
		Bytes Read=0
	File Output Format Counters
		Bytes Written=10000000000

```