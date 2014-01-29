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
    
    @JRubyMethod(name="new", meta=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Object");
        DiametricObject diametric_object = (DiametricObject)clazz.allocate();
        diametric_object.update(DiametricUtils.convertRubyToJava(context, arg));
        return diametric_object;
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), java_object);
    }
    
    @JRubyMethod(name="==", required=1)
    public IRubyObject op_equal(ThreadContext context, IRubyObject arg) {
        Ruby runtime = context.getRuntime();
        if (arg instanceof DiametricObject) {
            DiametricObject other = (DiametricObject)arg;
            if (java_object.toString().equals(other.toJava().toString())) {
                return runtime.getTrue();
            } else {
                return runtime.getFalse();
            }
        } else {
            return runtime.getFalse();
        }
    }

    @JRubyMethod(name={"to_s", "to_edn"})
    public IRubyObject to_s(ThreadContext context) {
        if (java_object == null) {
            return context.getRuntime().getNil();
        }
        return context.getRuntime().newString(java_object.toString());
    }

    @JRubyMethod
    public IRubyObject to_i(ThreadContext context) {
        if (java_object instanceof Long) {
            return context.getRuntime().newFixnum((Long)java_object);
        }
        return context.getRuntime().getNil();
    }
}
