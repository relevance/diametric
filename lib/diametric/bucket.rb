module Diametric
  class Bucket
    def initialize
      @tempids = Array.new
      @holder = Hash.new
      @temp_ref = -1000000
      @entity_class = nil
    end

    # Builds transact data
    def build(entity_class, attributes)
      tempid = entity_class.tempid(:"db.part/user", next_temp_ref)
      data = Hash[attributes.map {|k, v| [(entity_class.prefix + "/" + k.to_s).to_sym, v]}]
      data.merge!({:"db/id" => tempid})
      @tempids << tempid
      @holder[tempid] = data
      @entity_class ||= entity_class
      tempid
    end

    def next_temp_ref
      @temp_ref -= 1
    end

    def [](key)
      @holder[key]
    end

    def size
      @tempids.size
    end
    alias :length :size
    alias :count :size

    def tx_data
      @tempids.inject([]) do |memo, id|
        memo << @holder[id]
        memo
      end
    end

    def save(conn=nil)
      if @entity_class.ancestors.include?(Diametric::Persistence::REST)
        conn ||= Diametric::Persistence::REST.connection
        conn.transact(Diametric::Persistence::REST.database, tx_data)
      else
        conn ||= Diametric::Persistence::Peer.connect
        conn.transact(tx_data).get
      end
      @tempids = Array.new
      @holder = Hash.new
      @temp_ref = -1000000
      @entity_class = nil
    end
  end
end
