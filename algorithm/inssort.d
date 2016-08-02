/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.stdio;

/* Adapted from Phobos std.algorithm.sorting */
version(None)
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

    r.writeln;
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

void orderFront(R)(R r)
    if (hasAssignableElements!R)
{
    if (r.length < 2) return;

    typeof(r.front) tmp;
    // Establish sentinel in r.back
    if (r.front > r.back)
    {
        tmp = r.back;
        r.back = r.front;
    }
    else
        tmp = r.front;

    // shift and insert
    auto i = 0;
    while (tmp > r[i + 1])
    {
        r[i] = r[i + 1];
        i++;
    }
    r[i] = tmp;
}

void orderBack(R)(R r)
    if (hasAssignableElements!R)
{
    if (r.length < 2) return;

    typeof(r.front) tmp;
    // Establish sentinel in r.front
    if (r.back < r.front)
    {
        tmp = r.front;
        r.front = r.back;
    }
    else
        tmp = r.back;

    // shift and insert
    auto i = r.length - 1;
    while (tmp < r[i - 1])
    {
        r[i] = r[i - 1];
        i--;
    }
    r[i] = tmp;
}

private void optimisticInsertionSort(alias less, Range)(Range r)
{
    alias pred = binaryFun!less;
    if (r.length < 2)
        return;

    // TODO: make orderFront accept hasSwappableElements
    static assert(hasAssignableElements!Range);

    r.writeln;
    for (auto i = r.length - 2; i != size_t.max; --i)
    {
        orderFront(r[i..$]);
        r[i..$].writeln;
    }
}

@safe unittest
{
    import std.random : uniform;

    debug(std_algorithm) scope(success)
        writeln("unittest @", __FILE__, ":", __LINE__, " done.");

    //~ auto a = new int[uniform(100, 200)];
    auto a = new int[uniform(8, 10)];
    foreach (ref e; a)
    {
        //~ e = uniform(-100, 100);
        e = uniform(0, 100);
    }

    import std.algorithm.sorting : sort;
    auto tmp = a.dup.sort().release;
    optimisticInsertionSort!(binaryFun!"a < b", int[])(a);
    tmp.writeln;
    assert(isSorted(a));
    // check elements weren't modified
    assert(tmp == a);
}

import std.algorithm.mutation : SwapStrategy;
import std.functional; // : unaryFun, binaryFun;
import std.range.primitives;
// FIXME
import std.range; // : SortedRange;
import std.traits;

import std.algorithm.sorting : isSorted;