package diametric;

import org.jruby.Ruby;
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

@JRubyClass(name = "Diametric::Persistence::Database")
public class DiametricDatabase extends RubyObject {
    private static final long serialVersionUID = 6043433195693171937L;
    private Database database = null;

    public DiametricDatabase(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(Database database) {
        this.database = database;
    }
    
    Database toJava() {
        return database;
    }
    
    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), database);
    }
    
    @JRubyMethod
    public IRubyObject entity(ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof RubyFixnum)) return context.getRuntime().getNil();
        Long entityId = (Long) arg.toJava(Long.class);
        Entity entity = database.entity(entityId);
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Entity");
        DiametricEntity diametric_entity = (DiametricEntity)clazz.allocate();
        diametric_entity.init(entity);
        return diametric_entity;
    }
    
    @JRubyMethod
    public IRubyObject id(ThreadContext context) {
        return RubyString.newString(context.getRuntime(), database.id());
    }
}
