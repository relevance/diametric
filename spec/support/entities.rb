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
    module Utils
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
  attribute :birthday, DateTime
  attribute :awesomeness, Boolean
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

class ScarletMacaw
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :description, String, :fulltext => true
  attribute :talkative, Boolean
  attribute :colors, Integer
  attribute :average_speed, Float
  attribute :observed, DateTime
  attribute :case_no, UUID, :index => true
  attribute :serial, UUID, :unique => :value
end

class Peacock
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String
  attribute :description, String, :fulltext => true
  attribute :talkative, Boolean
  attribute :colors, Integer
  attribute :average_speed, Float
  attribute :observed, DateTime
  # REST failes to save UUID
  #attribute :case_no, UUID, :index => true
  #attribute :serial, UUID, :unique => :value
end

class MyWords
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :words, String, :cardinality => :many
end

class YourWords
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :words, String, :cardinality => :many
end

class Cage
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :pet, Ref
end

class Box
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :pet, Ref
end

class BigCage
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :pets, Ref, :cardinality => :many
end

class BigBox
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :pets, Ref, :cardinality => :many
end

class Author
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :books, Ref, :cardinality => :many
end

class Book
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :title, String
  attribute :authors, Ref, :cardinality => :many
end

class Writer
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String
  attribute :books, Ref, :cardinality => :many
end

class Article
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :title, String
  attribute :authors, Ref, :cardinality => :many
end

class Role
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :type, Ref
  enum :type, [:accountant, :manager, :developer]
end

class Position
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :type, Ref
  enum :type, [:accountant, :manager, :developer]
end

class Choice
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :item, String
  attribute :checked, Boolean
end

class Customer
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :id, UUID
end

class Account
  include Diametric::Entity
  include Diametric::Persistence::Peer

  attribute :name, String
  attribute :deposit, Float, :cardinality => :many
  attribute :amount, Double
end

class Organization
  include Diametric::Entity
  include Diametric::Persistence::REST

  attribute :name, String, :cardinality => :one, :fulltext => true, :doc => "A organization's name"
  attribute :url, String, :cardinality => :one, :doc => "A organization's url"
  attribute :neighborhood, Ref, :cardinality => :one, :doc => "A organization's neighborhood"
  attribute :category, String, :cardinality => :many, :fulltext => true, :doc => "All organization categories"
  attribute :orgtype, Ref, :cardinality => :one, :doc => "A organization orgtype enum value"
  attribute :type, Ref, :cardinality => :one, :doc => "A organization type enum value"
  enum :orgtype, [:community, :commercial, :nonprofit, :personal]
  enum :type, [:email_list, :twitter, :facebook_page, :blog, :website, :wiki, :myspace, :ning]
end

class Community
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

# issue 43
module This
  class Bug
    include Diametric::Entity
    include Diametric::Persistence::Peer

    attribute :id, String, index: true
    attribute :name, String
  end
end

module Outermost
  module Outer
    module Inner
      class Innermost
        include Diametric::Entity
        include Diametric::Persistence::Peer

        attribute :name, String
      end
    end
  end
end
