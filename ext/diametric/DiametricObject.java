package diametric;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Diametric::Persistence::Object")
public class DiametricObject extends RubyObject {
    private static final long serialVersionUID = -4198258841171995687L;
    private Object java_object = null;

    public DiametricObject(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void update(Object java_object) {
        this.java_object = java_object;
    }
    
    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
    
    Object toJava() {
        return java_object;
    }
    
    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), java_object);
    }
    
    @JRubyMethod
    public IRubyObject to_s(ThreadContext context) {
        return context.getRuntime().newString(java_object.toString());
    }
}
