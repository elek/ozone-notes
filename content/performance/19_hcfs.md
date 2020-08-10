 ---
title: HCFS test with instrumented FS
tags: ozone, perftest
date: 2020-08-09
---


## Test method

 * Deployed Ozone and HDFS with the help of K8s
 * Executed key generator using Hadoop Compatble File System
 * `ozone freon dfsg`
 * Tested with 
   * default write buffer (using `out.write([]byte, int, int)`)
   * minimal write buffer (using `out.write(byte)` (teragen seems to use this approach)
   * One client / 10 threads
 * Using spinning disk, no HDD (K8s emptydir)
 * Hadoop `FileSystem` interface was instrumented with byteman to get additional metrics

References:

 * Test setup source: [hdfs-vs-ozone](https://github.com/elek/ozone-perf-env/tree/4b2414072f862027624e5f4807a1f8c8414f56c1/hdfs-vs-ozone)
 * Ozone version: 5ce6f0eab (Fri Aug 7 18:35:36 2020 +0200) + few test related fixes
  
Test runs:

```

export HADOOP_USER_NAME=root
run_test_job "ozone-single-byte" "ozone freon dfsg -n 10000 --copy-buffer=1"
run_test_job "ozone-buffered" "ozone freon dfsg -n 10000"


export HADOOP_USER_NAME=hadoop
run_test_job "hdfs-single-byte" "ozone freon dfsg -n 10000 --copy-buffer=1 --path=hdfs://hdfs-namenode-0.hdfs-namenode:9820/"
run_test_job "hdfs-buffered" "ozone freon dfsg -n 10000 --path=hdfs://hdfs-namenode-0.hdfs-namenode:9820"
```

## Summary

Overall time spent in `write` and `close` methods (all thread, all clients)

| storage | buffered | single-byte write |
| ------- | --- | -- |
| Ozone - write |  5.7 s | 365.5 s
| Ozone - close |  583.8 s | 487.9 s
| HDFS - write |  6.92 s | 355.8 s
| HDFS - close |  411.2 s | 427.4 s

 * Ozone is 9% slower with single-byte write operation
 * Ozone is 30% slower with buffered write operation

Second run:

| storage | buffered | single-byte write |
| ------- | --- | -- |
| Ozone - write |  4.7 s | 401.8 s
| Ozone - close |  555.6 s | 565.0 s
| HDFS - write |  0.7 s | 348.1 s
| HDFS - close |  403.6 s | 397.3 s

 * Ozone is 23% slower with single-byte operation
 * Ozone is 18% slower with buffered write operation


## Detailed results

### HDFS, write with buffer

```
ozone freon dfsg -n 10000 --path=hdfs://hdfs-namenode-0.hdfs-namenode:9820
```

Output: 
```
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:38:54 INFO  ProgressBar:163 - Progress: 100.00 % (10000 out of 10000)
Closing file system instance: 1398604678
   write.call: 30000
   write.allTime: 692
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 10000
   close.allTime: 411171

2020-08-10 11:38:55 INFO  metrics:107 - type=TIMER, name=file-create, count=10000, min=41.385081, max=816.43621, mean=58.5215951875575, stddev=37.177717801211635, median=49.595019, p75=50.028302, p95=91.063631, p98=157.57557, p99=208.293648, p999=359.736041, mean_rate=166.56481956393807, m1=161.70502631779362, m5=156.60309390214252, m15=155.18871589812272, rate_unit=events/second, duration_unit=milliseconds
2020-08-10 11:38:55 INFO  BaseFreonGenerator:75 - Total execution time (sec): 61
2020-08-10 11:38:55 INFO  BaseFreonGenerator:75 - Failures: 0
2020-08-10 11:38:55 INFO  BaseFreonGenerator:75 - Successful executions: 10000
Process exited with exit code 0
```

### HDFS, write per one-bytes


```
ozone freon dfsg -n 10000 --copy-buffer=1 --path=hdfs://hdfs-namenode-0.hdfs-namenode:9820/
```

```
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:36 INFO  SaslDataTransferClient:239 - SASL encryption trust check: localHostTrusted = false, remoteHostTrusted = false
2020-08-10 11:37:37 INFO  ProgressBar:163 - Progress: 100.00 % (10000 out of 10000)
Closing file system instance: 1382688883
   write.call: 102400000
   write.allTime: 355779
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 10000
   close.allTime: 427402
2020-08-10 11:37:37 INFO  metrics:107 - type=TIMER, name=file-create, count=10000, min=57.527606, max=306.218368, mean=129.5180830258841, stddev=33.56189161092684, median=124.692845, p75=141.193199, p95=183.019699, p98=223.918406, p99=249.248969, p999=291.149726, mean_rate=74.97087805984943, m1=74.13839740597696, m5=64.33445025272118, m15=60.528153245488504, rate_unit=events/second, duration_unit=milliseconds
2020-08-10 11:37:37 INFO  BaseFreonGenerator:75 - Total execution time (sec): 134
2020-08-10 11:37:37 INFO  BaseFreonGenerator:75 - Failures: 0
2020-08-10 11:37:37 INFO  BaseFreonGenerator:75 - Successful executions: 10000
Process exited with exit code 0
```

### Ozone, write with buffer

```
ozone freon dfsg -n 10000
```

```
2020-08-10 11:34:51 INFO  ProgressBar:163 - Progress: 76.57 % (7657 out of 10000)
2020-08-10 11:34:52 INFO  ProgressBar:163 - Progress: 78.79 % (7879 out of 10000)
2020-08-10 11:34:53 INFO  ProgressBar:163 - Progress: 80.40 % (8040 out of 10000)
2020-08-10 11:34:54 INFO  ProgressBar:163 - Progress: 82.80 % (8280 out of 10000)
2020-08-10 11:34:55 INFO  ProgressBar:163 - Progress: 85.23 % (8523 out of 10000)
2020-08-10 11:34:56 INFO  ProgressBar:163 - Progress: 87.70 % (8770 out of 10000)
2020-08-10 11:34:57 INFO  ProgressBar:163 - Progress: 90.10 % (9010 out of 10000)
2020-08-10 11:34:58 INFO  ProgressBar:163 - Progress: 92.09 % (9209 out of 10000)
2020-08-10 11:34:59 INFO  ProgressBar:163 - Progress: 94.03 % (9403 out of 10000)
2020-08-10 11:35:00 INFO  ProgressBar:163 - Progress: 94.35 % (9435 out of 10000)
2020-08-10 11:35:01 INFO  ProgressBar:163 - Progress: 94.35 % (9435 out of 10000)
2020-08-10 11:35:02 INFO  ProgressBar:163 - Progress: 95.21 % (9521 out of 10000)
2020-08-10 11:35:03 INFO  ProgressBar:163 - Progress: 97.37 % (9737 out of 10000)
2020-08-10 11:35:04 INFO  ProgressBar:163 - Progress: 99.19 % (9919 out of 10000)
2020-08-10 11:35:05 INFO  ProgressBar:163 - Progress: 100.00 % (10000 out of 10000)
2020-08-10 11:35:05 INFO  metrics:107 - type=TIMER, name=file-create, count=10000, min=23.626278, max=3673.990331, mean=60.80244998164423, stddev=210.416573228068, median=33.588919, p75=55.982552, p95=74.940883, p98=139.664499, p99=183.612941, p999=2659.218763, mean_rate=146.99157827396593, m1=104.12563482159561, m5=29.10260270468229, m15=10.2991460850534, rate_unit=events/second, duration_unit=milliseconds
2020-08-10 11:35:05 INFO  BaseFreonGenerator:75 - Total execution time (sec): 69
2020-08-10 11:35:05 INFO  BaseFreonGenerator:75 - Failures: 0
2020-08-10 11:35:05 INFO  BaseFreonGenerator:75 - Successful executions: 10000
2020-08-10 11:35:08 WARN  GrpcUtil:217 - Timed out gracefully shutting down connection: ManagedChannelOrphanWrapper{delegate=ManagedChannelImpl{logId=1, target=10.42.1.36:9858}}.
Closing file system instance: 618312717
   write.call: 30000
   write.allTime: 5654
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 10000
   close.allTime: 583760
Process exited with exit code 0
```

### Ozone, write per one-bytes

```
ozone freon dfsg -n 10000 --copy-buffer=1
```

```
2020-08-10 11:33:24 INFO  ProgressBar:163 - Progress: 90.32 % (9032 out of 10000)
2020-08-10 11:33:25 INFO  ProgressBar:163 - Progress: 91.26 % (9126 out of 10000)
2020-08-10 11:33:26 INFO  ProgressBar:163 - Progress: 92.26 % (9226 out of 10000)
2020-08-10 11:33:27 INFO  ProgressBar:163 - Progress: 93.05 % (9305 out of 10000)
2020-08-10 11:33:28 INFO  ProgressBar:163 - Progress: 93.98 % (9398 out of 10000)
2020-08-10 11:33:29 INFO  ProgressBar:163 - Progress: 94.71 % (9471 out of 10000)
2020-08-10 11:33:30 INFO  ProgressBar:163 - Progress: 95.70 % (9570 out of 10000)
2020-08-10 11:33:31 INFO  ProgressBar:163 - Progress: 96.16 % (9616 out of 10000)
2020-08-10 11:33:32 INFO  ProgressBar:163 - Progress: 96.16 % (9616 out of 10000)
2020-08-10 11:33:33 INFO  ProgressBar:163 - Progress: 96.16 % (9616 out of 10000)
2020-08-10 11:33:34 INFO  ProgressBar:163 - Progress: 97.01 % (9701 out of 10000)
2020-08-10 11:33:35 INFO  ProgressBar:163 - Progress: 98.07 % (9807 out of 10000)
2020-08-10 11:33:36 INFO  ProgressBar:163 - Progress: 98.98 % (9898 out of 10000)
2020-08-10 11:33:37 INFO  ProgressBar:163 - Progress: 99.78 % (9978 out of 10000)
2020-08-10 11:33:38 INFO  ProgressBar:163 - Progress: 100.00 % (10000 out of 10000)
2020-08-10 11:33:38 INFO  metrics:107 - type=TIMER, name=file-create, count=10000, min=32.743198, max=2654.16336, mean=121.86809838711956, stddev=152.80149973670098, median=108.182047, p75=126.767492, p95=189.999038, p98=207.635745, p99=259.264809, p999=2654.16336, mean_rate=78.77864693142469, m1=71.14478797862922, m5=27.241829405996942, m15=10.305643234434587, rate_unit=events/second, duration_unit=milliseconds
2020-08-10 11:33:38 INFO  BaseFreonGenerator:75 - Total execution time (sec): 128
2020-08-10 11:33:38 INFO  BaseFreonGenerator:75 - Failures: 0
2020-08-10 11:33:38 INFO  BaseFreonGenerator:75 - Successful executions: 10000
2020-08-10 11:33:41 WARN  GrpcUtil:217 - Timed out gracefully shutting down connection: ManagedChannelOrphanWrapper{delegate=ManagedChannelImpl{logId=1, target=10.42.1.36:9858}}.
Closing file system instance: 667279054
   write.call: 102400000
   write.allTime: 360485
   hsync.call: 0
   hsync.allTime: 0
   hflush.call: 0
   hflush.allTime: 0
   close.call: 10000
   close.allTime: 487878
Process exited with exit code 0
```


## References


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