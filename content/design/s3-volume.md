---
tags: ozone, designdoc
author: Marton Elek
date: 2020-02-28
title: S3 Access key management for improved usability
---

NOTE: latest version can be found in the [Apache repository](https://github.com/apache/hadoop-ozone/blob/master/hadoop-hdds/docs/content/design/ozone-volume-management.md)

## Problem statement

Ozone has the semantics of volume *and* buckets while S3 has only buckets. To make it possible to use the same bucket both from Hadoop world and via S3 we need a mapping between then.

Currently we maintain a map between the S3 buckets and Ozone volumes + buckets in `OmMetadataManagerImpl`

```
s3_bucket --> ozone_volume/ozone_bucket
```
 
The current implementation uses the `"s3" + s3UserName` string as the volume name and the `s3BucketName` as the bucket name. Where `s3UserName` is is the `DigestUtils.md5Hex(kerberosUsername.toLowerCase())`

To create an S3 bucket and use it from o3fs, you should:

1. Get your personal secret based on your kerberos keytab

```
> kinit -kt /etc/security/keytabs/testuser.keytab testuser/scm
> ozone s3 getsecret
awsAccessKey=testuser/scm@EXAMPLE.COM
awsSecret=7a6d81dbae019085585513757b1e5332289bdbffa849126bcb7c20f2d9852092
```

2. Create the bucket with S3 cli

```
> export AWS_ACCESS_KEY_ID=testuser/scm@EXAMPLE.COM
> export AWS_SECRET_ACCESS_KEY=7a6d81dbae019085585513757b1e5332289bdbffa849126bcb7c20f2d9852092
> aws s3api --endpoint http://localhost:9878 create-bucket --bucket=bucket1
```

3. And identify the ozone path

```
> ozone s3 path bucket1
Volume name for S3Bucket is : s3c89e813c80ffcea9543004d57b2a1239
Ozone FileSystem Uri is : o3fs://bucket1.s3c89e813c80ffcea9543004d57b2a1239
```

## The problems

 1. This mapping is very confusing. Based on external feedback it's hard to understand what is the exact Ozone URL which should be used
 2. It's almost impossible to remember to the volume name
 3. We don't support the revocatin of access keys
 
## Possible solutions

### 1. Predefined volume mapping

 1. Let's support multiple `ACCESS_KEY_ID` for the same user.
 2. For each `ACCESS_KEY_ID` a volume name MUST be defined.
 3. Instead of using a specific mapping table, the `ACCESS_KEY_ID` would provide a **view** of the buckets in the specified volume.
 
With this approach the used volume will be more visible and -- hopefully -- understandable.

Instead of using `ozone s3 getsecret`, following commands would be used:

 1. `ozone s3 secret create --volume=myvolume`: To create a secret and use myvolume for all of these buckets
 2. `ozone s3 secret list`: To list all of the existing S3 secrets (available for the current user)
 3. `ozone s3 secret delete <ACCESS_KEY_ID`: To delete any secret

The `AWS_ACCESS_KEY_ID` should be a random identifier instead of using a kerberos principal.

 * __pro__: Easier to understand
 * __con__: We should either have global unique bucket names or it will be possible to see two different buckets with

### 2. Using one volume

Let's always use `s3` volume for all the s3 buckets (or any other predefined version.)

 * __pro__: Dead simple
 * __con__: Volume is removed from the s3 bucket part (and in this case, why do you need volume at all?).

### 3. String magic

We can try to make volume name visible for the S3 world to use some structured bucket names. Unforunatelly the available separated charates are very limited:

For example we can't use `/`

```
aws s3api create-bucket --bucket=vol1/bucket1

Parameter validation failed:
Invalid bucket name "vol1/bucket1": Bucket name must match the regex "^[a-zA-Z0-9.\-_]{1,255}$" or be an ARN matching the regex "^arn:(aws).*:s3:[a-z\-0-9]+:[0-9]{12}:accesspoint[/:][a-zA-Z0-9\-]{1,63}$"
```

But it's possible to use `volume-bucket` notion:

```
aws s3api create-bucket --bucket=vol1-bucket1
```
 * __pro__: Volume mapping is visible all the time.
 * __con__: Harder to use any external tool with defaults (all the buckets should have at least one `-`)

### 4. Remove volume **from the ozone path**

We can also make `volume`-s as a lightweight *bucket group* object with removing it from the ozonefs path. With this approach we can use all the benefits of the volumes as an administration object but it would be removed from the `o3fs` path.

 * __pro__: can be the most simple solution. Easy to understand as there are no more volumes in the path.
 * __con__: Bigger change (all the API can't be modified to make volumes optional)
 * __pro__: Harder to dis-join namespaces based on volumes. (With the current scheme, it's easier to delegate the responsibilties for one volumes to a different OM)