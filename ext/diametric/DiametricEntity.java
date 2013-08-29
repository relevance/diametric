package diametric;

import java.util.Set;

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

import datomic.Database;
import datomic.Entity;

@JRubyClass(name = "Diametric::Persistence::Entity")
public class DiametricEntity extends RubyObject {
    private static final long serialVersionUID = 3906852174830144427L;
    private Entity entity = null;

    public DiametricEntity(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(Entity entity) {
        this.entity = entity;
    }
    
    Entity toJava() {
        return entity;
    }
    
    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), entity);
    }
    
    @JRubyMethod
    public IRubyObject db(ThreadContext context) {
        try {
            Database database = (Database) clojure.lang.RT.var("datomic.api", "db").invoke(entity);
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
        Object value = entity.get(key);
        return DiametricUtils.convertJavaToRuby(context, value);
    }
    
    @JRubyMethod
    public IRubyObject keys(ThreadContext context) {
        Set keySet = entity.keySet();
        RubyArray ruby_keys = RubyArray.newArray(context.getRuntime());
        for (Object key : keySet) {
            // keys are clojure.lang.Keyword
            ruby_keys.append(RubyString.newString(context.getRuntime(), key.toString()));
        }
        return ruby_keys;
    }
    
    @JRubyMethod
    public IRubyObject touch(ThreadContext context) {
        try {
            Entity touched_entity = (Entity) clojure.lang.RT.var("datomic.api", "touch").invoke(entity);
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
