package diametric;

import java.util.Collection;

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

@JRubyClass(name = "Diametric::Persistence::Entity")
public class DiametricEntity extends RubyObject {
    private static final long serialVersionUID = 3906852174830144427L;
    //entity should be datomic.Entity type
    private Object entity = null;

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
            Object database = clojure.lang.RT.var("datomic.api", "db").invoke(entity);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Database");
            DiametricDatabase diametric_database = (DiametricDatabase)clazz.allocate();
            diametric_database.init(database);
            return diametric_database;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    @JRubyMethod(name={"[]","get"}, required=1)
    public IRubyObject op_aref(ThreadContext context, IRubyObject arg) {
        String key = (String) arg.toJava(String.class);
        Object value = clojure.lang.RT.var("clojure.core", "get").invoke(entity, key);
        return DiametricUtils.convertJavaToRuby(context, value);
    }
    
    @JRubyMethod
    public IRubyObject keys(ThreadContext context) {
        Collection keys = (Collection) clojure.lang.RT.var("clojure.core", "keys").invoke(entity);
        RubyArray ruby_keys = RubyArray.newArray(context.getRuntime());
        for (Object key : keys) {
            // keys are clojure.lang.Keyword
            ruby_keys.append(RubyString.newString(context.getRuntime(), key.toString()));
        }
        return ruby_keys;
    }
    
    @JRubyMethod
    public IRubyObject touch(ThreadContext context) {
        try {
            Object touched_entity = clojure.lang.RT.var("datomic.api", "touch").invoke(entity);
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
}
