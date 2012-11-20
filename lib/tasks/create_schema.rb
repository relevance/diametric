require 'rake'
namespace :diametric do
  desc "create schema on datomic"
  task :create_schema => :environment do
    puts "Creating all schemas ..."
    Dir.glob(File.join(Rails.root, "app", "models", "*.rb")).each {|model| load model}
    Module.constants.each do |const|
      class_def = eval "#{const.to_s}"
      if class_def.respond_to? :create_schema
        class_def.send(:create_schema)
        puts class_def.send(:schema)
      end
    end
    puts "done"
  end
end

