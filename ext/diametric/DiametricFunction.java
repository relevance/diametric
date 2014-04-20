package diametric;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.Keyword;
import clojure.lang.Var;

@JRubyClass(name = "Diametric::Persistence::Function")
public class DiametricFunction extends RubyObject {
    private static final long serialVersionUID = 1L;
    private datomic.function.Function java_object = null;

    public DiametricFunction(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    void init(datomic.function.Function java_object) {
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

    @JRubyMethod(name="==", required=1)
    public IRubyObject op_equal(ThreadContext context, IRubyObject arg) {
        Ruby runtime = context.getRuntime();
        if (arg instanceof DiametricFunction) {
            DiametricFunction other = (DiametricFunction)arg;
            Var keyword = DiametricService.getFn("clojure.core", "keyword");
            Keyword code_key = (Keyword) keyword.invoke("code");
            if (java_object.get(code_key).equals(other.java_object.get(code_key))) {
                return runtime.getTrue();
            } else {
                return runtime.getFalse();
            }
        } else {
            return runtime.getFalse();
        }
    }

    @JRubyMethod
    public IRubyObject lang(ThreadContext context) {
        Keyword lang = (Keyword)java_object.get(DiametricService.keywords.get("lang"));
        return context.getRuntime().newString(lang.toString());
    }

    @JRubyMethod
    public IRubyObject params(ThreadContext context) {
        clojure.lang.PersistentVector params =
                (clojure.lang.PersistentVector)java_object.get(DiametricService.keywords.get("params"));
        return context.getRuntime().newString(params.toString());
    }

    @JRubyMethod
    public IRubyObject code(ThreadContext context) {
        String code = (String)java_object.get(DiametricService.keywords.get("code"));
        return context.getRuntime().newString(code);
    }
/*
    @JRubyMethod(name={"to_s", "to_edn"})
    public IRubyObject to_s(ThreadContext context) {
        if (java_object == null) {
            return context.getRuntime().getNil();
        }
        return context.getRuntime().newString(java_object.toString());
    }*/
}
