---
title: Storage class support in Ozone
date: 2020-05-11
---

## Abstract

One of the fundamental abstraction of Ozone is the _Container_ which used as the unit of the replication.

Containers have to favors: _Open_ and _Closed_ containers: Open containers are replicated by Ratis and writable, Closed containers are replicated with data copy and read only.

In this document a new level of abstraction is proposed: the *storage class* which defines which type of containers should be used and what type of transitions are supported.

## Containers in more details

Container is the unit of replication of Ozone. One Container can store multiple blocks (default container size is 5GB) and they are replicated together. Datanodes report only the replication state of the Containers back to the Storage Container Manager (SCM) which makes it possible to scale up to billions of objects.

The identifier of a block (BlockId) containers ContainerId and LocalId (ID inside the container). ContainerId can be used to find the right Datanode which stores the data. LocalId can be used to find the data inside one container.

Container type defines the following:

 * How to write to the containers?
 * How to read from the containers?
 * How to recover / replicate data in case of error
 * How to store the data on the Datanode (related to the *how to write* question?)

The definition of *Ratis/THREE*:

 * **How to write**: Call standard Datanode RPC API on *Leader*. Leader will replicate the data to the followers
 * **How to read**: Read the data from the Leader (stale read can be possible long-term)
 * **How to replicate / recover** 
    * Transient failures can be handled by new leader election
    * Permanent degradation couldn't be handled. (Transition to Closed containers is required) 

The definitions of *Closed/THREE*:

  * **How to write**: Closed containers are not writeable
  * **How to read**: Read the data from any nodes (Simple RPC call to the DN)
  * **How to replicate / recover**
    * Datanodes provides a GRPC endpoint to publish containers as compressed package
    * Replication Manager (SCM) can send commands to DN to replicate data FROM other Datanode
    * Datanode downloads the compressed package and import it
 
The definitions of *Closed/ONE*:
  * **How to write**: Closed containers are not writeable
  * **How to read**: Read the data from any nodes (Simple RPC call to the DN)
  * **How to replicate / recover**: No recovery, sorry.
 
## Storage-class

Let's define the *storage-class* as set of used container **types and transitions** between them during the life cycle of the containers.

The type of the Container can be defined with the implementation type (eg. Ratis, EC, Closed) and with additional parameters related to type (eg. replication type of Ratis, or EC algorithm for EC containers).

Today Ozone supports two storage classes.

The definition STANDARD Storage class:

 * *First container type/parameters*: Ratis/THREE replicated containers
 * *Transitions*: In case of any error or if the container is full, convert to closed containers 
 * *Second container type/parameters*: Closed/THREE container


The definition REDUCED Storage class:

 * *First container type/parameters*: Ratis/ONE replicated containers
 * *Transitions*: In case the container is full, convert to closed containers 
 * *Second container type/parameters*: Closed/ONE container

But we can define other storage classes as well. For example we can define (Ratis/THREE --> Closed/FIVE) storage class, or more specific containers can be used for Erasure Coding or Random Read/Write.

With this approach the storage-class can be an adjustable abstraction to define the rules of replications. Some key properties of this approach:

 * **Storage-class can be defined by configuration**: Storage class is nothing more just the definition of rules to store / replicate containers. They can be configured in config files and changed any time. 
 * **Object creation requires storage class**: Right now we should defined *replication factor* and *replication type* during the key creation. They can be replaced with setting only the Storage class.
 * **Storage-class is property of the containers**: As the unit of replication in Ozone is container, one specific storage-class should be adjusted for each containers.
 * **Changing storage class of a key** means copying it to an other container
 * **Changing definition of storage class** will modify the behavior of the Replication Manager, and -- eventually -- the containers will be replaced in a different way. 

*Note*: we already support storage class for S3 objects the only difference is that it would become an Ozone level abstraction and it would defined *all* the container types and transitions. 

## Possible use-cases

First of all, we can configure different replication levels easily with this approach (eg. Ratis/THREE --> Closed/TWO). Ratis need quorum but we can have different replication number after closing containers.

We can also define topology related transitions (eg. after closing, one replica should be copied to different rack) or storage specific constrains (Right now we have only one implementation of the storage: `KeyValueContainer` but we can implement more and storage class provides an easy abstraction to configure the required storage).

Datanode also can provide different disk type for containers in a certain storage class (eg. SSD for fast access).

# Additional use cases

In addition to the possible, replication related additional options there are two very specific use cases where we can use storage classes. Both requires more design discussion but here I quickly summarize some possible directions with the help of the storage class abstraction.

## Erasure coding

To store cold data on less bits (less than the data * 3 replicas) we can encode the data and store some additional bits to survive replica loss. In a streaming situation (streaming write) it can be tricky as we need enough chunks to do the Reed-Solomon magic. With containers we are in a better position. After the first transition of the Open containers we can do EC encoding and that time we have enough data to encode.

There are multiple options to do EC, one most simplest way is to encode Containers after the first transition:

Storage class COLD:

 * *First container type/parameters*: Ratis/THREE replicated containers
 * *Transitions*: In case of any error or if the container is full, convert to closed containers 
 * *Second container type/parameters*: EC RS(6,2)

With this storage class the containers can be converted to a specific EC container together with other containers (For example instead of 3 x C1, 3 x C2 and 3 x C3 containers can be converted to C1, C2, C3 + Parity 1 + Parity2).

## Random-read write

NFS / Fuse file system might require to support Random read/write which can be tricky as the closed containers are immutable. In case of changing any one byte in a block, the whole block should be re-created with the new data. It can have a lot of overhead especially in case of many small writes.

But write is cheap with Ratis/THREE containers. Similar to any `ChunkWrite` and `PutBlock` we can implementa `UpdateChunk` call which modifies the current content of the chunk AND replicates the change with the help of Ratis.

Let's imagine that we solved the resiliency of Ratis pipelines: In case of any Ratis error we can ask other Datanode to join to the Ratis ring *instead of* closing it. I know that it can be hard to implement, but if it is solved, we have an easy solution for random read/write.

If it works, we can define the following storage-class:

 * **Initial container** type/parameters: Ratis/THREE
 * **Transitions**: NO. They will remain "Open" forever
 * **Second container type**: NONE

This would help the random read/write problem, with some limitations: only a few containers should be managed in this storage-class. It's not suitable for really Big data, but can be a very powerful addition to provide NFS/Fuse backend for containers / git db / SQL db.

## References

 * Storage class in S3: https://aws.amazon.com/s3/storage-classes/