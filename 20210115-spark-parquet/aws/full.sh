./run_parquet.sh generate --iteration 200 o3fs://bucket1.vol1/testdata
pause
./run_parquet.sh generate --iteration 200 hdfs://hdfs-namenode-0.hdfs-namenode:9820/testdata
pause
./run_parquet.sh copy o3fs://bucket1.vol1/testdata o3fs://bucket1.vol1/r1
pause
./run_parquet.sh copy hdfs://hdfs-namenode-0.hdfs-namenode:9820/testdata hdfs://hdfs-namenode-0.hdfs-namenode:9820/r1
