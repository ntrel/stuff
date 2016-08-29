/* Written in the D programming language.
 * Copyright (c) 2016 by the D Language Foundation
 * Authors: Walter Bright, Nick Treleaven
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/


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
    auto opIndex(size_t i) @trusted {
        return RCRef!T(&payload[i], count);
    }

    // ...
}

// Ensure on destruction there's an independent RCO alive with longer lifetime
@safe struct RCRef(T)
{
private:
    T* pval;
    version(assert) uint* count;

    this(T* pval, uint* count = null)
    {
        this.pval = pval;
        version(assert)
        {
            this.count = count;
            ++*count;
        }
    }

public:
    @property //scope
    ref get()
    {
        return *pval;
    }

    alias get this;

    @disable this(this); // prevent copying

    ~this()
    {
        assert(count);
        // Ensure it's not just our RCO keeping the memory alive
        assert(*count > 1, "Invalid reference: " ~ RCRef.stringof);
        version(assert) --*count;
    }
}

// Safe without -release
@safe unittest
{
    alias RCS = RCSlice!int;
    static fun(T)(ref RCS rc, ref T ri)
    {
        rc = rc.init;
        ri++;
    }

    auto rc = RCS(1);
    {
        auto copy = rc;
        // Note: dmd wants lvalue for ref argument
        // dmd could call `get` implicitly via alias this
        fun(rc, rc[0].get);
        // refcount OK, checked when rc[0] temporary is destroyed
        assert(!rc.count);
        assert(copy[0] == 1);
    }
    rc = RCS(1);
    auto ri = rc[0];
    // Note: asserts when ri is destroyed
    fun(rc, ri);
    import core.exception, std.exception;
    ()@trusted {assertThrown!AssertError(ri.destroy);}();

    // Workaround: RCRef dtor doesn't expect ri to be destroyed
    ri.count = new uint(2);
}
