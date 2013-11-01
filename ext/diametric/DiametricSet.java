package diametric;

import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.IPersistentSet;
import clojure.lang.PersistentHashMap;
import clojure.lang.PersistentHashSet;
import clojure.lang.Var;

@JRubyClass(name = "Diametric::Persistence::Set")
public class DiametricSet extends RubyObject {
    private static final long serialVersionUID = 2565282201531713809L;
    private PersistentHashSet set = null;
    private Integer count = null;  // unable to count the vector size that exceeds Integer
    private DiametricCommon common = null;

    public DiametricSet(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    void init(Object result) {
        if (result instanceof PersistentHashSet) {
            set = (PersistentHashSet)result;
        } else if (result instanceof HashSet) {
            set = PersistentHashSet.create(((HashSet)result).toArray(new Object[0]));
        } else if (result instanceof List) {
            set = PersistentHashSet.create((List)result);
        } else {
            System.out.println(result.getClass().getCanonicalName());
            throw new RuntimeException("Wrong type of query result");
        }
        common = new DiametricCommon();
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
        if (block.isGiven()) {
            return common.collect(context, block, set.iterator());
        }
        return this;       
    }

    @JRubyMethod
    public IRubyObject each(ThreadContext context, Block block) {
        if (block.isGiven()) {
            common.each(context, block, set.iterator());
        }
        return this;
    }

    @JRubyMethod(name="empty?")
    public IRubyObject empty_p(ThreadContext context) {
        return common.empty_p(context, set);
    }

    @JRubyMethod(name={"==", "eql?", "equal?"})
    public IRubyObject equal_p(ThreadContext context, IRubyObject arg) {
        if (!(arg.respondsTo("intersection"))) {
            throw context.getRuntime().newArgumentError("argument should be Set");
        }
        try {
            IPersistentSet other = DiametricUtils.getPersistentSet(context, arg);
            Var var = DiametricService.getFn("clojure.core", "=");
            if ((Boolean)var.invoke(set, other)) {
                return context.getRuntime().getTrue();
            } else {
                return context.getRuntime().getFalse();
            }
        } catch(Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name={"drop", "take"})
    public IRubyObject drop(ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof RubyFixnum)) {
            throw context.getRuntime().newArgumentError("argument should be Fixnum");
        }
        Long n = (Long)arg.toJava(Long.class);
        if (n < 0) {
            throw context.getRuntime().newArgumentError("negative drop size");
        }
        if (n == 0) return this;
        return common.drop_or_take(context, n, set);
    }

    @JRubyMethod
    public IRubyObject first(ThreadContext context) {
        Object first = common.first(context, set);
        if (first instanceof clojure.lang.PersistentVector) {
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection ruby_collection = (DiametricCollection) clazz.allocate();
            ruby_collection.init(first);
            return ruby_collection;
        } else {
            return DiametricUtils.convertJavaToRuby(context, first);
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
        try {
            Var var = DiametricService.getFn("clojure.core", "contains?");
            if ((Boolean)var.invoke(set, java_object)) {
                return context.getRuntime().getTrue();
            } else {
                return context.getRuntime().getFalse();
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name={"&", "intersection"})
    public IRubyObject intersection(ThreadContext context, IRubyObject arg) {
        if (!(arg.respondsTo("intersection"))) throw context.getRuntime().newArgumentError("argument should be a set");
        IPersistentSet other = (IPersistentSet)DiametricUtils.getPersistentSet(context, arg);
        try {
            Var var = DiametricService.getFn("clojure.set", "intersection");
            return DiametricUtils.convertJavaToRuby(context, var.invoke(set, other));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private int getCount() {
        if (count == null) {
            Var var = DiametricService.getFn("clojure.core", "count");
            count = (Integer)var.invoke(set);
        }
        return count;
    }

    @JRubyMethod(name={"length", "size"})
    public IRubyObject size(ThreadContext context) {
        try {
            return context.getRuntime().newFixnum(getCount());
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

    @JRubyMethod
    public IRubyObject to_s(ThreadContext context) {
        return common.to_s(context, set);
    }

    @JRubyMethod(name={"|", "union"})
    public IRubyObject union(ThreadContext context, IRubyObject arg) {
        if (!(arg.respondsTo("union"))) throw context.getRuntime().newArgumentError("argument should be a set");
        IPersistentSet other = (IPersistentSet)DiametricUtils.getPersistentSet(context, arg);
        try {
            Var var = DiametricService.getFn("clojure.set", "union");
            return DiametricUtils.convertJavaToRuby(context, var.invoke(set, other));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
}
