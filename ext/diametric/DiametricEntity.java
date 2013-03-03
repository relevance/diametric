package diametric;

import java.util.Set;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import datomic.Database;
import datomic.Entity;

@JRubyClass(name = "Diametric::Persistence::UUID")
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
        Database database = entity.db();
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Database");
        DiametricDatabase diametric_database = (DiametricDatabase)clazz.allocate();
        diametric_database.init(database);
        return diametric_database;
    }
    
    @JRubyMethod
    public IRubyObject get(ThreadContext context, IRubyObject arg) {
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
        Entity touched_entity = entity.touch();
        entity = touched_entity;
        return this;
    }
}
