/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/


/** Static array wrapper which only escapes its pointer in @system code.
 * This means converting to a slice is also @system, and because
 * static arrays implicity convert to a slice, converting to a static array
 * is @system as well (although then it can be implicit). */
struct StaticArray(SA : T[n], T, size_t n)
{
    private T[n] data;

    ///
    enum length = n;

    ///
    alias StaticArray_get this;

    ref T[n] StaticArray_get() @property @system return
    {
        return data;
    }

    ///
    void opAssign()(auto ref T[n] sa)
    {
        data = sa;
    }

    ///
    bool opEquals(inout(T)[] s) {return data == s;}

    ///
    ref opIndex(size_t n) return {return data[n];}

    ///
    int opApply(scope int delegate(size_t, ref T) @safe fun)
    {
        foreach (i, e; data)
            if (fun(i, e)) return 1;
        return 0;
    }

    ///
    T[] dup(size_t start = 0, size_t end = n) {return data[start..end].dup;}
    ///
    immutable(T)[] idup(size_t start = 0, size_t end = n) {return data[start..end].idup;}
}

///
@safe unittest
{
    alias SA = StaticArray!(int[2]);
    auto sa = SA();
    int[2] arr;

    static assert(sa.length == 2);
    static assert(!__traits(compiles, arr = sa));
    static assert(!__traits(compiles, arr = SA()));
    static assert(!__traits(compiles, sa.ptr));
    static assert(!__traits(compiles, {int[] s = sa[];}));

    arr = [1, 2];
    assert(sa == [0, 0]);
    sa = arr;
    assert(sa == [1, 2]);

    sa[0] = 3;
    assert(sa[0] == 3);
    assert(sa == [3, 2]);
    sa = [5, 6];
    assert(sa == [5, 6]);
    assert(sa == sa.dup);
    assert(sa == sa.idup(0, 2));
    assert(sa.dup(1) == [6]);

    foreach (i, e; sa)
        assert(sa[i] == e);

    ()@trusted {
        // implicit conversion to int[2] in @system code
        arr = SA();
        int[] invalid = SA(); // due to compiler allowing implicit slicing of rvalue int[2]
        int* p = sa.ptr;
        assert(p is sa[].ptr);
        // Slice!int converts to int[] in @system code:
        int[] s = sa[];
        s = sa; // implicit slicing of int[2]
    }();
}

