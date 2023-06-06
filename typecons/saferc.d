import std.experimental.allocator;

@safe:

struct SafeRC(T)
{
    private struct Store
    {
        T payload;
        size_t count;
    }
    private Store* store;

    this(ref SafeRC that)
    {
        store = that.store;
        store.count++;
        writeln("now: ", store.count);
    }

    // helper used only when deref operator is used
    alias helper this;
    auto helper() => Helper(store);

    private struct Helper
    {
        private Store* store;
        ref opUnary(string op: "*")() return
        {
            store.count++;
            return store.payload;
        }
        ~this() { store.count--; }
    }

    ~this() @trusted
    {
        if (!store)
            return;
        if (--store.count > 0)
        {
            writeln("remaining: ", store.count);
            return;
        }
        writeln("freeing data: ", store.payload);
        theAllocator.dispose(store);
        store = null;
    }
}

SafeRC!T safeRC(T)(T val) @trusted
{
    typeof(return) rc;
    rc.store = theAllocator.make!(rc.Store)(val, 1);
    return rc;
}

import std.stdio;

void main()
{
    auto rc = safeRC(5);
    ++*rc;
    auto r2 = rc;
    ++*r2;
    r2.destroy;
    assert(*rc == 7);
    writeln(*rc);
}
