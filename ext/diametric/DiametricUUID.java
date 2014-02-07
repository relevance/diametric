package diametric;

import java.util.UUID;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Diametric::Persistence::UUID")
public class DiametricUUID extends RubyObject {
    private static final long serialVersionUID = 2083281771243513904L;
    private java.util.UUID java_uuid = null;

    static IRubyObject getDiametricUUID(ThreadContext context, java.util.UUID value) {
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::UUID");
        DiametricUUID diametric_uuid = (DiametricUUID)clazz.allocate();
        diametric_uuid.init((java.util.UUID)value);
        return diametric_uuid;
    }

    public DiametricUUID(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(java.util.UUID java_uuid) {
        this.java_uuid = java_uuid;
    }
    
    java.util.UUID getUUID() {
        return java_uuid;
    }
    
    @JRubyMethod(name = "new", meta = true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz) {
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::UUID");
        DiametricUUID diametric_uuid = (DiametricUUID)clazz.allocate();
        try {
            java.util.UUID java_uuid = (UUID) DiametricService.getFn("datomic.api", "squuid").invoke();
            diametric_uuid.init(java_uuid);
            return diametric_uuid;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), java_uuid);
    }
    
    @JRubyMethod
    public IRubyObject to_s(ThreadContext context) {
        if (java_uuid == null) return context.getRuntime().getNil();
        return RubyString.newString(context.getRuntime(), java_uuid.toString());
    }
    
    @JRubyMethod
    public IRubyObject generate(ThreadContext context, IRubyObject arg) {
        if (java_uuid == null) return context.getRuntime().getNil();
        return RubyString.newString(context.getRuntime(), java.util.UUID.randomUUID().toString());
    }
}
