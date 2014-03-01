package diametric;

import java.util.Iterator;
import java.util.List;
import java.util.concurrent.BlockingQueue;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.RubyRange;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.APersistentVector;
import clojure.lang.LazySeq;
import clojure.lang.PersistentVector;
import clojure.lang.Var;

@JRubyClass(name = "Diametric::Persistence::Collection")
public class DiametricCollection extends RubyObject {
    // should be a Ruby's Enumerable
    private static final long serialVersionUID = 7656855654760249694L;
    private List vector_or_seq = null;
    private Integer count = null;  // unable to count the vector size that exceeds Integer
    private DiametricCommon common = null;

    static IRubyObject getDiametricCollection(ThreadContext context, List value) {
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
        DiametricCollection diametric_collection = (DiametricCollection)clazz.allocate();
        diametric_collection.init((List)value);
        return diametric_collection;
    }

    public DiametricCollection(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    void init(Object obj) {
        if ((obj instanceof APersistentVector) ||
                (obj instanceof LazySeq) ||
                (obj instanceof PersistentVector.ChunkedSeq) ||
                (obj instanceof BlockingQueue)) {
            this.vector_or_seq = (List)obj;
        } else {
            throw new RuntimeException("Wrong type of query result");
        }
        common = new DiametricCommon();
    }

    Object toJava() {
        return vector_or_seq;
    }

    @JRubyMethod(meta=true)
    public static IRubyObject wrap(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        try {
            clojure.lang.PersistentVector value =
                    (clojure.lang.PersistentVector)arg.toJava(clojure.lang.PersistentVector.class);
            return DiametricCollection.getDiametricCollection(context, (List)value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(meta=true)
    public static IRubyObject be_lazy(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        try {
            clojure.lang.PersistentVector v =
                    (clojure.lang.PersistentVector)arg.toJava(clojure.lang.PersistentVector.class);
            Var var = DiametricService.getFn("clojure.core", "take");
            Object value = var.invoke(100, v);
            return DiametricCollection.getDiametricCollection(context, (List)value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), vector_or_seq);
    }

    @JRubyMethod(name="&")
    public IRubyObject op_and(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod(name="-")
    public IRubyObject op_diff(ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof List)) {
            throw context.getRuntime().newRuntimeError("argument should be array");
        }
        List other = (List)arg;
        try {
            Var two_arrays_diff_fn = null;
            if (DiametricService.fnMap.containsKey("two-arrays-diff")) {
                two_arrays_diff_fn = DiametricService.fnMap.get("two-arrays-diff");
            } else {
                Var var = DiametricService.getFn("clojure.core", "load-string");
                String fn =
                        "(defn two-arrays-diff [this other]\n" +
                        "  (let [f (fn [ary n] (remove (partial = n) ary))]\n"+
                        "    (reduce f this other)))";
                two_arrays_diff_fn = (Var)var.invoke(fn);
                DiametricService.fnMap.put("two-arrays-diff", two_arrays_diff_fn);
            }
            Object value = two_arrays_diff_fn.invoke(vector_or_seq, other);
            return DiametricCollection.getDiametricCollection(context, (List)value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name="*")
    public IRubyObject op_times(ThreadContext context, IRubyObject arg) {
        if (arg instanceof RubyFixnum) {
            try {
                Var append_n_times_fn = null;
                if (DiametricService.fnMap.containsKey("append-n-times")) {
                    append_n_times_fn = DiametricService.fnMap.get("append-n-times");
                } else {
                    Var var = DiametricService.getFn("clojure.core", "load-string");
                    append_n_times_fn = (Var)var.invoke("(defn append-n-times [n array] (reduce concat (replicate n array)))");
                    DiametricService.fnMap.put("append-n-times", append_n_times_fn);
                }
                Integer n = (Integer)arg.toJava(Integer.class);
                Object value = append_n_times_fn.invoke(n, vector_or_seq);
                return DiametricCollection.getDiametricCollection(context, (List)value);
            } catch (Throwable t) {
                throw context.getRuntime().newRuntimeError(t.getMessage());
            }
        } else if (arg instanceof RubyString) {
            return join(context, arg);
        } else {
            throw context.getRuntime().newArgumentError("argument should be either String or Fixnum");
        }
    }

    @JRubyMethod(name="+")
    public IRubyObject op_plus(ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof List)) {
            throw context.getRuntime().newRuntimeError("argument should be array");
        }
        List other = (List)arg;
        try {
            Var var = DiametricService.getFn("clojure.core", "concat");
            Object value = var.invoke(vector_or_seq, other);
            return DiametricCollection.getDiametricCollection(context, (List)value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(name="<<")
    public IRubyObject op_append(ThreadContext context) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(name="<=>")
    public IRubyObject op_cmp(ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof List)) return context.getRuntime().getNil();
        List other = (List)arg;
        try {
            Var var = DiametricService.getFn("clojure.core", "compare");
            Integer value = (Integer)var.invoke(vector_or_seq, other);
            return context.getRuntime().newFixnum(value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
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
        if (index_or_range instanceof RubyFixnum) {
            Long index = (Long)index_or_range.toJava(Long.class);
            return commonArefIndex(context, index);
        } else if (index_or_range instanceof RubyRange) {
            RubyRange range = (RubyRange)index_or_range;
            Long start = (Long)range.first(context).toJava(Long.class);
            Long last = (Long)range.last(context).toJava(Long.class);
            // subvec returns from 'start' to element (- end 1)
            if (range.exclude_end_p().isTrue()) {
                return commonAref(context, start, null, last);
            } else {
                return commonAref(context, start, null, last + 1);
            }
        } else {
            throw context.getRuntime().newArgumentError("wrong argument");
        }
    }

    private IRubyObject aref(ThreadContext context, IRubyObject arg0, IRubyObject arg1) {
        Long start = (Long)arg0.toJava(Long.class);
        Long length = (Long)arg1.toJava(Long.class);
        if (length < 0L) return context.getRuntime().getNil();
        try {
            return commonAref(context, start, length, null);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private IRubyObject commonArefIndex(ThreadContext context, Long index) {
        try {
            Var var = DiametricService.getFn("clojure.core", "nth");
            Object value = var.invoke(vector_or_seq, index);
            return DiametricUtils.convertJavaToRuby(context, value);
        } catch (Throwable t) {
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

    private IRubyObject commonAref(ThreadContext context, Long start, Long length, Long last) {
        try {
            Object value = null;
            if (vector_or_seq instanceof APersistentVector) {
                long end = length != null ? (start + length) : last;
                // checking a vector's length may be a costly operation.
                // allows to raise exception for the first time
                value = commonArefBySubvec(start, end);
            } else {
                // negative drop doesn't raise exception
                // too big number for take doesn't raise exception
                if (start > (long)getCount()) return context.getRuntime().getNil();
                if (start == (long)getCount()) return context.getRuntime().newEmptyArray();
                if (start < 0L) start += (long)getCount();
                if (start < 0L) return context.getRuntime().getNil();
                if (length == null) length = last - start;
                value = commonArefByDropTake(start, length);
            }
            return DiametricCollection.getDiametricCollection(context, (List)value);
        } catch (Throwable t) {
            if (t instanceof IndexOutOfBoundsException) {
                return retryAref(context, start, length, last);
            }
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private Object commonArefBySubvec(Long start, Long end) {
        Var var = DiametricService.getFn("clojure.core", "subvec");
        // subvec returns from 'start' to element (- end 1)
        return var.invoke(vector_or_seq, start, end);
    }

    private Object commonArefByDropTake(Long start, Long length) {
        Var seq_subvec_fn = null;
        if (DiametricService.fnMap.containsKey("seq-subvec")) {
            seq_subvec_fn = DiametricService.fnMap.get("seq-subvec");
        } else {
            Var var = DiametricService.getFn("clojure.core", "load-string");
            seq_subvec_fn = (Var)var.invoke("(defn seq-subvec [seq start length] (take length (drop start seq)))");
            DiametricService.fnMap.put("seq-subvec", seq_subvec_fn);
        }
        return seq_subvec_fn.invoke(vector_or_seq, start, length);
    }

    private IRubyObject retryAref(ThreadContext context, Long start, Long length, Long last) {
        // now, check the vector's length
        if (start > (long)getCount()) return context.getRuntime().getNil();
        if (start == (long)getCount()) return context.getRuntime().newEmptyArray();
        if (start < 0L) start += (long)getCount();
        if (start < 0L) return context.getRuntime().getNil();

        long end = length != null ? (start + length) : last;
        end = (end <= (long)getCount()) ? end : (long)getCount();
        return commonAref(context, start, null, end);
    }

    @JRubyMethod
    public IRubyObject assoc(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not yet supported. Might be implented later depends on datomic queries.");
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
            return common.collect(context, block, vector_or_seq.iterator());
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
            Var var = DiametricService.getFn("clojure.core", "remove");
            Var nil_p = DiametricService.getFn("clojure.core", "nil?");
            LazySeq value = (LazySeq) var.invoke(nil_p, vector_or_seq);
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
            return common.count(context, block, vector_or_seq.iterator());
        } else {
            return context.getRuntime().newFixnum(getCount());
        }
    }

    @JRubyMethod(required = 1)
    public IRubyObject count(ThreadContext context, IRubyObject arg, Block block) {
        if (block.isGiven()) {
            throw context.getRuntime().newArgumentError("given block not used");
        } else {
            return common.count(context, arg, vector_or_seq);
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
        return common.drop_or_take(context, n, vector_or_seq);
    }

    @JRubyMethod(name={"drop_while", "take_while"})
    public IRubyObject drop_while(ThreadContext context, Block block) {
        if (block.isGiven()) {
            return common.drop_while(context, block, vector_or_seq.iterator());
        } else {
            return this;
        }
    }

    @JRubyMethod
    public IRubyObject each(ThreadContext context, Block block) {
        if (block.isGiven()) {
            common.each(context, block, vector_or_seq.iterator());
        }
        return this;
    }

    @JRubyMethod
    public IRubyObject each_index(ThreadContext context, Block block) {
        if (block.isGiven()) {
            Iterator<Object> itr = vector_or_seq.iterator();
            Long index = 0L;
            while (itr.hasNext()) {
                itr.next();
                block.yield(context, context.getRuntime().newFixnum(index));
                index++;
            }
        }
        return this;
    }

    @JRubyMethod(name="empty?")
    public IRubyObject empty_p(ThreadContext context) {
        return common.empty_p(context, vector_or_seq);
    }

    @JRubyMethod(name={"eql?", "=="})
    public IRubyObject equal_p(ThreadContext context, IRubyObject arg) {
        if (arg.isNil()) return context.getRuntime().getFalse();
        Object other_vector = null;
        if (arg instanceof DiametricCollection) {
            other_vector = ((DiametricCollection)arg).toJava();
        } else if ((arg instanceof List) || (arg instanceof RubyArray)) {
            other_vector = arg;
        } else {
            return context.getRuntime().getFalse();
        }
        try {
            Var var = DiametricService.getFn("clojure.core", "=");
            if ((Boolean)var.invoke(vector_or_seq, other_vector)) {
                return context.getRuntime().getTrue();
            } else {
                return context.getRuntime().getFalse();
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    @JRubyMethod(required=1, optional=1)
    public IRubyObject fetch(ThreadContext context, IRubyObject args[], Block block) {
        Long index = (Long)args[0].toJava(Long.class);
        try {
            Var var = DiametricService.getFn("clojure.core", "nth");
            // counting vector size will be costly when the vector is way huge.
            // allows to raise exception for negative or too big index
            Object value = var.invoke(vector_or_seq, index);
            return DiametricUtils.convertJavaToRuby(context, value);
        } catch (Throwable t) {
            if (t instanceof IndexOutOfBoundsException) {
                return retryFetch(context, args, block, index);
            }
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    private IRubyObject retryFetch(ThreadContext context, IRubyObject[] args, Block block, Long index) {
        // now, counts vector size and adjust the index
        if (index > (long)getCount()) return handleError(context, args, block);
        if (index < 0L) index += (long)getCount();
        if (index < 0L) return handleError(context, args, block);

        try {
            Var var = DiametricService.getFn("clojure.core", "nth");
            Object value = var.invoke(vector_or_seq, index);
            return DiametricUtils.convertJavaToRuby(context, value);
        } catch (Throwable t) {
            if (t instanceof IndexOutOfBoundsException) {
                return handleError(context, args, block);
            }
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    private IRubyObject handleError(ThreadContext context, IRubyObject[] args, Block block) {
        if (block.isGiven()) {
            return block.yield(context, args[0]);
        } else if (args.length == 2) {
            return args[1];
        } else {
            throw context.getRuntime().newIndexError("Given index is out of vector size");
        }
    }
    
    @JRubyMethod
    public IRubyObject fill(ThreadContext context, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is a query result.");
    }
    
    @JRubyMethod(required=1, optional=2)
    public IRubyObject fill(ThreadContext context, IRubyObject args[], Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is a query result.");
    }
    
    @JRubyMethod(name={"find_index", "index"})
    public IRubyObject find_index(ThreadContext context, IRubyObject arg, Block unsed) {
        Object java_obj = DiametricUtils.convertRubyToJava(context, arg);
        int index = vector_or_seq.indexOf(java_obj);
        if (index >= 0) {
            return context.getRuntime().newFixnum(index);
        } else {
            return context.getRuntime().getNil();
        }
    }
    
    @JRubyMethod(name={"find_index", "index"})
    public IRubyObject find_index(ThreadContext context, Block block) {
        if (block.isGiven()) {
            Iterator<Object> itr = vector_or_seq.iterator();
            int index = 0;
            while (itr.hasNext()) {
                IRubyObject value = DiametricUtils.convertJavaToRuby(context, itr.next());
                if (block.yield(context, value).isTrue()) {
                    return context.getRuntime().newFixnum(index);
                }
                index++;
            }
            return context.getRuntime().getNil();
        } else {
            return this;
        }
    }

    @JRubyMethod
    public IRubyObject first(ThreadContext context) {
        return common.first(context, vector_or_seq);
    }
    
    @JRubyMethod
    public IRubyObject first(ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof RubyFixnum)) throw context.getRuntime().newArgumentError("argument should be a Fixnum");
        Long n = (Long)arg.toJava(Long.class);
        return common.first(context, n, vector_or_seq);
    }
    
    @JRubyMethod
    public IRubyObject flatten(ThreadContext context) {
        throw context.getRuntime().newRuntimeError("Not yet supported. Might be implented later depends on datomic queries.");
    }

    @JRubyMethod
    public IRubyObject flatten(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not yet supported. Might be implented later depends on datomic queries.");
    }

    @JRubyMethod(name="flatten!")
    public IRubyObject flatten_bang(ThreadContext context) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(name="flatten!")
    public IRubyObject flatten_bang(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(name="frozen?")
    public RubyBoolean frozen_p(ThreadContext context) {
        return (RubyBoolean)context.getRuntime().getTrue();
    }

    @JRubyMethod
    public IRubyObject hash(ThreadContext context) {
        return common.hash(context, vector_or_seq);
    }

    @JRubyMethod(name="include?")
    public IRubyObject include_p(ThreadContext context, IRubyObject arg) {
        try {
            Var include_p_fn = null;
            if (DiametricService.fnMap.containsKey("include?")) {
                include_p_fn = DiametricService.fnMap.get("include?");
            } else {
                Var var = DiametricService.getFn("clojure.core", "load-string");
                include_p_fn = (Var)var.invoke("(defn include? [v array] (some (partial = v) array))");
                DiametricService.fnMap.put("include?", include_p_fn);
            }
            Object java_object = DiametricUtils.convertRubyToJava(context, arg);
            Object result = include_p_fn.invoke(java_object, vector_or_seq);
            if ((result instanceof Boolean) && (Boolean)result) {
                return context.getRuntime().getTrue();
            } else {
                return context.getRuntime().getFalse();
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod(required=2, rest=true)
    public IRubyObject insert(ThreadContext context, IRubyObject[] args) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod
    public IRubyObject join(ThreadContext context) {
        try {
            Var var = DiametricService.getFn("clojure.string", "join");
            return context.getRuntime().newString((String)var.invoke(vector_or_seq));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject join(ThreadContext context, IRubyObject arg) {
        if (arg.isNil()) {
            return join(context);
        } else if (arg instanceof RubyString) {
            try {
                String separator = (String)arg.toJava(String.class);
                Var var = DiametricService.getFn("clojure.string", "join");
                return context.getRuntime().newString((String)var.invoke(separator, vector_or_seq));
            } catch (Throwable t) {
                throw context.getRuntime().newRuntimeError(t.getMessage());
            }
        }
        return context.getRuntime().getNil();    
    }

    @JRubyMethod(name={"keep_if", "select!"})
    public IRubyObject keep_if(ThreadContext context, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod
    public IRubyObject last(ThreadContext context) {
        try {
            Var var = DiametricService.getFn("clojure.core", "last");
            return DiametricUtils.convertJavaToRuby(context, var.invoke(vector_or_seq));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject last(ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof RubyFixnum)) {
            throw context.getRuntime().newArgumentError("Argument should be a Fixnum");
        }
        if (vector_or_seq.isEmpty()) return context.getRuntime().newEmptyArray();
        Long n = (Long)arg.toJava(Long.class);
        try {
            Var var = DiametricService.getFn("clojure.core", "take-last");
            return DiametricUtils.convertJavaToRuby(context, var.invoke(n, vector_or_seq));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject pack(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod
    public IRubyObject permutation(ThreadContext context, IRubyObject arg, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod
    public IRubyObject permutation(ThreadContext context, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod
    public IRubyObject pop(ThreadContext context) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod
    public IRubyObject pop(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(rest = true)
    public IRubyObject product(ThreadContext context, IRubyObject[] args, Block block) {
        throw context.getRuntime().newRuntimeError("Not supported. Perhaps, doesn't make sense for query result.");
    }

    @JRubyMethod
    public IRubyObject replace(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod(rest = true)
    public IRubyObject push(ThreadContext context, IRubyObject[] arg) {
        throw context.getRuntime().newRuntimeError("Not supported. Data is immutable.");
    }

    @JRubyMethod
    public IRubyObject rassoc(ThreadContext context, IRubyObject arg) {
        throw context.getRuntime().newRuntimeError("Not yet supported. Might be implented later depends on datomic queries.");
    }

    private int getCount() {
        if (count == null) {
            Var var = DiametricService.getFn("clojure.core", "count");
            count = (Integer)var.invoke(vector_or_seq);
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

    @JRubyMethod(name={"to_a", "to_ary"})
    public IRubyObject to_a(ThreadContext context) {
        return this;
    }

    @JRubyMethod(name={"to_s", "inspect"})
    public IRubyObject to_s(ThreadContext context) {
        return common.to_s(context, vector_or_seq);
    }
}
