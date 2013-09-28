package diametric;

import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

public class DiametricService implements BasicLibraryService {

    @Override
    public boolean basicLoad(Ruby runtime) throws IOException {
        RubyModule diametric = runtime.defineModule("Diametric");
        RubyModule persistence = diametric.defineModuleUnder("Persistence");

        RubyModule diametric_peer = persistence.defineModuleUnder("Peer");
        diametric_peer.defineAnnotatedMethods(DiametricPeer.class);

        RubyClass connection = persistence.defineClassUnder("Connection", runtime.getObject(), CONNECTION_ALLOCATOR);
        connection.defineAnnotatedMethods(DiametricConnection.class);

        RubyClass uuid = persistence.defineClassUnder("UUID", runtime.getObject(), UUID_ALLOCATOR);
        uuid.defineAnnotatedMethods(DiametricUUID.class);

        RubyClass diametric_object = persistence.defineClassUnder("Object", runtime.getObject(), DIAMETRIC_OBJECT_ALLOCATOR);
        diametric_object.defineAnnotatedMethods(DiametricObject.class);

        RubyClass diametric_collection = persistence.defineClassUnder("Collection", runtime.getObject(), COLLECTION_ALLOCATOR);
        diametric_collection.defineAnnotatedMethods(DiametricCollection.class);

        RubyClass diametric_set = persistence.defineClassUnder("Set", runtime.getObject(), SET_ALLOCATOR);
        diametric_set.defineAnnotatedMethods(DiametricSet.class);

        RubyClass diametric_listenable = persistence.defineClassUnder("ListenableFuture", runtime.getObject(), LISTENABLE_ALLOCATOR);
        diametric_listenable.defineAnnotatedMethods(DiametricListenableFuture.class);

        RubyClass diametric_database = persistence.defineClassUnder("Database", runtime.getObject(), DATABASE_ALLOCATOR);
        diametric_database.defineAnnotatedMethods(DiametricDatabase.class);

        RubyClass diametric_entity = persistence.defineClassUnder("Entity", runtime.getObject(), ENTITY_ALLOCATOR);
        diametric_entity.defineAnnotatedMethods(DiametricEntity.class);

        RubyModule diametric_utils = persistence.defineModuleUnder("Utils");
        diametric_utils.defineAnnotatedMethods(DiametricUtils.class);

        setupClojureRT();

        return false;
    }

    public static final ObjectAllocator CONNECTION_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new DiametricConnection(runtime, klazz);
        }
    };

    public static final ObjectAllocator UUID_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new DiametricUUID(runtime, klazz);
        }
    };

    public static final ObjectAllocator DIAMETRIC_OBJECT_ALLOCATOR = new ObjectAllocator() {
        DiametricObject diametric_object = null;
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            if (diametric_object == null) diametric_object = new DiametricObject(runtime, klazz);
            try {
                return (DiametricObject) diametric_object.clone();
            } catch (CloneNotSupportedException e) {
                return new DiametricObject(runtime, klazz);
            }
        }
    };

    public static final ObjectAllocator COLLECTION_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new DiametricCollection(runtime, klazz);
        }
    };

    public static final ObjectAllocator SET_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new DiametricSet(runtime, klazz);
        }
    };

    public static final ObjectAllocator LISTENABLE_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new DiametricListenableFuture(runtime, klazz);
        }
    };

    public static final ObjectAllocator DATABASE_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new DiametricDatabase(runtime, klazz);
        }
    };

    public static final ObjectAllocator ENTITY_ALLOCATOR = new ObjectAllocator() {
        public IRubyObject allocate(Ruby runtime, RubyClass klazz) {
            return new DiametricEntity(runtime, klazz);
        }
    };

    private void setupClojureRT() {
        clojure.lang.RT.var("clojure.core", "require").invoke(clojure.lang.Symbol.intern("datomic.api"));
    }
}