package diametric;

import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.BlockingQueue;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Diametric::Persistence::Connection")
public class DiametricConnection extends RubyObject {
    private static final long serialVersionUID = 3806301567154638371L;
    //conn should a datomic.Connection type
    private Object conn = null;

    //static IRubyObject constants(String key) {
    //    
    //}

    public DiametricConnection(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }

    void init(Object conn) {
        this.conn = conn;
    }

    Object toJava() {
        return conn;
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), conn);
    }

    @JRubyMethod
    public IRubyObject db(ThreadContext context) {
        try {
            Object database = DiametricService.getFn("datomic.api", "db").invoke(conn);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Database");
            DiametricDatabase diametric_database = (DiametricDatabase)clazz.allocate();
            diametric_database.init(database);
            return diametric_database;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject transact(ThreadContext context, IRubyObject arg) {
        try {
            List<Object> tx_data = DiametricUtils.convertRubyTxDataToJava(context, arg); // may raise exception
            if (tx_data == null) {
                throw context.getRuntime().newArgumentError("Argument should be Array or clojure.lang.PersistentVector");
            }

            //System.out.println("tx_data: " + tx_data.toString() + " class: " + tx_data.getClass().getCanonicalName());
            Object future = DiametricService.getFn("datomic.api", "transact").invoke(conn, tx_data);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::ListenableFuture");
            DiametricListenableFuture diametric_listenable = (DiametricListenableFuture)clazz.allocate();
            diametric_listenable.init(future);
            return diametric_listenable;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject transact_async(ThreadContext context, IRubyObject arg) {
        try {
            List<Object> tx_data = DiametricUtils.convertRubyTxDataToJava(context, arg); // my raise exception
            if (tx_data == null) {
                throw context.getRuntime().newArgumentError("Argument should be Array or clojure.lang.PersistentVector");
            }

            Object future = DiametricService.getFn("datomic.api", "transact-async").invoke(conn, tx_data);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::ListenableFuture");
            DiametricListenableFuture diametric_listenable = (DiametricListenableFuture)clazz.allocate();
            diametric_listenable.init(future);
            return diametric_listenable;
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject tx_report_queue(ThreadContext context) {
        try {
            java.util.concurrent.BlockingQueue<java.util.Map> queue =
                    (BlockingQueue<Map>) DiametricService.getFn("datomic.api", "tx-report-queue").invoke(conn);
            return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), queue);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    @JRubyMethod
    public IRubyObject gc_storage(ThreadContext context, IRubyObject arg) {
        if (!(arg.respondsTo("to_time"))) {
            throw context.getRuntime().newArgumentError("Wrong argument type");
        }
        RubyTime rubyTime = (RubyTime) RuntimeHelpers.invoke(context, arg, "to_time");
        Date olderThan = rubyTime.getJavaDate();
        try {
            DiametricService.getFn("datomic.api", "gc-strage").invoke(conn, olderThan);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError("Datomic error: " + t.getMessage());
        }
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject release(ThreadContext context) {
        try {
            DiametricService.getFn("datomic.api", "release").invoke(conn);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
        return context.getRuntime().getNil();
    }
}
