---
tags:
 - ozone
 - perftest
title: Checking syscalls with different batch sizes
---

# Ozone Performance #7: Checking syscalls with different batch sizes

 * Date: 2020-02-11
 * Ozone master: 3ddcdbbef
 * Ratis master: 0.5.0-90cd474-SNAPSHOT
 * Docker image: elek/ozonedev:20200211-1

## How to test?

 1. Deploy a single Datanode which is forced to be in FOLLOWER mode. Starting it with `strace -f -c`
 2. Stress test with freon (which behaves like a Ratis Leader) from the same container (one node)
 3. Killing datanode to have the strace summary

## Environment

Running k8s based containers on physical cluster, using memdisk.

## Test runs 

Note: strace outputs are truncated from the bottup up until the first 3 digit call number to make the outputs more stable. 

## Batching 1

 * 30000 AppendLogEntry message
 * One ChunkWrite per message (batching=1)
 * 1MB chunk size

```
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 96.70 6831.961434        6243   1094305    131769 futex
  1.99  140.720842        4265     32992           epoll_wait
  0.36   25.085468          48    520661           read
  0.27   18.781636         346     54272           writev
  0.10    6.821235          43    156676     95741 stat
  0.10    6.775423          52    128596           write
  0.08    5.354975          44    120745           rt_sigprocmask
  0.05    3.445797          55     61608           mmap
  0.05    3.238968          53     60278           sched_getaffinity
  0.05    3.179296          52     61122     30031 lstat
  0.03    2.455378          81     30049           madvise
  0.03    2.371992          39     60481         2 fcntl
  0.02    1.642924          54     30183           clone
  0.02    1.604033          51     30891       149 openat
  0.02    1.586000          45     34946           mprotect
  0.02    1.576570          52     30011         1 rename
  0.02    1.391036          46     30172           set_robust_list
  0.02    1.385841          44     31155           close
  0.02    1.382258          45     30167        15 prctl
  0.02    1.187761          39     30135           gettid
  0.01    1.012435          21     47997           lseek
  0.01    0.963521          30     31136           fstat
  0.01    0.647210          39     16353           fdatasync
  0.00    0.135423        2257        60        29 wait4
  0.00    0.035264         277       127           poll
  0.00    0.013295          56       234           pwrite64
  0.00    0.011116          96       115        23 sendto
  0.00    0.008387          21       398           rt_sigreturn
  0.00    0.004159          28       147           brk
  0.00    0.003940          39        99           socket
  0.00    0.003343          39        85        19 connect
  0.00    0.002799          26       106        15 ioctl
  0.00    0.002268          36        62           recvfrom
  0.00    0.001626         406         4           fallocate
  0.00    0.001494          25        58           munmap
  0.00    0.001336           3       380           rt_sigaction
  0.00    0.001226         613         2           vfork
  0.00    0.001204          24        50           getdents64
  0.00    0.000892           7       121        50 access
...
------ ----------- ----------- --------- --------- ----------------
100.00 7064.807148               2727877    257953 total
```

## Batching 10

 * 30000 AppendLogEntry message
 * 10 ChunkWrite per message (batching=10)
 * 1MB chunk size

```
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 95.82 5503.306213       10664    516060     86596 futex
  2.11  121.291899        3342     36286           epoll_wait
  0.62   35.644037         948     37577           writev
  0.40   23.238008          46    496266           read
  0.28   16.310110         104    156700     95748 stat
  0.20   11.320880         187     60509         2 fcntl
  0.12    7.105031          75     93624           write
  0.10    5.770015         186     30978       149 openat
  0.09    5.446157         173     31367           close
  0.09    5.278145         109     48189           lseek
  0.09    5.166612         165     31223           fstat
  0.02    1.222427          20     61086     30013 lstat
  0.01    0.707895          23     30046         1 rename
  0.01    0.293017          36      8027           mmap
  0.01    0.288820          21     13648           rt_sigprocmask
  0.00    0.191670          58      3262           madvise
  0.00    0.175075          18      9235           mprotect
  0.00    0.130137          19      6710           sched_getaffinity
  0.00    0.118363          34      3399           clone
  0.00    0.113810        1896        60        29 wait4
  0.00    0.090536          26      3388           set_robust_list
  0.00    0.063638          18      3351           gettid
  0.00    0.063112          18      3383        15 prctl
  0.00    0.059951          19      3002           fdatasync
  0.00    0.032795         140       234           pwrite64
  0.00    0.018222          80       226        23 sendto
  0.00    0.018069          52       341           poll
  0.00    0.016475         120       137           brk
  0.00    0.012375          58       211        15 ioctl
  0.00    0.006990          31       224           socket
  0.00    0.006426          18       351           rt_sigreturn
  0.00    0.005439          26       205        29 connect
  0.00    0.002399          14       167           recvfrom
  0.00    0.001981         495         4           fallocate
  0.00    0.000989           2       380           rt_sigaction
  0.00    0.000920         460         2           vfork
  0.00    0.000918          10        85           dup2
  0.00    0.000901          14        62           munmap
  0.00    0.000790          16        49           uname
  0.00    0.000760           6       121        50 access
...
------ ----------- ----------- --------- --------- ----------------
100.00 5743.529995               1691167    212785 total
```

## Repeated batch size 1

```
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 96.70 7122.754013        6463   1101987    134644 futex
  2.00  147.296036        4490     32804           epoll_wait
  0.36   26.493150          50    520511           read
  0.26   19.331825         353     54663           writev
  0.10    7.037914          44    156682     95742 stat
  0.09    6.943003          53    130102           write
  0.07    5.509723          45    120879           rt_sigprocmask
  0.05    3.541023          57     61696           mmap
  0.05    3.361509          55     60342           sched_getaffinity
  0.04    3.284372          53     61122     30031 lstat
  0.03    2.537630          84     30082           madvise
  0.03    2.462962          40     60487         2 fcntl
  0.02    1.669205          55     30215           clone
  0.02    1.646458          47     34955           mprotect
  0.02    1.628511          54     30019         1 rename
  0.02    1.627651          52     30904       149 openat
  0.02    1.449768          47     30204           set_robust_list
  0.02    1.442078          46     31188           close
  0.02    1.418491          46     30199        15 prctl
  0.02    1.221666          40     30167           gettid
  0.01    1.090908          22     48009           lseek
  0.01    1.001395          32     31148           fstat
  0.01    0.710429          40     17333           fdatasync
  0.00    0.137381        2289        60        29 wait4
  0.00    0.037294         237       157           poll
  0.00    0.013822          59       234           pwrite64
  0.00    0.010959          89       122        18 sendto
  0.00    0.009565          24       393           rt_sigreturn
  0.00    0.006039          50       119           socket
  0.00    0.004235          40       104        22 connect
  0.00    0.003102          40        77           recvfrom
  0.00    0.002886          23       121        15 ioctl
  0.00    0.002553          17       147           brk
  0.00    0.001234         308         4           fallocate
  0.00    0.001213         606         2           vfork
  0.00    0.001007          22        45        18 statfs
  0.00    0.000931           2       380           rt_sigaction
  0.00    0.000879          15        58           munmap
  0.00    0.000805           6       121        50 access
 ...
------ ----------- ----------- --------- --------- ----------------
100.00 7365.703297               2738788    260830 total
```


## Observations

`write` call is used to 
 
  * write chunk data
  * write ratis log
  * write log4j logs

`fdatasync` is called only for flush the Ratis logs. Not called for state-machine-data.

Huge number of linux sub-processes are created during the test (huge number of java threads?). Strage is started with `-f` (to attach to all the child processes) and we have a lot of attachments.
