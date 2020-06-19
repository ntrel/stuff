FoldExpression:
    __Fold(AccumulatorDecl $(OPT = Expression); FoldLoopDecl => NextExpression)
FoldLoopDecl:
    foreach(Identifier; SeqExpression)
    foreach(Identifier; LwrExpression .. UprExpression)
AccumulatorDecl:
    Identifier
    BasicType Identifier
    alias Identifier
    Identifier...

alias Map(alias Tem, S...) =
    __Fold(Acc...; foreach(E; S) => AliasSeq!(Acc, Tem!E))

/// this file makes extensive use of bool converting to 0 or 1
// pred!E gives 0 or 1
alias Filter(alias pred, S...) =
    __Fold(Acc...; foreach(E; S) => AliasSeq!(Acc, AliasSeq!E[0..pred!E]));

alias NoDuplicates(S...) =
    __Fold(Acc...; foreach(E; S) =>
        AliasSeq!(Acc, AliasSeq!E[0..staticIndexOf!(E, Acc) == -1]));

/// we can't implement short-circuit staticIndexOf just with foreach

FoldLoopDecl~=
    FoldLoopDecl while (Expression)

/// stop evaluating when the while condition is no longer true
// isSame may be expensive, so avoid more instantiation after first match
enum staticIndexOf(alias A, S...) =
    __Fold(int acc = -1; foreach(i, E; S) while (acc == -1)
        => [-1, i][isSame!(A, E)]);

/// we can't implement std.traits.fullyQualifiedName with foreach

/// make the accumulator include other info as additional element(s)
FoldLoopDecl~=
    while (Expression)

// Use the accumulator length to index S
alias Map(alias Tem, S...) =
    __Fold(Acc...; while (Acc.length != S.length) =>
        AliasSeq!(Acc, Tem!(S[Acc.length])));

/// the following examples are hard to read, see the next grammar
/// variant for better syntax
// although this form allows a NextExpression of int[2] rather than an AliasSeq
// acc is (sIndex, matchIndex)
enum staticIndexOf(alias A, S...) =
    __Fold(int[2] acc = [0, -1]; while (acc[1] == -1 && acc[0] != S.length)
        => [acc[0] + 1, [-1, acc[0]][isSame!(A, S[acc[0]])]])[1];

// similar to std.traits.fullyQualifiedName (the real version would
// instantiate a formatting template instead of using stringof).
// use a 2-element AliasSeq for the AccumulatorDecl as A is not a value
enum fqn(alias A) =
    __Fold(Acc... = AliasSeq!(A.stringof, A);
        while (__traits(compiles(parent, Acc[1]))) =>
            AliasSeq!(__traits(parent, Acc[1]).stringof ~ '.' ~ Acc[0],
                __traits(parent, Acc[1])))[0];

/// this form allows separate naming of each component of the accumulator above
AccumulatorDecl~=
    AccumulatorDecl; AccumulatorDecl

/// each NextExpression is unpacked to match the AccumulatorDecls
/// Limitation: Only one AccumulatorDecl can be a sequence
enum staticIndexOf(alias A, S...) =
    __Fold(int acc = -1; uint i = 0; while (acc == -1 && i != S.length)
        => AliasSeq!([-1, i][isSame!(A, S[i])], i + 1))[0];

enum fqn(alias A) =
    __Fold(string acc = A.stringof; alias S = A;
        while (__traits(compiles(parent, S))) =>
            AliasSeq!(__traits(parent, S).stringof ~ '.' ~ acc,
                __traits(parent, S)))[0];

/// branchless style here is repetitive, see Block form at end
template Merge(alias Less, uint half, S...)
{
    alias Result = __Fold(uint i = 0; uint j = half; Acc...;
        while (i != half && j != S.length)
            => AliasSeq!(
                i + Less!(S[i], S[j]),
                j + !Less!(S[i], S[j]), Acc,
                AliasSeq!(S[i], S[j])[Less!(S[i], S[j])]));

    // fold handles min(half, S.length - half) elements of S
    // then append any remaining elements
    alias Merge = AliasSeq!(Result[2..$],
        S[Result[0]..half], S[Result[1]..$]);
}

/// this form separates the loop logic from the NextExpression
FoldLoopDecl~=
    for(Declaration; Expression; AssignExpression)

alias Map(alias Tem, S...) =
    __Fold(Acc...; for (uint i = 0; i != S.length; i++) =>
        AliasSeq!(Acc, Tem!(S[i])));

enum staticIndexOf(alias A, S...) =
    __Fold(int acc = -1; for (uint i = 0; acc == -1 && i != S.length; i++)
        => [-1, i][isSame!(A, S[i])]);

enum fqn(alias A) =
    __Fold(string acc = A.stringof;
        for (alias S = A;
            __traits(compiles(parent, S)); S = __traits(parent, S))
            => __traits(parent, S).stringof ~ '.' ~ acc);

/// can't implement Merge because i,j are incremented independently

FoldExpression:
    __Fold(AccumulatorDecls) if (Expression) {FoldStatements}
FoldStatement:
    __Fold!(Expressions);
    static if (Expression) FoldStatement else FoldStatement
    enum Identifier = Expression; FoldStatement
    alias Identifier = Expression; FoldStatement

alias Map(alias Tem, S...) =
    __Fold(Acc...) if (Acc.length != S.length) {
        __Fold!(Acc, Tem!(S[Acc.length]));
    };

// same
alias Map(alias Tem, S...) =
    __Fold(uint i = 0; Acc...) if (i != S.length) {
        __Fold!(i + 1, Acc, Tem!(S[i]));
    }[1..$];

alias Filter(alias pred, S...) =
    __Fold(uint i = 0; Acc...) if (i != S.length) {
        static if (pred!(S[i]))
            __Fold!(i + 1, Acc, S[i]);
        else
            __Fold!(i + 1, Acc);
    }[1..$];

enum anySatisfy(alias pred, S...) =
    __Fold(bool found = false; uint i = 0)
        if (!found && i != S.length) {
            static if (pred!(S[i]))
                __Fold!(true, i);
            else
                __Fold!(false, i + 1);
        }[0];

enum staticIndexOf(alias A, S...) =
    __Fold(bool found = false, uint i = 0)
        while (!found && i != S.length)
        {
            static if (isSame!(A, S[i]))
                __Fold!(true, i));
            else
                __Fold!(false, i + 1);
        }[1];

// AssignExpression style (harder for compiler, order of eval issues)
enum staticIndexOf(alias A, S...) =
    __Fold(bool found = false, uint i = 0)
        while(!found && i != S.length) {
            static if (isSame!(A, S[i]))
                found = true;
            else
                i++;
        }.i;

// closer to nested template - see foldtpl.d
enum staticIndexOf(alias A, S...) =
    __Fold(uint i = 0)
    {
        static if (i != S.length)
        {
            static if (isSame!(A, S[i]))
                i;
            else
                __Fold!(i + 1);
        }
        else -1;
    };

alias NoDuplicates(S...) =
    __Fold(uint i = 0; Acc...) if (i != S.length) {
        static if (staticIndexOf!(E, Acc) == -1)
            __Fold!(i + 1, Acc);
        else
            __Fold!(i + 1, Acc, S[i]);
    }[1..$];

enum fqn(alias A) =
    __Fold(string acc = A.stringof; alias S = A)
        if (__traits(compiles(parent, S))) {
            __Fold!(__traits(parent, S).stringof ~ '.' ~ acc,
                __traits(parent, S));
        }[0];

template Merge(alias Less, uint half, S...)
{
    alias Result = __Fold(uint i = 0; uint j = half; Acc...)
        if (i != half && j != S.length) {
            static if (Less!(S[i], S[j]))
                __Fold!(i + 1, j, Acc, S[i]);
            else
                __Fold!(i, j + 1, Acc, S[j]);
        };
    // fold handles min(half, S.length - half) elements of S
    // then append any remaining elements
    alias Merge = AliasSeq!(Result.Acc,
        S[Result.i .. half], S[Result.j .. $]);
}

