require 'diametric/entity'

def gen_entity_class(named = 'generated_entity_class', &block)
  Class.new do
    include Diametric::Entity
    namespace_prefix named
    instance_eval &block
  end
end
