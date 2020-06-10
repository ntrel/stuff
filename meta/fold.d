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
        => [-1, i][isSame!(A, E)];

/// we can't implement std.traits.fullyQualifiedName with foreach

/// make the accumulator include other info as additional element(s)
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

/// each NextExpression is unpacked to match the AccumulatorDecls
/// Limitation: Only one AccumulatorDecl can be a sequence
enum staticIndexOf(alias A, S...) =
    __Fold(int acc = -1; uint i = 0; while (acc == -1 && i != S.length)
        => AliasSeq!([-1, i][isSame!(A, S[i])], i + 1))[0];

enum fqn(alias A) =
    __Fold(string acc = ""; alias P = A; while (!__traits(isSame, P, null))
        => AliasSeq!(acc ~ P.stringof, __traits(parent, P)))[0];

template Merge(alias Less, uint half, S...)
{
    alias Result = __Fold(uint i = 0; uint j = half; Acc...;
        while (i != half && j != S.length)
            => AliasSeq!(
                i + Less!(S[i], S[j]),
                j + !Less!(S[i], S[j]), Acc,
                AliasSeq!(S[i], S[j])[Less!(S[i], S[j])]));

    // fold handles minLength(half, S.length - half) elements of S
    // then append any remaining elements
    alias Merge = AliasSeq!(Result[2..$],
        S[Result[0]..half], S[Result[1]..$]);
}

/// this form separates the loop logic from the NextExpression
FoldLoopDecl~=
    for(Declaration; Expression; AssignExpression)

enum staticIndexOf(alias A, S...) =
    __Fold(int acc = -1; for(uint i = 0; acc == -1 && i != S.length; i++)
        => [-1, i][isSame!(A, S[i])];

enum fqn(alias A) =
    __Fold(string acc; for(alias P = A; !__traits(isSame, P, null); P = __traits(parent, P))
         => acc ~ P.stringof);

/// can't implement Merge because i,j are incremented independently
