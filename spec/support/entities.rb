require 'diametric/entity'
require 'diametric/persistence/peer'
require 'diametric/persistence/rest'

# Prevent CRuby from blowing up
module Diametric
  module Persistence
    module Peer
    end
  end
end

class Person
  include Diametric::Entity

  attribute :name, String, :index => true
  attribute :email, String, :cardinality => :many
  attribute :birthday, DateTime
  attribute :awesome, :boolean, :doc => "Is this person awesome?"
  attribute :ssn, String, :unique => :value
  attribute :secret_name, String, :unique => :identity
  attribute :bio, String, :fulltext => true
  attribute :middle_name, String, :default => "Danger"
  attribute :nicknames, String, :cardinality => :many, :default => ["Buddy", "Pal"]
  attribute :parent, Ref, :cardinality => :many, :doc => "A person's parent"
end

class Goat
  include Diametric::Entity

  attribute :name, String
  attribute :birthday, DateTime
end

class Robin
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String
  validates_presence_of :name
  attribute :age, Integer
end

class Penguin
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :age, Integer
end

class Rat
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String, :index => true
  attribute :age, Integer
end

class Mouse
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String, :index => true
  attribute :age, Integer
end
