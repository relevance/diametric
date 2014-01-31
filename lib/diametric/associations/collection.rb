module Diametric
  module Associations
    class Collection
      def initialize(base, name, enum=nil, &block)
        @base = base
        @attribute_name = name
        @data = Set.new(enum, &block)
      end

      def add(*entities)
        old_data = @data.dup
        entities.each do |entity|
          if entity.dbid.nil? || entity.dbid.to_i < 0
            entity.save
          end
          @data << entity.dbid
        end
        if old_data != @data
          @base.send("#{@attribute_name}=", self)
        end
      end
      alias :<< :add

      def add_reified_entities(*entities)
        entities.each do |entity|
          @data << entity
        end
        @base.send("clean_#{@attribute_name}=", self)
      end

      def delete(*entities)
        entities.each do |entity|
          return unless self.include?(entity)
          if entity.is_a?(Fixnum) || entity.respond_to?(:to_i)
            # dbid or dbid object
            @data.delete_if {|e| e.to_i == entity.to_i}
          elsif entity.respond_to?(:dbid)
            # reified or created entity
            @data.delete_if {|e| e.dbid == entity.dbid}
          end
        end
      end

      def destroy(*entities)
        entities.each do |entity|
          return unless self.include?(entity)
          if entity.respond_to? :destroy
            entity.destroy
          end
          self.delete(entity)
        end
      end

      def include?(o)
        if o.is_a?(Fixnum) || o.respond_to?(:to_i)
          @data.find_all {|e| e.respond_to?(:to_i)}.collect(&:to_i).include?(o.to_i)
        elsif o.respond_to?(:dbid)
          @data.find_all {|e| e.respond_to?(:dbid)}.collect(&:dbid).include?(o.dbid)
        else
          false
        end
      end
      alias :member? :include?

      def &(enum)
        # this method is used to test the given class is Set or not.
        # don't delete this method.
        n = self.class.new
        @data.each { |o| n.add(o) if include?(o) }
        n
      end
      alias intersection &

      def inspect
        return sprintf('#<%s: {%s}>', self.class, @data.to_a.inspect[1..-2])
      end

      def replace(entities)
        @data = Set.new
        entities.each do |entity|
          if entity.dbid.nil? || entity.dbid.to_i < 0
            @data << entity.dbid if entity.save
          else
            @data << entity
          end
        end
        self
      end

      def method_missing(method, *args, &block)
        if !args.empty? && block
          @data.send(method, args, &block)
        elsif !args.empty?
          @data.send(method, args)
        elsif block
          @data.send(method, &block)
        else
          @data.send(method)
        end
      end
    end
  end
end
