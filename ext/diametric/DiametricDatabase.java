package diametric;

import java.util.List;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import datomic.Database;
import datomic.Entity;

@JRubyClass(name = "Diametric::Persistence::Database")
public class DiametricDatabase extends RubyObject {
    private static final long serialVersionUID = 6043433195693171937L;
    // database supposed to be datomic.Database type
    private Object database = null;

    public DiametricDatabase(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(Object database) {
        this.database = database;
    }
    
    Object toJava() {
        return database;
    }
    
    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), database);
    }
    
    @JRubyMethod
    public IRubyObject entity(ThreadContext context, IRubyObject arg) {
        Long entityId = null;
        if (arg instanceof RubyFixnum) {
            entityId = (Long) arg.toJava(Long.class);
        } else if (arg instanceof DiametricObject) {
            if (((DiametricObject)arg).toJava() instanceof Long) {
                entityId = (Long)((DiametricObject)arg).toJava();
            }
        }
        if (entityId == null) {
            throw context.getRuntime().newArgumentError("Argument should be Fixnum or dbid object");
        }
        try {
            Entity entity = (Entity) DiametricService.getFn("datomic.api", "entity").invoke(database, entityId);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Entity");
            DiametricEntity diametric_entity = (DiametricEntity)clazz.allocate();
            diametric_entity.init(entity);
            return diametric_entity;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + t.getMessage());
        }
    }
    
    @JRubyMethod
    public IRubyObject with(ThreadContext context, IRubyObject arg) {
        try {
            List<Object> tx_data = DiametricUtils.convertRubyTxDataToJava(context, arg); // may raise exception
            if (tx_data == null) {
                throw context.getRuntime().newArgumentError("Argument should be Array or clojure.lang.PersistentVector");
            }

            Map map = (Map) DiametricService.getFn("datomic.api", "with").invoke(database, tx_data);
            return RubyHash.newHash(context.getRuntime(), map, null);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject as_of(ThreadContext context, IRubyObject arg) {
        Object t_value = DiametricUtils.convertRubyToJava(context, arg);
        try {
            Database db_asof_t = (Database) DiametricService.getFn("datomic.api", "as-of").invoke(database, t_value);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Database");
            DiametricDatabase diametric_database = (DiametricDatabase)clazz.allocate();
            diametric_database.init(db_asof_t);
            return diametric_database;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject since(ThreadContext context, IRubyObject arg) {
        Object t_value = DiametricUtils.convertRubyToJava(context, arg);
        try {
            Database db_since_t = (Database) DiametricService.getFn("datomic.api", "since").invoke(database, t_value);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Database");
            DiametricDatabase diametric_database = (DiametricDatabase)clazz.allocate();
            diametric_database.init(db_since_t);
            return diametric_database;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic Error: " + t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject id(ThreadContext context) {
        return RubyString.newString(context.getRuntime(), ((Database)database).id());
    }
}
