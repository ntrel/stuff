/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/* UTF-8 string containers */

import std.range.primitives;
import std.string : raw = representation;

@safe:

struct String
{
private:
    immutable(ubyte)[] data;
    
public:
    @property raw()
    {
        return data;
    }
    
    bool opEquals(String s) @trusted
    {
        return raw == s.raw;
    }
    
    // Input range primitives
    @property bool empty() {return data.length == 0;}
    // decodes data[0..4]
    @property dchar front();
    void popFront();
    // Forward range
    String save() {return this;}
    // BiDi range
    @property dchar back();
    void popBack();
    static assert(isBidirectionalRange!String);
    // no opIndex, (public) length, opSlice because they can break UTF-8
    static assert(!hasLength!String);
    static assert(!isRandomAccessRange!String);
}

String assumeUtf8(immutable(ubyte)[] data)
{
    return String(data);
}

unittest
{
    String s = assumeUtf8("hi".raw);
    assert(!s.empty);
    assert(s.raw.length == 2);
    s = s.init;
    assert(s.empty);
}

struct HashString
{
immutable:
    private String str;
    size_t hash;
    
    alias str this;
}

unittest
{
    HashString hs;
    String s = hs;
}

/* Impl based on an idea from volt-lang.org */
struct VoltString
{
private:
    struct Impl
    {
        size_t length;
        size_t hash;
        ubyte[0] data;
        
        @property raw() @trusted inout
        {
            return data.ptr[0..length];
        }
    }
    static assert(Impl.sizeof == size_t.sizeof * 2);
    static immutable emptyImpl = Impl.init;
    immutable(Impl)* impl;
    
public:
    version(NullaryStructRuntimeCtors)
    this()
    {
        impl = &emptyImpl;
    }
    
    this(String s) @trusted
    {
        const data = s.raw;
        auto mi = cast(Impl*)new ubyte[Impl.sizeof + data.length].ptr;
        mi.length = data.length;
        mi.raw[] = data;
        mi.hash = data.hashOf;
        import util;
        impl = mi.assumeUnique;
    }
    
    @property hash()
    {
        return impl.hash;
    }
    
    private String get()
    {
        return String(impl.raw);
    }
    
    alias get this;
}

unittest
{
    VoltString vs;
    vs.impl = &vs.emptyImpl;
    String s = vs;
    assert(s.empty);
    s = assumeUtf8("hi".raw);
    vs = VoltString(s);
    assert(vs == s);
    assert(vs.hash == s.raw.hashOf);
}

struct SmallString
{
private:
    /* Small String Optimization */
    enum dataLen = String.sizeof;
    union
    {
        String str;
        // FIXME can't be immutable
        immutable(ubyte)[dataLen] data;
    }
    ubyte length;
    // needed for popFront
    ubyte offset;
    
    @property small() {return length <= dataLen;}
    
    @property smallRaw() @system
    {
        assert(small);
        return data[offset..length];
    }

public:
    /** Warning: Returned slice must not outlive `this`. */
    @property immutable(ubyte)[] raw() @system
    {
        if (small)
            return smallRaw;
        else
            return str.raw;
    }
    
    String toString() @trusted
    {
        if (small)
        {
            auto s = String(smallRaw.idup);
            length = ubyte.max;
            import std.algorithm : move;
            str = s.move;
        }
        return str;
    }

    // Range primitives
    @property bool empty() @trusted {return small ? length == 0 : str.empty;}
    @property dchar front();
    // writes to str or length, offset
    void popFront();
}

unittest
{
    SmallString ss;
    String s = ss.toString;
}

