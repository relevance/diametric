# -*- coding: utf-8 -*-

require 'diametric/entity'
require 'diametric/persistence'

class Community
  include Diametric::Entity
  include Diametric::Persistence

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
  attribute :name, String, :cardinality => :one, :unique => :identity, :doc => "A unique neighborhood name (upsertable)"
  attribute :district, Ref, :cardinality => :one, :doc => "A neighborhood's district"
end

class District
  attribute :name, String, :cardinality => :one, :unique => :indentity, :doc => "A unique district name (upsertable)"
  attribute :region, Ref, :cardinaloty => :one, :doc => "A district region enum value"
  enum :region, [:n, :ne, :e, :se, :s, :sw, :w, :nw]
end
