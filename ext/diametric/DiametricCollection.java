package diametric;

import java.util.Collection;
import java.util.Iterator;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Diametric::Persistence::Collection")
public class DiametricCollection extends RubyObject {
    // should be a Ruby's Enumerable
    private static final long serialVersionUID = 7656855654760249694L;
    private Collection query_result = null;

    public DiametricCollection(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(Object result) {
        if (result instanceof Collection) {
            this.query_result = (Collection)result;
        } else {
            throw new RuntimeException("Wrong type of query result");
        }
    }

    Object toJava() {
        return query_result;
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), query_result);
    }
    
    @JRubyMethod(name="==", required=1)
    public IRubyObject op_equal(ThreadContext context, IRubyObject arg) {
        Ruby runtime = context.getRuntime();
        if (arg instanceof DiametricCollection) {
            DiametricCollection other = (DiametricCollection)arg;
            if (query_result.toString().equals(other.toJava().toString())) {
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
        return context.getRuntime().newString(query_result.toString());
    }
    
    @JRubyMethod(name = "all?")
    public static IRubyObject all_p(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod(name = "any?")
    public static IRubyObject any_p(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject chunk(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject chunk(ThreadContext context, IRubyObject self, final IRubyObject initialState, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject collect(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject collect_concat(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject count(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject count(ThreadContext context, IRubyObject self, final IRubyObject methodArg, final Block block) {
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public static IRubyObject cycle(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject cycle(ThreadContext context, IRubyObject self, IRubyObject arg, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject detect(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject detect(ThreadContext context, IRubyObject self, IRubyObject ifnone, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject drop(ThreadContext context, IRubyObject self, IRubyObject n, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject drop_while(ThreadContext context, IRubyObject self, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject each_cons(ThreadContext context, IRubyObject self, IRubyObject arg, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod(rest = true)
    public static IRubyObject each_entry(ThreadContext context, final IRubyObject self, final IRubyObject[] args, final Block block) {
        return context.getRuntime().getNil();
    }
    
    @JRubyMethod
    public static IRubyObject each_slice(ThreadContext context, IRubyObject self, IRubyObject arg, final Block block) {
        return context.getRuntime().getNil();
    }
}
