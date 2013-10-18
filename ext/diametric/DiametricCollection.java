package diametric;

import java.util.Iterator;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.RubyRange;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.APersistentVector;
import clojure.lang.LazySeq;
import clojure.lang.Var;

@JRubyClass(name = "Diametric::Persistence::Collection")
public class DiametricCollection extends RubyObject {
    // should be a Ruby's Enumerable
    private static final long serialVersionUID = 7656855654760249694L;
    private APersistentVector vector = null;
    private Integer count = null;  // unable to count the vector size that exceeds Integer

    public DiametricCollection(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    void init(Object obj) {
        if (obj instanceof APersistentVector) {
            this.vector = (APersistentVector)obj;
        } else {
            throw new RuntimeException("Wrong type of query result");
        }
    }

    Object toJava() {
        return vector;
    }

    @JRubyMethod(meta=true)
    public static IRubyObject wrap(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        try {
            clojure.lang.PersistentVector v =
                    (clojure.lang.PersistentVector)arg.toJava(clojure.lang.PersistentVector.class);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
            ruby_collection.init(v);
            return ruby_collection;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), vector);
    }

    @JRubyMethod(name={"[]", "slice"}, required=1, optional=1)
    public IRubyObject aref(ThreadContext context, IRubyObject[] args) {
        /*
         * ary[index] -> obj or nil
         * ary[start, length] -> new_ary or nil
         * ary[range] -> new_ary or nil
         * slice(index) -> obj or nil
         * slice(start,length) -> new_ary or_nil
         * slice(range) -> new_ary or nil
         */
        switch(args.length) {
        case 1:
            return aref(context, args[0]);
        case 2:
            return aref(context, args[0], args[1]);
        default:
            Arity.raiseArgumentError(getRuntime(), args.length, 1, 2);
        }
        return context.getRuntime().getNil();
    }

    private IRubyObject aref(ThreadContext context, IRubyObject index_or_range) {
        Long index = null;
        try {
            if (index_or_range instanceof RubyFixnum) {
                index = (Long)index_or_range.toJava(Long.class);
                return commonArefIndex(context, index);
            } else if (index_or_range instanceof RubyRange) {
                RubyRange range = (RubyRange)index_or_range;
                Long start = (Long)range.first().toJava(Long.class);
                Long last = (Long)range.last().toJava(Long.class);
                // subvec returns from 'start' to element (- end 1)
                if (range.exclude_end_p().isTrue()) {
                    return commonAref(context, start, null, last);
                } else {
                    return commonAref(context, start, null, last + 1);
                }
            } else {
                throw context.getRuntime().newArgumentError("wrong argument");
            }
        } catch(Throwable t) {
            if (t instanceof IndexOutOfBoundsException) {
                // raised only from [index] when index is greater than the last index or negative
                if (index >= (long)getCount()) return context.getRuntime().getNil();
                if (index < 0L) index += (long)getCount();
                if (index < 0L) return context.getRuntime().getNil();
                return commonArefIndex(context, index);
            }
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private IRubyObject aref(ThreadContext context, IRubyObject arg0, IRubyObject arg1) {
        Long start = null, length = null;
        try {
            start = (Long)arg0.toJava(Long.class);
            length = (Long)arg1.toJava(Long.class);
            if (length < 0L) return context.getRuntime().getNil();
            return commonAref(context, start, length, null);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private IRubyObject commonArefIndex(ThreadContext context, Long index) {
        Var var = DiametricCommon.getFn("clojure.core", "nth");
        Object value = var.invoke(vector, index);
        if (index == 0L) {
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Object");
            DiametricObject ruby_object = (DiametricObject)clazz.allocate();
            ruby_object.update(value);
            return ruby_object;
        } else {
            return DiametricUtils.convertJavaToRuby(context, value);
        }
    }

    private IRubyObject commonAref(ThreadContext context, Long start, Long length, Long last) {
        try {
            long end = length != null ? (start + length) : last;
            // checking a vector's length may be a costly operation.
            // allows to raise exception for the first time
            Var var = DiametricCommon.getFn("clojure.core", "subvec");
            // subvec returns from 'start' to element (- end 1)
            Object value = var.invoke(vector, start, end);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection ruby_collection = (DiametricCollection) clazz.allocate();
            ruby_collection.init(value);
            return ruby_collection;
        } catch (Throwable t) {
            if (t instanceof IndexOutOfBoundsException) {
                return retryAref(context, start, length, last);
            }
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private IRubyObject retryAref(ThreadContext context, Long start, Long length, Long last) {
        // now, check the vector's length
        if (start < 0L) start += (long)getCount();
        if (start < 0L) return context.getRuntime().getNil();
        if (start > (long)getCount()) return context.getRuntime().getNil();

        long end = length != null ? (start + length) : last;
        end = (end <= (long)getCount()) ? end : (long)getCount();
        Var var = DiametricCommon.getFn("clojure.core", "subvec");
        // subvec returns from 'start' to element (- end 1)
        try {
            Object value = var.invoke(vector, start, end);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
            ruby_collection.init(value);
            return ruby_collection;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject assoc(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable");
    }

    @JRubyMethod
    public IRubyObject at(ThreadContext context, IRubyObject arg) {
        Long index = null;
        try {
            if (arg instanceof RubyFixnum) {
                index = (Long)arg.toJava(Long.class);
                return commonArefIndex(context, index);
            } else {
                throw context.getRuntime().newArgumentError("argument should be fixnum");
            }
        } catch (Throwable t) {
            if (t instanceof IndexOutOfBoundsException) {
                // raised only when index is greater than the last index or negative
                if (index >= (long)getCount()) return context.getRuntime().getNil();
                if (index < 0L) index += (long)getCount();
                if (index < 0L) return context.getRuntime().getNil();
                return commonArefIndex(context, index);
            }
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject bsearch(ThreadContext context, Block block) {
        throw context.getRuntime().newRuntimeError("bsearch is not supported.");
    }

    @JRubyMethod
    public IRubyObject clear(ThreadContext context) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(name={"collect", "map"})
    public IRubyObject collect(ThreadContext context, Block block) {
        if (block.isGiven()) {
            RubyArray ary = context.getRuntime().newArray();
            return DiametricCommon.collect(context, block, vector.iterator(), ary);
        } else {
            return this;
        }
    }

    @JRubyMethod(name={"collect!", "map!"})
    public IRubyObject collect_bang(ThreadContext context, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod
    public IRubyObject combination(ThreadContext context, IRubyObject arg, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported yet. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod
    public IRubyObject compact(ThreadContext context) {
        try {
            Var var = DiametricCommon.getFn("clojure.core", "remove");
            Var nil_p = DiametricCommon.getFn("clojure.core", "nil?");
            LazySeq value = (LazySeq) var.invoke(nil_p, vector);
            Iterator itr = value.iterator();
            RubyArray result = context.getRuntime().newArray();
            while (itr.hasNext()) {
                Object obj = itr.next();
                result.callMethod("<<", DiametricUtils.convertJavaToRuby(context, obj));
            }
            return result;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name="compact!")
    public IRubyObject compact_bang(ThreadContext context) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod
    public IRubyObject concat(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod
    public IRubyObject count(ThreadContext context, Block block) {
        if (block.isGiven()) {
            return context.getRuntime().newFixnum(DiametricCommon.count(context, block, vector.iterator()));
        } else {
            return context.getRuntime().newFixnum(getCount());
        }
    }

    @JRubyMethod(required = 1)
    public IRubyObject count(ThreadContext context, IRubyObject arg, Block block) {
        if (block.isGiven()) {
            throw context.getRuntime().newArgumentError("given block not used");
        } else {
            Object java_object = DiametricUtils.convertRubyToJava(context, arg);
            return context.getRuntime().newFixnum(DiametricCommon.count(context, java_object, vector));
        }
    }

    @JRubyMethod
    public IRubyObject cycle(ThreadContext context, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported yet. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod
    public IRubyObject cycle(ThreadContext context, IRubyObject arg, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported yet. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod
    public IRubyObject delete(ThreadContext context, IRubyObject arg, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(name={"delete_at", "slice!"}, required=1, optional=1)
    public IRubyObject delete_at(ThreadContext context, IRubyObject arg[]) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(name={"delete_if", "reject!"})
    public IRubyObject delete_if(ThreadContext context, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
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
        try {
            Var var = DiametricCommon.getFn("clojure.core", "subvec");
            Object value = var.invoke(vector, n);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
            ruby_collection.init(value);
            return ruby_collection;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject each(ThreadContext context, Block block) {
        if (block.isGiven()) {
            Iterator<Object> itr = vector.iterator();
            while (itr.hasNext()) {
                IRubyObject next = DiametricUtils.convertJavaToRuby(context, itr.next());
                block.yield(context, next);
            }
        }
        // when block is not given, enumerator should be returned
        return this;
    }

    @JRubyMethod(name="empty?")
    public IRubyObject empty_p(ThreadContext context) {
        Boolean result = DiametricCommon.empty_p(context, vector);
        if (result) {
            return context.getRuntime().getTrue();
        } else {
            return context.getRuntime().getFalse();
        }
    }

    @JRubyMethod
    public IRubyObject first(ThreadContext context) {
        Object first = DiametricCommon.first(context, vector);
        // first element should be a dbid since this is a result of diametric query
        RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Object");
        DiametricObject ruby_object = (DiametricObject)clazz.allocate();
        ruby_object.update(first);
        return ruby_object;
    }

    private int getCount() {
        if (count == null) {
            Var var = DiametricCommon.getFn("clojure.core", "count");
            count = (Integer)var.invoke(vector);
        }
        return count;
    }

    @JRubyMethod(name="include?")
    public IRubyObject include_p(ThreadContext context, IRubyObject arg) {
        Var include_p_fn = null;
        if (DiametricCommon.fnMap.containsKey("include?")) {
            include_p_fn = DiametricCommon.fnMap.get("include?");
        } else {
            Var var = DiametricCommon.getFn("clojure.core", "load-string");
            include_p_fn = (Var)var.invoke("(defn include? [v array] (some (partial = v) array))");
            DiametricCommon.fnMap.put("include?", include_p_fn);
        }
        Object java_object = DiametricUtils.convertRubyToJava(context, arg);
        try {
            Object result = include_p_fn.invoke(java_object, vector);
            if ((result instanceof Boolean) && (Boolean)result) {
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
        return context.getRuntime().newFixnum(getCount());
    }

    @JRubyMethod
    public IRubyObject to_a(ThreadContext context) {
        return this;
    }

    @JRubyMethod
    public IRubyObject to_s(ThreadContext context) {
        return context.getRuntime().newString(DiametricCommon.to_s(context, vector));
    }
}
