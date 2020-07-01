---
title: Ratis log and chunk storage separation
tags: ozone, perftest
date: 2020-03-03
---


# Ozone Performance #13: Ratis log and chunk storage separation


## Test method

 * The same chunk writer freon test is executed: `ozone freon dcg -n100000000` with the default 1k chunk size
 * All the tests are executed on one pipeline.
 * The storage (chunk) and the metadat (ratis log) directories are modified
 * Tests were run for 15-30 mins to write significant data to be sure that the Linux write cache doesn't hold significant part of the data.


## Results

| chunk space | ratis log     | rate 
|-------------|---------------|---------
| memdisk     | memdisk       | ~8900 chunk write / sec
| hdd         | same hdd      | ~420 chunk write / sec 
| hdd         | different hdd | ~520 chunk write / sec
| hdd         | memdisk       | ~1400 write / sec


### HDD (storage) + memdisk (ratis log) 

The first 3 test provided steady rate:

![](https://i.imgur.com/eNiUw0f.png)

But the 4th test was failed after a few minutes:

```
2020-03-03 12:55:50 INFO  SegmentedRaftLogWorker:582 - 7a6b5796-1a27-455c-b29d-5410181262ac@group-8214B09ED1B4-SegmentedRaftLogWorker: created new log segment /data/metadata/ratis/11eb91cb-3817-48fb-8fed-8214b09ed1b4/current/log_inprogress_1125986
2020-03-03 12:55:51 INFO  SegmentedRaftLogWorker:396 - 7a6b5796-1a27-455c-b29d-5410181262ac@group-8214B09ED1B4-SegmentedRaftLogWorker: Rolling segment log-1125986_1133190 to index:1133190
2020-03-03 12:55:51 ERROR SegmentedRaftLogInputStream:122 - caught exception initializing log_1125986-1133190
java.io.FileNotFoundException: /data/metadata/ratis/11eb91cb-3817-48fb-8fed-8214b09ed1b4/current/log_1125986-1133190 (No such file or directory)
2020-03-03 12:55:51 INFO  SegmentedRaftLogWorker:540 - 7a6b5796-1a27-455c-b29d-5410181262ac@group-8214B09ED1B4-SegmentedRaftLogWorker: Rolled log segment from /data/metadata/ratis/11eb91cb-3817-48fb-8fed-8214b09ed1b4/current/log_inprogress_1125986 to /data/metadata/ratis/11eb91cb-3817-48fb-8fed-8214b09ed1b4/current/log_1125986-1133190
org.apache.ratis.server.raftlog.RaftLogIOException: java.io.FileNotFoundException: /data/metadata/ratis/11eb91cb-3817-48fb-8fed-8214b09ed1b4/current/log_1125986-1133190 (No such file or directory)
Caused by: java.io.FileNotFoundException: /data/metadata/ratis/11eb91cb-3817-48fb-8fed-8214b09ed1b4/current/log_1125986-1133190 (No such file or directory)
```

![](https://i.imgur.com/sh9SmBi.png)

This is a very special case when the Ratis disk is significant faster than the storage disk. I noticed high usage of (Linux) write cache (which can be the reason of the initial peak)

### HDD (storage) + memdisk (ratis log) second attempt

With the second attept, the write was more stable. The persistent speed was sg around 1.5k write / second

![](https://i.imgur.com/GNwOAnu.png)


## Versions 

Date: 2020-02-28
Docker image: elek/ozonedev:20200220-1
Ozone master: 980b7cfb7

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

```
sudo sysctl -a | grep dirty
vm.dirty_background_bytes = 0
vm.dirty_background_ratio = 10
vm.dirty_bytes = 0
vm.dirty_expire_centisecs = 3000
vm.dirty_ratio = 20
vm.dirty_writeback_centisecs = 500
```

dirty_ratio is 20% which is 128GB * 0.2 = 24 Gb

Disk types:

```
cat /sys/block/sd*/device/model
ST2000NM0018-2F3
ST2000NM0018-2F3
ST2000NM0018-2F3
ST2000NM0018-2F3
```

I didn't find the exact model on Seagate, but based on similar disks, the official performance could be 190-250 MByte / sec

https://www.seagate.com/gb/en/support/internal-hard-drives/enterprise-hard-drives/3-5-hdd-10tb/

```
dd if=/dev/zero of=/data/3/test count=100000 bs=10240 conv=fsync
100000+0 records in
100000+0 records out
1024000000 bytes (1.0 GB) copied, 6.22637 s, 164 MB/s
```


