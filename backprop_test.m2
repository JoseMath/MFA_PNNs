------------------------------------------------------------
-- backprop_test.m2
-- Minimal Macaulay2 translation of feedforward/backprop only
------------------------------------------------------------

------------------------------------------------------------
-- Basic helpers
------------------------------------------------------------

zeroMat = (K, m, n) -> matrix apply(m, i -> apply(n, j -> 0_K));

onesMat = (K, m, n) -> matrix apply(m, i -> apply(n, j -> 1_K));

-- If random(K) causes trouble in your installation, replace this with:
-- randElt = K -> lift(random(1000), K);
randElt = K -> random(K);

randMat = (K, m, n) -> matrix apply(m, i -> apply(n, j -> randElt(K)));

basisVector = (K, m, j) -> matrix apply(m, i -> {if i == j then 1_K else 0_K});

shape = M -> {numRows M, numColumns M};

checkSameSize = (A, B, label) -> (
    if shape A =!= shape B then (
        << label << ": left shape = " << toString(shape A)
                 << ", right shape = " << toString(shape B) << endl;
        error(label | ": matrices must have the same size")
    );
);

entrywisePower = (M, e) -> (
    matrix apply(numRows M, i ->
        apply(numColumns M, j -> (M_(i,j))^e)
    )
);

entrywisePowerPrime = (M, e) -> (
    matrix apply(numRows M, i ->
        apply(numColumns M, j -> e * (M_(i,j))^(e-1))
    )
);

hadamardProduct = (M, N) -> (
    checkSameSize(M, N, "hadamardProduct");
    matrix apply(numRows M, i ->
        apply(numColumns M, j -> M_(i,j) * N_(i,j))
    )
);

------------------------------------------------------------
-- Network constructor
-- sizes = {d0,d1,...,dL}
-- exponent = r
-- p = prime
------------------------------------------------------------

makeNetwork = (sizes, exponent, p) -> (
    K := ZZ/p;
    biases := for i from 1 to #sizes - 1 list zeroMat(K, sizes#i, 1);
    weights := for i from 0 to #sizes - 2 list randMat(K, sizes#(i+1), sizes#i);

    hashTable {
        "numLayers" => #sizes,
        "sizes"     => sizes,
        "K"         => K,
        "biases"    => biases,
        "weights"   => weights,
        "exponent"  => exponent,
        "degree"    => exponent^(#sizes - 2)
    }
);

------------------------------------------------------------
-- Feedforward
-- Hidden layers use entrywise power; final layer is linear
------------------------------------------------------------

feedforward = (N, x) -> (
    activation := x;
    W := N#"weights";
    B := N#"biases";
    e := N#"exponent";

    if #W >= 2 then (
        for i from 0 to #W - 2 do (
            activation = entrywisePower(W#i * activation + B#i, e);
        );
    );

    (W#(#W - 1)) * activation + (B#(#B - 1))
);

------------------------------------------------------------
-- Backpropagation
-- Returns {nablaB, nablaW}
------------------------------------------------------------

backprop = (N, x, pullbackVector) -> (
    K := N#"K";
    sizes := N#"sizes";
    W := N#"weights";
    B := N#"biases";
    e := N#"exponent";

    nWeights := #W;

    if pullbackVector === null then
        pullbackVector = onesMat(K, sizes#(#sizes - 1), 1);

    -- these need to be mutable because we assign into them
    nablaB := new MutableList from apply(B, b -> zeroMat(K, numRows b, numColumns b));
    nablaW := new MutableList from apply(W, w -> zeroMat(K, numRows w, numColumns w));

    --------------------------------------------------------
    -- Forward pass
    --
    -- activations = {input, hidden activation 1, ..., hidden activation last}
    -- zs          = {hidden preactivation 1, ..., hidden preactivation last}
    --
    -- Final layer is linear, so it is NOT stored in zs.
    --------------------------------------------------------

    activation := x;
    activations := {x};
    zs := {};

    if nWeights >= 2 then (
        for i from 0 to nWeights - 2 do (
            z := W#i * activation + B#i;
            zs = join(zs, {z});
            activation = entrywisePower(z, e);
            activations = join(activations, {activation});
        );
    );

    --------------------------------------------------------
    -- Backward pass
    --------------------------------------------------------

    delta := pullbackVector;

    -- final linear layer gradient
    nablaB#(nWeights - 1) = delta;
    nablaW#(nWeights - 1) = delta * transpose(activations#(#activations - 1));

    -- hidden layers
    if nWeights >= 2 then (
        for ell from 2 to nWeights do (
            layerIndex := nWeights - ell;

            z := zs#layerIndex;
            sp := entrywisePowerPrime(z, e);

            tmp := transpose(W#(layerIndex + 1)) * delta;
            checkSameSize(tmp, sp, "backprop mismatch before hadamard");

            delta = hadamardProduct(tmp, sp);

            nablaB#layerIndex = delta;
            nablaW#layerIndex = delta * transpose(activations#layerIndex);
        );
    );

    {toList nablaB, toList nablaW}
);
end
restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/backprop_test.m2"
nn = makeNetwork({2,3,1}, 2, 100003)
x = randMat(nn#"K", 2, 1)
pb = basisVector(nn#"K", 1, 0)
grads = backprop(nn, x, pb)
apply(grads#1, M -> {numRows M, numColumns M})
apply(grads#1, M -> {numRows M, numColumns M})
apply(grads#0, M -> {numRows M, numColumns M})

--test--deeper architecture
nn2 = makeNetwork({2,3,4,1}, 2, 100003)
x2 = randMat(nn2#"K", 2, 1)
pb2 = basisVector(nn2#"K", 1, 0)
grads2 = backprop(nn2, x2, pb2)
apply(grads2#1, M -> {numRows M, numColumns M})
