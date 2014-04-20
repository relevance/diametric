package diametric;

import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyNil;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.APersistentMap;
import clojure.lang.APersistentVector;
import clojure.lang.IPersistentSet;
import clojure.lang.Keyword;
import clojure.lang.LazySeq;
import clojure.lang.PersistentHashSet;
import clojure.lang.PersistentVector;
import clojure.lang.Var;
import datomic.Util;

@JRubyModule(name="Diametric::Persistence::Utils")
public class DiametricUtils {

    @JRubyMethod(meta=true)
    public static IRubyObject read_all(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        String filename = null;
        if (arg instanceof RubyString) {
            filename = DiametricUtils.rubyStringToJava(arg);
        } else {
            throw context.getRuntime().newArgumentError("Argument should be filename");
        }
        Reader reader = null;
        try {
            reader = new FileReader(filename);
            List list = (List) Util.readAll(reader);
            RubyArray array = RubyArray.newArray(context.getRuntime(), list.size());
            array.addAll(list);
            return array;
        } catch (Exception e) {
            throw context.getRuntime().newRuntimeError(e.getMessage());
        } finally {
            try {
                if (reader != null) reader.close();
            } catch (IOException e) {
                // no-op
            }
        }
    }

    @JRubyMethod(meta=true)
    public static IRubyObject read_string(ThreadContext context, IRubyObject klazz, IRubyObject arg) {
        if (!(arg instanceof RubyString)) {
            throw context.getRuntime().newArgumentError("Argument should be string");
        }
        RubyString ruby_string = (RubyString)arg;
        try {
            Var reader = DiametricService.getFn("clojure.core", "read-string");
            Object value = reader.invoke((String)ruby_string.asJavaString());
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Object");
            DiametricObject diametric_object = (DiametricObject)clazz.allocate();
            diametric_object.update(value);
            return diametric_object;
        } catch (Exception e) {
            throw context.getRuntime().newRuntimeError(e.getMessage());
        }
    }

    @JRubyMethod(meta=true, required=1, rest=true)
    public static IRubyObject fn(ThreadContext context, IRubyObject klazz, IRubyObject args[]) {
        try {
            Var list_fn = DiametricService.getFn("clojure.core", "list");
            List list = (List) list_fn.invoke();
            Var cons_fn = DiametricService.getFn("clojure.core", "conj");
            Var read_string_fn = DiametricService.getFn("clojure.core", "read-string");
            for (int i=args.length-1; i>-1; i--) {
                Object value = DiametricUtils.convertRubyToJava(context, args[i]);
                if (value instanceof RubyString) {
                    value = read_string_fn.invoke(value);
                }
                list = (List) cons_fn.invoke(list, value);
            }
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Fn");
            DiametricFn diametric_fn = (DiametricFn)clazz.allocate();
            diametric_fn.init(list);
            return diametric_fn;
        } catch (Throwable t) {
            throw context.getRuntime().newArgumentError(t.getMessage());
        }
    }

    static String rubyStringToJava(IRubyObject arg) {
        if (arg instanceof RubyString) {
            // TODO probably, we need to specify encoding.
            return (String) ((RubyString)arg).toJava(String.class);
        } else {
            return null;
        }
    }

    static Object convertRubyToJava(ThreadContext context, IRubyObject value) {
        if (value instanceof RubyNil) return null;
        if (value instanceof RubyString) {
            String str = (String)((RubyString)value).toJava(String.class);
            return getStringOrUUID(str);
        }
        if (value instanceof RubyBoolean) return (Object)((RubyBoolean)value).toJava(Boolean.class);
        if (value instanceof RubyFixnum) return (Object)((RubyFixnum)value).toJava(Long.class);
        if (value instanceof DiametricUUID) return ((DiametricUUID)value).getUUID();
        if (value instanceof RubyBignum) {
            RubyString svalue = (RubyString)((RubyBignum)value).to_s();
            java.math.BigInteger bivalue = new java.math.BigInteger((String)svalue.toJava(String.class));
            return (Object)bivalue;
        }
        if (value instanceof RubyFloat) return (Object)((RubyFloat)value).toJava(Double.class);
        if (value instanceof RubyTime) {
            RubyTime tmvalue = (RubyTime)value;
            return (Object)tmvalue.getJavaDate();
        }
        if (value instanceof RubySymbol) {
            // schema or data keyword
            RubyString edn_string = (RubyString)RuntimeHelpers.invoke(context, value, "to_s");
            return (Object)Keyword.intern((String)edn_string.asJavaString());
        }
        if (value.respondsTo("to_edn") && value.respondsTo("symbol")) {
            // EDN::Type::Symbol (query)
            RubyString edn_string = (RubyString)RuntimeHelpers.invoke(context, value, "to_edn");
            return (Object)clojure.lang.Symbol.intern((String)edn_string.asJavaString());
        }
        if (value.respondsTo("to_time")) {
            // DateTime or Date
            RubyTime tmvalue = (RubyTime)RuntimeHelpers.invoke(context, value, "to_time");
            return (Object)tmvalue.getJavaDate();
        }
        // needs to check Set since Set responses to "to_a"
        if (value.respondsTo("intersection")) {
            return getPersistentSet(context, value);
        }
        //System.out.println("NOT YET CONVERTED");
        //System.out.println("RESPONDSTO? TO_A:" + value.respondsTo("to_a"));
        //if (value.respondsTo("to_a")) { // might be Set for cardinality many type
        //    return getList(context, value);
        //}
        if (value instanceof DiametricObject) {
            return ((DiametricObject)value).toJava();
        }
        if (value instanceof DiametricFn) {
            return ((DiametricFn)value).toJava();
        }
        if (value instanceof DiametricFunction) {
            return ((DiametricFunction)value).toJava();
        }
        return (Object)value.toJava(Object.class);
    }

    static Object getStringOrUUID(String str) {
        try {
            return (Object)UUID.fromString(str);
        } catch (IllegalArgumentException e) {
            return (Object)str;
        }
    }

    static IPersistentSet getPersistentSet(ThreadContext context, IRubyObject value) {
        return PersistentHashSet.create((List)value.callMethod(context, "to_a"));
    }

    static List<Object> getList(ThreadContext context, IRubyObject value) {
        RubyArray ruby_array = (RubyArray)RuntimeHelpers.invoke(context, value, "to_a");
        List<Object> list = new ArrayList<Object>();
        while (true) {
            IRubyObject element = ruby_array.shift(context);
            if (element.isNil()) break;
            list.add(DiametricUtils.convertRubyToJava(context, element));
        }
        return Collections.unmodifiableList(list);
    }

    static IRubyObject convertJavaToRuby(ThreadContext context, Object value) {
        Ruby runtime = context.getRuntime();
        if (value == null) return context.getRuntime().getNil();
        if (value instanceof String) return RubyString.newString(runtime, (String)value);
        if (value instanceof Boolean) return RubyBoolean.newBoolean(runtime, (Boolean)value);
        if (value instanceof Long) return RubyFixnum.newFixnum(runtime, (Long)value);
        if (value instanceof clojure.lang.Keyword) {
            return RubyString.newString(runtime, ((clojure.lang.Keyword)value).toString());
        }
        if (value instanceof java.math.BigInteger) return RubyBignum.newBignum(runtime, ((java.math.BigInteger)value).longValue());
        if (value instanceof Double) return RubyFloat.newFloat(runtime, (Double)value);
        if (value instanceof Date) return RubyTime.newTime(runtime, ((Date)value).getTime());
        if (value instanceof Set) {
            return DiametricSet.getDiametricSet(context, (Set)value);
        }
        if ((value instanceof APersistentVector) ||
                (value instanceof LazySeq) ||
                (value instanceof PersistentVector.ChunkedSeq)){
            return DiametricCollection.getDiametricCollection(context, (List)value);
        }
        if (value instanceof datomic.Entity) {
            return DiametricEntity.getDiametricEntity(context, value);
        }
        if (value instanceof java.util.UUID) {
            return DiametricUUID.getDiametricUUID(context, (java.util.UUID)value);
        }
        return JavaUtil.convertJavaToUsableRubyObject(runtime, value);
    }

    static PersistentVector convertRubyTxDataToJava(ThreadContext context, IRubyObject arg) {
        if (arg instanceof RubyArray) {
            return fromRubyArray(context, (RubyArray)arg);
        } else {
            Object obj = arg.toJava(Object.class);
            if (obj instanceof clojure.lang.PersistentVector) {
                return (clojure.lang.PersistentVector)obj;
            }
        }
        return null;
    }

    static PersistentVector fromRubyArray(ThreadContext context, RubyArray ruby_array) {
        Var var = DiametricService.getFn("clojure.core", "vector");
        PersistentVector clj_tx_data = (PersistentVector)var.invoke();
        Var adder = DiametricService.getFn("clojure.core", "conj");
        for (int i=0; i<ruby_array.getLength(); i++) {
            Object element = ruby_array.get(i);
            if (element instanceof RubyHash) {
                APersistentMap map = fromRubyHash(context, (RubyHash)element);
                clj_tx_data = (PersistentVector)adder.invoke(clj_tx_data, map);
            } else if (element instanceof RubyArray) {
                PersistentVector vector = fromRubyArray(context, (RubyArray)element);
                clj_tx_data = (PersistentVector)adder.invoke(clj_tx_data, vector);
            } else if (element instanceof IRubyObject) {
                clj_tx_data =
                        (PersistentVector)adder.invoke(clj_tx_data, DiametricUtils.convertRubyToJava(context, (IRubyObject)element));
            } else if (element instanceof String) {
                clj_tx_data = (PersistentVector)adder.invoke(clj_tx_data, getStringOrUUID((String)element));
            } else {
                clj_tx_data = (PersistentVector)adder.invoke(clj_tx_data, element);
            }
        }
        return clj_tx_data;
    }

    private static APersistentMap fromRubyHash(ThreadContext context, RubyHash ruby_hash) {
        Var var = DiametricService.getFn("clojure.core", "hash-map");
        APersistentMap map = (APersistentMap)var.invoke();
        Var associator = DiametricService.getFn("clojure.core", "assoc");
        while (true) {
            IRubyObject pair = ruby_hash.shift(context);
            if (pair instanceof RubyNil) break;
            Object key = DiametricUtils.convertRubyToJava(context, ((RubyArray) pair).shift(context));
            Object value = DiametricUtils.convertRubyToJava(context, ((RubyArray) pair).shift(context));
            if (value instanceof RubyHash) {
                value = fromRubyHash(context, (RubyHash)value);
            } else if (value instanceof RubyArray) {
                value = fromRubyArray(context, (RubyArray)value);
            }
            map = (APersistentMap)associator.invoke(map, key, value);
        }
        return map;
    }
}
