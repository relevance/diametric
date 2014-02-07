require 'diametric/service_base'
require 'pathname'
require 'securerandom'

module Diametric
  class Transactor
    include ::Diametric::ServiceBase
    class << self
      def datomic_command(datomic_home)
        classpath = datomic_classpath(datomic_home)
        java_opts='-XX:NewRatio=4 -XX:SurvivorRatio=8 -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=60 -XX:+UseCMSInitiatingOccupancyOnly -XX:+CMSScavengeBeforeRemark'
        command = ["java -server -Xmx1g -Xms1g", java_opts, "-cp", classpath, "clojure.main", "--main datomic.launcher"].flatten.join(" ")
      end
    end

    attr_accessor :datomic_version, :datomic_version_no, :datomic_home, :pid
    attr_accessor :host, :port, :db_alias, :uri

    def initialize(conf="datomic_version.yml", dest="vendor/datomic")
      @conf = conf
      @dest = dest
      datomic_type, datomic_version = Transactor.datomic_version(conf)
      datomic_path = "datomic-#{datomic_type}-#{datomic_version}"
      if Pathname.new(dest).relative?
        @datomic_home = File.join(File.dirname(__FILE__), "../..", dest, datomic_path)
      else
        @datomic_home = File.join(dest, datomic_path)
      end
      #@datomic_version_no = Transactor.datomic_version_no(@datomic_version)
      @hostname = nil
      @port = nil
      @pid = nil
    end

    def start(props)
      return if @pid
      Transactor.download(@conf, @dest)
      command = Transactor.datomic_command(@datomic_home)

      unless File.exists?(props)
        puts "Transactor property file #{props} doesn't exist."
        return
      end
      properties(props)
      tmp_pid = spawn("#{command} #{props}")
      if ready?
        @pid = tmp_pid
      end
      @pid
    end

    def stop
      Process.kill("HUP", @pid) if @pid
      @pid = nil
    end

    def properties(props)
      File.readlines(props).each do |line|
        m = /^(host=)(.+)/.match(line)
        if m && m[2]
          @hostname = m[2]
        end
        m = /^(port=)(\d+)/.match(line)
        if m && m[2]
          @port = m[2]
        end
      end
    end

    def ready?
      tmp_database = "datomic:free://#{@hostname}:#{port}/tmp_database-#{SecureRandom.uuid}"
      while true
        begin
          if Diametric::Persistence::Peer.create_database(tmp_database)
            Diametric::Persistence::Peer.delete_database(tmp_database)
            return true
          end
        rescue
          sleep 1
          redo
        end
      end
      true
    end
  end

end
