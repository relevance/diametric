### version 0.1.2

The main purpose of this release is to avoid OutOfMemoryError on a peer
connection when:
- Entity has huge number of attributes
- huge number of Entities will be returned in a single query

A big change is a query result from the peer connection. Up to this
version, a query resut was converted to Ruby array. However, when
dealing with big data, such conversion causes peformance
degredation and OutOfMemoryError. From this version, on the peer
connection without resolve option, query result is a Set of
Arrays, which is exactly the same as a Datomic query result.

Other changes:
- method name change: from_dbid_or_entity of Entity is now reify
- Entity instance no longer retains transaction data
