---
title: OM isolated tests
date: 2020-05-13
---

 * docker image: elek/ozone-dev:be8a2fcc8
  
## Tests

### Master / real hard disk 

```shell
2020-05-13 09:25:22 INFO  metrics:107 - type=TIMER, name=key-create, count=100000, min=99.738493, max=191.694249, mean=114.07656516845911, stddev=6.4852681842374595, median=116.563162, p75=116.767639, p95=117.051115, p98=117.197165, p99=133.151007, p999=191.694249, mean_rate=93.26821496222848, m1=87.78774649502344, m5=90.84493425379769, m15=90.96491171281808, rate_unit=events/second, duration_unit=milliseconds
2020-05-13 09:25:22 INFO  BaseFreonGenerator:75 - Total execution time (sec): 1073
2020-05-13 09:25:22 INFO  BaseFreonGenerator:75 - Failures: 0
2020-05-13 09:25:22 INFO  BaseFreonGenerator:75 - Successful executions: 100000
```

* Metrics*:

 * `ozone_manager_double_buffer_metrics_total_num_of_flush_operations`: 1681424581
 * `ozone_manager_double_buffer_metrics_max_number_of_transactions_flushed_in_one_iteration`: 10
 * `ozone_manager_double_buffer_metrics_avg_flush_transactions_in_one_iteration`: 3

### Master / memdisk 

```shell
2020-05-13 10:59:45 INFO  ProgressBar:163 - Progress: 100.00 % (100000 out of 100000)
2020-05-13 10:59:45 INFO  metrics:107 - type=TIMER, name=key-create, count=100000, min=0.409601, max=8.059166, mean=1.1537104826333886, stddev=0.5373965194906646, median=1.079674, p75=1.259194, p95=1.765195, p98=2.042014, p99=2.839105, p999=7.886175, mean_rate=7625.529778924966, m1=6199.342936453909, m5=6003.607093506489, m15=5969.696909056889, rate_unit=events/second, duration_unit=milliseconds
2020-05-13 10:59:45 INFO  BaseFreonGenerator:75 - Total execution time (sec): 14
2020-05-13 10:59:45 INFO  BaseFreonGenerator:75 - Failures: 0
2020-05-13 10:59:45 INFO  BaseFreonGenerator:75 - Successful executions: 100000
```


### Master / memdisk / HA enabled


Using configuration:

```
OZONE-SITE.XML_ozone.om.ratis.enabled: "true"
```


```shell
2020-05-13 11:07:56 INFO  metrics:107 - type=TIMER, name=key-create, count=100000, min=0.401899, max=20.96909, mean=1.1709102282937172, stddev=0.8278094993323316, median=1.051309, p75=1.305925, p95=1.708282, p98=2.378382, p99=3.634954, p999=9.109112, mean_rate=7645.554541694369, m1=6233.499960673744, m5=6033.5145061004405, m15=5998.868099240561, rate_unit=events/second, duration_unit=milliseconds
2020-05-13 11:07:56 INFO  BaseFreonGenerator:75 - Total execution time (sec): 14
2020-05-13 11:07:56 INFO  BaseFreonGenerator:75 - Failures: 0
2020-05-13 11:07:56 INFO  BaseFreonGenerator:75 - Successful executions: 100000
```

**Note**: Couldn't see ANY

