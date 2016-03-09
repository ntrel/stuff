/* Written in the D programming language.
 * Copyright: 2016 Nick Treleaven <nick dot treleaven at btinternet com>
 * License: Boost Software License, Version 1.0. See accompanying file
 *          LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt.
*/

@safe:

/** Holds a reassignable reference to a constant object. */
struct TailConst(T)
if (is(T == class))
{
    // mutable only so we can reassign it, fields must be treated as const
    private T TailConst_payload;
    
    this(const T val)
    {
        this = val;
    }
    
    @trusted
    void opAssign(const T val)
    {
        // we own the struct's memory for the payload reference, which isn't
        // const, so this is safe as long as its fields are never modified
        TailConst_payload = cast(T) val;
    }
    
    alias TailConst_get this;
    
    @property
    const(T) TailConst_get()
    {
        return TailConst_payload;
    }
}

/// ditto
auto tailConst(T)(const T val)
{
    return TailConst!T(val);
}

///
unittest
{
    class C
    {
        pure this(int i) {this.i = i;}
        int i;
    }
    
    auto c = new C(5);
    auto tc = tailConst(c);
    assert(tc.i == 5);
    
    static assert(!__traits(compiles, tc.i = 1));
    
    c = new C(1);
    assert(tc.i == 5);
    tc = c;
    assert(tc.i == 1);
    
    const C cc = tc;
    assert(cc.i == 1);
    const Object co = tc;
    
    auto ctc = tailConst(cc);
    const C cc2 = ctc;
    
    auto ic = new immutable C(2);
    tc = ic;
    assert(tc.i == 2);
    auto itc = tailConst(ic);
    itc = new immutable C(3);
    const C cc3 = itc;
    //immutable C ic2 = itc; // not implemented
}

// TailConst mimics Object
unittest
{
    class C {}
    
    TailConst!Object tc;
    assert(tc is null);
    tc = new C;
    assert(tc !is null);
    tc = null;
    assert(tc is null);
}

void main(){}
