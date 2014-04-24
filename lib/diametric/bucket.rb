module Diametric
  class Bucket
    def initialize
      @tempids = Array.new
      @holder = Hash.new
      @temp_ref = -1000000
    end

    # Builds transact data
    def build(entity_class, attributes)
      tempid = entity_class.tempid(:"db.part/user", next_temp_ref)
      data = Hash[attributes.map {|k, v| [(entity_class.prefix + "/" + k.to_s).to_sym, v]}]
      data.merge!({:"db/id" => tempid})
      @tempids << tempid
      @holder[tempid] = data
      tempid
    end

    def next_temp_ref
      @temp_ref -= 1
    end

    def [](key)
      @holder[key]
    end
  end
end
