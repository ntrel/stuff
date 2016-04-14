/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/


/** Models safe reassignment of otherwise constant structs.
 * 
 * Structs with fields of reference type cannot be assigned to a constant 
 * struct of the same type. `Rebindable!(const S)` allows assignment to
 * `const S` while enforcing only constant access to fields of `S`.
 * 
 * `Rebindable!(immutable S)` does the same but field access may create a 
 * temporary copy of `S` in order to enforce _true immutability.
 */
struct Rebindable(S)
if (is(S == struct))
{
    import std.traits : Unqual;
    
    // fields of payload must be treated as tail const (unless S is mutable)
    private Unqual!S payload;
    
    this(S s)
    {
        this = s;
    }
    
    static if (!is(S == immutable))
    ref S Rebindable_get() @property
    {
        // payload exposed as const ref when S is const
        return payload;
    }
    
    static if (is(S == immutable))
    S Rebindable_get() @property @trusted
    {
        // we return a copy so cast to immutable is OK
        return cast(S)payload;
    }

    alias Rebindable_get this;
    
    version(MultipleAliasThis)
    static if (is(S == immutable))
    {
        ref const(Unqual!S) Rebindable_getRef() @property
        {
            // payload exposed as const ref when S is immutable
            return payload;
        }
        alias Rebindable_getRef this;
    }
    
    void opAssign()(auto ref S s) @trusted
    {
        // we preserve tail immutable guarantees so cast is OK
        payload = cast(Unqual!S)s;
    }
    
    ~this() @trusted
    {
        import std.algorithm : move;
        // call destructor with proper constness
        S s = cast(S)move(payload);
    }
}

///
@safe unittest
{
    static struct S
    {
        int* ptr;
    }
    
    S s = S(new int);

    const cs = s;
    // Can't assign s.ptr to cs.ptr
    static assert(!__traits(compiles, {s = cs;}));
    
    Rebindable!(const S) rs = s;
    assert(rs.ptr is s.ptr);
    // rs.ptr is const
    static assert(!__traits(compiles, {rs.ptr = null;}));
    
    // Can't assign s.ptr to rs.ptr 
    static assert(!__traits(compiles, {s = rs;}));
    
    const S cs2 = rs;
    // Rebind rs
    rs = cs2;
    rs = S();
    assert(rs.ptr is null);
    
    Rebindable!(immutable S) ri = S(new int);
    assert(ri.ptr !is null);
    static assert(!__traits(compiles, {ri.ptr = null;}));
    
    // ri is not compatible with mutable S
    static assert(!__traits(compiles, {s = ri;}));
    static assert(!__traits(compiles, {ri = s;}));
    
    const S cs3 = ri;
    static assert(!__traits(compiles, {ri = cs3;}));
    
    immutable S si = ri;
    // Rebind ri
    ri = si;
    ri = S();
    assert(ri.ptr is null);
}

// Test Rebindable!mutable
@safe unittest
{
    static struct S
    {
        int* ptr;
    }
    
    S s = S(new int);
    Rebindable!S rs = s;
    s = rs;
    
    assert(rs.ptr is s.ptr);
    // mutate
    rs.ptr = null;
    assert(rs.ptr is null);
    rs = S();
}

void main()
{
    
}