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
    bool opEquals(T[] s) {return data == s;}

    ///
    ref opIndex(size_t n) return {return data[n];}

    ///
    Slice!T opSlice()
    {
        return data[].slice;
    }
}

/** Immovable, non-copyable slice.
 * Also useful to force tuple unpacking on foreach(...; Tuple[]) */
struct Slice(T)
{
    private T[] data;

    ///
    alias Slice_get this;

    ref T[] Slice_get() @property @system return
    {
        return data;
    }

    // TODO: make std.algorithm.move respect this
    Slice move() @disable;
    this(this) @disable;

    import std.range.primitives;
    ///
    bool empty() @property {return data.empty;}
    ///
    auto ref front() @property return {return data.front;}
    ///
    void popFront() {data.popFront;}

    ///
    T[] dup() {return data.dup;}
    ///
    immutable(T)[] idup() {return data.idup;}

    ///
    void opAssign(T[] s)
    {
        data[] = s;
    }

    ///
    bool opEquals(T[] s) {return data == s;}
}

/// ditto
Slice!T slice(T)(T[] s)
{
    return Slice!T(s);
}

///
@safe unittest
{
    alias SA = StaticArray!(int[2]);
    auto sa = SA();
    int[2] arr = [1, 2];

    static assert(sa.length == 2);
    static assert(!__traits(compiles, arr = sa));
    static assert(!__traits(compiles, arr = SA()));
    static assert(!__traits(compiles, sa.ptr));
    static assert(!__traits(compiles, {int[] s = sa[];}));

    assert(sa == [0, 0]);
    sa = arr;
    assert(sa == [1, 2]);
    arr[0] = 3;
    sa[] = arr; // implicit slicing of int[2]
    assert(sa[0] == 3);
    sa[1] = 4;
    assert(sa == [3, 4]);
    sa[] = [5, 6];
    assert(sa[] == [5, 6]);

    ()@trusted{
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

