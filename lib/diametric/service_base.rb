require 'net/http'
require 'pathname'
require 'yaml'

module Diametric
  module ServiceBase
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def datomic_conf_file?(file="datomic_version.yml")
        if Pathname.new(file).relative?
          file = File.join(File.dirname(__FILE__), "../..", file)
        end
        return File.exists?(file)
      end

      def datomic_version(conf="datomic_version.yml")
        if datomic_conf_file?(conf)
          datomic_names = File.read(File.join(File.dirname(__FILE__), "../..", conf))
          datomic_versions = YAML.load(datomic_names)
          if ENV['DIAMETRIC_ENV'] && (ENV['DIAMETRIC_ENV'] == "pro")
            return "pro", datomic_versions["pro"]
          else
            return "free", datomic_versions["free"]
          end
        else
          return "free", conf
        end
      end

      def datomic_version_no(datomic_version_str)
        /(\d|\.)+/.match(datomic_version_str)[0]
      end

      def downloaded?(conf="datomic_version.yml", dest="vendor/datomic")
        datomic_type, datomic_version = datomic_version(conf)
        if Pathname.new(dest).relative?
          dest = File.join(File.dirname(__FILE__), "..", "..", dest)
        end
        File.exists?(File.join(dest, "datomic-#{datomic_type}-#{datomic_version}"))
      end

      def download(conf="datomic_version.yml", dest="vendor/datomic")
        return true if downloaded?(conf, dest)
        type, version = datomic_version(conf)
        url = "https://my.datomic.com/downloads/#{type}/#{version}"
        if Pathname.new(dest).relative?
          dest = File.join(File.dirname(__FILE__), "../..", dest)
        end
        require 'open-uri'
        require 'zip/zipfilesystem'
        open(url) do |zip_file|
          Zip::ZipFile.open(zip_file.path) do |zip_path|
            zip_path.each do |zip_entry|
              file_path = File.join(dest, zip_entry.to_s)
              FileUtils.mkdir_p(File.dirname(file_path))
              zip_path.extract(zip_entry, file_path) { true }
            end
          end
        end
      end

      def datomic_classpath(datomic_home)
        # Find jar archives
        jars = Dir["#{datomic_home}/lib/*.jar"]
        jars += Dir["#{datomic_home}/*transactor*.jar"]

        # Setup CLASSPATH
        classpath = jars.join(File::PATH_SEPARATOR)
        files = ["samples/clj", "bin", "resources"]
        classpath += File::PATH_SEPARATOR + files.collect {|f| datomic_home + "/" + f}.join(File::PATH_SEPARATOR)
      end
    end
  end
end
