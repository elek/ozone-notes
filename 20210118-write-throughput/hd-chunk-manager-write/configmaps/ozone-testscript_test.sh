#/usr/bin/env bash
set -x
for i in `seq 1 48`; do sudo rm -rf /data/disk$i/elek; done
for i in `seq 1 48`; do sudo mkdir /data/disk$i/elek; done
for i in `seq 1 48`; do sudo chmod 777 /data/disk$i/elek; done

time sync
START_TIME=$(date +%s.%N)
ozone freon --verbose cmdw -n250000 -s$(numfmt --from=iec 4M) -t48 -l FILE_PER_BLOCK
time sync
END_TIME=$(date +%s.%N)
echo "Total time: $(echo $END_TIME $START_TIME | awk '{print $1 - $2}')"
echo "Hostname: $(hostname)"
echo "Test is Done"
sleep 100000
