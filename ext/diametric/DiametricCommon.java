package diametric;

import java.util.Iterator;

import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import clojure.lang.PersistentVector;
import clojure.lang.Var;

class DiametricCommon {
    IRubyObject collect(ThreadContext context, Block block, Iterator<Object> itr) {
        RubyArray ary = context.getRuntime().newArray();
        while (itr.hasNext()) {
            IRubyObject next = DiametricUtils.convertJavaToRuby(context, itr.next());
            ary.callMethod(context, "<<", block.yield(context, next));
        }
        return ary;
    }

    IRubyObject count(ThreadContext context, IRubyObject arg, Object target) {
        try {
            Var count_value_fn = null;
            if (DiametricService.fnMap.containsKey("count-value")) {
                count_value_fn = DiametricService.fnMap.get("count-value");
            } else {
                Var var = DiametricService.getFn("clojure.core", "load-string");
                count_value_fn = (Var)var.invoke("(defn count-value [v array] (count (filterv (partial = v) array)))");
                DiametricService.fnMap.put("count-value", count_value_fn);
            }
            Object value = DiametricUtils.convertRubyToJava(context, arg);
            return context.getRuntime().newFixnum((Integer)count_value_fn.invoke(value, target));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    IRubyObject count(ThreadContext context, Block block, Iterator<Object> itr) {
        Long count = 0L;
        while (itr.hasNext()) {
            IRubyObject next = DiametricUtils.convertJavaToRuby(context, itr.next());
            if (block.yield(context, next).isTrue()) {
                count++;
            }
        }
        return context.getRuntime().newFixnum(count);
    }

    IRubyObject empty_p(ThreadContext context, Object target) {
        try {
            Var var = DiametricService.getFn("clojure.core", "empty?");
            if ((Boolean)var.invoke(target)) {
                return context.getRuntime().getTrue();
            } else {
                return context.getRuntime().getFalse();
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    IRubyObject drop_or_take(ThreadContext context, Long n, Object target) {
        try {
            Var drop_or_take_fn = null;
            if (DiametricService.fnMap.containsKey("drop-or-take")) {
                drop_or_take_fn = DiametricService.fnMap.get("drop-or-take");
            } else {
                Var var = DiametricService.getFn("clojure.core", "load-string");
                drop_or_take_fn = (Var)var.invoke("(defn drop-or-take [n target] (apply vector (drop n target)))");
                DiametricService.fnMap.put("drop-or-take", drop_or_take_fn);
            }
            PersistentVector value = (PersistentVector)drop_or_take_fn.invoke(n, target);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
            ruby_collection.init(value);
            return ruby_collection;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    IRubyObject drop_while(ThreadContext context, Block block, Iterator<Object> itr) {
        RubyArray ary = context.getRuntime().newArray();
        while (itr.hasNext()) {
            IRubyObject next = DiametricUtils.convertJavaToRuby(context, itr.next());
            if (block.yield(context, next).isTrue()) {
                continue;
            } else {
                ary.callMethod(context, "<<", next);
                break;
            }
        }
        while (itr.hasNext()) {
            ary.callMethod(context, "<<", DiametricUtils.convertJavaToRuby(context, itr.next()));
        }
        return ary;
    }

    void each(ThreadContext context, Block block, Iterator<Object> itr) {
        while (itr.hasNext()) {
            IRubyObject next = DiametricUtils.convertJavaToRuby(context, itr.next());
            block.yield(context, next);
        }
    }

    IRubyObject first(ThreadContext context, Object target) {
        try {
            Var var = DiametricService.getFn("clojure.core", "first");
            return DiametricUtils.convertJavaToRuby(context, var.invoke(target));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    IRubyObject first(ThreadContext context, Long n, Object target) {
        try {
            Var first_n_fn = null;
            if (DiametricService.fnMap.containsKey("first-n")) {
                first_n_fn = DiametricService.fnMap.get("first-n");
            } else {
                Var var = DiametricService.getFn("clojure.core", "load-string");
                first_n_fn = (Var)var.invoke("(defn first-n [n target] (apply vector (take n target)))");
                DiametricService.fnMap.put("first-n", first_n_fn);
            }
            PersistentVector value = (PersistentVector)first_n_fn.invoke(n, target);
            RubyClass clazz = (RubyClass) context.getRuntime().getClassFromPath("Diametric::Persistence::Collection");
            DiametricCollection ruby_collection = (DiametricCollection)clazz.allocate();
            ruby_collection.init(value);
            return ruby_collection;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
    
    IRubyObject hash(ThreadContext context, Object target) {
        try {
            Var var = DiametricService.getFn("clojure.core", "hash");
            Integer hash_value = (Integer)var.invoke(target);
            return context.getRuntime().newFixnum(hash_value);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    IRubyObject to_s(ThreadContext context, Object target) {
        try {
            Var to_s_fn = null;
            if (DiametricService.fnMap.containsKey("to-s")) {
                to_s_fn = DiametricService.fnMap.get("to-s");
            } else {
                Var var = DiametricService.getFn("clojure.core", "load-string");
                String fn = "(defn to-s [coll] (str (reduce str \"[\" (interpose \", \" coll)) \"]\"))";
                to_s_fn = (Var)var.invoke(fn);
                DiametricService.fnMap.put("to-s", to_s_fn);
            }
            return context.getRuntime().newString((String)to_s_fn.invoke(target));
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
}
