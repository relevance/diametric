# -*- coding: utf-8 -*-

require 'diametric/entity'
require 'diametric/persistence'
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

class Community
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String, :cardinality => :one, :fulltext => true, :doc => "A community's name"
  attribute :url, String, :cardinality => :one, :doc => "A community's url"
  attribute :neighborhood, Ref, :cardinality => :one, :doc => "A community's neighborhood"
  attribute :category, String, :cardinality => :many, :fulltext => true, :doc => "All community categories"
  attribute :orgtype, Ref, :cardinality => :one, :doc => "A community orgtype enum value"
  attribute :type, Ref, :cardinality => :one, :doc => "A community type enum value"
  enum :orgtype, [:community, :commercial, :nonprofit, :personal]
  enum :type, [:email_list, :twitter, :facebook_page, :blog, :website, :wiki, :myspace, :ning]
end

class Seattle
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String, :cardinality => :one, :fulltext => true, :doc => "A community's name"
  attribute :url, String, :cardinality => :one, :doc => "A community's url"
  attribute :neighborhood, Ref, :cardinality => :one, :doc => "A community's neighborhood"
  attribute :category, String, :cardinality => :many, :fulltext => true, :doc => "All community categories"
  attribute :orgtype, Ref, :cardinality => :one, :doc => "A community orgtype enum value"
  attribute :type, Ref, :cardinality => :one, :doc => "A community type enum value"
  enum :orgtype, [:community, :commercial, :nonprofit, :personal]
  enum :type, [:email_list, :twitter, :facebook_page, :blog, :website, :wiki, :myspace, :ning]
end

class Neighborhood
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String, :cardinality => :one, :unique => :identity, :doc => "A unique neighborhood name (upsertable)"
  attribute :district, Ref, :cardinality => :one, :doc => "A neighborhood's district"
end

class District
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String, :cardinality => :one, :unique => :identity, :doc => "A unique district name (upsertable)"
  attribute :region, Ref, :cardinality => :one, :doc => "A district region enum value"
  enum :region, [:n, :ne, :e, :se, :s, :sw, :w, :nw]
end
