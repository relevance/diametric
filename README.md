# Diametric

Diametric is a library for building schemas, queries, and transactions
for [Datomic][] from Ruby objects. It is also used to map Ruby objects
as entities into a Datomic database.

## Entity API

The `Entity` module is interesting, in that it is primarily made of
pure functions that take their receiver (an instance of the class they
are included in) and return data that you can use in Datomic. This
makes it not an ORM-like thing at all, but instead a Ruby-ish data
builder for Datomic. And yet, a `Diametric::Entity` is fully
`ActiveModel` compliant! You can use them anywhere you would use an
`ActiveRecord` model or another `ActiveModel`-compliant instance.

They do not include all `ActiveModel` modules by default, only the
ones needed to establish compliance. You may want to include others
yourself, such as `Validations`, `Callbacks`, or `Dirty`.

```ruby
require 'diametric'

class Person
  include Diametric::Entity

  attribute :name, String, :index => true
  attribute :email, String, :cardinality => :many
  attribute :birthday, DateTime
  attribute :iq, Integer
  attribute :website, URI
end

Person.schema
# Datomic transaction:
# [{:db/id #db/id[:db.part/db]
#   :db/ident :person/name
#   :db/valueType :db.type/string
#   :db/cardinality :db.cardinality/one
#   :db/index true
#   :db.install/_attribute :db.part/db}
#  {:db/id #db/id[:db.part/db]
#   :db/ident :person/email
#   :db/valueType :db.type/string
#   :db/cardinality :db.cardinality/many
#   :db.install/_attribute :db.part/db}
#  {:db/id #db/id[:db.part/db]
#   :db/ident :person/birthday
#   :db/valueType :db.type/instant
#   :db/cardinality :db.cardinality/one
#   :db.install/_attribute :db.part/db}
#  {:db/id #db/id[:db.part/db]
#   :db/ident :person/iq
#   :db/valueType :db.type/long
#   :db/cardinality :db.cardinality/one
#   :db.install/_attribute :db.part/db}
#  {:db/id #db/id[:db.part/db]
#   :db/ident :person/website
#   :db/valueType :db.type/uri
#   :db/cardinality :db.cardinality/one
#   :db.install/_attribute :db.part/db}]

Person.attributes
# [:dbid, :name, :email, :birthday, :iq, :website]

person = Person.new(Hash[*(Person.attributes.zip(results_from_query).flatten)])
# or
person = Person.from_query(results_from_query)

person.iq = 180
person.tx_data(:iq)
# Datomic transaction:
# [{:db/id person.dbid
#   :person/iq 180}]

person = Person.new(:name => "Peanut")
person.tx_data
# Datomic transaction:
# [{:db/id #db/id[:db.part/user]
#   :person/name "Peanut"}]
```

## Query API

The query API is used for generating Datomic queries, whether to send via an external client or via the persistence API. The two methods used to generate a query are `.where` and `.filter`, both of which are chainable. 

To get query data and args for a query, call `.data` on a `Query`.

If you are using a persistence API, you can ask `Query` to get the results of a Datomic query. `Diametric::Query` is an `Enumerable`. To get the results of a query, use `Enumerable` methods such as `.each` or `.first`. `Query` also provides a `.all` method to run the query and get the results.

```ruby
query = Datomic::Query.new(Person).where(:name => "Clinton Dreisbach")
query.data
# Datomic query:
# [:find ?e ?name ?email ?birthday ?iq ?website
#  :from $ ?name
#  :where [?e :person/name ?name]
#         [?e :person/email ?email]
#         [?e :person/birthday ?birthday]
#         [?e :person/iq ?iq]
#         [?e :person/website ?website]]
# Args:
#   ["Clinton Dreisbach"]
#
# Returns as an array, [query, args].

query = Datomic::Query.new(Person).where(:name => "Clinton Dreisbach").filter(:>, :iq, 150)
query.data
# Datomic query:
# [:find ?e ?name ?email ?birthday ?iq ?website
#  :from $ ?name
#  :where [?e :person/name ?name]
#         [?e :person/email ?email]
#         [?e :person/birthday ?birthday]
#         [?e :person/iq ?iq]
#         [?e :person/website ?website]
#         [> ?iq 150]
# Args:
#   ["Clinton Dreisbach"]
#
# Returns as an array, [query, args].
```

## Persistence API

The persistence API comes in two flavors: REST- and Java-based. For the most part, they have the same API.

### Java

With `Diametric::Persistence::Java`, you can create objects that know how to store themselves to Datomic through the Datomic Java API.

To use the `Diametric::Persistence::Java`, you will need to use JRuby and require `diametric/persistence/java`. When you install the `diametric` gem with JRuby, all `.jar` files needed to run Datomic will be downloaded. 

```ruby
require 'diametric'
require 'diametric/persistence/java'

# database URI
# will create database if it does not already exist
Diametric::Persistence::Java.connect('datomic:mem://animals')
```

### REST

With `Diametric::Persistence::REST`, you can create objects that know how to store themselves to Datomic through the Datomic REST API. This is your only option unless you are using JRuby.

```ruby
require 'diametric'
require 'diametric/persistence/rest'

# database url, database alias, database name
# will create database if it does not already exist
Diametric::Persistence::REST.connect('http://localhost:9000', 'test', 'animals')
```

### Using persisted models

```ruby
class Goat
  include Diametric::Entity
  include Diametric::Persistence::REST # if using REST API
  include Diametric::Persistence::Java # if using JRuby and not using REST
  
  attribute :name, String, :index => true
  attribute :age, Integer
end

goat = Goat.new(:name => 'Beans', :age => 2)
goat.dbid # => nil
goat.name # => "Beans"
goat.persisted? # => false
goat.new? # => true

goat.save
goat.dbid # => new id autogenerated
goat.name # => "Beans"
goat.persisted? # => true
goat.new? # => false

goats = Goat.where(:name => "Beans")
#=> [Goat(id: 1, age: 2, name: "Beans")]

goat = Goat.first(:name => "Beans")
#=> Goat(id: 1, age: 2, name: "Beans")

goats = Goat.filter(:<, :age, 3)
#=> [Goat(id: 1, age: 2, name: "Beans")]

goats = Goat.filter(:>, :age, 3)
#=> []
```

## Installation

Add this line to your application's Gemfile:

    gem 'diametric'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install diametric

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[Datomic]: http://www.datomic.com
