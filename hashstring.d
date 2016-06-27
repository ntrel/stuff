/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/** Hashed string that can reuse existing slice memory. */
alias HString = immutable(Impl)*;

struct Impl
{
    char[0] data;
    size_t length;
    size_t hash;

    inout(char)[] slice() @trusted @property inout
    {
        auto p = data.ptr - length;
        return p[0..length];
    }

    bool opEquals(inout(Impl)* hs)
    {
        return hs.hash == hash || hs.slice == slice;
    }
}

HString makeNew(string s) @trusted
{
    const len = s.length;
    auto data = new ubyte[len + size_t.sizeof * 2];
    auto impl = cast(Impl*)data[len..$].ptr;
    impl.length = len;
    impl.slice[] = s;
    impl.hash = s.hashOf;
    return cast(HString)impl;
}

unittest
{
    HString hs = makeNew("hi!");
    assert(hs.slice == "hi!");
    assert(hs.length == 3);
}

/** Allows a string to become a HString, possibly avoiding allocation
 * if `s.capacity` is big enough. */
HString makeAppend(string s)
{
    const len = s.length;
    size_t[2] fields = [len, s.hashOf];
    s ~= cast(char[])(fields[]);
    HString hs = cast(HString)(s.ptr + len);
    return hs;
}

unittest
{
    auto s = "long str";
    HString hs = makeAppend(s);
    assert(hs.slice == s);
    assert(hs.length == 8);
}

