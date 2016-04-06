/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/


struct Rebindable(S)
if (is(S == struct))
{
    import std.traits : Unqual;
    
    // fields of payload must be treated as tail const
    private Unqual!S payload;
    
    @property S get() @trusted
    {
        // we return a copy so cast to immutable is OK
        return cast(S)payload;
    }

    // TODO: prefix payload, get against alias this conflicts
    alias get this;
    
    void opAssign()(auto ref S s) @trusted
    {
        // we preserve tail immutable guarantees so cast is OK
        payload = cast(Unqual!S)s;
    }
}

///
@safe unittest
{
    static struct S
    {
        int* ptr;
    }
    // can't assign S.ptr to (const S).ptr:
    {
        S s;
        const cs = s;
        static assert(!__traits(compiles, {s = cs;}));
    }
    Rebindable!(const S) rs;
    static assert(!__traits(compiles, {S s = rs;}));
    rs = S();
    {
        const S cs = rs;
        rs = cs;
    }
    Rebindable!(immutable S) ri;
    static assert(!__traits(compiles, {S s = ri;}));
    ri = immutable S();
    {
        const S cs = ri;
        static assert(!__traits(compiles, {ri = cs;}));
        immutable S i = ri;
    }
}

void main()
{
    
}