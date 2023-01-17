import std.stdio;
import core.atomic;

void main() {
    int sum = 0;
    auto a = [0,2,3,6,1,4,6,3,3,3,6];
    immutable l = a.length;
    a.parallel!sum(
        (int e, ref shared int s) immutable {
            s.atomicOp!"+="(e);
            writeln(e, ',', l); // l is immutable so OK
            //sum++; // not immutable
        });
    writeln(sum);
    assert(sum == 37);
}

template parallel(vars...)
{
    //~ Parallel!E
    //~ void parallel(E)(E[] a, immutable void delegate(E, ref shared typeof(vars)) dg)
    void parallel(E, D)(E[] a, D dg)
    {
        //~ static assert(is(D == immutable)); // compiler bug?
        import std.algorithm.searching;
        static assert(D.stringof.canFind(") immutable "));
        static assert(!is(typeof(vars) == immutable)); // so we don't cast it away
        foreach (e; a)
        {
            dg(e, cast(shared)vars);
        }
        //~ return Parallel!E(a, dg);
    }

    struct Parallel(E)
    {
        E[] a;
        immutable void delegate(E) dg;
    }
}

