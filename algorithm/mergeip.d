/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/// Merge in-place without allocating


import std.algorithm : find, min, swap;
import std.range.primitives;
debug import std.stdio : writeln, writefln;

version(Wrong)
void merge(T)(T[] left, T[] right) @nogc
    if (hasAssignableElements!(T[]))
{
    if (!right.length)
        return;
    debug writeln(left, right);

    // skip in place elements
    const r = right[0];
    left = left.find!(e => e > r);
    if (!left.length)
        return;

    // swap runs of elements
    const len = min(left.length, right.length);
    size_t i;
    do
    {
        swap(left[i], right[i]);
        i++;
    } while (i != len && left[i] > right[i]);

    // number of elements swapped
    const n = i;
    debug writefln(">%s%s; %s", left, right, n);

    // may need to re-merge right if we ran out of left elements to swap
    if (n == left.length)
        merge(right[0..n], right[n..$]);
    else
        merge(left[n..$], right);
}

// FIXME
void merge(T)(T[] left, T[] right) //@nogc
    if (hasAssignableElements!(T[]))
{
    if (left.empty || right.empty) return;

    // merge elements into left
    size_t li, ri;
outer:
    while (1)
    {
import std.stdio; writeln(left, right);
        if (left[li] > right[ri])
        {
            swap(left[li], right[ri]);
            ri++;
            if (ri == right.length) return;
        }
writeln(left, right);
        li++;
        if (li == left.length) break;
        // ensure right[0] > left[li] and keep swapped elements in order
        size_t ti;
        while (ti < ri && left[li] > right[ti])
        {
            swap(left[li], right[ti]);
writeln(left[li..$], right[0..ri], "-shift");
            li++;
            if (li == left.length)
            {
                merge(right[0..ti], right[ti..ri]);
                break outer;
            }
            ti++;
        }
    }
    // merge swapped elements
    merge(right[0..ri], right[ri..$]);
}

version(Disabled)
@safe unittest
{
    void test(T)(T l, T r)
    {
        import std.algorithm : sort;
        const s = sort(l ~ r).release;
        merge(l, r);
        assert(l ~ r == s);
    }
    test([2,3,4], [1,3,5]);
    test([1,3,5], [2,3,4]);
    test([1,2], [4,5]);
    test([4,5], [1,2]);
    test([4,5], [1,2,3]);
    test([4,5,6], [1,2]);
}

@safe unittest
{
    import std.random : uniform;

    //~ auto a = new int[uniform(100, 200)];
    auto a = new int[uniform(8, 10)];
    foreach (ref e; a)
    {
        //~ e = uniform(-100, 100);
        e = uniform(0, 100);
    }
    import std.algorithm : sort;
    const sa = sort(a.dup).release;
    const n = a.length / 2;
    merge(a[0..n].sort().release, a[n..$].sort().release);
import std.stdio; writeln(a); writeln(sa);
    assert(a == sa);
}