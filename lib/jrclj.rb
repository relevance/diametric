require 'java'

java_import "clojure.lang.RT"

class JRClj
  def initialize *pkgs
    @mappings = {}
    @ns_map  = RT.var "clojure.core", "ns-map"
    @symbol  = RT.var "clojure.core", "symbol"
    @require = RT.var "clojure.core", "require"
    _import "clojure.core"
    pkgs.each do |pkg|
      _import pkg
    end
  end

  def _import pkg_name, sym=nil, sym_alias=nil
    @require.invoke @symbol.invoke(pkg_name)
    if sym
      sym_alias ||= sym
      @mappings[sym_alias] = RT.var pkg_name, sym
      return
    end
    pkg = @symbol.invoke pkg_name
    @ns_map.invoke(pkg).each do |sym,var|
      @mappings[sym.to_s] = var
    end
  end

  def _eval s
    self.eval self.read_string(s)
  end

  def _invoke m, *args
    fun = @mappings[m.to_s] || @mappings[m.to_s.gsub "_", "-"]
    unless fun
      raise "Error, no current binding for symbol=#{m}"
    end
    fun.invoke(*args)
  end

  def _alias new, old
    @mappings[new] = @mappings[old]
  end

  def method_missing symbol, *args
    _invoke symbol, *args
  end

  def self.persistent_map entries=[]
    Java::ClojureLang::PersistentArrayMap.new entries.to_java
  end

  def edn_convert(obj)
    self.read_string(obj.to_edn)
  end
end

class Symbol
  def to_clj
    Java::ClojureLang::Keyword.intern(self.to_s)
  end
end
