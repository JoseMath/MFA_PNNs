------------------------------------------------------------
-- MinimalFillingArchitectures.m2
--
-- A Macaulay2-style package for searching for minimal filling
-- architectures in polynomial neural networks.
--
-- This package bundles:
--   * dimension computation via sampled Jacobian rank over finite fields,
--   * exhaustive searches over architecture boxes,
--   * filling / minimality bookkeeping,
--   * unimodality checks,
--   * randomized frontier search,
--   * guided frontier search using midpoint proposals.
------------------------------------------------------------

newPackage(
    "MinimalFillingArchitectures",
    Version => "0.1",
    Date => "June 18, 2026",
    Authors => {{Name => ""}},
    Headline => "Search tools for minimal filling architectures of polynomial neural networks",
    DebuggingMode => false
)

export {
    "zeroMat", "onesMat", "randMat", "basisVector",
    "entrywisePower", "entrywisePowerPrime", "hadamardProduct",
    "weakCompositions", "monomialList",
    "makeNetwork", "feedforward", "backprop",
    "monomialEvaluationMatrix", "submatrixByLists",
    "independentRowIndices", "recoverCoefficientMatrix",
    "gradientSamplesMatrix", "computeDimension",
    "allTuples", "allBoundedTuples", "architectureFromHidden",
    "architecturesUniform", "architecturesVariable",
    "searchArchitectures", "searchArchitecturesUniform", "searchArchitecturesVariable",
    "fillingArchitecturesFromResults", "nonFillingArchitecturesFromResults",
    "minimalFillingResults", "runUniformSearch", "runVariableSearch",
    "isUnimodal", "hiddenLayerWidths", "isUnimodalArchitecture",
    "isUnimodalHiddenLayers", "counterexampleCandidates",
    "frontierSearchHidden", "runFrontierSearch",
    "frontierSearchHiddenGuided", "runGuidedFrontierSearch",
    "printResult", "printResults", "printSearchSummary",
    "printFrontierSummary", "printFrontierFillingResults",
    "printGuidedFrontierSummary", "printGuidedFrontierFillingResults"
}

begin

------------------------------------------------------------
-- Basic matrix helpers
------------------------------------------------------------

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

submatrixByLists = (M, rowIdx, colIdx) -> (
    E := entries M;
    matrix apply(rowIdx, i ->
        apply(colIdx, j -> (E#i)#j)
    )
);

------------------------------------------------------------
-- Weak compositions and monomials
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

monomialList = (v, k) -> (
    expsList := weakCompositions(k, #v);
    apply(expsList, a -> product apply(#v, i -> (v#i)^(a#i)))
);

------------------------------------------------------------
-- Network construction and backpropagation
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

    delta := pullbackVector;
    nablaB#(nWeights - 1) = delta;
    nablaW#(nWeights - 1) = delta * transpose(activations#(#activations - 1));

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
-- Dimension computation
------------------------------------------------------------

monomialEvaluationMatrix = (X, degree) -> (
    rows := for j from 0 to numColumns X - 1 list (
        v := for i from 0 to numRows X - 1 list X_(i,j);
        monomialList(v, degree)
    );
    matrix rows
);

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

recoverCoefficientMatrix = (monomials, gradientsSamples) -> (
    idx := independentRowIndices monomials;
    monoCols := toList(0 .. numColumns monomials - 1);
    gradCols := toList(0 .. numColumns gradientsSamples - 1);

    Msq := submatrixByLists(monomials, idx, monoCols);
    Gsq := submatrixByLists(gradientsSamples, idx, gradCols);

    (inverse Msq) * Gsq
);

gradientSamplesMatrix = (nn, X, j) -> (
    sizes := nn#"sizes";
    K := nn#"K";
    outDim := sizes#(#sizes - 1);
    nsamples := numColumns X;
    basisVec := basisVector(K, outDim, j);

    rows := for i from 0 to nsamples - 1 list (
        xi := submatrixByLists(X, toList(0 .. numRows X - 1), {i});
        grads := backprop(nn, xi, basisVec);
        gradMats := grads#1;
        flatten apply(gradMats, M -> flattenMatrixEntries M)
    );

    matrix rows
);

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
        monomials := monomialEvaluationMatrix(X, degree);

        jacobianRows := {};

        for j from 0 to outDim - 1 do (
            gradientsSamples := gradientSamplesMatrix(nn, X, j);
            coeffs := recoverCoefficientMatrix(monomials, gradientsSamples);
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
-- Search utilities
------------------------------------------------------------

lastEntry = L -> L#(#L - 1);
rangeList = (m, n) -> apply(n - m + 1, i -> m + i);

allTuples = (k, vals) -> (
    if k == 0 then return {{}};
    tails := allTuples(k - 1, vals);
    flatten apply(vals, v -> apply(tails, t -> prepend(v, t)))
);

allBoundedTuples = bounds -> (
    if #bounds == 0 then return {{}};
    firstBounds := first bounds;
    tailBounds := drop(bounds, 1);
    vals := rangeList(firstBounds#0, firstBounds#1);
    tails := allBoundedTuples(tailBounds);
    flatten apply(vals, v -> apply(tails, t -> prepend(v, t)))
);

architectureFromHidden = (d0, dL, hidden) -> join({d0}, join(hidden, {dL}));

architecturesUniform = (d0, dL, numHidden, m, n) -> (
    tuples := allTuples(numHidden, rangeList(m, n));
    apply(tuples, t -> architectureFromHidden(d0, dL, t))
);

architecturesVariable = (d0, dL, bounds) -> (
    tuples := allBoundedTuples(bounds);
    apply(tuples, t -> architectureFromHidden(d0, dL, t))
);

resultSizes       = res -> res#0;
resultExponent    = res -> res#1;
resultAmbientDim  = res -> res#2;
resultExpectedDim = res -> res#3;
resultDimension   = res -> res#4;
resultDefect      = res -> res#5;

isFillingResult = res -> resultDefect(res) == 0;

searchArchitectures = (archList, exponent) -> (
    total := #archList;
    apply(0 .. total - 1, i -> (
        arch := archList#i;
        << "Evaluating architecture " << toString(i + 1)
           << " of " << toString total
           << ": " << toString arch << endl;
        res := computeDimension(arch, exponent);
        << "  -> dim = " << toString(res#4)
           << ", defect = " << toString(res#5) << endl;
        res
    ))
);

searchArchitecturesUniform = (d0, dL, numHidden, m, n, exponent) -> (
    archs := architecturesUniform(d0, dL, numHidden, m, n);
    searchArchitectures(archs, exponent)
);

searchArchitecturesVariable = (d0, dL, bounds, exponent) -> (
    archs := architecturesVariable(d0, dL, bounds);
    searchArchitectures(archs, exponent)
);

fillingArchitecturesFromResults = results -> select(results, res -> isFillingResult res);
nonFillingArchitecturesFromResults = results -> select(results, res -> not isFillingResult res);
architectureListFromResults = results -> apply(results, res -> resultSizes res);

parameterCount = arch -> sum apply(#arch - 1, i -> arch#i * arch#(i + 1));

coordinateWiseLEQ = (a, b) -> (
    if #a =!= #b then error "coordinateWiseLEQ: lists must have same length";
    all(#a, i -> a#i <= b#i)
);

isMinimalInResults = (res, results) -> (
    if not isFillingResult res then return false;
    arch := resultSizes res;
    fills := fillingArchitecturesFromResults results;
    smallerOrEqual := select(fills, s -> #resultSizes(s) == #arch and coordinateWiseLEQ(resultSizes s, arch));
    #smallerOrEqual == 1
);

minimalFillingResults = results -> select(results, r -> isMinimalInResults(r, results));

printResult = res -> (
    << "architecture = " << toString(resultSizes res)
       << ", r = " << toString(resultExponent res)
       << ", ambient = " << toString(resultAmbientDim res)
       << ", expected = " << toString(resultExpectedDim res)
       << ", dim = " << toString(resultDimension res)
       << ", defect = " << toString(resultDefect res)
       << endl;
);

printResults = results -> scan(results, r -> printResult r);

searchSummary = results -> (
    nAll := #results;
    fills := fillingArchitecturesFromResults results;
    nFill := #fills;
    defects := apply(results, r -> resultDefect r);
    minDefect := if #defects == 0 then null else min defects;
    maxDefect := if #defects == 0 then null else max defects;

    hashTable {
        "numArchitectures" => nAll,
        "numFilling" => nFill,
        "numNonFilling" => nAll - nFill,
        "minDefect" => minDefect,
        "maxDefect" => maxDefect
    }
);

printSearchSummary = results -> (
    s := searchSummary results;
    << "number of architectures searched = " << toString(s#"numArchitectures") << endl;
    << "number of filling architectures = " << toString(s#"numFilling") << endl;
    << "number of non-filling architectures = " << toString(s#"numNonFilling") << endl;
    << "minimum defect = " << toString(s#"minDefect") << endl;
    << "maximum defect = " << toString(s#"maxDefect") << endl;
);

runUniformSearch = (d0, dL, numHidden, m, n, exponent) -> (
    << "Running uniform search over architectures of the form" << endl;
    << "  {" << toString d0 << ", a1, ..., a" << toString numHidden << ", " << toString dL << "}" << endl;
    << "with each hidden width ai in [" << toString m << ", " << toString n << "]" << endl;
    << "and exponent r = " << toString exponent << endl;
    << "Total architectures to test = " << toString((n - m + 1)^numHidden) << endl;
    << endl;
    results := searchArchitecturesUniform(d0, dL, numHidden, m, n, exponent);
    << "Search complete." << endl;
    printSearchSummary results;
    results
);

runVariableSearch = (d0, dL, bounds, exponent) -> (
    << "Running variable-bounds search over architectures of the form" << endl;
    << "  {" << toString d0 << ", a1, ..., a" << toString #bounds << ", " << toString dL << "}" << endl;
    << "with hidden-layer bounds:" << endl;
    scan(0 .. #bounds - 1, i -> (
        << "  a" << toString(i + 1)
           << " in [" << toString((bounds#i)#0)
           << ", " << toString((bounds#i)#1) << "]" << endl;
    ));
    << "and exponent r = " << toString exponent << endl;
    << "Total architectures to test = "
       << toString(product apply(bounds, b -> b#1 - b#0 + 1)) << endl;
    << endl;
    results := searchArchitecturesVariable(d0, dL, bounds, exponent);
    << "Search complete." << endl;
    printSearchSummary results;
    results
);

------------------------------------------------------------
-- Unimodality helpers
------------------------------------------------------------

isWeaklyIncreasing = L -> (
    if #L <= 1 then true else all(#L - 1, i -> L#i <= L#(i + 1))
);

isWeaklyDecreasing = L -> (
    if #L <= 1 then true else all(#L - 1, i -> L#i >= L#(i + 1))
);

isUnimodal = L -> (
    n := #L;
    if n <= 2 then return true;
    any(0 .. n - 1, k -> (
        isWeaklyIncreasing(L_(toList(0 .. k))) and
        isWeaklyDecreasing(L_(toList(k .. n - 1)))
    ))
);

hiddenLayerWidths = arch -> (
    if #arch <= 2 then {} else arch_(toList(1 .. #arch - 2))
);

isUnimodalArchitecture = arch -> isUnimodal arch;
isUnimodalHiddenLayers = arch -> isUnimodal(hiddenLayerWidths arch);

counterexampleCandidates = results -> select(results,
    r -> isFillingResult r and not isUnimodalArchitecture(resultSizes r)
);

------------------------------------------------------------
-- Frontier search (random)
------------------------------------------------------------

tupleEQ = (a, b) -> (
    if #a =!= #b then false else all(#a, i -> a#i == b#i)
);

tupleLEQ = (a, b) -> (
    if #a =!= #b then error "tupleLEQ: tuples must have same length";
    all(#a, i -> a#i <= b#i)
);

tupleGEQ = (a, b) -> tupleLEQ(b, a);
tupleLT = (a, b) -> tupleLEQ(a, b) and not tupleEQ(a, b);
tupleGT = (a, b) -> tupleGEQ(a, b) and not tupleEQ(a, b);

impliedFilling = (a, Fmin) -> any(Fmin, f -> tupleGEQ(a, f));
impliedNonFilling = (a, Nmax) -> any(Nmax, q -> tupleLEQ(a, q));

updateMinimalAntichain = (Fmin, a) -> (
    if any(Fmin, f -> tupleEQ(f, a)) then return Fmin;
    kept := select(Fmin, f -> not tupleGT(f, a));
    join(kept, {a})
);

updateMaximalAntichain = (Nmax, a) -> (
    if any(Nmax, q -> tupleEQ(q, a)) then return Nmax;
    kept := select(Nmax, q -> not tupleLT(q, a));
    join(kept, {a})
);

randomHiddenTuple = (k, m, n) -> (
    if n < m then error "randomHiddenTuple: require m <= n";
    apply(k, i -> m + random(n - m + 1))
);

printTupleList = (label, L) -> (
    << label << endl;
    if #L == 0 then (
        << "  <empty>" << endl;
    ) else (
        scan(L, a -> << "  " << toString a << endl);
    );
);

frontierSearchHidden = (depth, d0, dL, m, n, r, B, seed) -> (
    if depth < 1 then error "frontierSearchHidden: require depth >= 1";
    if n < m then error "frontierSearchHidden: require m <= n";

    k := depth - 1;
    if seed =!= null then setRandomSeed seed;

    Fmin := {};
    Nmax := {};
    FminResults := {};

    nEvaluated := 0;
    nSkippedByFilling := 0;
    nSkippedByNonFilling := 0;

    << "Running frontier search with:" << endl;
    << "  depth = " << toString depth << endl;
    << "  architecture form = {" << toString d0 << ", a1, ..., a" << toString k << ", " << toString dL << "}" << endl;
    << "  hidden widths in [" << toString m << ", " << toString n << "]" << endl;
    << "  exponent r = " << toString r << endl;
    << "  budget B = " << toString B << endl;
    if seed =!= null then << "  seed = " << toString seed << endl;
    << endl;

    for t from 1 to B do (
        a := randomHiddenTuple(k, m, n);
        << "Iteration " << toString t << " / " << toString B
           << ": proposed hidden widths " << toString a << endl;
        if impliedFilling(a, Fmin) then (
            nSkippedByFilling = nSkippedByFilling + 1;
            << "  skipped (implied filling by current Fmin)" << endl;
        ) else if impliedNonFilling(a, Nmax) then (
            nSkippedByNonFilling = nSkippedByNonFilling + 1;
            << "  skipped (implied non-filling by current Nmax)" << endl;
        ) else (
            arch := architectureFromHidden(d0, dL, a);
            << "  evaluating architecture " << toString arch << endl;
            res := computeDimension(arch, r);
            nEvaluated = nEvaluated + 1;
            << "  -> dim = " << toString(resultDimension res)
               << ", defect = " << toString(resultDefect res) << endl;
            if isFillingResult res then (
                Fmin = updateMinimalAntichain(Fmin, a);
                FminResults = select(FminResults, rr -> not tupleGT(hiddenWidths(resultSizes rr), a));
                if not any(FminResults, rr -> tupleEQ(hiddenWidths(resultSizes rr), a)) then
                    FminResults = join(FminResults, {res});
                << "  classified as filling; updated Fmin" << endl;
            ) else (
                Nmax = updateMaximalAntichain(Nmax, a);
                << "  classified as non-filling; updated Nmax" << endl;
            );
        );
        << endl;
    );

    hashTable {
        "FminTuples" => Fmin,
        "NmaxTuples" => Nmax,
        "FminArchitectures" => apply(Fmin, a -> architectureFromHidden(d0, dL, a)),
        "FminResults" => FminResults,
        "nEvaluated" => nEvaluated,
        "nSkippedByFilling" => nSkippedByFilling,
        "nSkippedByNonFilling" => nSkippedByNonFilling,
        "budget" => B,
        "depth" => depth,
        "d0" => d0,
        "dL" => dL,
        "range" => {m, n},
        "exponent" => r,
        "seed" => seed
    }
);

printFrontierSummary = out -> (
    << "Frontier search summary" << endl;
    << "  evaluated candidates = " << toString(out#"nEvaluated") << endl;
    << "  skipped by filling implication = " << toString(out#"nSkippedByFilling") << endl;
    << "  skipped by non-filling implication = " << toString(out#"nSkippedByNonFilling") << endl;
    << "  final |Fmin| = " << toString(#(out#"FminTuples")) << endl;
    << "  final |Nmax| = " << toString(#(out#"NmaxTuples")) << endl;
    << endl;
    printTupleList("Fmin hidden tuples:", out#"FminTuples");
    << endl;
    printTupleList("Nmax hidden tuples:", out#"NmaxTuples");
);

printFrontierFillingResults = out -> (
    << "Minimal filling results currently stored in Fmin:" << endl;
    if #(out#"FminResults") == 0 then (
        << "  <empty>" << endl;
    ) else (
        scan(out#"FminResults", res -> ( << "  "; printStep2ResultHelper res; ));
    );
);

-- helper to avoid recursion confusion
printStep2ResultHelper = res -> (
    << "architecture = " << toString(resultSizes res)
       << ", r = " << toString(resultExponent res)
       << ", ambient = " << toString(resultAmbientDim res)
       << ", expected = " << toString(resultExpectedDim res)
       << ", dim = " << toString(resultDimension res)
       << ", defect = " << toString(resultDefect res)
       << endl;
);

runFrontierSearch = (depth, d0, dL, m, n, r, B, seed) -> (
    out := frontierSearchHidden(depth, d0, dL, m, n, r, B, seed);
    printFrontierSummary out;
    out
);

------------------------------------------------------------
-- Guided frontier search
------------------------------------------------------------

coordinateWiseStrictInterior = (a, q, f) -> (
    tupleGEQ(a, q) and tupleLEQ(a, f) and not tupleEQ(a, q) and not tupleEQ(a, f)
);

comparablePairs = (Nmax, Fmin) -> flatten apply(Nmax, q ->
    apply(select(Fmin, f -> tupleLT(q, f)), f -> {q, f})
);

pairGapVolume = pair -> (
    q := pair#0; f := pair#1;
    product apply(#q, i -> f#i - q#i + 1)
);

uniqueTuples = L -> (
    out := {};
    scan(L, a -> (
        if not any(out, b -> tupleEQ(a, b)) then out = join(out, {a});
    ));
    out
);

midpointCandidates = pair -> (
    q := pair#0; f := pair#1;
    lows := apply(#q, i -> floor((q#i + f#i)/2));
    highs := apply(#q, i -> ceiling((q#i + f#i)/2));

    buildCombos = (i, partial) -> (
        if i == #q then return {partial};
        vals := if lows#i == highs#i then {lows#i} else {lows#i, highs#i};
        flatten apply(vals, v -> buildCombos(i + 1, append(partial, v)))
    );

    cands := buildCombos(0, {});
    uniqueTuples select(cands, a -> coordinateWiseStrictInterior(a, q, f) or
        (tupleGEQ(a, q) and tupleLEQ(a, f) and not tupleEQ(a, q) and not tupleEQ(a, f)))
);

nearbyInteriorCandidates = pair -> (
    q := pair#0; f := pair#1;
    mids := midpointCandidates pair;
    if #mids == 0 then return {};

    gaps := apply(#q, i -> f#i - q#i);
    maxGap := max gaps;
    bigCoords := select(toList(0 .. #q - 1), i -> gaps#i == maxGap);

    perturbOne = (a, i) -> uniqueTuples select({
        apply(#a, j -> if j == i then a#j - 1 else a#j),
        apply(#a, j -> if j == i then a#j + 1 else a#j)
    }, b -> coordinateWiseStrictInterior(b, q, f));

    uniqueTuples flatten apply(mids, a -> flatten apply(bigCoords, i -> perturbOne(a, i)))
);

chooseGuidedCandidateFiltered = (Fmin, Nmax) -> (
    pairs := comparablePairs(Nmax, Fmin);
    if #pairs == 0 then return null;
    orderedPairs := sort(pairs, (A, B) -> pairGapVolume(A) > pairGapVolume(B));

    for pair in orderedPairs do (
        mids := midpointCandidates pair;
        goodMid := select(mids, a -> not impliedFilling(a, Fmin) and not impliedNonFilling(a, Nmax));
        if #goodMid > 0 then return first goodMid;

        near := nearbyInteriorCandidates pair;
        goodNear := select(near, a -> not impliedFilling(a, Fmin) and not impliedNonFilling(a, Nmax));
        if #goodNear > 0 then return first goodNear;
    );

    null
);

frontierSearchHiddenGuided = (depth, d0, dL, m, n, r, B, seed) -> (
    if depth < 1 then error "frontierSearchHiddenGuided: require depth >= 1";
    if n < m then error "frontierSearchHiddenGuided: require m <= n";

    k := depth - 1;
    if seed =!= null then setRandomSeed seed;

    Fmin := {};
    Nmax := {};
    FminResults := {};

    nEvaluated := 0;
    nSkippedByFilling := 0;
    nSkippedByNonFilling := 0;
    nGuidedProposals := 0;
    nRandomProposals := 0;

    << "Running guided frontier search with:" << endl;
    << "  depth = " << toString depth << endl;
    << "  architecture form = {" << toString d0 << ", a1, ..., a" << toString k << ", " << toString dL << "}" << endl;
    << "  hidden widths in [" << toString m << ", " << toString n << "]" << endl;
    << "  exponent r = " << toString r << endl;
    << "  budget B = " << toString B << endl;
    if seed =!= null then << "  seed = " << toString seed << endl;
    << endl;

    for t from 1 to B do (
        guided := chooseGuidedCandidateFiltered(Fmin, Nmax);
        if guided === null then (
            a := randomHiddenTuple(k, m, n);
            proposalType := "random";
            nRandomProposals = nRandomProposals + 1;
        ) else (
            a := guided;
            proposalType := "guided";
            nGuidedProposals = nGuidedProposals + 1;
        );

        << "Iteration " << toString t << " / " << toString B
           << ": proposed hidden widths " << toString a
           << " (" << proposalType << ")" << endl;

        if impliedFilling(a, Fmin) then (
            nSkippedByFilling = nSkippedByFilling + 1;
            << "  skipped (implied filling by current Fmin)" << endl;
        ) else if impliedNonFilling(a, Nmax) then (
            nSkippedByNonFilling = nSkippedByNonFilling + 1;
            << "  skipped (implied non-filling by current Nmax)" << endl;
        ) else (
            arch := architectureFromHidden(d0, dL, a);
            << "  evaluating architecture " << toString arch << endl;
            res := computeDimension(arch, r);
            nEvaluated = nEvaluated + 1;
            << "  -> dim = " << toString(resultDimension res)
               << ", defect = " << toString(resultDefect res) << endl;
            if isFillingResult res then (
                Fmin = updateMinimalAntichain(Fmin, a);
                FminResults = select(FminResults, rr -> not tupleGT(hiddenWidths(resultSizes rr), a));
                if not any(FminResults, rr -> tupleEQ(hiddenWidths(resultSizes rr), a)) then
                    FminResults = join(FminResults, {res});
                << "  classified as filling; updated Fmin" << endl;
            ) else (
                Nmax = updateMaximalAntichain(Nmax, a);
                << "  classified as non-filling; updated Nmax" << endl;
            );
        );
        << endl;
    );

    hashTable {
        "FminTuples" => Fmin,
        "NmaxTuples" => Nmax,
        "FminArchitectures" => apply(Fmin, a -> architectureFromHidden(d0, dL, a)),
        "FminResults" => FminResults,
        "nEvaluated" => nEvaluated,
        "nSkippedByFilling" => nSkippedByFilling,
        "nSkippedByNonFilling" => nSkippedByNonFilling,
        "nGuidedProposals" => nGuidedProposals,
        "nRandomProposals" => nRandomProposals,
        "budget" => B,
        "depth" => depth,
        "d0" => d0,
        "dL" => dL,
        "range" => {m, n},
        "exponent" => r,
        "seed" => seed
    }
);

printGuidedFrontierSummary = out -> (
    << "Guided frontier search summary" << endl;
    << "  evaluated candidates = " << toString(out#"nEvaluated") << endl;
    << "  guided proposals used = " << toString(out#"nGuidedProposals") << endl;
    << "  random proposals used = " << toString(out#"nRandomProposals") << endl;
    << "  skipped by filling implication = " << toString(out#"nSkippedByFilling") << endl;
    << "  skipped by non-filling implication = " << toString(out#"nSkippedByNonFilling") << endl;
    << "  final |Fmin| = " << toString(#(out#"FminTuples")) << endl;
    << "  final |Nmax| = " << toString(#(out#"NmaxTuples")) << endl;
    << endl;
    printTupleList("Fmin hidden tuples:", out#"FminTuples");
    << endl;
    printTupleList("Nmax hidden tuples:", out#"NmaxTuples");
);

printGuidedFrontierFillingResults = out -> (
    << "Minimal filling results currently stored in Fmin:" << endl;
    if #(out#"FminResults") == 0 then (
        << "  <empty>" << endl;
    ) else (
        scan(out#"FminResults", res -> ( << "  "; printStep2ResultHelper res; ));
    );
);

runGuidedFrontierSearch = (depth, d0, dL, m, n, r, B, seed) -> (
    out := frontierSearchHiddenGuided(depth, d0, dL, m, n, r, B, seed);
    printGuidedFrontierSummary out;
    out
);

------------------------------------------------------------
-- End package
------------------------------------------------------------

end
