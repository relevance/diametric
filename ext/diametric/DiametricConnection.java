package diametric;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyNil;
import org.jruby.RubyObject;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import datomic.Connection;
import datomic.Database;
import datomic.ListenableFuture;

@JRubyClass(name = "Diametric::Persistence::Connection")
public class DiametricConnection extends RubyObject {
    private static final long serialVersionUID = 3806301567154638371L;
    private Connection conn = null;

    public DiametricConnection(Ruby runtime, RubyClass klazz) {
        super(runtime, klazz);
    }
    
    void init(Connection conn) {
        this.conn = conn;
    }
    
    Connection toJava() {
        return conn;
    }

    @JRubyMethod
    public IRubyObject to_java(ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), conn);
    }
    
    @JRubyMethod
    public IRubyObject db(ThreadContext context) {
        Database database = conn.db();
        RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::Database");
        DiametricDatabase diametric_database = (DiametricDatabase)clazz.allocate();
        diametric_database.init(database);
        return diametric_database;
    }
    
    @JRubyMethod
    public IRubyObject transact(ThreadContext context, IRubyObject arg) {
        List<Object> tx_data = DiametricUtils.convertRubyTxDataToJava(context, arg);
        if (tx_data == null) {
            throw context.getRuntime().newArgumentError("Argument should be Array or clojure.lang.PersistentVector");
        }

        ListenableFuture<java.util.Map> future;
        try {
            future = conn.transact(tx_data);
            RubyClass clazz = (RubyClass)context.getRuntime().getClassFromPath("Diametric::Persistence::ListenableFuture");
            DiametricListenableFuture diametric_listenable = (DiametricListenableFuture)clazz.allocate();
            diametric_listenable.init(future);
            return diametric_listenable;
        } catch (Exception e) {
            context.getRuntime().newRuntimeError(e.getMessage());
        }
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject gc_storage(ThreadContext context, IRubyObject arg) {
        if (!(arg.respondsTo("to_time"))) {
            throw context.getRuntime().newArgumentError("Wrong argument type");
        }
        RubyTime rubyTime = (RubyTime) RuntimeHelpers.invoke(context, arg, "to_time");
        Date olderThan = rubyTime.getJavaDate();
        try {
            conn.gcStorage(olderThan);
        } catch (Exception e) {
            throw context.getRuntime().newRuntimeError("Datomic error: " + e.getMessage());
        }
        return context.getRuntime().getNil();
    }

    @JRubyMethod
    public IRubyObject release(ThreadContext context) {
        conn.release();
        return context.getRuntime().getNil();
    }
}
