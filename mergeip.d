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
    size_t swapped;
    foreach (i; 0..left.length)
    {
        if (i == right.length || left[i] <= right[i])
            break;
        swap(left[i], right[i]);
        swapped++;
    }
    debug writeln('>', left, right);
    
    // may need to re-merge right if we ran out of left elements to swap
    if (swapped == left.length)
        merge(right[0..swapped], right[swapped..$]);
    else
        merge(left[swapped..$], right);
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
    test([4,5], [1,2,3]);
}

