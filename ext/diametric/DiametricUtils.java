package diametric;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

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
        if (value instanceof RubyString) return (Object)((RubyString)value).toJava(String.class);
        if (value instanceof RubyBoolean) return (Object)((RubyBoolean)value).toJava(Boolean.class);
        if (value instanceof RubyFixnum) return (Object)((RubyFixnum)value).toJava(Long.class);
        if (value instanceof RubyBignum) {
            RubyString svalue = (RubyString)((RubyBignum)value).to_s();
            java.math.BigInteger bivalue = new java.math.BigInteger((String)svalue.toJava(String.class));
            return (Object)bivalue;
        }
        if (value instanceof RubyFloat) return (Object)((RubyFloat)value).toJava(Double.class);
        if (value instanceof RubyTime) {
            RubyTime tmvalue = (RubyTime)value;
            return (Object)tmvalue.toJava(Date.class);
        }
        //System.out.println("NOT YET CONVERTED");
        //System.out.println("RESPONDSTO? TO_A:" + value.respondsTo("to_a"));
        if (value.respondsTo("to_a")) { // might be Set for cardinality many type
            RubyArray ruby_array = (RubyArray)RuntimeHelpers.invoke(context, value, "to_a");
            List<Object> list = new ArrayList<Object>();
            while (true) {
                IRubyObject element = ruby_array.shift(context);
                if (element.isNil()) break;
                list.add(DiametricUtils.convertRubyToJava(context, element));
            }
            return Collections.unmodifiableList(list);
        }
        if (value instanceof DiametricObject) {
            return ((DiametricObject)value).toJava();
        }
        return (Object)value.toJava(Object.class);
    }
   
    static IRubyObject convertJavaToRuby(ThreadContext context, Object value) {
        Ruby runtime = context.getRuntime();
        if (value instanceof String) return RubyString.newString(runtime, (String)value);
        if (value instanceof Boolean) return RubyBoolean.newBoolean(runtime, (Boolean)value);
        if (value instanceof Long) return RubyFixnum.newFixnum(runtime, (Long)value);
        if (value instanceof clojure.lang.Keyword) {
            return RubyString.newString(runtime, ((clojure.lang.Keyword)value).toString());
        }
        if (value instanceof java.math.BigInteger) return RubyBignum.newBignum(runtime, ((java.math.BigInteger)value).longValue());
        if (value instanceof Double) return RubyFloat.newFloat(runtime, (Double)value);
        if (value instanceof Date) return RubyTime.newTime(runtime, ((Date)value).getTime());
        if (value instanceof java.util.UUID) {
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::UUID");
            DiametricUUID diametric_uuid = (DiametricUUID)clazz.allocate();
            diametric_uuid.init((java.util.UUID)value);
            return diametric_uuid;
        }
        return JavaUtil.convertJavaToUsableRubyObject(runtime, value);
    }
}
