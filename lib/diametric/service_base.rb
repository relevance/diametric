require 'net/http'

module Diametric
  module ServiceBase
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def datomic_conf_file?(file="datomic_version.cnf")
        file = File.join(File.dirname(__FILE__), "../..", file)
        return File.exists?(file)
      end

      def datomic_version(conf="datomic_version.cnf")
        if datomic_conf_file?(conf)
          File.read(File.join(File.dirname(__FILE__), "../..", conf))
        else
          conf
        end
      end

      def datomic_version_no(datomic_version_str)
        /(\d|\.)+/.match(datomic_version_str)[0]
      end

      def downloaded?(conf="datomic_version.cnf", dest="vendor/datomic")
        datomic_home = datomic_version(conf)
        File.exists?(File.join(File.dirname(__FILE__), "../..", dest, datomic_home))
      end

      def download(conf="datomic_version.cnf", dest="vendor/datomic")
        return true if downloaded?(conf, dest)
        version = datomic_version(conf)
        url = "http://downloads.datomic.com/#{datomic_version_no(version)}/#{version}.zip"
        dest_dir = File.join(File.dirname(__FILE__), "../..", dest)
        require 'open-uri'
        require 'zip/zipfilesystem'
        open(url) do |zip_file|
          Zip::ZipFile.open(zip_file.path) do |zip_path|
            zip_path.each do |zip_entry|
              file_path = File.join(dest_dir, zip_entry.to_s)
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
