---
title: Teragen crosscheck of master / HDDS-2717 (new / old layout)
tags: ozone, perftest
date: 2020-03-10
---
# Ozone Performance #15: Teragen crosscheck of master / HDDS-2717 (new / old layout)


## Test method

 * 100G Teragen has been executed on Yarn with using o3fs as input / output dir
 * 3 nodes are used for HDFS/Ozone 3 nodes for YARN
 * Storage
   * Ratis log is saved to memdisk
   * OM, SCM metadata is saved to disk (emptyDir)
   * Chunks are saved to real disk (hostPath)
   * Local disks are deleted after each sequence of tests
 * Default settings used except:
     * **GC** 
         * HADOOP_OPTS: -server -XX:ParallelGCThreads=8 -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:+UseCMSInitiatingOccupancyOnly
     * **Handlers**:
         * OZONE-SITE.XML_ozone.om.handler.count.key: "250"
         * OZONE-SITE.XML_ozone.scm.handler.count.key: "250" 
  * Provisioned with kubernetes
     * 3 nodes are assigned to HDFS *and* Ozone
     * 3 nodes are assigned to Yarn
     * Kubernetes master is not used
  * Result is checked via Yarn Rest API:

```
curl http://myhost:32230/ws/v1/cluster/apps | jq -r '.apps.app[] | [.id,.state,.finalStatus,.elapsedTime, .vcoreSeconds] | @csv'
```

**Test script**:

```
ROWS=$(numfmt --from=auto --to-unit=100 100G)
OUTPUT_DIR=teragen-$(shuf -i 1000-2000 -n 1)

OUTPUT_DIR=o3fs://bucket1.vol1.ozone-om-0.ozone-om/$OUTPUT_DIR

MR_EXAMPLES_JAR=/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar

time yarn jar $MR_EXAMPLES_JAR teragen \
-Dmapreduce.map.log.level=INFO \
-Dmapreduce.reduce.log.level=INFO \
-Dyarn.app.mapreduce.am.log.level=INFO \
-Dmapreduce.map.cpu.vcores=1 \
-Dmapreduce.map.java.opts=-Xmx1536m \
-Dmapreduce.map.maxattempts=1 \
-Dmapreduce.map.memory.mb=2048 \
-Dmapreduce.map.output.compress=true \
-Dmapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.Lz4Codec \
-Dmapreduce.reduce.cpu.vcores=1 \
-Dmapreduce.reduce.java.opts=-Xmx1536m \
-Dmapreduce.reduce.maxattempts=1 \
-Dmapreduce.reduce.memory.mb=2048 \
-Dyarn.app.mapreduce.am.command.opts=-Xmx768m \
-Dyarn.app.mapreduce.am.resource.mb=1024 \
-Dmapreduce.task.io.sort.factor=100 \
-Dmapreduce.task.io.sort.mb=384 \
-Dmapred.map.tasks=92 \
-Dio.file.buffer.size=131072 \
$ROWS $OUTPUT_DIR

sleep 10000000
```

## Environment

 * 6 Dell PowerEdge R440
 * Intel(R) Xeon(R) Silver 4114 CPU @ 2.20GHz
 * 128GB Ram
 * 4-2TB disks

## Results

### Running teragen with HDFS

Hadoop version:

```
Hadoop 3.2.1
Source code repository https://gitbox.apache.org/repos/asf/hadoop.git -r b3cbbb467e22ea829b3808f4b7b01d07e0bf3842
Compiled by rohithsharmaks on 2019-09-10T15:56Z
Compiled with protoc 2.5.0
From source with checksum 776eaf9eee9c0ffc370bcbc1888737
This command was run using /opt/hadoop/share/hadoop/common/hadoop-common-3.2.1.jar
```

From 3 run:

```
"application_1583838490219_0001","FINISHED","SUCCEEDED",555664,6328
"application_1583838490219_0002","FINISHED","SUCCEEDED",563995,6462
"application_1583838490219_0003","FINISHED","SUCCEEDED",584901,6694
```


### Running teragen with Ozone master

Ozone version: `elek/ozone-dev:49edf55c8`

```
"application_1583847724655_0001","FINISHED","SUCCEEDED",637877,7283
"application_1583847724655_0002","FINISHED","SUCCEEDED",674029,7681
"application_1583847724655_0003","FINISHED","SUCCEEDED",736952,8436
```

### Running teragen with Ozone master (FILE_PER_BLOCK)

 * Ozone version: `elek/ozone-dev:290c827ec`
 * `OZONE-SITE.XML_ozone.scm.chunk.layout: FILE_PER_BLOCK`

```
"application_1583852788449_0003","FINISHED","SUCCEEDED",561795,6347
"application_1583852788449_0002","FINISHED","SUCCEEDED",533016,6055
"application_1583852788449_0004","FINISHED","SUCCEEDED",543886,6155
"application_1583852788449_0001","FINISHED","SUCCEEDED",518231,5838
```

### Running teragen with Ozone master (FILE_PER_CHUNK)

 * Ozone version: `elek/ozone-dev:290c827ec`
 * `OZONE-SITE.XML_ozone.scm.chunk.layout: FILE_PER_CHUNK`

```
"application_1583856757708_0003","FINISHED","SUCCEEDED",608841,6905
"application_1583856757708_0002","FINISHED","SUCCEEDED",586114,6644
"application_1583856757708_0001","FINISHED","SUCCEEDED",576812,6496
```

### Running terage with Ozone master (second run to double check previous results)

Ozone version: `elek/ozone-dev:49edf55c8`

```
"application_1583861158263_0002","FINISHED","SUCCEEDED",588957,6708
"application_1583861158263_0003","FINISHED","SUCCEEDED",634666,7218
"application_1583861158263_0001","FINISHED","SUCCEEDED",580441,6569
```
