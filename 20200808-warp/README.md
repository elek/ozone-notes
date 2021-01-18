 ---
title: S3 performance test (Ozone, Minio)
tags: ozone, perftest
date: 2020-08-08
---

## Tests

 * Deployed [Ozone](https://github.com/flokkr/docker-ozone/tree/master/examples/simple) and [Minio](https://github.com/elek/docker-minio/tree/master/examples/simple)
 * Using empty dir for Ozone (disk)
 * Executing S3 `put` test with using [minio/warp](https://github.com/minio/warp) 

## Summary 

Ozone seems to be slower with the default settings (1.88 obj/s vs 14 obj/s)

## Results

### Executing warp with Minio

```shell
warp: Preparing server.
warp: Creating Bucket "warp-benchmark-bucket"...
warp: Clearing Bucket "warp-benchmark-bucket"...
warp: Starting benchmark in 3s ...
warp: Benchmark starting...
warp: Benchmark data written to "warp-put-2020-08-08[090737]-al94.csv.zst"

-------------------
Operation: PUT. Concurrency: 40. Hosts: 1.
* Average: 141.82 MiB/s, 14.18 obj/s (4m54.878s, starting 09:07:43 UTC)

Aggregated Throughput, split into 294 x 1s time segments:
 * Fastest: 183.7MiB/s, 18.37 obj/s (1s, starting 09:12:34 UTC)
 * 50% Median: 142.7MiB/s, 14.27 obj/s (1s, starting 09:11:16 UTC)
 * Slowest: 106.5MiB/s, 10.65 obj/s (1s, starting 09:11:37 UTC)
warp: Starting cleanup...
warp: Cleanup Done.
```

### Executing warp with Ozone

Test command:

```shell
- put
- --access-key=root
- --secret-key=WELCOME1
- --host=ozone-s3g-0.ozone-s3g:9878
```

Ozone version:

```shell
Source code repository git@github.com:apache/hadoop-ozone.git -r 5ce6f0eab381389fd04c3130531b3ec626acbc65
Compiled by elek on 2020-08-08T09:29Z
```

Output:

```shell
warp: Preparing server.
warp: Clearing Bucket "warp-benchmark-bucket"...
warp: Starting benchmark in 3s ...
warp: Benchmark starting...
warp: Benchmark data written to "warp-put-2020-08-08[102616]-3g0T.csv.zst"

-------------------
Operation: PUT. Concurrency: 40. Hosts: 1.
* Average: 121.34 MiB/s, 12.13 obj/s (4m30.985s, starting 10:26:21 UTC)

Aggregated Throughput, split into 270 x 1s time segments:
 * Fastest: 400.2MiB/s, 40.02 obj/s (1s, starting 10:26:25 UTC)
 * 50% Median: 18.8MiB/s, 1.88 obj/s (1s, starting 10:27:15 UTC)
 * Slowest: 10.7MiB/s, 1.07 obj/s (1s, starting 10:29:52 UTC)
warp: Starting cleanup...
warp: Cleanup Done.
warp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Markerwarp: <ERROR> unrecognized option:Marker
```



## Hardware AWS/SSD

