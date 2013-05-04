require 'diametric/entity'

def gen_entity_class(named = 'generated_entity_class', &block)
  Class.new(Diametric::Entity) do
    namespace_prefix named
    instance_eval &block
  end
end
