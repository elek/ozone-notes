# Ozone performance test index

## 1: Ratis follower throughput

Testing the follower with sync, serial appendEntries request.

Increasing the batching size shows Huge improvements.

[Details](https://hackmd.io/-eBCcZ-DSPurmamqRlFczw)

## 2: Key generation vs batching

End-to-End test (key generation) with differebt batch sizing.

Strange results: slower with higher batch size: **Couldn't been reproduced**

[Details](https://hackmd.io/2pNWgHWOTY64oLVIBoOi1g)

## 3: Chunk writer with batching

Got the expected result: increasing the batch size helped to gain +30%

[Details](https://hackmd.io/oa8-AqEvSkqWAQb-lFqIAQ)


## 4: Leader stress test without real followers

Initial numbers on local machine. Seems to be slower than the followers.

[Details](https://hackmd.io/Iz3wTw7sRxqIYl5NYocQiA)

## 5: Follower stress test on physical nodes

Got the expected results, high number of messages can be handled with small chunk size.

Open question: OutOfMemory exception in case of bigger chunks.

[Details](https://hackmd.io/ORZAb2-WRcq0K2Gd-wTAiw)

Until this point the GRPC client in the tests used a separated channel (without closing the previous one) for each of the messages which is not handled very well.

## 6: Repeating the previous test with fixed GRPC

Works well with big chunks (1MB, 4MB, 10MB) but there are some unknown points (slower with batching and slower with bigger chunks...)

[https://hackmd.io/UYi24kYMS2KF4swX_NQu6w](https://hackmd.io/UYi24kYMS2KF4swX_NQu6w)
