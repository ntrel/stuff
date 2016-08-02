/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/// Merge in-place without heap allocation
// Worst case time not good, average case should be OK


import std.algorithm : swap;
import std.range.primitives; //: empty, hasAssignableElements;
import inssort;

//~ debug
    import std.stdio : writeln;
//~ else
    //~ void writeln(T...)(T){}

void merge(T)(T[] left, T[] right) //@nogc
    if (hasAssignableElements!(T[]))
{
    if (left.empty || right.empty) return;

    // merge elements into left
    size_t li, ri;
    while (1)
    {
        writeln(left, right, li, ",", ri);
        if (left[li] > right[ri])
        {
            // Use 3 sorted ranges: left, right[0..ri], right[ri..$]
            swap(left[li], right[ri]);
            writeln(left, right);
            if (ri + 1 == right.length)
            {
                // order right.back in middle range
                orderBack(right);
                // any remaining left elements
                merge(left[li + 1..$], right);
                return;
            }
            // minimize ri
            if (right[ri] > right[ri + 1])
                ri++;
        }
        li++;
        if (li == left.length) break;

        // ensure right[0] > next left element
        if (ri == 0 || left[li] <= right[0]) continue;
        swap(left[li], right[0]);
        writeln(left, right);
        // order right[0] in middle range
        orderFront(right[0..ri]);
    }
    // merge middle range
    merge(right[0..ri], right[ri..$]);
}

private
void test(T)(T l, T r, bool slr = false)
{
    import std.algorithm : isSorted, sort;
    if (slr)
    {
        l.sort();
        r.sort();
    }
    const sa = sort(l ~ r).release;
    writeln("test");
    merge(l, r);
    writeln(l,r);
    assert(isSorted(l ~ r));
    // check elements weren't modified
    assert(l ~ r == sa);
}

@safe unittest
{
    test([2,3,4], [1,3,5]);
    test([1,3,5], [2,3,4]);
    test([1,2], [4,5]);
    test([4,5], [1,2]);
    test([4,5], [1,2,3]);
    test([4,5,6], [1,2]);
    test([2, 8, 32, 34], [17, 30, 61, 68, 82]);
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
    const n = a.length / 2;
    test(a[0..n], a[n..$], true);
}