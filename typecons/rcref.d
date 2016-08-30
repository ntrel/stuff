/* Written in the D programming language.
 * Copyright (c) 2016 by the D Language Foundation
 * Authors: Nick Treleaven, Walter Bright (RefCountedSlice)
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/** Memory-safe Reference Counted Slice.
 * Safety is enforced using a runtime check in RCRef's destructor.
 * 'scope' is commented out until DIP1000 support is stable. */


///
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

    alias get this;

    // Interesting fact #2: references to internals can be given away
    //scope
    private auto get() {
        return RCRef!T(payload, count);
    }
}

// Disable RC checking if bounds checking is disabled
version (D_NoBoundsChecks){}
else version = SafeRC;

// Ensure on destruction there's an independent RCO alive with longer lifetime
@safe struct RCRef(T)
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
        assert(count);
        // Ensure it's not just our +1 keeping the memory alive
        assert(*count > 1, "Invalid reference: " ~ RCRef.stringof);
        --*count;
    }

    //scope
    ref opIndex(size_t i) {
        return payload[i];
    }

    // ...
}

private @trusted checkAssert(lazy void ex)
{
    import core.exception, std.exception;
    assertThrown!AssertError(ex);
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
    fun(rc, rc[0]);
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
    gun(copy[0]);
    assert(*rc.count == 1);
    assert(rc[0] == 2);

    // call to fun is invalid, as internally rc[0] outlives rc
    checkAssert(fun(rc, rc[0]));
    assert(!rc.count);
    // Note: old rc heap memory will leak (we ignored an AssertError)
}
