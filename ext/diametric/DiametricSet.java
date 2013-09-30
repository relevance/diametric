package diametric;

import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.RT;
import clojure.lang.Var;

@JRubyClass(name = "Diametric::Persistence::Set")
public class DiametricSet extends RubyObject {
    private static final long serialVersionUID = 2565282201531713809L;
    private Collection<Object> set = null;
    private Map<String, Var> fnMap = new HashMap<String, Var>();

    public DiametricSet(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    void init(Object result) {
        if (result instanceof Collection) {
            set = (Collection<Object>)result;
        } else {
            throw new RuntimeException("Wrong type of query result");
        }
    }

    Object toJava() {
        return set;
    }

    private Var getFn(String namespace, String fn) {
        String fullname = namespace + "/" + fn;
        if (fnMap.containsKey(fullname)) {
            return fnMap.get(fullname);
        } else {
            Var var = RT.var(namespace, fn);
            fnMap.put(fullname, var);
            return var;
        }
    }

    @JRubyMethod(meta=true)
    public static IRubyObject wrap(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        try {
            Set<Object> s = (Set<Object>)arg.toJava(Set.class);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Set");
            DiametricSet ruby_set = (DiametricSet)clazz.allocate();
            ruby_set.init(s);
            return ruby_set;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), set);
    }

    @JRubyMethod(name={"collect", "map"})
    public IRubyObject collect(ThreadContext context, Block block) {
        Ruby runtime = context.getRuntime();
        if (block.isGiven()) {
            RubyArray array_result = runtime.newArray();
            Iterator<Object> itr = set.iterator();
            while (itr.hasNext()) {
                Object next = itr.next();
                IRubyObject ruby_next = DiametricUtils.convertJavaToRuby(context, next);
                IRubyObject block_result = block.yield(context, ruby_next);
                array_result.callMethod(context, "<<", block_result);
            }
            return array_result;
        }
        return this;       
    }

    @JRubyMethod
    public IRubyObject each(ThreadContext context, Block block) {
        if (block.isGiven()) {
            Iterator<Object> itr = set.iterator();
            while (itr.hasNext()) {
                Object next = itr.next();
                if (next instanceof clojure.lang.PersistentVector) {
                    RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
                    DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
                    ruby_collection.init(next);
                    block.yield(context, ruby_collection);
                } else {
                    IRubyObject ruby_next = DiametricUtils.convertJavaToRuby(context, next);
                    block.yield(context, ruby_next);
                }
            }
        }
        return this;
    }

    @JRubyMethod(name="empty?")
    public IRubyObject empty_p(ThreadContext context) {
        Var var = getFn("clojure.core", "empty?");
        try {
            if ((Boolean)var.invoke(set)) {
                return context.getRuntime().getTrue();
            } else {
                return context.getRuntime().getFalse();
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject first(ThreadContext context) {
        Var var = getFn("clojure.core", "first");
        try {
            Object first = var.invoke(set);
            if (first instanceof clojure.lang.PersistentVector) {
                RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
                DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
                ruby_collection.init(first);
                return ruby_collection;
            } else {
                return DiametricUtils.convertJavaToRuby(context, first);
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject group_by(ThreadContext context, Block block) {
        Ruby runtime = context.getRuntime();
        if (block.isGiven()) {
            RubyHash hash_result = new RubyHash(runtime);
            Iterator<Object> itr = set.iterator();
            while (itr.hasNext()) {
                IRubyObject ruby_next = DiametricUtils.convertJavaToRuby(context, itr.next());
                IRubyObject block_result = block.yield(context, ruby_next);
                IRubyObject value = hash_result.callMethod(context, "[]", block_result);
                if (value.isNil()) {
                    // new key
                    IRubyObject[] args = new IRubyObject[]{block_result, runtime.newArray()};
                    value = hash_result.callMethod(context, "[]=", args);
                }
                value.callMethod(context, "<<", ruby_next);
            }
            return hash_result;
        } else {
            return this;
        }
    }

    @JRubyMethod(name="include?")
    public IRubyObject include_p(ThreadContext context, IRubyObject arg) {
        Object java_object = DiametricUtils.convertRubyToJava(context, arg);
        Var var = getFn("clojure.core", "contains?");
        try {
            if ((Boolean)var.invoke(set, java_object)) {
                return context.getRuntime().getTrue();
            } else {
                return context.getRuntime().getFalse();
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name={"length", "size"})
    public IRubyObject size(ThreadContext context) {
        Var var = getFn("clojure.core", "count");
        try {
            Integer count = (Integer)var.invoke(set);
            return context.getRuntime().newFixnum(count);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject to_a(ThreadContext context) {
        try {
            RubyArray array = context.getRuntime().newArray();
            Iterator<Object> itr = set.iterator();
            while (itr.hasNext()) {
                Object value = itr.next();
                array.callMethod(context, "<<", DiametricUtils.convertJavaToRuby(context, value));
            }
            return array;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
}
