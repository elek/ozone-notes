#!/usr/bin/env bash

set -ex

: ${SPARK_HOME:=/opt/spark}
: ${SAMPLES_DIR:=/opt}
: ${BTM_SCRIPT:=watchforcommit.btm}


#--conf "spark.driver.extraJavaOptions=-agentpath:/opt/java-async-profiler/build/libasyncProfiler.so=start,file=/tmp/profile-%t-%p.svg" \
#--conf "spark.driver.extraJavaOptions=-javaagent:/opt/byteman/lib/byteman.jar=script:/opt/btm/$BTM_SCRIPT" \
time $SPARK_HOME/bin/spark-submit \
    --conf spark.executor.memory=4g \
    --jars /opt/ozonefs/hadoop-ozone-filesystem.jar \
    $SAMPLES_DIR/spark-samples-1.0-SNAPSHOT.jar \
    $@
#sleep infinity
