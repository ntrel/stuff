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

alias Filter(alias pred, S...) =
    __Fold(Acc...; foreach(E; S) => AliasSeq!(Acc, AliasSeq!E[0..pred!E]));

alias NoDuplicates(S...) =
    __Fold(Acc...; foreach(E; S) =>
        AliasSeq!(Acc, AliasSeq!E[0..staticIndexOf!(E, Acc) == -1]));

/// we can't implement short-circuit staticIndexOf just with foreach

FoldLoopDecl~=
    FoldLoopDecl while (Expression)

// stop evaluating when the while condition is no longer true
enum staticIndexOf(alias A, S...) =
    __Fold(size_t acc = -1; foreach(i, E; S) while (acc == -1)
        => [-1, i][isSame!(A, E)];

/// we can't implement std.traits.fullyQualifiedName with foreach

// this form is hard to read, see the next grammar variant for better syntax
// this form allows the NextExpression to be e.g. int[2] rather than an AliasSeq
FoldLoopDecl~=
    while (Expression)

// acc is (sIndex, matchIndex)
enum staticIndexOf(alias A, S...) =
    __Fold(int[2] acc = [0, -1]; while (acc[1] == -1 && acc[0] != S.length)
        => [acc[0] + 1, [-1, acc[0]][isSame!(A, S[acc[0]])]])[1];

// fullyQualifiedName
enum fqn(alias A) =
    __Fold(Acc... = AliasSeq!(A, ""); while (!__traits(isSame, Acc[0], null))
        => AliasSeq!(__traits(parent, Acc[0]), Acc[1] ~ Acc[0].stringof))[1];

/// this form allows separate naming of each component of the accumulator above
AccumulatorDecl~=
    AccumulatorDecl; AccumulatorDecl

// NextExpression must be a sequence whose length must correspond to the AccumulatorDecls
// Only one AccumulatorDecl can be a sequence
enum staticIndexOf(alias A, S...) =
    __Fold(int acc = -1; uint i = 0; while (acc == -1 && i != S.length)
        => AliasSeq!([-1, i][isSame!(A, S[i])], i + 1))[0];

enum fqn(alias A) =
    __Fold(string acc = ""; alias P = A; while (!__traits(isSame, P, null))
        => AliasSeq!(acc ~ P.stringof, __traits(parent, P)))[0];

/// this form separates the loop logic from the NextExpression
FoldLoopDecl~=
    for(Declaration; Expression; AssignExpression)

enum staticIndexOf(alias A, S...) =
    __Fold(size_t acc = -1; for(size_t i = 0; acc == -1 && i != S.length; i++)
        => [-1, i][isSame!(A, S[i])];

enum fqn(alias A) =
    __Fold(string acc; for(alias P = A; !__traits(isSame, P, null); P = __traits(parent, P))
         => acc ~ P.stringof);
