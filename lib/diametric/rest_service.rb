module Diametric
  class RestService
    class << self
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

      def datomic_command(datomic_home)
        classpath = datomic_classpath(datomic_home)
        command = ["java -server -Xmx1g", "-cp", classpath, "clojure.main", "-i", "#{datomic_home}/bin/bridge.clj", "--main datomic.rest"].flatten.join(" ")
      end

    end

    attr_accessor :datomic_version, :datomic_version_no, :datomic_home, :pid
    attr_accessor :host, :port, :db_alias, :uri

    def initialize(conf="datomic_version.cnf", dest="vendor/datomic")
      @conf = conf
      @dest = dest
      @datomic_version = RestService.datomic_version(conf)
      @datomic_home = File.join(File.dirname(__FILE__), "../..", dest, @datomic_version)
      @datomic_version_no = RestService.datomic_version_no(@datomic_version)
      @pid = nil
    end

    def start(opts={})
      return if @pid
      RestService.download(@conf, @dest)
      command = RestService.datomic_command(@datomic_home)

      require 'socket'
      @host = opts[:host] ? opts[:host] : Socket.gethostname
      @port = opts[:port] ? opts[:port] : 9000
      @db_alias = opts[:db_alias] ? opts[:db_alias] : "free"
      @uri = opts[:uri] ? opts[:uri] : "datomic:mem://"

      temp_pid = spawn("#{command} -p #{@port} #{@db_alias} #{@uri}")

      uri = URI("http://#{@host}:#{@port}/")
      while true
        begin
          Net::HTTP.get_response(uri)
          break
        rescue
          sleep 1
          redo
        end
      end
      @pid = temp_pid
    end

    def stop
      Process.kill("HUP", @pid) if @pid
      @pid = nil
    end

  end
end
