class Post
  include Diametric::Entity
  include Diametric::Persistence::REST
      
  attribute :name, String, :index => true
  attribute :content, String
end
