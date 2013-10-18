package diametric;

import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.jruby.RubyArray;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.RT;
import clojure.lang.Var;

class DiametricCommon {
    static Map<String, Var> fnMap = null;
    
    static Var getFn(String namespace, String fn) {
        if (fnMap == null) {
            fnMap = new HashMap<String, Var>();
            Collections.synchronizedMap(fnMap);
        }
        String fullname = namespace + "/" + fn;
        if (fnMap.containsKey(fullname)) {
            return fnMap.get(fullname);
        } else {
            Var var = RT.var(namespace, fn);
            fnMap.put(fullname, var);
            return var;
        }
    }
    
    static RubyArray collect(ThreadContext context, Block block, Iterator<Object> itr, RubyArray ary) {
        try {
            while (itr.hasNext()) {
                IRubyObject next = DiametricUtils.convertJavaToRuby(context, itr.next());
                ary.callMethod(context, "<<", block.yield(context, next));
            }
            return ary;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }

    }
    
    static Integer count(ThreadContext context, Object value, Object target) {
        Var count_value_fn = null;
        if (DiametricCommon.fnMap.containsKey("count-value")) {
            count_value_fn = DiametricCommon.fnMap.get("count-value");
        } else {
            Var var = DiametricCommon.getFn("clojure.core", "load-string");
            count_value_fn = (Var)var.invoke("(defn count-value [v array] (count (filterv (partial = v) array)))");
            DiametricCommon.fnMap.put("count-value", count_value_fn);
        }
        try {
            return (Integer)count_value_fn.invoke(value, target);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    static Integer count(ThreadContext context, Block block, Iterator<Object> itr) {
        Integer count = 0;
        synchronized (count) {
            while (itr.hasNext()) {
                IRubyObject next = DiametricUtils.convertJavaToRuby(context, itr.next());
                if (block.yield(context, next).isTrue()) {
                    count++;
                }
            }
            return count;
        }
    }

    static Boolean empty_p(ThreadContext context, Object target) {
        Var var = getFn("clojure.core", "empty?");
        try {
            return (Boolean)var.invoke(target);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    static Object first(ThreadContext context, Object target) {
        Var var = getFn("clojure.core", "first");
        try {
            return var.invoke(target);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    static String to_s(ThreadContext context, Object target) {
        Var var = getFn("clojure.core", "str");
        try {
            return (String)var.invoke(target);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
}
