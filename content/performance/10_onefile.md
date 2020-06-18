---
tags: ozone, perftest
title: Writing one file per chunks vs. one file per blocks
date: 2020-02-24
---

 * Docker image: elek/ozone-dev:HDDS-2717-cmdw

## How to test?

 * Freon test executed Chunk Writes calling the `ChunkManagerImpl.writeChunk` method directly.
 * Size of chunks has been modified between the tests
 * All the results are 
 * All the tests are executed parallel on 6 machines (one test requires only one machine --> 6 test results)
 * After the freon test a `sync` call has been executed. If it took >0.1s, the sync time has been added to the measured write time.
 * Real hard disk has been used


Example test script:

```
ozone freon --verbose cmdw -n10000 -s 102400 -c 16 -t16 -l FILE_PER_BLOCK
date
time sync
date
echo "Hostname: $(hostname)"
echo "TEST HAS BEEN FINISHED"
sleep 100000
```

Executed tests:

```
execute_test perchunk-1k   ozone freon --verbose cmdw -n1000000 -s 1024    -t16 -l FILE_PER_CHUNK
execute_test perchunk-10k  ozone freon --verbose cmdw -n100000  -s 10240   -t16 -l FILE_PER_CHUNK
execute_test perchunk-100k ozone freon --verbose cmdw -n10000   -s 102400  -t16 -l FILE_PER_CHUNK
execute_test perchunk-1M   ozone freon --verbose cmdw -n1000    -s 1024000 -t16 -l FILE_PER_CHUNK
execute_test perchunk-4M   ozone freon --verbose cmdw -n100     -s 4096000 -t16 -l FILE_PER_CHUNK


execute_test onefile-1k    ozone freon --verbose cmdw -n1000000 -s 1024    -c 16 -t16 -l FILE_PER_BLOCK
execute_test onefile-10k   ozone freon --verbose cmdw -n100000  -s 10240   -c 16 -t16 -l FILE_PER_BLOCK
execute_test onefile-100k  ozone freon --verbose cmdw -n10000   -s 102400  -c 16 -t16 -l FILE_PER_BLOCK
execute_test onefile-1M    ozone freon --verbose cmdw -n1000    -s 1024000 -c 16 -t16 -l FILE_PER_BLOCK
execute_test onefile-4M    ozone freon --verbose cmdw -n100     -s 4096000 -c 16 -t16 -l FILE_PER_BLOCK
```

## Environment

Tests are run on a 10 node physical cluster (only 3 nodes were used in a given time)

 * Cisco UCSC-C220-M4L racks
 * 2 x Intel(R) Xeon(R) CPU E5-2630 v3 @ 2.40GHz (2 x 8 core --> 2 x 16 threads)
 * 256GB mem
 * HGST HUS726060AL4210 SCSi disks

**All the tests are executed three times, on 3 different machines parallel**

## Test results

```
testname        rate                    chunks  sec             sync
onefile-100k	9718.592507444693	10000	4		0m17.418s
onefile-100k	9722.676047031922	10000	4		0m17.777s
onefile-100k	9719.050682705287	10000	4		0m17.898s
onefile-100k	9758.300509215931	10000	4		0m18.005s
onefile-100k	9762.677767708628	10000	4		0m17.978s
onefile-100k	9734.463205598586	10000	4		0m19.281s

onefile-10k	93419.46017150157	100000	4		0m15.858s
onefile-10k	93696.40662165661	100000	4		0m16.094s
onefile-10k	97504.11938816235	100000	3		0m16.178s
onefile-10k	93755.63005488343	100000	4		0m16.681s
onefile-10k	87472.2507514669	100000	4		0m16.355s
onefile-10k	71124.24526195972	100000	4		0m18.288s
onefile-1k	329674.4873003501	1000000	5		0m16.352s
onefile-1k	395181.4064201807	1000000	5		0m16.332s
onefile-1k	330022.30937940534	1000000	6		0m16.311s
onefile-1k	454726.63665333844	1000000	5		0m16.241s
onefile-1k	329875.5645803382	1000000	6		0m16.032s
onefile-1k	318038.9377145058	1000000	6		0m17.992s
onefile-1M	974.6677307023314	1000	4		0m10.824s
onefile-1M	975.8830033384957	1000	4		0m10.770s
onefile-1M	977.8707019186994	1000	4		0m10.732s
onefile-1M	969.9443443025407	1000	4		0m11.095s
onefile-1M	914.5892375003585	1000	4		0m9.749s
onefile-1M	969.9313878877617	1000	4		0m12.034s
onefile-4M	97.63963343164137	100	4		0m4.067s
onefile-4M	84.23741908523114	100	4		0m4.313s
onefile-4M	97.74440132287272	100	4		0m3.471s
onefile-4M	98.00806708908581	100	4		0m4.568s
onefile-4M	97.9658124002108	100	4		0m4.223s
onefile-4M	97.7080350677499	100	4		0m4.262s
perchunk-100k	9746.162893029552	10000	4		0m16.403s
perchunk-100k	9723.154687611583	10000	4		0m16.049s
perchunk-100k	9750.785190509403	10000	4		0m16.010s
perchunk-100k	8098.507189940932	10000	4		0m15.702s
perchunk-100k	9749.991659613384	10000	3		0m16.194s
perchunk-100k	9742.77946659929	10000	4		0m17.370s
perchunk-10k	65106.33467370175	100000	4		0m19.251s
perchunk-10k	65901.61482021875	100000	4		0m19.971s
perchunk-10k	67843.26480981767	100000	4		0m19.669s
perchunk-10k	64629.24204758634	100000	4		0m19.586s
perchunk-10k	49293.41186885904	100000	5		0m19.413s
perchunk-10k	49136.89315104702	100000	5		0m21.224s
perchunk-1k	124198.8051207543	1000000	11		1m20.980s
perchunk-1k	116521.04902996239	1000000	11		1m22.745s
perchunk-1k	110797.51590364997	1000000	12		1m22.156s
perchunk-1k	117657.46404823025	1000000	11		1m24.717s
perchunk-1k	99719.9752903275	1000000	12		1m12.232s
perchunk-1k	110731.0381296006	1000000	12		1m26.626s
perchunk-1M	976.6990948021158	1000	4		0m15.740s
perchunk-1M	979.5745511221822	1000	3		0m16.113s
perchunk-1M	974.7307401123004	1000	4		0m16.217s
perchunk-1M	972.326921439805	1000	4		0m15.811s
perchunk-1M	968.7241283149776	1000	4		0m15.686s
perchunk-1M	974.4809193020677	1000	4		0m17.188s
perchunk-4M	97.71888370102266	100	4		0m5.790s
perchunk-4M	97.92370085659168	100	4		0m6.224s
perchunk-4M	97.66749854893443	100	4		0m5.753s
perchunk-4M	97.7990869991661	100	4		0m6.442s
perchunk-4M	98.08197096364069	100	4		0m6.305s
perchunk-4M	97.68548276230054	100	4		0m6.512s
```