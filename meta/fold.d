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
    __Fold!(Acc...; foreach(E; S) => AliasSeq!(Acc, AliasSeq!E[0..pred!E]));

alias NoDuplicates(S...) =
    __Fold(Acc...; foreach(E; S) =>
        AliasSeq!(Acc, AliasSeq!E[0..staticIndexOf!(E, Acc) == -1]));

FoldLoopDecl~=
    for(Declaration; Expression; AssignExpression)

enum staticIndexOf(alias A, S...) =
    __Fold!(size_t acc = -1; for(size_t i = 0; acc == -1 && i != S.length; i++)
        => [-1, i][isSame!(A, S[i])];

enum fqn(alias A) =
    __Fold(string acc; for(alias P = A; !__traits(isSame, P, null); P = __traits(parent, P))
         => acc ~ P.stringof);
