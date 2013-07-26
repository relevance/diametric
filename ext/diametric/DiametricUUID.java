package diametric;

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

    public DiametricUUID(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(java.util.UUID java_uuid) {
        this.java_uuid = java_uuid;
    }
    
    java.util.UUID getUUID() {
        return java_uuid;
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
