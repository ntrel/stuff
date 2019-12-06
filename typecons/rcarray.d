/* Written in the D programming language.
 * Copyright (c) 2016 by the D Language Foundation
 * Authors: Nick Treleaven, Walter Bright (RefCountedSlice)
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/** Memory-safe Reference Counted Slice.
 * Safety is enforced using a runtime check in RCRef's destructor.
 * Note: Runtime check is disabled if -noboundscheck is passed.
 * 'scope' is commented out until DIP1000 support is stable. */


struct RCMem(T)
{
    uint count;
    T[0] _data;
}

///
@safe struct RCSlice(T) {
private:
    RCMem!T* rc;
    size_t length;
    
    @property count() {return rc ? &rc.count : null;}
    
    @property data() @system
    {
        return rc._data.ptr[0..length];
    }
    
public:
    import core.stdc.stdlib : calloc, free;
    import core.exception : RangeError;

    this(size_t initialSize) @trusted {
        //rc = cast(RCMem!T*) malloc(RCMem!T.sizeof + T.sizeof * initialSize);
        rc = cast(RCMem!T*) calloc(1, RCMem!T.sizeof + T.sizeof * initialSize);
        rc.count = 1;
        length = initialSize;
    }

    this(this) {
        if (rc) ++rc.count;
    }

    void opAssign()(auto ref RCSlice rhs) {
        this = rhs;
        if (rc)
            ++rc.count;
    }

    // Interesting fact #1: destructor can be @trusted
    @trusted ~this() {
        if (rc && !--rc.count) {
            free(rc);
        }
    }

    T opIndex(size_t i) @trusted {
        return data[i];
    }

    @property T[] items() @system {
        return data;
    }

    //scope
    @property get() @trusted {
        return RCRef!T(data, &rc.count);
    }
}

// Disable RC checking if bounds checking is disabled
version (D_NoBoundsChecks){}
else version = SafeRC;

// Ensure on destruction there's an independent RCO alive with longer lifetime
private @safe
struct RCRef(T)
{
private:
    T[] payload;
    version(SafeRC) uint* count;

    this(T[] payload, uint* count = null)
    {
        this.payload = payload;
        version(SafeRC)
        {
            this.count = count;
            ++*count;
        }
    }

public:
    @disable this(this); // prevent copying
    @disable void opAssign(RCRef);

    version(SafeRC)
    ~this()
    {
        debug assert(count, RCRef.stringof ~ ": count is null");
        // Ensure it's not just our +1 keeping the memory alive
        assert(*count > 1, RCRef.stringof ~ ": no owner");
        --*count;
    }

    // Interesting fact #2: references to internals can be given away
    //scope
    ref opIndex(size_t i) {
        return payload[i];
    }

    // ...
}

private @trusted checkInvalidRef(lazy void ex)
{
    import core.exception, std.exception;
    assert(collectExceptionMsg!AssertError(ex) == "RCRef!int: no owner");
}

///
@safe unittest
{
    alias RCS = RCSlice!int;

    static fun(ref RCS rc, ref int ri)
    {
        rc = rc.init;
        ri++;
    }
    auto rc = RCS(1);
    auto copy = rc;
    assert(*rc.count == 2);

    assert(rc[0] == 0);
    static assert(!__traits(compiles, fun(rc, rc[0])));
    fun(rc, rc.get[0]);
    // refcount OK due to copy
    // count checked above when rc.get temporary is destroyed
    assert(!rc.count);
    assert(copy[0] == 1);

    // nested references
    void gun(ref int ri) @trusted //FIXME: why is move unsafe?
    {
        import std.algorithm : move;
        rc = copy.move;
        assert(!copy.count);
        ri++;
    }
    gun(copy.get[0]);
    assert(*rc.count == 1);
    assert(rc[0] == 2);

    // call to fun is invalid, as internally rc[0] outlives rc
    checkInvalidRef(fun(rc, rc.get[0]));
    assert(!rc.count);
    // Note: old rc heap memory will leak (we ignored an AssertError)
}
