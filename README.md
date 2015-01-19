[![Build Status](https://secure.travis-ci.org/relevance/diametric.png)](http://travis-ci.org/relevance/diametric)

# Diametric

Diametric is ActiveRecord style wrapper for [Datomic](http://www.datomic.com/),
and a library for building schemas, queries, and transactions
for Datomic from Ruby objects. It is also used to map Ruby objects
as entities into a Datomic database.


Diametric supports both CRuby and JRuby.
When Diametric is used on CRuby, Diametric connects to Datomic's REST service.
Using Datomic's REST API, Diametric creates schema/data and makes a queries to Datomic.
When Diametric is used on JRuby, both Datomic's REST and Peer services are supported.
The core parts of Peer service are implemented using Datomic API.


For Rubyists who are familiar with object oriented programming, Diametric converts:
- Ruby model definition to Datomic schema
- Creating, saving and updating model data to Datomic transaction data
- Ruby query to Datomic's datalog query
- Datomic's dbid to model object (depends on the value of resolve option)


The biggest difference between REST and Peer services is available database types.
REST service can use memory database only, which means we can't save data in any file
as long as using free version.
While Peer service can use memory and free version of transactor,
which means we can save data in a file through Datomic's transactor.
Other than that, Peer service has an excellent API to use Datomic's various features.


## Installation

```bash
gem install diametric
```

Diametric is a multi-platform gem. On CRuby, the above installs the CRuby version of the gem.
On JRuby, the above installs the JRuby version of gem, with a Java extension.


[note]
When you install diametric on JRuby, you'll see a message, "Building native extensions.  This could take a while...."
Although Diametric doesn't rely on a C library, it depends on several Java libraries.
While installing gem, diametric downloads those jar archives, including dependencies on your local maven repo. 
The message shows up because of this.


## Preparation for CRuby

On CRuby, you need to start Datomic's REST server.

Diametric has a command to start REST server.
Type `datomic-rest -p port -a db_alias -u uri`, for example

```
datomic-rest -p 9000 -a free -u datomic:mem://
```

When you run the command at the very first time, it takes a while to start running.
This is because Diametric downloads datomic if it doesn't exist in Diametric's directory tree.
If it is the second time or later, the REST server starts quickly.

To learn more about the options in the above command, please go to [http://docs.datomic.com/rest.html](http://docs.datomic.com/rest.html).

Once the REST server starts running, go to [localhost:9000](localhost:9000) on your browser.
You can see Datomic's REST service is running.

Alternatively, you can download Datomic archive from [https://my.datomic.com/downloads/free](https://my.datomic.com/downloads/free),
and start REST server using the Datomic command, `script/datomic-rest -p 9000 free datomic:mem://`


## Preparation for JRuby

You have 2 choices on JRuby, Peer and REST services.
Peer service works on the same JVM as JRuby and looks like just a Java library for JRuby.


When you choose REST service, follow *Preparation for CRuby* section.


When you choose Peer service, you don't need to prepare anything. 
You even don't need to start Datomic. Diametric does everything for you.
What you need to do is just coding in Ruby using Diametric API.


Although Diametric API makes coding very easy, you still have the freedom to hit Datomic's Java API directly.


## Typical coding steps

Typical Diametric coding follows the steps below:

1. Connect to Datomic
2. Define entities
3. Create schema on Datomic from entity definitions
4. Create entities and save it on Datomic
5. Make a query to Datomic


##  Connect to the Datomic REST Service

To establish a connection to Datomic REST Service, you can do as such:

```ruby
require 'diametric'
Diametric::Persistence.establish_base_connection({:uri => 'http://localhost:9000', :storage => 'free', :database => 'sample'})
```

Optionally, you can connect using datomic-client gem:
```ruby
require 'datomic/client'

@datomic_uri = 'http://localhost:9000'
@storage = 'free'
@dbname = "sample"
@client = Datomic::Client.new @datomic_uri, @storage
@client.create_database(@dbname)
```

Each parameter should be consistent to the ones used to start the REST service.


##  Connect to the Datomic Peer service (JRuby only)

```ruby
require 'diametric'
Diametric::Persistence.establish_base_connection({:uri=>'datomic:mem://sample'})
```

Or in a peer service specific way,
```ruby
datomic_uri = "datomic:mem://sample-#{SecureRandom.uuid}"
@conn = Diametric::Persistence::Peer.connect(datomic_uri)
```

## Define an entity

While a relational databse inserts a record, Diametric saves an `Entity`.
To save data by Diametric, you need to define `Entity` first.
Defining entities loosely corresponds to defining database tables.

Below is an example of `Entity` definition for Peer service.
Be aware, you should include `Diametric::Entity` and
either one of `Diametric::Persistence::REST` or `Diametric::Persistence::Peer`in your Entity definition.


```ruby
require 'diametric'

class Person
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String, index: true
  attribute :birthday, DateTime
  attribute :awesomeness, Boolean, doc: "Is this person awesome?"
end
```

The `attribute` definition is consists of:
- attribute name (required)
- attribute type (required)
- attribute options (optional)

This is the Diametric way of converting [Datomic schema](http://docs.datomic.com/schema.html)
to a Ruby model definition.

The attribute name goes to `:db/ident` and the value will be `:<class name>/<attribute name>`.
This is interpreted as `:<namespace>/<name>` on Datomic.

Currently, Diametric supports the following data types:

| Diametric  | Datomic            |
| ---------- |:------------------:|  
| String     | `:db.type/string`  |
| Symbol     | `:db.type/keyword` |
| Boolean    | `:db.type/boolean` |
| Integer    | `:db.type/long`    |
| Float      | `:db.type/double`  |
| Double     | `:db.type/double`  |
| BigDecimal | `:db.type/bigdec`  |
| Ref        | `:db.type/ref`     |
| DateTime   | `:db.type/instant` |
| UUID       | `:db.type/uuid`    |

In addition, Diametric supports an `Enum` type.

Available options are:

| Diametric                        | Datomic                |
| -------------------------------- |:----------------------:|  
| `:cardinality => :one` (default) | `:db.cardinality/one`  |
| `:cardinality => :many`          | `:db.cardinality/many` |
| `:doc => "some document here"`   | `:db/doc`              |
| `:unique => :identity`           | `:db.unique/identity`  |
| `:unique => :value`              | `:db.unique/value`     |
| `:index => true`                 | `:db/index`            |
| `:fulltext => true`              | `:db/fulltext`         |


## Create a schema

Creating schema in Datomic is similar to a migration in Ruby on Rails.
However, schema creation can be done as a part of a program.
For Datomic, the difference between schema and entity is quite small.
Like saving entities, schemas are saved in Datomic.

Creating schema is done by calling `create_schema` method of the entity.

```ruby
Person.create_schema.get
```

`Person.create_schema` (not followed by get) also creates a schema,
but it is a sort of piling up on the queue and not performed immediately.
If `get` is not specified, schema creation is done by at some point implicitly.
Adding `get` requests Datomic to create schema *now*.
This is good to know whether the entity definition is correct or not.
If some attribute definition has a problem, error will be raised.


## Create, save and update an entity

Once the entity is defined, and schema is created on Datomic,
you can create an entity instance like you create a new object in Ruby.
Below is an example:


```ruby
person = Person.new
person.name = "Sky"
person.birthday = DateTime.parse('2005-01-01')
person.awesomeness = true

puts "dbid (before save): #{person.dbid}"

person.save

puts "dbid (after save): #{person.dbid}"
```

The above prints:

```
dbid (before save): 
dbid (after save): 17592186045418
```

The *dbid* is equivalent to *id* of ordinary ActiveModel objects. 
Before `save`, the person object doesn't have `dbid` value.
But after `save`, it will have an auto-generated value as dbid.

Alternatively, you can create an entity in one line:
```ruby
Person.new(name: "Sky", birthday: DateTime.parse('2005-01-01'), awesomeness: true).save
```

To update attribue values of the instance, use update_attributes:
```ruby
person.update_attributes(name: "Sky Jr.", awesomeness: false)
```


## Make queries

Queries are done by Diametric::Query instance. A basic usage is:


1. Create Diametric::Query instance with a required argument.
2. Call methods of Query instance. This triggers a query to Datomic.
3. Iterate the query result and do something to get data.

Diametric::Query has three arguments in constructor:
```ruby
Diametric::Query.new(entity_class, db_or_conn=nil, resolve=false)
```
The second and the third options work only on Peer service.


On REST service, the query results are an array of entity objects.
On Peer service, the result data type depends on the constructor arguments.
In default setting, the query result is a Set of Arrays.
Each array has an entity id (future Diametric version will have a couple of attributes depends on the query).
This data structure is exactly the same as what Datomic returns.
Also, to avoid the overhead that comes from converting to Ruby's Set and Arrays,
Diametric wraps in Diametric::Persistence::Set or Diametric::Persistence::Collection.
(Diametric's wrappers are not a perfect Ruby Array nor Ruby Set in this version.
Those will be improved in future versions.)

The reason Diametric doesn't create entity instances by default is to save memory.
When dealing with millions or billions of data, saving memory is key to running faster,
and, more importantly, to avoid OutOfMemoryError.
In terms of saving memory, Diametric returns minimum by default.

If you don't have a lot of data and want to get instances directly from query results,
set true to the third option, `resolve`.

When resolve option is set to true, the query result will be an Array of entity instances.
You should be careful when setting this option to true. When it is true, Diametric tries to
create instances recursively following associations.
If friends or friends of friends includes self, you'll likely to get StackOverflowError.

To resolve an entity from a dbid, use Entity's reify method.
The reify method creates an instance from the dbid.

The second option, `db_or_conn` is to specify the database state at some time in the past.
If it is not specified, Diametric uses the default database state, which means the latest state.

### find all
Query example1:
```ruby
# create test data
Person.new(name: "Sun", birthday: DateTime.parse('2005-01-01'), awesomeness: true).save
Person.new(name: "Cloud", birthday: DateTime.parse('1980-02-12'), awesomeness: false).save
Person.new(name: "Breeze", birthday: DateTime.parse('1911-03-23'), awesomeness: true).save
Person.new(name: "Sleet", birthday: DateTime.parse('2010-04-30'), awesomeness: false).save
Person.new(name: "Rain", birthday: DateTime.parse('2005-05-05'), awesomeness: true).save

# make a query
query = Diametric::Query.new(Person)
query.each do |ary|
  person = Person.reify(ary.first)
  puts "name: #{person.name}, dbid: #{person.dbid}, birthday: #{person.birthday}, awesomeness: #{person.awesomeness}"
end
```

Above prints:
```ruby
name: Rain, dbid: 17592186045429, birthday: 2005-05-04 20:00:00 -0400, awesomeness: true
name: Breeze, dbid: 17592186045425, birthday: 1911-03-22 19:00:00 -0500, awesomeness: true
name: Sleet, dbid: 17592186045427, birthday: 2010-04-29 20:00:00 -0400, awesomeness: false
name: Sun, dbid: 17592186045421, birthday: 2004-12-31 19:00:00 -0500, awesomeness: true
name: Cloud, dbid: 17592186045423, birthday: 1980-02-11 19:00:00 -0500, awesomeness: false
```

Query example2 (with resolve to true):
```ruby
query = Diametric::Query.new(Person, nil, true)
query.each do |entity|
  puts "name: #{entity.name}, dbid: #{entity.dbid}, birthday: #{entity.birthday}, awesomeness: #{entity.awesomeness}"
end
```

The example2 prints exactly the same as the example1.


### where

To narrow down the query results, you can use `where` and `filter` methods.

Query example3:
```ruby
query = Diametric::Query.new(Person, nil, true).where(awesomeness: true)
query.each do |entity|
  puts "name: #{entity.name}, dbid: #{entity.dbid}, birthday: #{entity.birthday}, awesomeness: #{entity.awesomeness}"
end
```

Above prints:
```ruby
name: Sun, dbid: 17592186045421, birthday: 2004-12-31 19:00:00 -0500, awesomeness: true
name: Rain, dbid: 17592186045429, birthday: 2005-05-04 20:00:00 -0400, awesomeness: true
name: Breeze, dbid: 17592186045425, birthday: 1911-03-22 19:00:00 -0500, awesomeness: true
```

### filter

Query example4:
```ruby
query = Diametric::Query.new(Person, nil, true).filter(:>, :birthday, DateTime.parse('2004-12-31'))
query.each do |entity|
  puts "name: #{entity.name}, dbid: #{entity.dbid}, birthday: #{entity.birthday}, awesomeness: #{entity.awesomeness}"
end
```
The results are:
```ruby
name: Sun, dbid: 17592186045418, birthday: 2004-12-31 19:00:00 -0500, awesomeness: true
name: Sleet, dbid: 17592186045424, birthday: 2010-04-29 20:00:00 -0400, awesomeness: false
name: Rain, dbid: 17592186045426, birthday: 2005-05-04 20:00:00 -0400, awesomeness: true
```

Currently, filter supports simple Clojure comparisons.
For example:
```clojure
(< attribute value)
(> attribute value)
(= attribute value)
...
```
The first argument of filter is mapped to the predicate of the clojure function.
The second argument of filter is always an attrbute name,
which will be replaced by attribute values of entities.
The third argument of the filter is the value to be compared.


### chaining

Ruby's method chaining can be used for `where` and `filter` methods.

Query example5:
```ruby
query = Diametric::Query.new(Person, nil, true).where(awesomeness: true).filter(:>, :birthday, DateTime.parse('2004-12-31'))
query.all.each do |p|
  puts "name: #{p.name}, dbid: #{p.dbid}, birthday: #{p.birthday}, awesomeness: #{p.awesomeness}"
end
```
The query finds entities whose awesomenesses are true and whose birthdays are after December 31, 2004.
As expected, it prints:
```ruby
name: Sun, dbid: 17592186045418, birthday: 2004-12-31 19:00:00 -0500, awesomeness: true
name: Rain, dbid: 17592186045426, birthday: 2005-05-04 20:00:00 -0400, awesomeness: true
```

### short cut methods

So far, the query examples use `Diametric::Query.new(...)`.
Other than that, Diametric supports concise short-cut query methods.
The examples above can be rewritten below.
In this case, the resolve option is set to true by default.

```ruby
#query = Diametric::Query.new(Person)
query = Person.all

#query = Diametric::Query.new(Person, nil, true).where(awesomeness: true)
query = Person.where(awesomeness: true)

#query = Diametric::Query.new(Person, nil, true).filter(:>, :birthday, DateTime.parse('2004-12-31'))
query = Person.filter(:>, :birthday, DateTime.parse('2004-12-31'))
```

### make query to the past (Peer only)

Datomic has the idea of time.
It allows database state to role back at some point in the past.
The example below makes the query to the current and secounds (milliseconds?) before of database.

Query example6:
```ruby
# prints current awesomeness values
Diametric::Query.new(Person, nil, true).all.collect(&:awesomeness)
 => [true, true, false, true, false]

# saves the time. this will be the past
past = Time.now
 => 2013-11-09 20:17:59 -0500

# updates awesomeness false to true
Diametric::Query.new(Person, nil, true).where(awesomeness: false).each do |person|
  person.update_attributes(awesomeness: true)
end
 => [[17592186045420], [17592186045424]]

# prints updated awesomeness values
Diametric::Query.new(Person, nil, true).all.collect(&:awesomeness)
 => [true, true, true, true, true]

# pulls out the past database
past_db = @conn.db.as_of(past)
 => #<Diametric::Persistence::Database:0x49fe0bcd>

# makes a query to past database
Diametric::Query.new(Person, past_db, true).all.collect(&:awesomeness)
 => [true, true, false, true, false]

# query results shows the database before "past"
```

### using datomic's query string (Peer only)

Currently, Diametric's query can do only a part of Datomic can do.
When you want a more complicated query or customized query, you can use
`Diametric::Persistence::Peer.q` method. For example:

```ruby
result = Diametric::Persistence::Peer.q("[:find ?name :where [?person :person/name ?name]]", @conn.db)
```

You'll get the results below:
```
[["Rain"], ["Sleet"], ["Sun"], ["Cloud"], ["Breeze"]]
```
This result data type is a Set of Arrays, which is the same as the default setting.

Below is another example with a value argument. This is what Diametric's filter query does.
```ruby
result = Diametric::Persistence::Peer.q("[:find ?birthday :in $ [?value] :where [?e :person/birthday ?birthday] [(< ?birthday ?value)]]", @conn.db, DateTime.parse('2002-01-01'))
```
The result is:
```ruby
[[#inst "1980-02-12T00:00:00.000-00:00"], [#inst "1911-03-23T00:00:00.000-00:00"]]
```

This is a Set of Arrays whose elements are Datomic's Date expression.
However, Diametric wrapper converts to Ruby object when it is used.
```ruby
result.each do |ary|
  puts ary.first.strftime("%m/%d/%Y")
end
```
returns:
```ruby
02/11/1980
03/22/1911
```


### Delete entities

To delete an entity, use the destroy method:

```ruby
query = Person.where(:name => "Sleet")
query.all.each {|p| p.destroy }
```

## Validation

ActiveModel's validations are included by default. All you need to do is start using them!

```ruby
require 'diametric'

class Person
  include Diametric::Entity
  include Diametric::Persistence

  attribute :name, String, :index => true

  validates :name, :length => {:minimum => 5}
end
Person.create_schema
```

This model validates the length of the name. If the name has less than 5 letters, the input is invalid. For example:

```ruby
jeff = Person.new(:name => "Geoffrey")
jeff.valid?
# => true

jeff.name = "Jeff"
jeff.valid?
# => false
```

Similarly to ActiveRecord, models cannot save until they are valid:

```ruby
jeff.name = "Jeff"
jeff.save
# => false

jeff.name = "Goeffrey"
jeff.save 
# => #<... transaction results object ...>
```

## Cardinality

When you want to define one-to-many attributes, you should add `:cardinality => :many` to an attribute definition.

```ruby
class Profile
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String, :index => true
  attribute :likes, String, :cardinality => :many
end
Profile.create_schema.get
```

The attribute with `:cardinality => :many` accepts either Array or Set. Usage will be:

```ruby
Profile.new(name: "Breeze", likes: ["chocolate", "biking", "afternoon"]).save
Profile.new(name: "Sun", likes: ["banana", "running", "morning"]).save
Profile.new(name: "Rain", likes: (Set.new ["pumpkin pie", "video game", "night"])).save
```

Datomic saves values in a Set object when the attribute has `:cardinality => :many` definition. For example:
```ruby
Profile.where(:name => "Breeze").each {|e| puts e.likes}
```
returns `#<Set:0x007fbb66294928>`. So, if the following gets run:

```ruby
Diametric::Query.new(Profile).each do |ary|
  profile = Profile.reify(ary.first)
  puts "#{profile.name} likes #{profile.likes.inspect}"
end
```
Above prints:
```ruby
Rain likes #<Set: {"pumpkin pie", "video game", "night"}>
Sun likes #<Set: {"morning", "banana", "running"}>
Breeze likes #<Set: {"chocolate", "afternoon", "biking"}>
```
The order is not guaranteed.

## Association

On Datomic, association is fairly easy even though it is one to many or many to many.
Association is defined by `Ref` type.
Just assigning a saved entity instance to `Ref` type attribute makes association.

The entity definition looks like below:
```ruby
class Somebody
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :mom, Ref, :cardinality => :one
  attribute :dad, Ref, :cardinality => :one
  attribute :kids, Ref, :cardinality => :many
end
```

This entity has one to one and one to many associations.
Below is an example of creating an entity instance and making queries.

```ruby
# creates mom and dad
mom = Somebody.new(name: "Snow White")
 => #<Somebody:0x3292eff7 @changed_attributes={"name"=>nil}, @name="Snow White">
mom.save
 => {:db-before datomic.db.Db@f89fe443, :db-after datomic.db.Db@efb79a88, :tx-data [#Datum{:e 13194139534333 :a 50 :v #inst "2013-11-10T03:35:06.889-00:00" :tx 13194139534333 :added true} #Datum{:e 17592186045438 :a 67 :v "Snow White" :tx 13194139534333 :added true}], :tempids {-9223350046623220305 17592186045438}}
dad = Somebody.new(name: "Prince Brave")
 => #<Somebody:0x1425e531 @changed_attributes={"name"=>nil}, @name="Prince Brave">
dad.save
 => {:db-before datomic.db.Db@efb79a88, :db-after datomic.db.Db@3bddfe3, :tx-data [#Datum{:e 13194139534335 :a 50 :v #inst "2013-11-10T03:35:09.405-00:00" :tx 13194139534335 :added true} #Datum{:e 17592186045440 :a 67 :v "Prince Brave" :tx 13194139534335 :added true}], :tempids {-9223350046623220306 17592186045440}}

# creates sombody who has mom and dad
Somebody.new(name: "Alice Wonderland", mom: mom, dad: dad).save
 => {:db-before datomic.db.Db@3bddfe3, :db-after datomic.db.Db@df977d06, :tx-data [#Datum{:e 13194139534337 :a 50 :v #inst "2013-11-10T03:35:39.562-00:00" :tx 13194139534337 :added true} #Datum{:e 17592186045442 :a 68 :v 17592186045438 :tx 13194139534337 :added true} #Datum{:e 17592186045442 :a 69 :v 17592186045440 :tx 13194139534337 :added true} #Datum{:e 17592186045442 :a 67 :v "Alice Wonderland" :tx 13194139534337 :added true}], :tempids {-9223350046623220307 17592186045442}}

# makes a query whose name is "Alice Wonderland"
me = Diametric::Query.new(Somebody, @conn, true).where(name: "Alice Wonderland").first
 => #<Somebody:0x5f369fc6 @changed_attributes={"dad"=>nil, "mom"=>nil, "name"=>nil}, @dbid=17592186045442, @name="Alice Wonderland", @dad=#<Somebody:0x75de7009 @changed_attributes={"name"=>nil}, @dbid=17592186045440, @name="Prince Brave">, @mom=#<Somebody:0x7c840fe3 @changed_attributes={"name"=>nil}, @dbid=17592186045438, @name="Snow White">>

# creates another two others who have mom as me
mario = Somebody.new(name: "Mario", mom: me)
 => #<Somebody:0x6ad3fbe4 @changed_attributes={"name"=>nil, "mom"=>nil}, @name="Mario", @mom=#<Somebody:0x5f369fc6 @changed_attributes={"dad"=>nil, "mom"=>nil, "name"=>nil}, @dbid=17592186045442, @name="Alice Wonderland", @dad=#<Somebody:0x75de7009 @changed_attributes={"name"=>nil}, @dbid=17592186045440, @name="Prince Brave">, @mom=#<Somebody:0x7c840fe3 @changed_attributes={"name"=>nil}, @dbid=17592186045438, @name="Snow White">>>
mario.save
 => {:db-before datomic.db.Db@df977d06, :db-after datomic.db.Db@79b5b85f, :tx-data [#Datum{:e 13194139534339 :a 50 :v #inst "2013-11-10T03:36:37.567-00:00" :tx 13194139534339 :added true} #Datum{:e 17592186045444 :a 68 :v 17592186045445 :tx 13194139534339 :added true} #Datum{:e 17592186045444 :a 67 :v "Mario" :tx 13194139534339 :added true} #Datum{:e 17592186045445 :a 68 :v 17592186045447 :tx 13194139534339 :added true} #Datum{:e 17592186045445 :a 69 :v 17592186045446 :tx 13194139534339 :added true} #Datum{:e 17592186045445 :a 67 :v "Alice Wonderland" :tx 13194139534339 :added true} #Datum{:e 17592186045446 :a 67 :v "Prince Brave" :tx 13194139534339 :added true} #Datum{:e 17592186045447 :a 67 :v "Snow White" :tx 13194139534339 :added true}], :tempids {-9223350046623220311 17592186045447, -9223350046623220310 17592186045446, -9223350046623220309 17592186045445, -9223350046623220308 17592186045444}}
luigi = Somebody.new(name: "Luigi", mom: me)
 => #<Somebody:0x4ebed2b3 @changed_attributes={"name"=>nil, "mom"=>nil}, @name="Luigi", @mom=#<Somebody:0x5f369fc6 @temp_ref=-1013, @changed_attributes={}, @dbid=17592186045445, @name="Alice Wonderland", @dad=#<Somebody:0x75de7009 @temp_ref=-1014, @changed_attributes={}, @dbid=17592186045446, @name="Prince Brave", @previously_changed={"name"=>[nil, "Prince Brave"]}>, @previously_changed={"dad"=>[nil, #<Somebody:0x75de7009 @temp_ref=-1014, @changed_attributes={}, @dbid=17592186045446, @name="Prince Brave", @previously_changed={"name"=>[nil, "Prince Brave"]}>], "mom"=>[nil, #<Somebody:0x7c840fe3 @temp_ref=-1015, @changed_attributes={}, @dbid=17592186045447, @name="Snow White", @previously_changed={"name"=>[nil, "Snow White"]}>], "name"=>[nil, "Alice Wonderland"]}, @mom=#<Somebody:0x7c840fe3 @temp_ref=-1015, @changed_attributes={}, @dbid=17592186045447, @name="Snow White", @previously_changed={"name"=>[nil, "Snow White"]}>>>
luigi.save
 => {:db-before datomic.db.Db@79b5b85f, :db-after datomic.db.Db@9a8e7dab, :tx-data [#Datum{:e 13194139534344 :a 50 :v #inst "2013-11-10T03:36:37.649-00:00" :tx 13194139534344 :added true} #Datum{:e 17592186045449 :a 68 :v 17592186045445 :tx 13194139534344 :added true} #Datum{:e 17592186045449 :a 67 :v "Luigi" :tx 13194139534344 :added true}], :tempids {-9223350046623220312 17592186045449}}
me.update_attributes(kids: [mario, luigi])
 => {:db-before datomic.db.Db@9a8e7dab, :db-after datomic.db.Db@7507454d, :tx-data [#Datum{:e 13194139534346 :a 50 :v #inst "2013-11-10T03:36:38.821-00:00" :tx 13194139534346 :added true} #Datum{:e 17592186045445 :a 70 :v 17592186045444 :tx 13194139534346 :added true} #Datum{:e 17592186045445 :a 70 :v 17592186045449 :tx 13194139534346 :added true}], :tempids {}}

# again, makes a query whose name is "Alice Wonderland"
me = Diametric::Query.new(Somebody, @conn, true).where(name: "Alice Wonderland").first
 => #<Somebody:0x1eb6037d @mom=#<Somebody:0x335b3d6 @dbid=17592186045427, @changed_attributes={"name"=>nil}, @name="Snow White">, @dad=#<Somebody:0x38848217 @dbid=17592186045426, @changed_attributes={"name"=>nil}, @name="Prince Brave">, @dbid=17592186045425, @changed_attributes={"kids"=>nil, "dad"=>nil, "mom"=>nil, "name"=>nil}, @kids=#<Set: {#<Somebody:0x3c743d40 @mom=#<Java::DatomicQuery::EntityMap:0x77a9ac36>, @dbid=17592186045424, @changed_attributes={"mom"=>nil, "name"=>nil}, @name="Mario">, #<Somebody:0x2444c3df @mom=#<Java::DatomicQuery::EntityMap:0x5aac6f9f>, @dbid=17592186045429, @changed_attributes={"mom"=>nil, "name"=>nil}, @name="Luigi">}>, @name="Alice Wonderland">

# looks kids data
me.kids.collect(&:name)
 => ["Mario", "Luigi"]

# retieve mom's instance from kids
Somebody.reify(me.kids.first.mom).name
 => "Alice Wonderland"
```

## Datomic Verion

Diametric sets up the default Datomic version.
On that version, all Diametric's tests pass.
However, Datomic team frequently releases a new version.
Just to update Datomic version, Diametric won't make a new release.
From version 0.1.3, Diametric supports user defined Datomic version.

Here is how a user can use a newer version of Datomic.


Specify a datomic version file by `ENV["DATOMIC_VERSION_PATH"]` *before* `require 'diametric'`.

For example:
```ruby
ENV["DATOMIC_VERSION_PATH"] = File.expand_path(File.join(File.dirname(__FILE__), "..", "datomic_version.yml"))
require 'diametric'
```

The format of datomic version file is simple yaml. For example:
```ruby
free:
  0.9.4532
pro:
  0.9.4470
```

## Other Documents

More than highlights above, there are documents on Wiki.

- [Entity API](https://github.com/relevance/diametric/wiki/Entity-API)
- [Query API](https://github.com/relevance/diametric/wiki/Query-API)
- [Persistence API](https://github.com/relevance/diametric/wiki/Persistence-API)
- [Rails Integration](https://github.com/relevance/diametric/wiki/Rails-Integration-%28Experimental%29)
- [Seattle Example](https://github.com/relevance/diametric/wiki/Seattle-Example)



## Thanks

Development of Diametric was sponsored by [Cognitect][]. They are the
best Clojure shop around and one of the best Ruby shops. I highly
recommend them for help with your corporate projects.

Special thanks to Mongoid for writing some solid ORM code that was liberally borrowed from to add Rails support to Diametric.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This project uses the [MIT License][].

Copyright (c) 2012 - 2014, Clinton Dreisbach & Cognitect Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

* When this project is used, a user is considered to have agreed to the [Datomic Free Edition License][]. This is because Diametric downloads Datomic free version automatically when Diametric is installed, Diametric's rspec gets run, or Datomic REST server gets started by a Diametric command.

[Datomic]: http://www.datomic.com
[Cognitect]: http://www.cognitect.com
[MIT License]: http://opensource.org/licenses/MIT
[Datomic Free Edition License]: http://www.datomic.com/datomic-free-edition-license.html
