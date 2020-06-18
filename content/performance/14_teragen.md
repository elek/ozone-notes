---
title: Teragen crosscheck of master / HDDS-3053 / HDDS-2717
tags: ozone, perftest
date: 2020-03-10
---

## Test method

 * 100G Teragen has been executed on Yarn with using o3fs as input / output dir
 * 3 nodes are used for HDFS/Ozone 3 nodes for YARN
 * Storage
   * Ratis log is saved to memdisk
   * OM, SCM metadata is saved to disk (emptyDir)
   * Chunks are saved to real disk (hostPath)
 * Default settings used except:
     * **GC** 
         * HADOOP_OPTS: -server -XX:ParallelGCThreads=8 -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:+UseCMSInitiatingOccupancyOnly
     * **Handlers**:
         * OZONE-SITE.XML_ozone.om.handler.count.key: "250"
         * OZONE-SITE.XML_ozone.scm.handler.count.key: "250" 

**Test script**:

```
ROWS=$(numfmt --from=auto --to-unit=100 100G)
OUTPUT_DIR=teragen-$(shuf -i 1000-2000 -n 1)

#for HDFS test it was commented out
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

## Environment (margo-01)

 * 6 Dell PowerEdge R430
 * e5-2630 v4 @ 2.2Ghz
 * 128GB Ram 
 * 4-2TB disks (xfs)

Provisioned with kubernetes. 3 nodes are assigned to HDFS *and* Ozone, 3 nodes are assigned to Yarn

## Results

### Running teragen on master

 * docker image: elek/ozone-dev:a68ed78d9 
 * branch: master 
 * date: 2020-03-04

yarn app                        |state       |final_status |elapsed_time  |vcore_seconds
--------------------------------|------------|-------------|--------------|--------------
application_1583403976683_0003  |FINISHED    |SUCCEEDED    |804163        |9217
application_1583403976683_0002  |FINISHED    |SUCCEEDED    |737088        |8411
application_1583403976683_0001  |FINISHED    |SUCCEEDED    |906759        |6669
**average**                     |            |             |**816003**    |**8099**

### Running teragen with master + using 10 chunk writer thread (=HDDS-3053)

Same as before but `dfs.container.ratis.num.write.chunk.threads` set to 10

yarn app                        |state       |final_status |elapsed_time  |vcore_seconds
--------------------------------|------------|-------------|--------------|--------------
application_1583403976683_0007  |FINISHED    |SUCCEEDED    |833224        |9536
application_1583403976683_0006  |FINISHED    |SUCCEEDED    |892604        |10276
application_1583403976683_0005  |FINISHED    |SUCCEEDED    |725781        |8293
application_1583403976683_0004  |FINISHED    |SUCCEEDED    |690087        |7897
**average**                     |            |             |**785424**    |**9000**

### Running teragen with HDDS-2717

 * docker image: elek/ozone-dev:980b7cfb7
 * branch: elek/HDDS-2717
 * date: 2020-03-04
 
yarn app                        |state       |final_status |elapsed_time  |vcore_seconds
--------------------------------|------------|-------------|--------------|--------------
application_1583428240736_0001	|FINISHED	 |SUCCEEDED	   |926361	      |8333
application_1583428240736_0002	|FINISHED	 |SUCCEEDED	   |810906	      |9307
application_1583428240736_0005	|FINISHED	 |SUCCEEDED	   |956264	      |11067
application_1583428240736_0003	|FINISHED	 |SUCCEEDED	   |812252	      |9100
**average**                     |            |             |**876445.75** |**9451**


## Stats

Statistics after one (Ozone master) teragen with 100G write

| metrics                                           | value
|---------------------------------------------------|----------------------------|
| om_metrics_num_keys                               | 91
| om_metrics_num_key_ops                            | 1486
| om_metrics_num_key_deletes                        | 95
| om_metrics_num_key_commits                        | 93
| om_metrics_num_key_lists                          | 94
| om_metrics_num_key_renames                        | 92
| om_metrics_num_block_allocations                  | 373
| om_metrics_num_volume_ops                         | 98
| om_metrics_num_fs_ops                             | 1112
| om_metrics_num_get_file_status                    | 832
| csm_metrics_write_chunk_num_ops                   | 24160
| storage_container_metrics_num_write_chunk         | 48320
| storage_container_metrics_bytes_write_chunk       | 101006632960
| ozone_manager_double_buffer_metrics_total_num_of_flush_operations | 750
| ozone_manager_double_buffer_metrics_max_number_of_transactions_flushed_in_one_iteration | 4
| rpc_rpc_processing_time_num_ops{servername="..."} | 
| ... ScmBlockLocationProtocolService               | 469
| ... StorageContainerLocationProtocolService       | 1016
| ... StorageContainerDatanodeProtocolService       | 341
| ... OzoneManagerService                           | 2151