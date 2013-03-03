package diametric;

import java.util.Date;

import org.jruby.Ruby;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

public class DiametricUtils {
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
       if (value instanceof DiametricObject) {
           Object java_object= ((DiametricObject)value).toJava();
           return java_object;
       }
       return (Object)value.toJava(Object.class);
   }
   
   static IRubyObject convertJavaToRuby(ThreadContext context, Object value) {
       Ruby runtime = context.getRuntime();
       if (value instanceof String) return RubyString.newString(runtime, (String)value);
       if (value instanceof Boolean) return RubyBoolean.newBoolean(runtime, (Boolean)value);
       if (value instanceof Long) return RubyFixnum.newFixnum(runtime, (Long)value);
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
