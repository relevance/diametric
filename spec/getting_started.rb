require 'sample_helper'
require 'pry'

describe "Seattle Sample", :jruby => true do
  Peer = Diametric::Persistence::Peer
  Utils = Diametric::Persistence::Utils

  puts "\nCreating and connecting to database..."
  uri = "datomic:mem://seattle";
  @conn = Peer.connect(uri);
  binding.pry unless ENV['DEBUG']

  puts "\nParsing schema edn file and running transaction..."
  schema_tx = Utils.read_all(File.join(File.dirname(__FILE__), "edn", "seattle-schema.edn"))
  tx_result = @conn.transact(schema_tx[0]).get
  puts tx_result
  binding.pry unless ENV['DEBUG']

  puts "\nParsing seed data edn file and running transaction..."
  data_tx = Utils.read_all(File.join(File.dirname(__FILE__), "edn", "seattle-data0.edn"))
  tx_result = @conn.transact(data_tx[0]).get
  binding.pry unless ENV['DEBUG']

  puts "\nFinding all communities, counting results..."
  @results = Peer.q([:find, ~"?c", :where, [~"?c", :"community/name"]], @conn.db)
  puts @results.size
  binding.pry unless ENV['DEBUG']

  puts "\nGetting first entity id in results, making entity map, displaying keys..."
  id = @results.first[0]
  entity = @conn.db.entity(id)
  puts entity.keys
  binding.pry unless ENV['DEBUG']

  puts "\nDisplaying the value of the entity's community name..."
  puts entity[:"community/name"]
  binding.pry unless ENV['DEBUG']

  puts "\nGetting name of each community (some may appear more than " +
    "because multiple online communities share the same name)..."
  db = @conn.db
  @results.each do |result|
    entity = db.entity(result[0])
    puts entity[:"community/name"]
  end
  binding.pry unless ENV['DEBUG']

  puts "\nGetting communities' neighborhood names (there are duplicates because " +
    "multiple communities are in the same neighborhood..."
  db = @conn.db
  @results.each do |result|
    entity = db.entity(result[0])
    neighborhood = entity[:"community/neighborhood"]
    puts neighborhood[:"neighborhood/name"]
  end
  binding.pry unless ENV['DEBUG']

  puts "\nGetting names of all communities in first community's " +
    "neighborhood..."
  community = @conn.db.entity(@results.first[0])
  neighborhood = community[:"community/neighborhood"]
  communities = neighborhood[:"community/_neighborhood"]
  communities.each do |comm|
    puts comm[:"community/name"]
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities and their names..."
  results = Peer.q([:find, ~"?c", ~"?n", :where, [~"?c", :"community/name", ~"?n"]],
                   @conn.db)
  results.each do |result|
    puts result[1]
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all community names and urls..."
  results = Peer.q([:find, ~"?n", ~"?u", :where,
                    [~"?c", :"community/name", ~"?n"],
                    [~"?c", :"community/url", ~"?u"]],
                   @conn.db)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts '\nFind all categories for community named "belltown"...'

  results = Peer.q([:find, ~"?e", ~"?c", :where,
                    [~"?e", :"community/name", "belltown"],
                    [~"?e", :"community/category", ~"?c"]],
                   @conn.db)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind names of all communities that are twitter feeds..."
  results = Peer.q([:find, ~"?n", :where,
                    [~"?c", :"community/name", ~"?n"],
                    [~"?c", :"community/type", :"community.type/twitter"]],
                   @conn.db)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind names of all communities that are in a neighborhood " +
    "in a district in the NE region..."
  results = Peer.q([:find, ~"?c_name", :where,
                    [~"?c", :"community/name", ~"?c_name"],
                    [~"?c", :"community/neighborhood", ~"?n"],
                    [~"?n", :"neighborhood/district", ~"?d"],
                    [~"?d", :"district/region", :"region/ne"]],
                   @conn.db)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind community names and region names for of all communities..."
  results = Peer.q([:find, ~"?c_name", ~"?r_name", :where,
                    [~"?c", :"community/name", ~"?c_name"],
                    [~"?c", :"community/neighborhood", ~"?n"],
                    [~"?n", :"neighborhood/district", ~"?d"],
                    [~"?d", :"district/region", ~"?r"],
                    [~"?r", :"db/ident", ~"?r_name"]],
                   @conn.db)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities that are twitter feeds and facebook pages using " +
    "the same query and passing in type as a parameter..."
  query_by_type =
    [:find, ~"?n",
     :in, ~"\$", ~"?t",
     :where,
     [~"?c", :"community/name", ~"?n"],
     [~"?c", :"community/type", ~"?t"]]
  results = Peer.q(query_by_type,
                   @conn.db,
                   :"community.type/twitter")
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  results = Peer.q(query_by_type,
                   @conn.db,
                   :"community.type/facebook-page");
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities that are twitter feeds or facebook pages using " +
    "one query and a list of individual parameters..."
  dots = Diametric::Persistence::Utils.read_string("...")
  results = Peer.q([:find, ~"?n", ~"?t", :in, ~"\$", [~"?t", dots], :where,
                    [~"?c", :"community/name", ~"?n"],
                    [~"?c", :"community/type", ~"?t"]],
                   @conn.db,
                   [:"community.type/facebook-page",
                    :"community.type/twitter"])
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities that are non-commercial email-lists or commercial " +
    "web-sites using a list of tuple parameters..."
  results = Peer.q([:find, ~"?n", ~"?t", ~"?ot",
                    :in, ~"\$", [[~"?t", ~"?ot"]],
                    :where,
                    [~"?c", :"community/name", ~"?n"],
                    [~"?c", :"community/type", ~"?t"],
                    [~"?c", :"community/orgtype", ~"?ot"]],
                   @conn.db,
                   [[":community.type/email-list",
                     ":community.orgtype/community"],
                    [":community.type/website",
                     ":community.orgtype/commercial"]])
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts '\nFind all community names coming before "C" in alphabetical order...'
  results = Peer.q([:find, ~"?n",
                    :where,
                    [~"?c", :"community/name", ~"?n"],
                    [Utils.fn(~".compareTo", ~"?n", "C"), ~"?res"],
                    [Utils.fn(~"<", ~"?res", 0)]],
                   @conn.db)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts '\nFind all communities whose names include the string "Wallingford"...'
  results = Peer.q([:find, ~"?n",
                    :where,
                    [Utils.fn(~"fulltext", ~"\$", :"community/name", "Wallingford"),
                     [[~"?e", ~"?n"]]]],
                   @conn.db)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities that are websites and that are about " +
    "food, passing in type and search string as parameters..."
  results = Peer.q([:find, ~"?name", ~"?cat",
                    :in, ~"\$", ~"?type", ~"?search",
                    :where,
                    [~"?c", :"community/name", ~"?name"],
                    [~"?c", :"community/type", ~"?type"],
                    [Utils.fn(~"fulltext", ~"\$", :"community/category", ~"?search"),
                     [[~"?c", ~"?cat"]]]],
                   @conn.db,
                   :"community.type/website",
                   "food")
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all names of all communities that are twitter feeds, using rules..."
  rules = [[[~"twitter", ~"?c"],
            [~"?c", :"community/type", :"community.type/twitter"]]]
  results = Peer.q("[:find ?n :in $ % :where " +
                   "[?c :community/name ?n]" +
                   "(twitter ?c)]",
                   @conn.db,
                   rules);
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind names of all communities in NE and SW regions, using rules " +
    "to avoid repeating logic..."
  rules = [[[~"region", ~"?c", ~"?r"],
            [~"?c", :"community/neighborhood", ~"?n"],
            [~"?n", :"neighborhood/district", ~"?d"],
            [~"?d", :"district/region", ~"?re"],
            [~"?re", :"db/ident", ~"?r"]]]
  results = Peer.q([:find, ~"?n", :in, ~"\$", ~"%", :where,
                    [~"?c", :"community/name", ~"?n"],
                    Utils.fn(~"region", ~"?c", :"region/ne")],
                   @conn.db,
                   rules)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  results = Peer.q([:find, ~"?n",
                    :in, ~"\$", ~"%",
                    :where,
                    [~"?c", :"community/name", ~"?n"],
                    Utils.fn(~"region", ~"?", :"region/sw")],
                   @conn.db,
                   rules)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind names of all communities that are in any of the southern " +
    "regions and are social-media, using rules for OR logic..."
  rules = [[[~"region", ~"?c", ~"?r"],
            [~"?c", :"community/neighborhood", ~"?n"],
            [~"?n", :"neighborhood/district", ~"?d"],
            [~"?d", :"district/region", ~"?re"],
            [~"?re", :"db/ident", ~"?r"]],
           [[~"social-media", ~"?c"],
            [~"?c", :"community/type", :"community.type/twitter"]],
           [[~"social-media", ~"?c"],
            [~"?c", :"community/type", :"community.type/facebook-page"]],
           [[~"northern", ~"?c"], Utils.fn(~"region", ~"?c", :"region/ne")],
           [[~"northern", ~"?c"], Utils.fn(~"region", ~"?c", :"region/n")],
           [[~"northern", ~"?c"], Utils.fn(~"region", ~"?c", :"region/nw")],
           [[~"southern", ~"?c"], Utils.fn(~"region", ~"?c", :"region/sw")],
           [[~"southern", ~"?c"], Utils.fn(~"region", ~"?c", :"region/s")],
           [[~"southern", ~"?c"], Utils.fn(~"region", ~"?c", :"region/se")]]
  results = Peer.q([:find, ~"?n",
                    :in, ~"\$",  ~"%",
                    :where,
                    [~"?c", :"community/name", ~"?n"],
                    Utils.fn(~"southern", ~"?c"),
                    Utils.fn(~"social-media", ~"?c")],
                   @conn.db,
                   rules)
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']

  puts "\nFind all database transactions..."
  results = Peer.q([:find, ~"?when", :where, [~"?tx", :"db/txInstant", ~"?when"]],
                   @conn.db)
  binding.pry unless ENV['DEBUG']

  puts "\nSort transactions by time they occurred, then " +
    "pull out date when seed data load transaction and " +
    "schema load transactions were executed..."

  tx_dates = results.inject([]) do |memo, result|
    memo << result[0]
    memo
  end
  tx_dates.sort! {|x, y| y <=> x }
  @data_tx_date = tx_dates[0]
  @schema_tx_date = tx_dates[1]
  @communities_query = [:find, ~"?c", :where, [~"?c", :"community/name"]]
  binding.pry unless ENV['DEBUG']

  puts "\nMake query to find all communities, use with database " +
    "values as of and since different points in time..."

  puts "\nFind all communities as of schema transaction..."
  db_asOf_schema = @conn.db.as_of(@schema_tx_date)
  results = Peer.q(@communities_query, db_asOf_schema)
  puts results.size
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities as of seed data transaction..."
  db_asOf_data = @conn.db.as_of(@data_tx_date)
  results = Peer.q(@communities_query, db_asOf_data)
  puts results.size
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities since schema transaction..."
  db_since_schema = @conn.db.since(@schema_tx_date)
  results = Peer.q(@communities_query, db_since_schema)
  puts results.size
  binding.pry unless ENV['DEBUG']

  puts "\nFind all communities since seed data transaction..."
  db_since_data = @conn.db.since(@data_tx_date);
  results = Peer.q(@communities_query, db_since_data)
  puts results.size
  binding.pry unless ENV['DEBUG']

  puts "\nMake a new partition..."
  partition_tx = [{:"db/id" => Peer.tempid(:"db.part/db"),
                    :"db/ident"=> :"communities",
                    :"db.install/_partition" => :"db.part/db"}]
  txResult = @conn.transact(partition_tx).get
  puts txResult
  binding.pry unless ENV['DEBUG']

  puts "\nMake a new community..."
  add_community_tx = [{:"db/id" => Peer.tempid(:"communities"),
                        :"community/name" => "Easton"}]
  txResult = @conn.transact(add_community_tx).get
  puts txResult
  binding.pry unless ENV['DEBUG']

  puts "\nUpdate data for a community..."
  results = Peer.q([:find, ~"?id", :where, [~"?id", :"community/name", "belltown"]],
                   @conn.db)
  belltown_id = results.first[0]
  update_category_tx = [{:"db/id" => belltown_id,
                          :"community/category" => "free stuff"}]
  txResult = @conn.transact(update_category_tx).get
  puts txResult
  binding.pry unless ENV['DEBUG']
  
  puts "\nRetract data for a community..."
  retract_category_tx = [[:"db/retract", belltown_id,
                          :"community/category", "free stuff"]]
  txResult = @conn.transact(retract_category_tx).get
  puts txResult
  binding.pry unless ENV['DEBUG']

  puts "\nRetract a community entity..."
  results = Peer.q([:find, ~"?id", :where, [~"?id", :"community/name", "Easton"]],
                   @conn.db)
  easton_id = results.first[0]
  retract_entity_tx = [{:"db.fn/retractEntity" => easton_id}]
  txResult = @conn.transact(retract_category_tx).get
  puts txResult
  binding.pry unless ENV['DEBUG']

  puts "\nGet transaction report queue, add new community again..."
  queue = @conn.tx_report_queue
  add_community_tx = [{:"db/id" => Peer.tempid(:"communities"),
                        :"community/name" => "Easton"}]
  txResult = @conn.transact(add_community_tx).get
  puts txResult
  binding.pry unless ENV['DEBUG']

  puts "\nPoll queue for transaction notification, print data that was added..."
  report = queue.poll
  results = Peer.q([:find, ~"?e", ~"?aname", ~"?v", ~"?added",
                    :in, ~"\$", [[~"?e", ~"?a", ~"?v", ~"_", ~"?added"]],
                    :where,
                    [~"?e", ~"?a", ~"?v", ~"_", ~"?added"],
                    [~"?a", :"db/ident", ~"?aname"]],
                   report[Java::Datomic::Connection::DB_AFTER],
                   report[Java::Datomic::Connection::TX_DATA])
  results.each do |result|
    puts result
  end
  binding.pry unless ENV['DEBUG']
end
