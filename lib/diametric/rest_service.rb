require 'diametric/service_base'

module Diametric
  class RestService
    include ::Diametric::ServiceBase
    class << self
      def datomic_command(datomic_home)
        classpath = datomic_classpath(datomic_home)
        ["java -server -Xmx1g", "-cp", classpath, "clojure.main", "-i", "#{datomic_home}/bin/bridge.clj", "--main datomic.rest"].flatten.join(" ")
      end
    end

    attr_accessor :datomic_version, :datomic_version_no, :datomic_home, :pid
    attr_accessor :host, :port, :db_alias, :uri

   def initialize(conf="datomic_version.yml", dest="vendor/datomic")
     @conf = conf
     @dest = dest
     datomic_type, datomic_version = RestService.datomic_version(conf)
     @datomic_home = File.join(File.dirname(__FILE__), "../..", dest, "datomic-#{datomic_type}-#{datomic_version}")
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

      uri = URI("http://#{@host}:#{@port}/")

      unless port_available?(uri)
        puts "Somebody is using #{@port}. Choose other."
        return
      end

      temp_pid = spawn("#{command} -p #{@port} #{@db_alias} #{@uri}")

      @pid = temp_pid if ready?(uri)
    end

    def stop
      Process.kill("HUP", @pid) if @pid
      @pid = nil
    end

    def port_available?(uri)
      Net::HTTP.get_response(uri)
      false
    rescue Errno::ECONNREFUSED
      true
    end

    def ready?(uri)
      while true
        begin
          Net::HTTP.get_response(uri)
          return true
        rescue
          sleep 1
          redo
        end
      end
      true
    end

  end
end
