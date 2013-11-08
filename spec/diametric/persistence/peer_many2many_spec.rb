require 'spec_helper'
require 'diametric/persistence/peer'
require 'securerandom'

describe Diametric::Persistence::Peer, :jruby do
  before do
    db_uri = "datomic:mem://hello-#{SecureRandom.uuid}"
    @conn = subject.connect(:uri => db_uri)
    Author.create_schema(@conn)
    Book.create_schema(@conn)
  end
  after do
    @conn.release
  end

  it "should save one in caridinality many associations" do
    author = Author.new(:name => "wilber", :books => [])
    author.save
    book = Book.new(:title => "Candy", :authors => [])
    book.save
    author.update(:books => [book])
    result = Diametric::Persistence::Peer.q("[:find ?e ?name ?books :in $ :where [?e :author/name ?name] [?e :author/books ?books]]", @conn.db)
    boo_dbid = result.first[2]
    boo = Author.reify(boo_dbid, @conn)
    boo.title.should == "Candy"
  end

  it "should save two in caridinality many associations" do
    author = Author.new(:name => "wilber", :books => [])
    author.save
    book1 = Book.new(:title => "Honey", :authors => [])
    book1.save
    book2 = Book.new(:title => "Chips", :authors => [])
    book2.save
    author.update(:books => [book1, book2])
    result = Diametric::Persistence::Peer.q("[:find ?e ?name ?books :in $ :where [?e :author/name ?name] [?e :author/books ?books]]", @conn.db)
    result.size.should == 2
    result_in_array = result.to_a
    boo_dbid = result_in_array[0][2]
    boo = Book.reify(boo_dbid, @conn)
    boo.title.should match(/Honey|Chips/)
    foo_dbid = result_in_array[1][2]
    foo = Book.reify(boo_dbid, @conn)
    foo.title.should match(/Honey|Chips/)
  end

  it "should save two in caridinality many associations" do
    author1 = Author.new(:name => "Ms. Wilber", :books => [])
    author1.save
    author2 = Author.new(:name => "Mr. Smith", :books => [])
    author2.save
    book1 = Book.new(:title => "Pie", :authors => [])
    book1.save
    book2 = Book.new(:title => "Donuts", :authors => [])
    book2.save
    author1.update(:books => [book1, book2])
    book1.update(:authors => [author1, author2])

    result = Diametric::Persistence::Peer.q("[:find ?e :in $ [?name] :where [?e :author/name ?name]]", @conn.db, ["Ms. Wilber"])
    result.size.should == 1
    result.first.first.to_s.should == author1.dbid.to_s
    a = Author.reify(result.first.first, @conn)
    a.books.size.should == 2
    a.books.each do |b|
      Author.reify(b, @conn).title.should match(/Pie|Donuts/)
    end

    result = Diametric::Persistence::Peer.q("[:find ?e :in $ [?title] :where [?e :book/title ?title]]", @conn.db, ["Pie"])
    result.size.should == 1
    result.first.first.to_s.should == book1.dbid.to_s
    b = Book.reify(result.first.first, @conn)
    b.authors.size.should == 2
    b.authors.each do |a|
      Book.reify(a, @conn).name.should match(/Ms\.\sWilber|Mr\.\sSmith/)
    end
  end
end
