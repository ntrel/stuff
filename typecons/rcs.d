@safe struct RCSlice(T) {
private:
    T[] payload;
    uint* count;
    
    version(assert)
    bool checkLive(T* ptr) {
        assert(payload.ptr);
        const pd = ptr - payload.ptr;
        return pd >= 0 && pd < payload.length;
    }
    
public:
    this(size_t initialSize) {
        payload = new T[initialSize];
        count = new size_t;
        *count = 1;
    }

    this(this) {
        if (count) ++*count;
    }

    // Prevent reassignment as references to payload may still exist
    @system opAssign(RCSlice rhs) {
        this.__dtor();
        payload = rhs.payload;
        count = rhs.count;
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
    auto opIndex(size_t i) @trusted {
        return TempRef!T(&payload[i], &this.checkLive);
    }

    // ...
}

// Prevent premature destruction as references to payload may still exist
// (defined in object.d)
@system void destroy(T)(ref RCSlice!T rcs);

@safe struct TempRef(T)
{
private:
    T* pval;
    version(assert)
    bool delegate(T*) checkLive;
    
    @property //scope
    ref get()
    {
        assert(checkLive(pval), "Invalid reference:" ~ T.stringof);
        return *pval;
    }

public:
    alias get this;
    @disable this(this); // prevent copying & move?
}

@safe unittest
{
    alias RCS = RCSlice!int;
    static fun(ref RCS rc, ref int ri)
    {
        //rc = rc.init; // Error: can't call opAssign in @safe code
        //rc.destroy;   // Error: can't call destroy(RCS) in @safe code
        ri++;         // would have been unsafe
    }
    auto rc = RCS(1);
    fun(rc, rc[0]);
    assert(rc[0] == 1);
}
