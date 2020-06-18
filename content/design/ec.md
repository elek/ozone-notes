# Erasure coding for Ozone

Abstract: Modern storage systems should differentiate between hot and cold data. Cold data can be different availability and durability requirements which can make it possible the use less pace to store it.


## Requirements for erasure coding

The implement an earasure coding we need to have an implementation for the following functions.

   1. Given a piece of data (chunk / block / container) we should have a way to locate and read.
   2. Given a specific piece of data (chunk / block / container) we should identify the associated data which (other EC parts and parities) to recover the data
   3. We need a background process which recovers the data in case of data loss. 
   
   ### Container based Erasure coding 