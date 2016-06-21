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

    enum length = n;

    alias StaticArray_get this;

    ref T[n] StaticArray_get() @property @system return
    {
        return data;
    }

    ///
    void opAssign(ref T[n] sa)
    {
        data = sa;
    }
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
    static assert(!__traits(compiles, sa[]));
    static assert(!__traits(compiles, sa.ptr));

    ()@trusted{
        arr = SA();
        int[] invalid = SA();
        int[] s2 = sa[];
        int* p = sa.ptr;
        assert(p is sa.data.ptr);
    }();

    sa = arr;
}

