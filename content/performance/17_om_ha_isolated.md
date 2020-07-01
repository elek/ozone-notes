



## Hardware (y124)

Three phisical machine, spinning disks

```
VENDOR
	Manufacturer: Cisco Systems Inc
	Product Name: UCSC-C220-M4L
MEMORY
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
	Size: 32 GB
CPUs
	Version: Intel(R) Xeon(R) CPU E5-2630 v3 @ 2.40GHz
	Max Speed: 4000 MHz
	Core Enabled: 8
	Thread Count: 16
	Version: Intel(R) Xeon(R) CPU E5-2630 v3 @ 2.40GHz
	Max Speed: 4000 MHz
	Core Enabled: 8
	Thread Count: 16
DISKS
     NAME                 SIZE TYPE FSTYPE      MOUNTPOINT       VENDOR   MODEL
     sda                  5.5T disk                              HGST     HUS726060AL4210
     ├─sda1               200M part vfat        /boot/efi
     ├─sda2               500M part xfs         /boot
     └─sda3               5.5T part LVM2_member
       ├─vg01-root         50G lvm  ext4        /
       ├─vg01-swap          4G lvm  swap
       └─vg01-home        5.4T lvm  xfs         /home
     sdb                  5.5T disk                              HGST     HUS726060AL4210
     └─sdb1               5.5T part LVM2_member
       └─vg02-docker       10T lvm  ext4        /var/lib/docker
     sdc                  5.5T disk                              HGST     HUS726060AL4210
     └─sdc1               5.5T part LVM2_member
       ├─vg02-docker       10T lvm  ext4        /var/lib/docker
       └─vg02-kubernetes  1.4T lvm  ext4        /var/lib/kubelet
     sdd                  5.5T disk                              HGST     HUS726060AL4210
     └─sdd1               5.5T part LVM2_member
       ├─vg02-data          5T lvm  ext4        /data
       └─vg02-kubernetes  1.4T lvm  ext4        /var/lib/kubelet
```

## Test method

 * Scheduled three OM to three different machines with Kubernetes
 * SCM is mocked with byteman
 * Freon is started from the same machine (one instance, 10 threads)
 * Used docker image: elek/ozone-dev:8c4500b06 (master + HDDS-3878)
```
ozone freom omkg --om-service-id=omservice -n 100000
```

## Tests

### First run

* Default setup
* real HDD
* 1 freon instance (10 threads)

**~ 252 tps/sec (alloc + commit)**

### Second run

* Default setup
* real HDD
* 1 freon instance (10 threads)
* **adjusted log segment size**

```
OZONE-SITE.XML_ozone.om.ratis.segment.preallocated.size: 16MB
OZONE-SITE.XML_ozone.om.ratis.segment.size: 16MB
```

1 freon instance (10 threads)

**~ 390 tps/sec (alloc + commit)**

### Third run

* Default setup
* real HDD
* 1 freon instance (10 threads)
* **adjusted log segment size**
* **adjusted handler number**
  
```
OZONE-SITE.XML_ozone.om.ratis.segment.preallocated.size: 16MB
OZONE-SITE.XML_ozone.om.ratis.segment.size: 16MB
OZONE-SITE.XML_ozone.om.handler.count.key: "250"
OZONE-SITE.XML_ozone.scm.handler.count.key: "250"

```
**~ 390 tps/sec (alloc + commit)**

### Forth run

* Default setup
* real HDD
* 1 freon instance (10 threads)
* **adjusted log segment size**
* **adjusted handler number**
* **30 freon containers / JVM** (running on the same 3 physical machines)
    
```
OZONE-SITE.XML_ozone.om.ratis.segment.preallocated.size: 16MB
OZONE-SITE.XML_ozone.om.ratis.segment.size: 16MB
OZONE-SITE.XML_ozone.om.handler.count.key: "250"
OZONE-SITE.XML_ozone.scm.handler.count.key: "250"

```
**~ 2500 tps/sec (alloc + commit)**

### Fifth run

* Default setup
* real HDD
* 1 freon instance (10 threads)
* **with adjusted log segment size**
* **adjusted handler number**
* **30 freon containers / JVM** (running on the same 3 physical machines)
    
```
OZONE-SITE.XML_ozone.om.handler.count.key: "250"
OZONE-SITE.XML_ozone.scm.handler.count.key: "250"

```
**~ 390 tps/sec (alloc + commit)**
