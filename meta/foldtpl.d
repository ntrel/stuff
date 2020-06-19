version(None)
template staticIndexOf(alias A, S...)
{
    template __Fold(bool found = false, uint i = 0)
    {
        static if (!found && i != S.length)
        {
            static if (isSame!(A, S[i]))
                alias __Fold = __Fold!(true, i);
            else
                alias __Fold = __Fold!(false, i + 1);
        }
        else
            alias __Fold = AliasSeq!(found, i);
    }
    enum staticIndexOf = __Fold!()[1];
}

version(None)
template staticIndexOf(alias A, S...)
{
    template __Fold(uint i = 0)
    {
        static if (i != S.length)
        {
            static if (isSame!(A, S[i]))
                enum __Fold = i;
            else
                enum __Fold = __Fold!(i + 1);
        }
        else
            enum __Fold = -1;
    }
    alias staticIndexOf = __Fold;
}

template staticIndexOf(alias A, S...)
{
    template __Fold(uint i = 0)
    {
        static if (i != S.length)
        {
            static if (isSame!(A, S[i]))
                enum __Fold = i;
            else
                enum __Fold = __Fold!(i + 1);
        }
        else
            enum __Fold = -1;
    }
    alias staticIndexOf = __Fold!();
}

template Merge(alias Less, uint half, S...)
{
    template __Fold(uint i = 0, uint j = half, Acc...)
    {
        static if (i != half && j != S.length) {
            static if (Less!(S[i], S[j]))
                alias __Fold = __Fold!(i + 1, j, Acc, S[i]);
            else
                alias __Fold = __Fold!(i, j + 1, Acc, S[j]);
        }
        else
            // Acc has min(half, S.length - half) elements of S
            // append any remaining elements
            alias __Fold = AliasSeq!(Acc, S[i .. half], S[j .. $]);
    }
    alias Merge = __Fold!();
}

