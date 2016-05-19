/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

import std.traits : isMutable;

/** Models safe reassignment of otherwise constant structs.
 * 
 * A struct with a field of reference type cannot be assigned to a constant 
 * struct of the same type. `Rebindable!(const S)` allows assignment to
 * `const S` while enforcing only constant access to fields of `S`.
 * 
 * `Rebindable!(immutable S)` does the same but field access may create a 
 * temporary copy of `S` in order to enforce _true immutability.
 */
struct Rebindable(S)
if (is(S == struct) && !isMutable!S)
{
    import std.traits : Unqual;
    
    // fields of payload must be treated as tail const (unless S is mutable)
    private Unqual!S payload;
    
    this()(S s) @trusted
    {
        // we preserve tail immutable guarantees so cast is OK
        payload = cast(Unqual!S)s;
    }
    
    void opAssign()(S s)
    {
        this = Rebindable(s);
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
    
    ~this() @trusted
    {
        import std.algorithm : move;
        // call destructor with proper constness
        S s = cast(S)move(payload);
    }
}

///
template Rebindable(S)
if (is(S == struct) && isMutable!S)
{
    alias Rebindable = S;
}

///
Rebindable!S rebindable(S)(S s)
if (is(S == struct))
{
    static if (isMutable!S)
        return s;
    else
        return Rebindable!S(s);
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
    static assert(is(typeof(rs) == S));
    rs = rebindable(S());
}

// Test disabled default ctor
unittest
{
    static struct ND
    {
        int i;
        @disable this();
        this(int i) inout {this.i = i;}
    }
    static assert(!__traits(compiles, Rebindable!ND()));
    
    Rebindable!(const ND) rb = ND(1);
    rb = immutable ND(2);
    rb = rebindable(ND(3));
    assert(rb.i == 3);
    static assert(!__traits(compiles, rb.i++));
}


