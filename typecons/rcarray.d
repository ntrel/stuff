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
    
    @property data() {return _data.ptr;}
}

///
@safe struct RCSlice(T) {
private:
    RCMem!T* rc;
    size_t length;
    
    @property count() {return rc ? &rc.count : null;}

public:
    import core.stdc.stdlib : malloc, free;
    import core.exception : RangeError;

    this(size_t initialSize) @trusted {
        rc = cast(RCMem!T*) malloc(RCMem!T.sizeof + T.sizeof * initialSize);
        rc.count = 1;
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
        version (D_NoBoundsChecks){}
        else if (i >= length) throw new RangeError;
        return rc.data[i];
    }

    ref T unsafeItems(size_t i) @system {
        version (D_NoBoundsChecks){}
        else if (i >= length) throw new RangeError;
        return rc.data[i];
    }

    // Interesting fact #2: references to internals can be given away
    //scope
    version(None)
    private auto items() {
        return RCRef!T(payload, count);
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
        assert(count, "Attempting to destroy an invalid " ~ RCRef.stringof);
        // Ensure it's not just our +1 keeping the memory alive
        import core.exception;
        if (*count <= 1)
            throw new AssertError("Invalid reference: " ~ RCRef.stringof,
                __FILE__, __LINE__);
        --*count;
    }

    //scope
    ref opIndex(size_t i) {
        return payload[i];
    }

    // ...
}

private @trusted checkInvalidRef(lazy void ex)
{
    import core.exception, std.exception;
    assert(collectExceptionMsg!AssertError(ex) == "Invalid reference: RCRef!int");
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
    //fun(rc, rc.items[0]);
    // refcount OK due to copy
    // count checked above when rc.get temporary is destroyed
    assert(!rc.count);
    assert(copy[0] == 1);

    // nested references
    void gun(ref int ri)
    {
        import std.algorithm : move;
        rc = copy.move;
        assert(!copy.count);
        ri++;
    }
    //gun(copy.items[0]);
    assert(*rc.count == 1);
    assert(rc[0] == 2);

    // call to fun is invalid, as internally rc[0] outlives rc
    //checkInvalidRef(fun(rc, rc.items[0]));
    assert(!rc.count);
    // Note: old rc heap memory will leak (we ignored an AssertError)
}
