/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.range;
import std.traits;

/** Overwrites r with elements of src until r is full. */
auto refill(R, Input)(R r, Input src)
if (hasSlicing!R && isInputRange!Input)
{
    foreach (i, ref e; r)
    {
        if (src.empty)
        {
            return r[0..i];
        }
        e = src.front;
        src.popFront;
    }
    // ignore leftover elements in src
    return r;
}

import std.algorithm : uniq;
/// eager wrapper for uniq
auto dedup(R)(R r){return r.refill(r.uniq);}

unittest
{
    auto a = [5,5,5,5,4,3,3,3,1];
    auto b = a.dedup;
    assert (a.ptr is b.ptr);
    assert(a != b);
    assert(b == [5, 4, 3, 1]);
}

