------------------------------------------------------------
-- step2_compute_dimension.m2
-- Step 2: extend the working backprop code with
--   * weak compositions
--   * monomial lists
--   * monomial evaluation matrices
--   * coefficient recovery from sampled evaluations
--   * a minimal computeDimension routine
--
-- Notes:
-- 1. This file assumes the final layer is linear and hidden layers
--    use entrywise power x |-> x^r, matching the earlier translation.
-- 2. Instead of a pseudoinverse, we recover coefficients by choosing
--    a full-rank square row-submatrix of the monomial evaluation matrix.
------------------------------------------------------------

------------------------------------------------------------
-- Basic helpers
------------------------------------------------------------
submatrixByLists = (M, rowIdx, colIdx) -> (
    E := entries M;
    matrix apply(rowIdx, i ->
        apply(colIdx, j -> (E#i)#j)
    )
);
zeroMat = (K, m, n) -> matrix apply(m, i -> apply(n, j -> 0_K));

onesMat = (K, m, n) -> matrix apply(m, i -> apply(n, j -> 1_K));

-- If random(K) causes trouble in your installation, replace this by
--   randElt = K -> lift(random(1000), K);
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
        apply(numColumns M, j -> e * (M_(i,j))^(e - 1))
    )
);

hadamardProduct = (M, N) -> (
    checkSameSize(M, N, "hadamardProduct");
    matrix apply(numRows M, i ->
        apply(numColumns M, j -> M_(i,j) * N_(i,j))
    )
);

flattenMatrixEntries = M -> flatten entries M;

------------------------------------------------------------
-- Weak compositions of k into n parts
-- Replacement for Sage's WeightedIntegerVectors(k,[1,...,1])
------------------------------------------------------------

weakCompositions = (k, n) -> (
    if n == 1 then return {{k}};
    L := {};
    for i from 0 to k do (
        tails := weakCompositions(k - i, n - 1);
        L = join(L, apply(tails, t -> prepend(i, t)));
    );
    L
);

------------------------------------------------------------
-- Monomials of total degree k in entries of a vector v
------------------------------------------------------------

monomialList = (v, k) -> (
    expsList := weakCompositions(k, #v);
    apply(expsList, a ->
        product apply(#v, i -> (v#i)^(a#i))
    )
);

------------------------------------------------------------
-- Network constructor
-- sizes = {d0,d1,...,dL}
-- exponent = r
-- p = prime for the finite field ZZ/p
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

    nablaB := new MutableList from apply(B, b -> zeroMat(K, numRows b, numColumns b));
    nablaW := new MutableList from apply(W, w -> zeroMat(K, numRows w, numColumns w));

    --------------------------------------------------------
    -- Forward pass
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

    -- Final linear layer gradient
    nablaB#(nWeights - 1) = delta;
    nablaW#(nWeights - 1) = delta * transpose(activations#(#activations - 1));

    -- Hidden layers
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

------------------------------------------------------------
-- Build monomial evaluation matrix
-- Input:  X = d0 x nsamples matrix
-- Output: nsamples x dimPoly matrix
------------------------------------------------------------

monomialEvaluationMatrix = (X, degree) -> (
    rows := for j from 0 to numColumns X - 1 list (
        v := for i from 0 to numRows X - 1 list X_(i,j);
        monomialList(v, degree)
    );
    matrix rows
);

------------------------------------------------------------
-- Choose enough independent rows to form an invertible square
-- submatrix.
--
-- The routine greedily accumulates rows whose addition increases rank.
-- If monomials has full column rank, this returns exactly numColumns
-- many row indices.
------------------------------------------------------------

independentRowIndices = M -> (
    targetRank := numColumns M;
    cols := toList(0 .. numColumns M - 1);
    idx := {};
    currentRank := 0;

    for i from 0 to numRows M - 1 do (
        trialIdx := join(idx, {i});
        sub := submatrixByLists(M, trialIdx, cols);
        r := rank sub;
        if r > currentRank then (
            idx = trialIdx;
            currentRank = r;
        );
    );

    if currentRank < targetRank then
        error "independentRowIndices: matrix does not have full column rank";

    idx
);
------------------------------------------------------------
-- Recover coefficient matrix C from sampled evaluations:
--
--    monomials * C = gradientsSamples
--
-- by picking an invertible square row-submatrix.
------------------------------------------------------------

recoverCoefficientMatrix = (monomials, gradientsSamples) -> (
    idx := independentRowIndices monomials;
    monoCols := toList(0 .. numColumns monomials - 1);
    gradCols := toList(0 .. numColumns gradientsSamples - 1);

    Msq := submatrixByLists(monomials, idx, monoCols);
    Gsq := submatrixByLists(gradientsSamples, idx, gradCols);

    (inverse Msq) * Gsq
);

------------------------------------------------------------
-- Utility: build the sampled gradient-value matrix for a fixed
-- output coordinate j.
--
-- Returns an nsamples x numParams matrix whose i-th row is the
-- flattened weight-gradient at sample x_i for the j-th output basis
-- vector.
------------------------------------------------------------

gradientSamplesMatrix = (nn, X, j) -> (
    sizes := nn#"sizes";
    K := nn#"K";
    outDim := sizes#(#sizes - 1);
    nsamples := numColumns X;

    basisVec := basisVector(K, outDim, j);

    rows := for i from 0 to nsamples - 1 list (
        --xi := X_(toList(0 .. numRows X - 1), {i});
	xi := submatrixByLists(X, toList(0 .. numRows X - 1), {i});
	grads := backprop(nn, xi, basisVec);
        gradMats := grads#1; -- only weight gradients
        flatten apply(gradMats, M -> flattenMatrixEntries M)
    );

    matrix rows
);

------------------------------------------------------------
-- Minimal computeDimension routine
--
-- Returns:
--   {sizes, exponent, ambient_dim, expected_dim, dimension, defect}
--
-- This is the Step 2 version: it uses the working backprop code,
-- sampled monomial evaluations, coefficient recovery, and rank.
------------------------------------------------------------

computeDimension = (networkWidths, networkExponent) -> (
    primes := {100003, 100153};
    dims := {};

    for p in primes do (
        nn := makeNetwork(networkWidths, networkExponent, p);
        sizes := nn#"sizes";
        K := nn#"K";

        inDim := sizes#0;
        outDim := sizes#(#sizes - 1);
        degree := nn#"degree";
        numParams := sum apply(#sizes - 1, i -> sizes#i * sizes#(i + 1));

        dimPolyVector := binomial(degree + inDim - 1, inDim - 1);
        nsamples := 2 * dimPolyVector;

        X := randMat(K, inDim, nsamples);
        monomials := monomialEvaluationMatrix(X, degree);  -- nsamples x dimPolyVector

        jacobianRows := {};

        for j from 0 to outDim - 1 do (
            gradientsSamples := gradientSamplesMatrix(nn, X, j); -- nsamples x numParams
            coeffs := recoverCoefficientMatrix(monomials, gradientsSamples); -- dimPolyVector x numParams
            jacobianRows = join(jacobianRows, entries coeffs);
        );

        jacobianMatrix := matrix jacobianRows;
        dims = join(dims, {rank jacobianMatrix});
    );

    if any(dims, d -> d =!= dims#0) then
        error("different dimensions over finite fields: " | toString dims);

    ambientDim := binomial(networkExponent^(#networkWidths - 2) + networkWidths#0 - 1,
                           networkWidths#0 - 1) * networkWidths#(#networkWidths - 1);
    naiveBound := (sum apply(#networkWidths - 1,
                    i -> (networkWidths#i - 1) * networkWidths#(i + 1)))
                  + networkWidths#(#networkWidths - 1);
    exDim := min(ambientDim, naiveBound);

    {
        networkWidths,
        networkExponent,
        ambientDim,
        exDim,
        dims#0,
        exDim - dims#0
    }
);

------------------------------------------------------------
-- Suggested smoke tests
--
-- load "step2_compute_dimension.m2"
--
-- 1) Re-test backprop:
--    nn = makeNetwork({2,3,1}, 2, 100003)
--    x = randMat(nn#"K", 2, 1)
--    pb = basisVector(nn#"K", 1, 0)
--    grads = backprop(nn, x, pb)
--    apply(grads#1, M -> {numRows M, numColumns M})
--
-- 2) Test monomials:
--    X = randMat(nn#"K", 2, 6)
--    mon = monomialEvaluationMatrix(X, nn#"degree")
--    {numRows mon, numColumns mon}
--
-- 3) Test computeDimension on a tiny network:
--    computeDimension({2,3,1}, 2)
------------------------------------------------------------

end
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/step2_compute_dimension.m2"
nn = makeNetwork({2,3,1}, 2, 100003)
x = randMat(nn#"K", 2, 1)
pb = basisVector(nn#"K", 1, 0)
grads = backprop(nn, x, pb)
apply(grads#1, M -> {numRows M, numColumns M})
X = randMat(nn#"K", 2, 6)
mon = monomialEvaluationMatrix(X, nn#"degree")
{numRows mon, numColumns mon}
computeDimension({2,3,1}, 2)
computeDimension({2,3,1}, 2)

nn = makeNetwork({2,3,1}, 2, 100003)
X = randMat(nn#"K", 2, 6)
submatrixByLists(X, {0,1}, {0})


G = gradientSamplesMatrix(nn, X, 0)
{numRows G, numColumns G}


queryExample = (QD,rDeg) ->(
    out1 := timing computeDimension(QD, rDeg);
    print out1;
    out2 := for i from 1 to #QD-2 list(
	print i;
	decreasedQD =replace(i,(QD_i)-1,QD);
	--print decreasedQD;
	timing outB:=computeDimension(decreasedQD, rDeg);
	print outB;
	outB
	);
    out1=>out2
    )

QD = {2,3,4,5,4,6,4,1}
queryExample (QD,2)
