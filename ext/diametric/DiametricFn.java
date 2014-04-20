package diametric;

import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Diametric::Persistence::Fn")
public class DiametricFn extends RubyObject {
    private static final long serialVersionUID = -8192829430622753020L;
    private List function = null;

    public DiametricFn(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    void init(List function) {
        this.function = (List)function;
    }

    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

    Object toJava() {
        return function;
    }

    @JRubyMethod(name="new", meta=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Fn");
        DiametricFn diametric_object = (DiametricFn)clazz.allocate();
        diametric_object.init((List)DiametricUtils.convertRubyToJava(context, arg));
        return diametric_object;
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), function);
    }

    @JRubyMethod(name="==", required=1)
    public IRubyObject op_equal(ThreadContext context, IRubyObject arg) {
        Ruby runtime = context.getRuntime();
        if (arg instanceof DiametricFn) {
            DiametricFn other = (DiametricFn)arg;
            if (function.toString().equals(other.toJava().toString())) {
                return runtime.getTrue();
            } else {
                return runtime.getFalse();
            }
        } else {
            return runtime.getFalse();
        }
    }

    @JRubyMethod
    public IRubyObject to_s(ThreadContext context) {
        if (function == null) {
            return context.getRuntime().getNil();
        }
        return context.getRuntime().newString(function.toString());
    }
}
