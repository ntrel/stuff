//~ import std.stdio;

@safe struct RCSlice(T) {
private:
    T[] payload;
    uint* count;
    
public:
    this(size_t initialSize) {
        payload = new T[initialSize];
        count = new size_t;
        *count = 1;
    }

    this(this) {
        if (count) ++*count;
    }

    void opAssign(RCSlice rhs) {
        this.__dtor();
        payload = rhs.payload;
        count = rhs.count;
        if (count)
            ++*count;
    }

    // Interesting fact #1: destructor can be @trusted
    @trusted ~this() {
        if (count && !--*count) {
            delete payload;
            delete count;
        }
    }

    // Interesting fact #2: references to internals can be given away
    //scope
    auto opIndex(size_t i) @trusted @nogc {
        return TempRef!T(&payload[i], &payload);
    }

    // ...
}

@safe struct TempRef(T)
{
private:
    T* pval;
    version(assert) T[]* pslice;
    
    @property //scope
    ref get()
    {
        assert(checkLive(), "Invalid reference:" ~ T.stringof);
        return *pval;
    }

    version(assert)
    bool checkLive() {
        const payload = *pslice;
        const pd = pval - payload.ptr;
        return payload.ptr && pd >= 0 && pd < payload.length;
    }
    
public:
    alias get this;
    @disable this(this); // prevent copying & move?
}

@safe unittest
{
    alias RCS = RCSlice!int;
    static fun(T)(ref RCS rc, ref T ri)
    {
        rc = rc.init;
        ri++;   // runtime error?
    }
    auto rc = RCS(1);
    //fun(rc, rc[0].get); // unsafe T=int, checkLive called too early
    auto ri = rc[0]; // need lvalue for ref argument
    fun(rc, ri);
    assert(rc[0] == 1);
}
