/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/
/* Adapted from Phobos std.algorithm.sorting */


private void optimisticInsertionSort(alias less, Range)(Range r)
{
    alias pred = binaryFun!(less);
    if (r.length < 2)
        return;

    // Move max element to r[lastIndex], swapping elements as we go
    //~ import std.algorithm.mutation : swap;
    static assert(hasAssignableElements!Range);
    size_t i = 0;
    immutable lastIndex = r.length - 1;

import std.stdio; r.writeln;
outer:
    while (1)
    {
        auto temp = r[i];

        if (!pred(r[i + 1], temp))
        {
            if (++i == lastIndex)
                break;
            continue;
        }
        do
        {
            r[i] = r[i + 1];
            if (++i == lastIndex)
            {
                r[i] = temp;
                break outer;
            }
        }
        while (pred(r[i + 1], temp));

        r[i] = temp;
    }
    // now we have a sentinel
    version(assert) import std.algorithm.searching : maxPos;
r.writeln; r.maxPos!less.front.writeln;
    assert(r[lastIndex] == r.maxPos!less.front);

    for (i = r.length - 2; i != size_t.max; --i)
    {
        static if (hasAssignableElements!Range)
        {
            auto temp = r[i];
            size_t j = i;

            for (; pred(r[j + 1], temp); ++j)
            {
                r[j] = r[j + 1];
            }
            r[j] = temp;
        }
        else
        {
            import std.algorithm.mutation : swapAt;
            for (size_t j = i; pred(r[j + 1], r[j]); ++j)
            {
                r.swapAt(j, j + 1);
            }
        }
    }
}

@safe unittest
{
    import std.random : uniform;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    //~ auto a = new int[uniform(100, 200)];
    auto a = new int[uniform(10, 20)];
    foreach (ref e; a)
    {
        e = uniform(-100, 100);
    }

    import std.algorithm.sorting : sort;
    auto tmp = a.dup.sort().release;
    optimisticInsertionSort!(binaryFun!"a < b", int[])(a);
    import std.stdio;
    a.writeln;
    tmp.writeln;
    // check that elements weren't modified
    assert(tmp == a);
    assert(isSorted(a));
}

import std.algorithm.mutation : SwapStrategy;
import std.functional; // : unaryFun, binaryFun;
import std.range.primitives;
// FIXME
import std.range; // : SortedRange;
import std.traits;

import std.algorithm.sorting : isSorted;