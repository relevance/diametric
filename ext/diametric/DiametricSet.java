package diametric;

import java.util.Collection;
import java.util.Iterator;
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

@JRubyClass(name = "Diametric::Persistence::Set")
public class DiametricSet extends RubyObject {
    private static final long serialVersionUID = 2565282201531713809L;
    private Collection<Object> set = null;

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
        if (set.isEmpty()) {
            return context.getRuntime().getTrue();
        } else {
            return context.getRuntime().getFalse();
        }
    }
    
    @JRubyMethod
    public IRubyObject first(ThreadContext context) {
        Iterator<Object> itr = set.iterator();
        if (itr.hasNext()) {
            Object next = itr.next();
            if (next instanceof clojure.lang.PersistentVector) {
                RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
                DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
                ruby_collection.init(next);
                return ruby_collection;
            } else {
                return DiametricUtils.convertJavaToRuby(context, next);
            }
        }
        return context.getRuntime().getNil();
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
        if (set.contains(java_object)) {
            return context.getRuntime().getTrue();
        } else {
            return context.getRuntime().getFalse();
        }
    }
    
    @JRubyMethod(name={"length", "size"})
    public IRubyObject size(ThreadContext context) {
        return context.getRuntime().newFixnum(set.size());
    }
}
