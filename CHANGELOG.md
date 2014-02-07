### version 0.1.3

This version has improved a couple of features.

- Behaviors of has_one/has_many are consitent to ActiveRecord.
- The has_one/has_many associations are supported by both REST and Peer.
- REST supports reify method to create a object from dbid
- The Datomic version file format is simplified.
- Users can specify datomic version.
- The default Datomic version has been updated to 0.9.4532

Internally, massive refactoring has been done for Peer transaction/query
data generation.
From this version, transaction data (both schema and instance data) are
expressed by arrays and hashes with edn notation.
Thus, both REST and Peer use the same notation.
As for Peer, the data is directly converted to Clojure's arrays and
hashes, then given to transact function.
No stringify is involved in this process.
Queries of Peer also use the same style as REST, arrays with edn notation.
Like transaction data, the query is directly converted to Clojure's
arrays, then, given to q function.

Other change is an exception handling improvement on Peer.
Especially, the exeptions raised from Datomic API often blew up irb or pry session.
From this version, all code blocks that may raise exceptions are wrapped
in Ruby.


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
