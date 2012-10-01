# Diametric

Diametric is a library for building schemas, queries, and transactions for
[Datomic][] from Ruby objects.

Currently, Diametric does not contain the logic for communicating with Datomic,
only for creating the schema, queries, and transactions.

## Usage

```ruby
class Person
  include Diametric

  attr :name, String, :index => true
  attr :email, String, :cardinality => :many
  attr :birthday, DateTime
  attr :iq, Integer
  attr :website, URI
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

Person.query_data(:name => "Clinton Dreisbach")
# Datomic query:
# [:find ?e ?name ?email ?birthday ?iq ?website
#  :from $ ?name
#  :where [?e :person/name ?name]
#         [?e :person/email ?email]
#         [?e :person/birthday ?birthday]
#         [?e :person/iq ?iq]
#         [?e :person/website ?website]]
# Options:
#   :args => ["Clinton Dreisbach"]
#
# Returns as an array, [query, options].

Person.attrs
# [:dbid, :name, :email, :birthday, :iq, :website]

person = Person.new(Hash[*(Person.attrs.zip(results_from_query).flatten)])
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
