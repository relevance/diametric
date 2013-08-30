package diametric;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import datomic.ListenableFuture;

@JRubyClass(name = "Diametric::Persistence::ListenableFuture")
public class DiametricListenableFuture extends RubyObject {
    private static final long serialVersionUID = 2083281771243513904L;
    // future is supposed to datomic.ListenableFuture type;
    private Object future = null;

    public DiametricListenableFuture(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(Object future) {
        this.future = future;
    }
    
    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), future);
    }
    
    @JRubyMethod
    public IRubyObject get(ThreadContext context) {
        Ruby runtime = context.getRuntime();
        if (future == null) return runtime.getNil();
        try {
            Object result = ((ListenableFuture)future).get();
            RubyClass clazz = (RubyClass)runtime.getClassFromPath("Diametric::Persistence::Object");
            DiametricObject diametric_object = (DiametricObject)clazz.allocate();
            diametric_object.update(result);
            return diametric_object;
        } catch (Throwable t) {
            throw runtime.newRuntimeError(t.getMessage());
        }
    }
}
