/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/


import std.algorithm;
import std.traits : isSomeChar;
debug import std.stdio;

void merge(T)(T[] left, T[] right)
    if (!isSomeChar!T)
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

unittest
{
    void test(T)(T l, T r)
    {
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

