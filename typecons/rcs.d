@safe struct RCSlice(T) {
    private T[] payload;
    private uint* count;

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
    //~ scope
    ref T opIndex(size_t i) {
        return payload[i];
    }

    // ...
}

// Prevent premature destruction as references to payload may still exist
// (defined in object.d)
@system void destroy(T)(ref RCSlice!T rcs);

@safe unittest
{
    alias RCS = RCSlice!int;
    static fun(ref RCS rc, ref int ri)
    {
        rc = rc.init; // Error: can't call opAssign in @safe code
        rc.destroy;   // Error: can't call destroy(RCS) in @safe code
        ri++;         // would have been unsafe
    }
    auto rc = RCS(1);
    fun(rc, rc[0]);
    assert(rc[0] == 1);
}
