/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/


auto assumeUnique(T)(T* ptr)
{
    return cast(immutable(T)*)ptr;
}

auto recast(T, V)(V v){return cast(T)v;}

unittest
{
    auto s = "hi";
    import std.string : raw = representation;
    assert(s.raw.recast!(string) == s);
}

