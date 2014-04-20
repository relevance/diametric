package diametric;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.h2.expression.Function;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.Keyword;
import clojure.lang.PersistentArrayMap;
import clojure.lang.PersistentHashSet;
import clojure.lang.PersistentVector;
import clojure.lang.Var;
import datomic.Connection;
import datomic.Database;

@JRubyModule(name="Diametric::Persistence::Peer")
public class DiametricPeer extends RubyModule {
    private static final long serialVersionUID = 8659857729004427581L;
    
    protected DiametricPeer(Ruby runtime) {
        super(runtime);
    }
    
    private static DiametricConnection saved_connection = null;
    
    @JRubyMethod(meta=true)
    public static IRubyObject connect(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        String uriOrMap = null;
        if (arg instanceof RubyString) {
            uriOrMap = DiametricUtils.rubyStringToJava(arg);
        } else if (arg instanceof RubyHash) {
            RubySymbol key = RubySymbol.newSymbol(context.getRuntime(), "uri");
            RubyString value = (RubyString)((RubyHash)arg).op_aref(context, key);
            uriOrMap = DiametricUtils.rubyStringToJava(value);
        } else {
            throw context.getRuntime().newArgumentError("Argument should be a String or Hash");
        }
        if (uriOrMap == null )
            throw context.getRuntime().newArgumentError("Argument should be a String or Hash with :uri key");
        
        RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Connection");
        DiametricConnection rubyConnection = (DiametricConnection)clazz.allocate();
        try {
            // what value will be returned when connect fails? API doc doesn't tell anything.
            Connection connection = (Connection) DiametricService.getFn("datomic.api", "connect").invoke(uriOrMap);
            rubyConnection.init(connection);
            saved_connection = rubyConnection;
            return rubyConnection;
        } catch (Exception e) {
            // Diametric doesn't require creating database before connect.
            // if database has not yet created, try that first and return the connection
            if (e instanceof clojure.lang.ExceptionInfo) {
                try {
                    DiametricService.getFn("datomic.api", "create-database").invoke(uriOrMap);
                    Connection connection = (Connection) DiametricService.getFn("datomic.api", "connect").invoke(uriOrMap);
                    rubyConnection.init(connection);
                    saved_connection = rubyConnection;
                    return rubyConnection;
                } catch (Throwable t) {
                    throw context.getRuntime().newRuntimeError(t.getMessage());
                }
            }
            throw context.getRuntime().newRuntimeError(e.getMessage());
        }
    }
    
    @JRubyMethod(meta=true)
    public static IRubyObject create_database(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        String uriOrMap = DiametricUtils.rubyStringToJava(arg);
        if (uriOrMap == null)
            throw context.getRuntime().newArgumentError("Argument should be a String");
        try {
            boolean status = (Boolean)DiametricService.getFn("datomic.api", "create-database").invoke(uriOrMap);
            return RubyBoolean.newBoolean(context.getRuntime(), status);
        } catch (Exception e) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + e.getMessage());
        }
    }
    
    @JRubyMethod(meta=true, required=2, rest=true)
    public static IRubyObject rename_database(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        if (args.length != 2) return context.getRuntime().getNil();
        String uriOrMap = DiametricUtils.rubyStringToJava(args[0]);
        if (uriOrMap == null) return context.getRuntime().getNil();
        String newName = DiametricUtils.rubyStringToJava(args[1]);
        if (newName == null) return context.getRuntime().getNil();
        try {
            boolean status = (Boolean)DiametricService.getFn("datomic.api", "rename-database").invoke(uriOrMap, newName);
            return RubyBoolean.newBoolean(context.getRuntime(), status);
        } catch (Exception e) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + e.getMessage());
        }
    }
    
    @JRubyMethod(meta=true)
    public static IRubyObject delete_database(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        String uriOrMap = DiametricUtils.rubyStringToJava(arg);
        if (uriOrMap == null) return context.getRuntime().getNil();
        try {
            boolean status = (Boolean)DiametricService.getFn("datomic.api", "delete-database").invoke(uriOrMap);
            return RubyBoolean.newBoolean(context.getRuntime(), status);
        } catch (Exception e) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + e.getMessage());
        }
    }
    
    @JRubyMethod(meta=true)
    public static IRubyObject shutdown(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        if (!(arg instanceof RubyBoolean)) {
            throw context.getRuntime().newArgumentError("Wrong argument type.");
        }
        Boolean shutdownClojure = (Boolean) arg.toJava(Boolean.class);
        try {
            DiametricService.getFn("datomic.api", "shutdown").invoke(shutdownClojure);
        } catch (Exception e) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + e.getMessage());
        }
        return context.getRuntime().getNil();
    }

    /**
     * Constructs a semi-sequential UUID useful for creating UUIDs that don't fragment indexes
     * 
     * @param context
     * @param klazz
     * @return java.util.UUID. a UUID whose most significant 32 bits are currentTimeMillis rounded to seconds
     */
    @JRubyMethod(meta=true)
    public static IRubyObject squuid(ThreadContext context, IRubyObject klazz) {
        RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::UUID");
        diametric.DiametricUUID ruby_uuid = (diametric.DiametricUUID)clazz.allocate();
        try {
            java.util.UUID java_uuid = (UUID) DiametricService.getFn("datomic.api", "squuid").invoke();
            ruby_uuid.init(java_uuid);
            return ruby_uuid;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic Exception: " + t.getMessage());
        }
    }
    
    /**
     * Gets the time part of a squuid
     * 
     * @param context
     * @param klazz
     * @param arg diametric.UUID. squuid -  a UUID created by squuid()
     * @return the time in the format of System.currentTimeMillis
     */
    @JRubyMethod(meta=true)
    public static IRubyObject squuid_time_millis(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        if (!(arg instanceof diametric.DiametricUUID)) {
            throw context.getRuntime().newArgumentError("Wrong argument type.");
        }
        java.util.UUID squuid = ((diametric.DiametricUUID)arg).getUUID();
        if (squuid == null) return context.getRuntime().getNil();
        long value;
        try {
            value = (Long) DiametricService.getFn("datomic.api", "squuid-time-millis").invoke(squuid);
            return RubyFixnum.newFixnum(context.getRuntime(), value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic Exception: " + t.getMessage());
        }
    }
    
    /**
     * Generates a temp id in the designated partition
     * In case the second argument is given,
     * it should be an idNumber from -1 (inclusive) to -1000000 (exclusive).
     * 
     * @param context
     * @param klazz
     * @param args the first argument: String. a partition, which is a keyword identifying the partition.
     * @return
     */
    @JRubyMethod(meta=true, required=1, optional=1)
    public static IRubyObject tempid(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        if (args.length < 1 || args.length > 2) {
            throw context.getRuntime().newArgumentError("Wrong number of arguments");
        }
        if (!(args[0] instanceof RubySymbol)) {
            throw context.getRuntime().newArgumentError("The first argument should be a Symbol");
        }
        RubyString edn_string = (RubyString)RuntimeHelpers.invoke(context, args[0], "to_s");
        Keyword partition = Keyword.intern((String)edn_string.asJavaString());
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Object");
        DiametricObject diametric_object = (DiametricObject)clazz.allocate();
        try {
            clojure.lang.Var clj_var = DiametricService.getFn("datomic.api", "tempid");
            if (args.length > 1 && (args[1] instanceof RubyFixnum)) {
                long idNumber = (Long) args[1].toJava(Long.class);
                diametric_object.update(clj_var.invoke(partition, idNumber));
            } else {
                diametric_object.update(clj_var.invoke(partition));
            }
            return diametric_object;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    /**
     * 
     * @param context
     * @param klazz
     * @param args Both 2 arguments should be DiametricObject.
     *             The first argument should hold clojure.lang.PersistentArrayMap.
     *             The second one should hold datomic.db.DbId.
     * @return
     */
    @JRubyMethod(meta=true, required=2, rest=true)
    public static IRubyObject resolve_tempid(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        if (args.length != 2) {
            throw context.getRuntime().newArgumentError("Wrong number of arguments");
        }
        Map map;
        DiametricObject ruby_object;
        if ((args[0] instanceof DiametricObject) && (args[1] instanceof DiametricObject)) {
            map = (Map) ((DiametricObject)args[0]).toJava();
            ruby_object = ((DiametricObject)args[1]);
        } else {
            throw context.getRuntime().newArgumentError("Wrong argument type.");
        }
        try {
            Object dbid = DiametricService.getFn("datomic.api", "resolve-tempid")
                            .invoke(map.get(Connection.DB_AFTER), map.get(Connection.TEMPIDS), ruby_object.toJava());
            ruby_object.update(dbid);
            return ruby_object;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic Exception: " + t.getMessage());
        }
    }
    
    @JRubyMethod(meta=true, required=2, rest=true)
    public static IRubyObject q(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        Ruby runtime = context.getRuntime();
        if (args.length < 2) {
            throw runtime.newArgumentError("Wrong number of arguments");
        }
        Object query = null;
        if (args[0] instanceof RubyArray) {
            try {
                query = DiametricUtils.fromRubyArray(context, (RubyArray)args[0]);
            } catch (Throwable t) {
                throw runtime.newRuntimeError(t.getMessage());
            }
        } else if (args[0] instanceof RubyString) {
            query = DiametricUtils.rubyStringToJava(args[0]);
        }
        if (query == null) {
            throw runtime.newArgumentError("The first arg should be a query string or array");
        }
        //System.out.println("query: " + query.toString());
        Database database = DiametricPeer.getDatabase(args[1]);
        if (database == null) {
            throw runtime.newArgumentError("The second arg should be a database.");
        }

        Collection<List<Object>> results = null;
        try {
            switch (args.length) {
            case 2:
                results = query_without_arg(query, database);
                break;
            case 3:
                if ((args[2] instanceof RubyArray) && (((RubyArray)args[2]).getLength() == 0)) {
                    results = query_without_arg(query, database);
                } else if (args[2] instanceof RubyArray) {
                    PersistentVector clj_arg = DiametricUtils.fromRubyArray(context, (RubyArray)args[2]);
                    results = query_with_arg(query, database, clj_arg);
                } else {
                    Object arg = DiametricUtils.convertRubyToJava(context, args[2]);
                    results = query_with_arg(query, database, arg);
                }
                break;
            default:
                Object[] inputs = new Object[args.length-2];
                for (int i=0; i<inputs.length; i++) {
                    inputs[i] = DiametricUtils.convertRubyToJava(context, args[i+2]);
                }
                results = query_with_args(query, database, inputs);
            }
        } catch (Throwable t) {
            throw runtime.newRuntimeError("Datomic Exception: " + t.getMessage());
        }

        if (results == null) return context.getRuntime().getNil();
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Set");
        DiametricSet diametric_set = (DiametricSet)clazz.allocate();
        diametric_set.init(results);
        return diametric_set;
    }

    private static Database getDatabase(Object value) {
        if (value instanceof DiametricDatabase) {
            return (Database) ((DiametricDatabase)value).toJava();
        } else if (value instanceof MapJavaProxy) {
            Object map = ((MapJavaProxy)value).toJava(Object.class);
            if (map instanceof datomic.Database) return (Database)map;
        }
        return null;
    }

    private static Collection<List<Object>> query_without_arg(Object query, Object database) {
        return (Collection<List<Object>>) DiametricService.getFn("datomic.api", "q").invoke(query, database);
    }

    private static Collection<List<Object>> query_with_arg(Object query, Object database, Object arg) {
        return (Collection<List<Object>>) DiametricService.getFn("datomic.api", "q").invoke(query, database, arg);
    }

    private static Collection<List<Object>> query_with_args(Object query, Object database, Object[] args) {
        switch(args.length) {
        case 2:
            return (Collection<List<Object>>) DiametricService.getFn("datomic.api", "q")
                    .invoke(query, database, args[0], args[1]);
        case 3:
            return (Collection<List<Object>>) DiametricService.getFn("datomic.api", "q")
                    .invoke(query, database, args[0], args[1], args[2]);
        case 4:
            return (Collection<List<Object>>) DiametricService.getFn("datomic.api", "q")
                    .invoke(query, database, args[0], args[1], args[2], args[3]);
        default:
            return (Collection<List<Object>>) DiametricService.getFn("datomic.api", "q").invoke(query, database, args);
        }
    }

    /**
     * Generates a function object given a map with required keys.
     * This method takes hash as an argument.
     * Given hash should have keys of
     *     :lang (either :clojure or :java)
     *     :params (list of parameters for code)
     *     :code (code in string)
     * The given has may have keys of
     *     :requires
     *     :imports
     *
     * @param context
     * @param klazz
     * @param args
     * @return
     */
    @JRubyMethod(meta=true, required=1, rest=true)
    public static IRubyObject function(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        if ((args.length < 1) || !(args[0] instanceof RubyHash)) {
            throw context.getRuntime().newArgumentError("This method takes one Hash as an argument");
        }
        RubyHash params = (RubyHash)args[0];
        if (params.size() < 3) {
            throw context.getRuntime().newArgumentError("This method needs at least :lang, :params, and :code keys with values");
        }
        try {
            Var hash_map_fn = DiametricService.getFn("clojure.core", "hash-map");
            clojure.lang.PersistentArrayMap clj_map =
                    (PersistentArrayMap) hash_map_fn.invoke();
            Var assoc_fn = DiametricService.getFn("clojure.core", "assoc");
            String[] keys = new String[] { "lang", "params", "code", "requires", "imports" };
            Class[] valueTypes =
                    new Class[] { RubySymbol.class, RubyArray.class, RubyString.class, RubyArray.class, RubyArray.class };
            for (int i = 0; i < keys.length; i++) {
                RubySymbol ruby_key = context.getRuntime().newSymbol(keys[i]);
                IRubyObject ruby_value = params.op_aref(context, ruby_key);
                if (ruby_value.isNil()) continue;
                clj_map = (PersistentArrayMap) assoc_fn.invoke(
                            clj_map,
                            DiametricService.keywords.get(ruby_key.toString()),
                            convertRubyValueToJava(context, ruby_value, valueTypes[i]));
            }
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Function");
            DiametricFunction ruby_function = (DiametricFunction) clazz.allocate();
            Var function_fn = DiametricService.getFn("datomic.api", "function");
            ruby_function.init((datomic.function.Function) function_fn.invoke(clj_map));
            return ruby_function;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private static Object convertRubyValueToJava(ThreadContext context, IRubyObject value, Class clazz) {
        if (clazz == RubySymbol.class) {
            return DiametricService.keywords.get(((RubySymbol)value).toString());
        } else if (clazz == RubyArray.class) {
            return convertArrayElementsToJava(context, (RubyArray)value);
        } else if (clazz == RubyString.class) {
            return ((RubyString)value).asJavaString();
        } else {
            throw context.getRuntime().newRuntimeError("Given arguments or some of them are worng");
        }
    }

    private static List convertArrayElementsToJava(ThreadContext context, RubyArray ruby_array) {
        List list = new ArrayList<clojure.lang.Symbol>();
        Var symbol_fn = DiametricService.getFn("clojure.core", "symbol");
        for (int i=0; i<ruby_array.size(); i++) {
            IRubyObject element = ruby_array.at(context.getRuntime().newFixnum(i));
            if (element instanceof RubySymbol) { // params
                list.add(symbol_fn.invoke(((RubySymbol)element).toString()));
            } else if (element instanceof RubyString) { // requires and imports
                list.add(((RubyString)element).asJavaString());
            }
        }
        return list;
    }

    private static List<RubyModule> bases = new ArrayList<RubyModule>();

    @JRubyMethod(meta=true)
    public static IRubyObject included(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        Ruby runtime = context.getRuntime();
        if (arg instanceof RubyModule) {
            RubyModule base = (RubyModule)arg;
            bases.add(base);
            base.instance_variable_set(RubyString.newString(context.getRuntime(), "@peer"), runtime.getTrue());
            IRubyObject common = runtime.getClassFromPath("Diametric::Persistence::Common");
            base.send(context, RubySymbol.newSymbol(runtime, "include"), common, Block.NULL_BLOCK);
            IRubyObject classmethods = runtime.getClassFromPath("Diametric::Persistence::Peer::ClassMethods");
            base.send(context, RubySymbol.newSymbol(runtime, "extend"), classmethods, Block.NULL_BLOCK);
        }
        return runtime.getNil();
    }

    @JRubyMethod(meta=true)
    public static IRubyObject connect(ThreadContext context, IRubyObject klazz) {
        if (saved_connection == null) return context.getRuntime().getNil();
        return saved_connection;
    }

    @JRubyMethod(meta=true)
    public static IRubyObject create_schemas(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        if (!(arg instanceof DiametricConnection))
            throw context.getRuntime().newArgumentError("Argument should be Connection.");
        IRubyObject result = context.getRuntime().getNil();
        for (RubyModule base : bases) {
            if (base.respondsTo("schema")) {
                IRubyObject schema = base.send(context, RubySymbol.newSymbol(context.getRuntime(), "schema"), Block.NULL_BLOCK);
                result = ((DiametricConnection)arg).transact(context, schema);
            }
        }
        return result;
    }

    @JRubyMethod(meta=true)
    public static IRubyObject transact(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        return saved_connection.transact(context, arg);
    }

    @JRubyMethod(meta=true)
    public static IRubyObject get(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        Ruby runtime = context.getRuntime();
        Object dbid = null;
        if ((arg instanceof DiametricObject) && (((DiametricObject)arg).to_java(context) instanceof RubyFixnum)) {
            dbid = ((DiametricObject)arg).toJava();
        } else if (arg instanceof RubyFixnum) {
            dbid = ((RubyFixnum)arg).toJava(Long.class);
        } else {
            throw runtime.newArgumentError("Argument should be dbid");
        }
        if (saved_connection == null) throw runtime.newRuntimeError("Connection is not established");
        try {
            Object database = DiametricService.getFn("datomic.api", "db").invoke(saved_connection.toJava());
            Object entity = DiametricService.getFn("datomic.api", "entity").invoke(database, dbid);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Entity");
            DiametricEntity ruby_entity = (DiametricEntity)clazz.allocate();
            ruby_entity.init(entity);
            return ruby_entity;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(meta=true)
    public static IRubyObject retract_entity(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        Object dbid = DiametricUtils.convertRubyToJava(context, arg);
        List query = datomic.Util.list((datomic.Util.list(":db.fn/retractEntity", dbid)));
        try {
            DiametricService.getFn("datomic.api", "transact-async").invoke(saved_connection.toJava(), query);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic error: " + t.getMessage());
        }
        return context.getRuntime().getNil();
    }

    /**
     * 
     * @param context
     * @param klazz
     * @param args database, dbid, query
     * @return
     */
    @JRubyMethod(meta=true, required=3, rest=true)
    public static IRubyObject reverse_q(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        Ruby runtime = context.getRuntime();
        if (args[0] instanceof DiametricDatabase &&
                (args[1] instanceof DiametricObject || args[1] instanceof RubyFixnum) &&
                args[2] instanceof RubyString) {
            Object database = ((DiametricDatabase)args[0]).toJava();
            Long dbid = (Long)DiametricUtils.convertRubyToJava(context, args[1]);
            String query_string = (String)args[2].toJava(String.class);
            try {
                Object entity = DiametricService.getFn("datomic.api", "entity").invoke(database, dbid);
                clojure.lang.PersistentHashSet set =
                         (PersistentHashSet) DiametricService.getFn("clojure.core", "get").invoke(entity, query_string);

                if (set == null) {
                    return RubyArray.newEmptyArray(runtime);
                }

                RubyArray array = RubyArray.newArray(runtime, set.size());
                Iterator iter = set.iterator();
                while (iter.hasNext()) {
                    Object e = iter.next();
                    RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Entity");
                    DiametricEntity ruby_entity = (DiametricEntity)clazz.allocate();
                    ruby_entity.init(e);
                    array.append(ruby_entity);
                }
                return array;
            } catch (Throwable t) {
                throw runtime.newRuntimeError("Datomic Error: " + t.getMessage());
            }
        } else {
            throw runtime.newArgumentError("Arguments should be 'database, dbid, query_string'");
        }
    }

    @JRubyMethod(meta=true)
    public static IRubyObject get_set(ThreadContext context, IRubyObject klazz) {
        IRubyObject set = context.getRuntime().getClass("Set");
        return context.getRuntime().getNil();
    }
}
