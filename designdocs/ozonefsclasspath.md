# Ozone Client with and Ozone FileSystem support with older Hadop versions (2.x / 3.1)

Apache Hadoop Ozone is a Hadoop subproject. It depends on the released Hadoop 3.2. But as Hadoop 3.2 is very rare in production, older versions should be supported to make it possible to work together with Spark, Hive, HBase and older clusters.

## The problem

We have two separated worlds: the client and the server side. The server can have any kind of dependencies as the classloaders of the server are usually separated from the client (different JVM, service, etc.). But the Ozone Client might be used from an environment where a specific Hadoop instance is already available:

![](https://i.imgur.com/Uize9qu.png)

This is the happy scenario where we have the same Hadoop version both on server and client side. 

The problem starts when the Ozone File system is used from an environment where the Hadoop version is different.

Let's look at the used classes and dependencies between classes __on the client__ side:

![](https://i.imgur.com/5v1QNvL.png)

Hadoop classes are marked with Orange, Ozone classes are white. 

The problem here clearly visible: to the `Configuration` we have multiple dependency path. With using the Same Hadoop everywhere, it's not a problem, but using different Hadoop version makes it difficult:

![](https://i.imgur.com/tUDsCYZ.png)

Here the red and orange classes represent different Hadoop versions. Which version should be used from `Configuration` (or any other shared Hadoop classes)? If we use it from the older version, the Ozone part can't work (as it depends on newer features). If we use a newer version it generates conflicts (as the classes are not always backward compatible).

### Shading?

Shading is the packaging of multiple jar files to one jar with moving all the classes files to one jar file. During the move it's also possible to modify the bytecode and rename some of the packages (relocation). Usually this relocation is called *shading*.

Unfortunately it's not working in our case.

![](https://i.imgur.com/s11XprK.png)

If we don't shade `Configuration`, the `OzoneConfiguration` class can't use new 3.2 features from it.

If we shade (package relocate) the `Configuration`, the `OzoneFileSystem` will not implement the `FileSystem` interface any more as the `FileSystem` class requires a method `public void initialize(URI name, Configuration conf)` but our specific `OzoneFileSystem` will provide a `initialize(URI name, org.apache.hadoop.ozone.shaded.Configuration conf)` which is clearly not the same. `OzoneFileSystem` won't be a `FileSystem` any more.
 
## Classloader isolation

To solve this problem Ozone started to use a specific classloader. With using multiple classloaders, you might have different versions from the same classes (It means different class definitions not different instances). The only question is the definition of the boundaries between the two classloaders:

![](https://i.imgur.com/6g0mOtI.png)

With two different classloaders we can have two `Configuration` classes without any problem. The only dangerous area here is the usage of the two type of `Configuration` classes at the same place.

For example if the `OzoneClient` returns a `Configuration (loaded by isoloated)` or `Path (loaded by isolated)` it generates very strange errors as the `Configuration (loaded by isolated)` won't be instance of `Configuration (loaded by app classloader)`.

Therefore we should follow the following rules:

 1. Use only a very limited set of classes in the method signatures of `OzoneClient`.
 2. If some classes are added to the method signatures of the adapter (as parameter or return value) we should have one and only one type from that one.



### OzoneClientAdapter

To achieve the first rule, instead of refactoring the `OzoneClient` we introduced a new *interface* only the minimal set of the required functions:
(called `OzoneClientAdapter`):

```
public interface OzoneClientAdapter {

  InputStream readFile(String key) throws IOException;

  OzoneFSOutputStream createFile(String key, boolean overWrite,
      boolean recursive) throws IOException;

  void renameKey(String key, String newKeyName) throws IOException;

  boolean createDirectory(String keyName) throws IOException;

  boolean deleteObject(String keyName);

  Iterator<BasicKeyInfo> listKeys(String pathKey);

  ....
  
```

Usage of this adapter helps us to minimize the used classes which cross the boundaries.

![](https://i.imgur.com/U9fbD2k.png)

Here the `OzoneFileSystem(#app cl)` uses a reference to an interface (`OzoneClientAdapter(#app cl)`) implementation. We don't need to know anything about the implementation as we use only it via the interface, but under the hood the implementation is created by the specific ("isolated") classloader.

Obviously, if something is used in the `OzoneClientAdapter` we should load it by the *app* classloader (and we need to have just one instance from all the used classes).

---
**NOTE**
Classloader isolation works by ensuring that all dependent classes of the `ClientAdapter` are transitively loaded using the isolated classloader. This is because the ClientAdapter was loaded using the custom classloader.

---

### Classloaders in Java

As we saw earlier we need a separated classloader:

 1. Which can load specific classes (like `Configuration`) independent from the *app* classloader.
 2. And should use some classes (like `Path` or `BasicKeyInfo` which are used in the methods of `OzoneClientAdapter` interface) from the *app* classloader.

In Java it's fairly easy to use a specific classloader as the `java.net.URLClassloader` very generic and usable. But in Java if a class is loaded by the parent classloader, it won't be loaded by the child classloader.

For example, if you create a new `ClassLoader isolated = new URLClassLoader(appCl)`, it will **always** use a class loaded by the parent (`appCl`) classloader, **if** the specific class is available from there. If you creates a classloader with a parent and the parent already loaded a class (like `Configuration`) it will use the shared, alread-loaded instance from the class definition.

But as we described earlier we need something different: some of the classes can be shared, some of the classes should be isolated:

![](https://i.imgur.com/lI8LYeM.png)

Here the Hadoop 3.2 classes are isolated but some of the key classes (`OzoneClientAdater` or the `org.apache.hadoop.fs.Path` ) should be loaded only once, therefore can be used from both world.

To achieve this (some classes are shared, but not all of them) we started to use a specific classloader `FilteredClassLoader` which loads everything from the specific location **first** and only after from the parent. Except  some of the well-defined classes, which are used directly from the parent (*app* classloader).

With this approach we can support all the old Hadoop versions **except** when security is required.

### Security

Hadoop security is based on the famous `UserGroupInformation` class (aka. `UGI`) which contains a field with `javax.security.auth.Subject` type.

From high level `Subject` works as a thread-local `Map`. You can put everything to there in your current thread specific `AccessControlContext` and later you can get it.

Hadoop adds one `org.apache.hadoop.security.Credentials` instance to this thread-local map, which can contain tokens or other credentials.

`Subject` is a java class, it's easy to share between different classloaders (by default core Java classes are shared), but `Credentials` is not shared and has a lot of other dependencies (It depends on `Token`, which depends on the whole world...)

**With Hadoop security we need to extract the current UGI information before calling the methods of `OzoneClientAdapter`, propagate the identification information in a safe way, and inject it back to the UGI of the *isloated* classloader to use it during the RPC calls.**

---
**NOTE**

There will be two different versions of the `Credentials` and `Token` classes, and also their dependencies. One loaded by the default classloader and one by the isolated classloader. They are not seen as the same class by the Java runtime. When the Ozone client attempts to pass the Token generated using the default classloader to the RPC client, it causes strange runtime errors (***Marton***: can you add the exception message here?)

---

For example 
 1. we can serialize the current `Token` (==`TokenIdentifier`) to a byte array
 2. we can add this `[]byte` as a required parameter to all the method of `OzoneClientAdapter`
 3. And we can create a new (different type of) `Token` and `TokenIdentifier` inside the `OzoneClientAdapterImpl` (implementation, loaded by the *isolated* classloader) and inject it back to *that* UGI. 

There are three main type of authentication information which needs to be propagated in this way.

 1. **Tokens** they can be handled by the previous method (serialize, deserialize)
 2. Current Kerberos identification based on **`kinit`**. That should be easy as it's based on the reading of some session files from `/tmp/...` which is accessible by both the UGIs (*app* and *isolated*)
 3. Kerberos identification based on **keytab** (for example when the Yarn server is downloading requried resources from the defaultFs o3fs). In theory it can be handled as the `Token`s, but it's not yet proven and can be tricky (especialy with all the expiry and reissue logic.)

### Summary

With isolated classloader we can support older Hadoop versions but we introduced **signification** complexity. This complexitiy will be increased when we implement the UGI information propagation (if it's possible at all). 

## Dependency separation

Let's try to go one step back and try to achieve the same goals (support old Hadoop versions) in a different way (And thanks to Anu Engineer who forced to check this option again and again).

Let's talk about the current project hierarchy (for the sake of the simplicity only the HDDS projects will be shown, but the same hierarchy is true for Ozone projects):

![](https://i.imgur.com/tF77sJY.png)

Here the boxes represent *maven projects* and the arrows represent project *dependencies*. Dependencies are transitive therefore all the project depends on Hadoop 3.2. 

(**Note**: in fact we also depend on `hdfs-server` and `hdfs-client` but those dependencies can be removed and doesn't modify the big picture. Orange box is *the* Hadoop dependency.)

What we need is something similar to the Spark where we have multiple clients with different Hadoop versions:

![](https://i.imgur.com/BdyNEOm.png)

**But** as we have transitive dependencies, it means that the `hdds-common` projects should be 100% hadoop-free:

![](https://i.imgur.com/iZF5JZZ.png)

But it means that all of the Hadoop dependent classes should be replicated somehow (which is reasonable, as according to our original problem, they are not always backward compatible). And the clear interface between server and client will be based on `proto` files. It's the client responsibility to create the binary message on the client side (with Hadoop 2.7 or Hadoop 3.2). The Hadoop RPC is backward compatible on binary level.

This is only possible if the majority of the common classes are Hadoop independent and won't be duplicated: only a reasonable amount of code will be cloned and maintained at multiple places.

Based on the early investigation it's the case, as the majority of the hdds-common is Hadoop free and it's not impossible to fix the remaining problems:

 1. Either move the Hadoop specific classes to the `framework` project (if it's required only from the server side, like the Certifcate handling)
 2. Or we can make it Hadoop free (for example use our own `string2bytes` instead of using one from the `DfsUtils`)

### Notes and TODOs

 * As protobuf versions are changed between Hadoop versions (Hadoop 3.3 will use protobuf 3.x) we shouldn't generate the Java protobuf files in `hdds-common`. We should share only the `proto` files and generate the Java files in different ways. Which means that some of the serialization/deserialization logic might be duplicated as they should be removed from common.
 * Seems to be better to use a Hadoop independent metric framework (to make it possible to add to metrics in `hdds-common`). As of now [micrometer](http://micrometer.io/) seems to be the best choice as it supports tags on specific metrics. (Note: Hadoop metrics also can be forked but it has a huge number of dependencies).
 * Instead of using `OzoneConfiguration` everywhere we will use a `Configurable` interface which can be implemented by `OzoneConfiguration` or any other adapter which is compatible with older Hadoop versions.

## Summary

 1. The isolated classloader couldn't work in secure environments without significant additional high-level magic.
 2. It seems to be possible to support older Hadoop versions with limiting the Hadoop dependencies (but still use Hadoop RPC and UGI on the client side)
 
 The final solution might require bigger refactor: In the current phase I suggest to cleanup the current project: remove dumb dependencies, try to organize the code better. There are many small tasks which can be done (eg. remove dependency on `hdfs-client` or move server specific shared code out from the client side: move it from `common` to `framework`).
 
 If the cleanup tasks are done, we will clearly see how this second approach is possible. Worst case we will have a more clean project. 