/* Written in the D programming language.
 * Copyright: 2014 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.range;
import std.traits;

/** Overwrites r with elements of src until r is full. */
auto refill(R, Input)(R r, Input src)
if (hasSlicing!R && isInputRange!R && isInputRange!Input)
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

/** Overwrites r with elements of fun(r) until r is full. */
auto refill(alias fun, R)(R r)
if (hasSlicing!R && isInputRange!R)
{
    import std.functional : unaryFun;
    return r.refill(unaryFun!fun(r));
}

///
unittest
{
    import std.algorithm : filter, sort, uniq;

    auto a = [5,5,5,4,3,3,1];
    auto b = a.refill!uniq;
    assert (a.ptr is b.ptr);
    assert(b == [5,4,3,1]);
    assert(a == [5,4,3,1,3,3,1]);
    
    // refill b with some elements of a
    const ca = a;
    assert(b.refill(ca.filter!(e => e < 4)) == [3,1,3,3]);
    
    auto c = [1,4,1,3];
    assert(c.sort().release.refill!uniq == [1,3,4]);
    assert(c == [1,3,4,4]);
}

