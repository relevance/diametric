package diametric;

import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.Var;

@JRubyClass(name = "Diametric::Persistence::Entity")
public class DiametricEntity extends RubyObject {
    private static final long serialVersionUID = 3906852174830144427L;
    //entity should be datomic.Entity type
    private Object entity = null;

    static IRubyObject getDiametricEntity(ThreadContext context, Object value) {
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Entity");
        DiametricEntity diametric_entity = (DiametricEntity)clazz.allocate();
        diametric_entity.init(value);
        return diametric_entity;
    }

    public DiametricEntity(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(Object entity) {
        this.entity = entity;
    }
    
    Object toJava() {
        return entity;
    }
    
    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), entity);
    }
    
    @JRubyMethod
    public IRubyObject db(ThreadContext context) {
        try {
            Object database = DiametricService.getFn("datomic.api", "entity-db").invoke(entity);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Database");
            DiametricDatabase diametric_database = (DiametricDatabase)clazz.allocate();
            diametric_database.init(database);
            return diametric_database;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject touch(ThreadContext context) {
        try {
            Object touched_entity = DiametricService.getFn("datomic.api", "touch").invoke(entity);
            entity = touched_entity;
            return this;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject eid(ThreadContext context) {
        if (entity instanceof datomic.query.EntityMap) {
            Long eid = (Long) ((datomic.query.EntityMap)entity).eid;
            return RubyFixnum.newFixnum(context.getRuntime(), eid);
        }
        return context.getRuntime().getNil();
    }

    @JRubyMethod(name={"==","eql?"}, required=1)
    public IRubyObject eql_p(ThreadContext context, IRubyObject arg) {
        Object other = DiametricUtils.convertRubyToJava(context, arg);
        try {
            Var var = DiametricService.getFn("clojure.core", "=");
            Boolean value = (Boolean)var.invoke(entity, other);
            return context.getRuntime().newBoolean(value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name={"[]","get"}, required=1)
    public IRubyObject op_aref(ThreadContext context, IRubyObject arg) {
        String key = (String) arg.toJava(String.class);
        try {
            Var var = DiametricService.getFn("clojure.core", "get");
            Object value = var.invoke(entity, key);
            return DiametricUtils.convertJavaToRuby(context, value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name={"has_key?","include?", "key?", "member?"}, required=1)
    public IRubyObject has_key_p(ThreadContext context, IRubyObject arg) {
        String key = (String) arg.toJava(String.class);
        try {
            Var var = DiametricService.getFn("clojure.core", "contains?");
            Boolean value = (Boolean)var.invoke(entity, key);
            return context.getRuntime().newBoolean(value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject keys(ThreadContext context) {
        try {
            Var var = DiametricService.getFn("clojure.core", "keys");
            List<Object> keys = (List<Object>) var.invoke(entity);
            RubyArray ruby_keys = RubyArray.newArray(context.getRuntime());
            for (Object key : keys) {
                // keys are clojure.lang.Keyword
                ruby_keys.append(RubyString.newString(context.getRuntime(), key.toString()));
            }
            return ruby_keys;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject values(ThreadContext context) {
        try {
            Var var = DiametricService.getFn("clojure.core", "vals");
            List<Object> keys = (List<Object>) var.invoke(entity);
            RubyArray ruby_keys = RubyArray.newArray(context.getRuntime());
            for (Object key : keys) {
                // keys are clojure.lang.Keyword
                ruby_keys.append(RubyString.newString(context.getRuntime(), key.toString()));
            }
            return ruby_keys;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name={"length", "size"})
    public IRubyObject length(ThreadContext context) {
        try {
            Var var = DiametricService.getFn("clojure.core", "count");
            Integer count = (Integer) var.invoke(entity);
            return context.getRuntime().newFixnum(count);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject to_s(ThreadContext context) {
        try {
            Var var = DiametricService.getFn("clojure.core", "str");
            String str = (String) var.invoke(entity);
            return context.getRuntime().newString(str);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
}
