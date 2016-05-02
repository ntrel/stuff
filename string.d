/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

@safe:

struct String
{
    size_t length;
private:
    /* Note: ptr may point past the end of a memory block, so we must ensure
     * it doesn't escape in @safe code (at least when length == 0). It can
     * escape as void* though for comparisons. */
    immutable(ubyte)* ptr;
    
    /* Could do Small String Optimization using data + offset in a union with ptr */
    immutable(ubyte)[size_t.sizeof - 1] data;
    // needed for popFront
    ubyte offset;
    
public:
    /* Returned `data` slice must not outlive `this`, hence new `return` feature */
    @property immutable(ubyte)[] raw() return @system
    {
        if (length > size_t.sizeof)
            return ptr[0..length];
        else
            return data[offset..length];
    }
    
    // Range primitives
    @property bool empty() {return length == 0;}
    // decodes ptr[0..4]
    @property dchar front();
    // writes to length, ptr/offset
    void popFront();
    // BiDi range
    void popBack();
    // no opIndex, opSlice because they can break UTF-8
}

struct HashString
{
immutable:
    String string;
    size_t hash;
}

unittest
{
    
}

