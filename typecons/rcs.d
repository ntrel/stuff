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
    //scope
    auto opIndex(size_t i) @trusted {
        return TempRef!T(&payload[i], this);
    }

    // ...
}

@safe struct TempRef(T)
{
private:
    T* pval;
    version(assert) RCSlice!T rcs;
    
    void checkRef()
    {
        // Ensure it's not just our rcs keeping the memory alive
        assert(*rcs.count > 1, "Invalid reference: " ~ RCSlice!T.stringof);
    }
    
public:
    @property //scope
    ref get()
    {
        // Detect invalid reference earlier in case TempRef lvalue is passed by ref
        checkRef;
        return *pval;
    }

    alias get this;
    @disable this(this); // prevent copying
    
    ~this()
    {
        checkRef;
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
    // Note: asserts earlier on ri++ line in fun instead of when ri is destroyed
    fun(rc, ri);
}
