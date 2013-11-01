package diametric;

import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
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
import org.jruby.RubyTime;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.APersistentVector;
import clojure.lang.IPersistentSet;
import clojure.lang.LazySeq;
import clojure.lang.PersistentHashSet;
import clojure.lang.PersistentVector;
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
            try {
                return (Object)UUID.fromString(str);
            } catch (IllegalArgumentException e) {
                return (Object)str;
            }
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
        if (value.respondsTo("to_a")) { // might be Set for cardinality many type
            return getList(context, value);
        }
        if (value instanceof DiametricObject) {
            return ((DiametricObject)value).toJava();
        }
        return (Object)value.toJava(Object.class);
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
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Set");
            DiametricSet diametric_set = (DiametricSet)clazz.allocate();
            diametric_set.init((Set)value);
            return diametric_set;
        }
        if ((value instanceof APersistentVector) ||
                (value instanceof LazySeq) ||
                (value instanceof PersistentVector.ChunkedSeq)){
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection diametric_collection = (DiametricCollection)clazz.allocate();
            diametric_collection.init((List)value);
            return diametric_collection;
        }
        if (value instanceof java.util.UUID) {
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::UUID");
            DiametricUUID diametric_uuid = (DiametricUUID)clazz.allocate();
            diametric_uuid.init((java.util.UUID)value);
            return diametric_uuid;
        }
        return JavaUtil.convertJavaToUsableRubyObject(runtime, value);
    }

    static List<Object> convertRubyTxDataToJava(ThreadContext context, IRubyObject arg) {
        List<Object> tx_data = null;
        if (arg instanceof RubyArray) {
            tx_data = fromRubyArray(context, arg);
        } else {
            Object obj = arg.toJava(Object.class);
            if (obj instanceof clojure.lang.PersistentVector) {
                tx_data = (clojure.lang.PersistentVector)obj;
            }
        }
        return tx_data;
    }

    private static List<Object> fromRubyArray(ThreadContext context, IRubyObject arg) {
        RubyArray ruby_tx_data = (RubyArray)arg;
        List<Object> java_tx_data = new ArrayList<Object>();
        for (int i=0; i<ruby_tx_data.getLength(); i++) {
            IRubyObject element = (IRubyObject) ruby_tx_data.get(i);
            if (element instanceof RubyHash) {
                RubyHash ruby_hash = (RubyHash) element;
                Map<Object, Object> keyvals = new HashMap<Object, Object>();
                while (true) {
                    IRubyObject pair = ruby_hash.shift(context);
                    if (pair instanceof RubyNil) break;
                    Object key = DiametricUtils.convertRubyToJava(context, ((RubyArray) pair).shift(context));
                    Object value = DiametricUtils.convertRubyToJava(context, ((RubyArray) pair).shift(context));
                    keyvals.put(key, value);
                }
                java_tx_data.add(Collections.unmodifiableMap(keyvals));
            } else if (element instanceof RubyArray) {
                RubyArray ruby_array = (RubyArray) element;
                List<Object> keyvals = new ArrayList<Object>();
                while (true) {
                    IRubyObject ruby_element = ruby_array.shift(context);
                    if (ruby_element instanceof RubyNil) break;
                    Object key_or_value = DiametricUtils.convertRubyToJava(context, ruby_element);
                    keyvals.add(key_or_value);
                }
                java_tx_data.add(Collections.unmodifiableList(keyvals));
            } else {
                continue;
            }
        }
        return java_tx_data;
    }
}
