require 'rake'
namespace :diametric do
  desc "Create schema on datomic for REST connection"
  task :create_schema => :environment do
    create_schema
  end

  # intentionally, no desc for this task
  # this task is used inside of the rails app
  task :create_schema_for_peer do
    create_schema(false)
  end
end

def create_schema(print_info=true)
  puts "Creating all schemas ..." if print_info
  Dir.glob(File.join(Rails.root, "app", "models", "*.rb")).each {|model| load model}
  Module.constants.each do |const|
    class_def = eval "#{const.to_s}"
    if class_def.respond_to? :create_schema
      class_def.send(:create_schema)
      puts class_def.send(:schema) if print_info
    end
  end
  puts "done" if print_info
end

