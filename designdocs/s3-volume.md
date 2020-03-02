---
tags: ozone, designdoc
author: Marton Elek
---

# S3 Access key management for improved usability

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
 3. We don't support the revokatin of access keys
 5. There is no way to access the same bucket with multiple users (s3 buckets are always separated to separated volumes)

## Proposed solution

 1. Let's support multiple `ACCESS_KEY_ID` for the same user.
 2. For each `ACCESS_KEY_ID` a volume name MUST be defined during the generation of the key. (Or we can use a default volume name `S3`)
 3. Default mapping will `s3BucketName` -> `definedVolume/s3BucketName` (without the `s3` prefix and md5hex obfuscation).

With this approach the used volume will be more visible and -- hopefully -- understandable.

Instead of using `ozone s3 getsecret`, following commands would be used:

 1. `ozone s3 secret create --volume=myvolume`: To create a secret and use myvolume for all of these buckets
 2. `ozone s3 secret list`: To list all of the existing S3 secrets (available for the current user)
 3. `ozone s3 secret delete <ACCESS_KEY_ID`: To delete any secret

The `AWS_ACCESS_KEY_ID` should be a random identifier instead of using a kerberos principal.

Implementation-wise it's a small change, we already have the table for the mapping in-place. We need to extend the current OM admin RPC protocol and the CLI. 

## Alternative solutions

 1. The problem can be solved with removing the support of volumes from the Ozone. This would be a very huge step, and there are very strong opinions to keep it to make it easier the administration of buckets.
 2. We can also weaken the volumes and use them as a special *bucket groups*. In this case each of the buckets would be assigned to a bucket group (aka. volume), but the volume wouldn't be part of the hierarchy. (ozonefs would contain just the same bucket as the s3). With the approach the volume wouldn't be a hierarchical element any more. But this is a bigger chance and conflicted witht the current effort to make the ozonefs url `o3fs://om/volume/bucket/....` format. 

These alternative solutions either don't have the consensus or require significant more changes than this proposals. Therefore I suggest to improve only the mapping between the ACCESS_KEY_ID -> volume, which can improve the usability without any bigger changes.