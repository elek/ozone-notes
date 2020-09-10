---
title: Ozone + Spark + Parquet
tags: ozone, perftest
date: 2020-09-10
---

## Test method

 1. Start both HDFS and Ozone
 2. Execute Spark job with `local` executor to generate/copy/count parquet files
    1. `generate` creates multiple parquet files in `hdfs`/`o3fs`
    2. `count` calculates the number of records
    3. `copy` reads the records and writes to an other directory

Tests are executed with:
 
```shell
time $SPARK_HOME/bin/spark-submit \
    --conf spark.executor.memory=4g \
    --jars /opt/ozonefs/hadoop-ozone-filesystem.jar \
    $SAMPLES_DIR/spark-samples-1.0-SNAPSHOT.jar \
    $@
```

And this script is called multiple times:

```shell
./run_parquet.sh generate --records 50 --iteration 200 o3fs://bucket1.vol1/testdata1
./run_parquet.sh count o3fs://bucket1.vol1/testdata1
./run_parquet.sh copy o3fs://bucket1.vol1/testdata1 o3fs://bucket1.vol1/test1
```

Same commands are executed with `hdfs` file system.

Spark samples can be found here: https://github.com/elek/spark-samples

## Results

*Real* time of the test execution (reported by linux `time` command) 

| test | HDFS | Ozone |
|--|--|--|
| copy | 3m12s | 7m22s | 
| count | 0m13s | 0m16s | 

Detailed results (including flamegraph) are committed to here: 

## Analysis

After checking the overall time of executions (with byteman), it turned out that the client spends a lot of time in watch for commit call (132 second in this case)

```
Closing file system instance: 753980739
   write.call: 18200
   write.allTime: 8389
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 101
   close.allTime: 14221
   watchForCommit.call: 600
   watchForCommit.allTime: 132813
```

Adding server side byteman instrumentation also showed that even with RATIS-1042, we can see long pause with certain watch for commit requests. (Usually it tasks 5-20 ms, but sometimes leader waits 2-3 sec before the HB.)

Note: Ozone default min timeout heartbeat for Raft is 5 seconds.

## References
 
Ozone version: https://github.com/elek/hadoop-ozone/commit/d65fb279bcfda1ce2c5777d0ea7e30673b60ff72

(upstream + HDDS-4119, HDDS-4185)

Ratis version: https://github.com/elek/incubator-ratis/commit/ddc48d3c0bb77f8a29fb9133ed8c2f7f27fce2d8

(upstream + RATIS-1042, RATIS-1050)

Spark samples: https://github.com/elek/spark-samples/commit/fad74c095d47398a4732b700dd55121daa9f999b

Deployment definition:

https://github.com/elek/ozone-perf-env/tree/master/spark-ozone 

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