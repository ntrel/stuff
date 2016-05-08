/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

/* UTF-8 string containers */

import std.range.primitives;

@safe:

struct String
{
private:
    size_t length;
    /* Note: ptr may point past the end of a memory block, so we must ensure
     * it doesn't escape in @safe code (at least when length == 0). It can
     * escape as void* though for comparisons. */
    immutable(ubyte)* ptr;
    
public:
    /* Returned `data` slice must not outlive `this`, hence new `return` feature */
    @property immutable(ubyte)[] raw() return @system
    {
        return ptr[0..length];
    }
    
    // Input range primitives
    @property bool empty() {return length == 0;}
    // decodes ptr[0..4]
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
    String s = String(data.length, data.ptr);
    return s;
}

unittest
{
    import std.string : raw = representation;
    String s = assumeUtf8("hi".raw);
    assert(!s.empty);
    s.length = 0;
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
            String s = String(length, smallRaw.idup.ptr);
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

