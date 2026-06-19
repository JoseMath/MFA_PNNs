------------------------------------------------------------
-- step3_architecture_search.m2
-- Step 3: architecture search utilities on top of Step 2
--
-- This file extends the Step 2 Macaulay2 code with helpers to:
--   * generate hidden-width tuples
--   * build architectures in a box [m,n]^k
--   * build architectures with per-layer bounds
--   * run computeDimension over many architectures
--   * filter filling architectures (defect = 0)
--
-- It assumes step2_compute_dimension.m2 is available and loadable.
------------------------------------------------------------

-- Uncomment and edit the path if needed:
-- load "step2_compute_dimension.m2"

------------------------------------------------------------
-- Small utilities
------------------------------------------------------------

lastEntry = L -> L#(#L - 1);

allEqual = L -> (
    if #L == 0 then true else all(L, x -> x == first L)
);

rangeList = (m, n) -> apply(n - m + 1, i -> m + i);

------------------------------------------------------------
-- Cartesian products / tuple generation
------------------------------------------------------------

-- allTuples(k, vals)
-- Return all length-k lists with entries from vals
allTuples = (k, vals) -> (
    if k == 0 then return {{}};
    tails := allTuples(k - 1, vals);
    flatten apply(vals, v -> apply(tails, t -> prepend(v, t)))
);

-- allBoundedTuples(bounds)
-- bounds is a list of pairs {{m1,n1},...,{mk,nk}}
-- Return all tuples {a1,...,ak} with ai in [mi,ni]
allBoundedTuples = bounds -> (
    if #bounds == 0 then return {{}};
    firstBounds := first bounds;
    tailBounds := drop(bounds, 1);
    vals := rangeList(firstBounds#0, firstBounds#1);
    tails := allBoundedTuples(tailBounds);
    flatten apply(vals, v -> apply(tails, t -> prepend(v, t)))
);

------------------------------------------------------------
-- Architecture constructors
------------------------------------------------------------

-- architectureFromHidden(d0, dL, hidden)
-- Example: architectureFromHidden(2,1,{3,4}) = {2,3,4,1}
architectureFromHidden = (d0, dL, hidden) -> join({d0}, join(hidden, {dL}));

-- architecturesUniform(d0, dL, numHidden, m, n)
-- All architectures {d0, a1, ..., ak, dL} with k=numHidden and ai in [m,n]
architecturesUniform = (d0, dL, numHidden, m, n) -> (
    tuples := allTuples(numHidden, rangeList(m, n));
    apply(tuples, t -> architectureFromHidden(d0, dL, t))
);

-- architecturesVariable(d0, dL, bounds)
-- bounds = {{m1,n1},...,{mk,nk}}
architecturesVariable = (d0, dL, bounds) -> (
    tuples := allBoundedTuples(bounds);
    apply(tuples, t -> architectureFromHidden(d0, dL, t))
);

------------------------------------------------------------
-- Result helpers
------------------------------------------------------------

-- The Step 2 output format is:
-- {sizes, exponent, ambient_dim, expected_dim, dimension, defect}

resultSizes       = res -> res#0;
resultExponent    = res -> res#1;
resultAmbientDim  = res -> res#2;
resultExpectedDim = res -> res#3;
resultDimension   = res -> res#4;
resultDefect      = res -> res#5;

isFillingResult = res -> resultDefect(res) == 0;

------------------------------------------------------------
-- Search routines
------------------------------------------------------------

-- searchArchitectures(archList, exponent)
-- Run computeDimension on each architecture in archList.
-- Returns a list of Step 2 results.
-*
searchArchitectures = (archList, exponent) -> (
    apply(archList, arch -> computeDimension(arch, exponent))
);
*-
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


-- searchArchitecturesUniform(d0, dL, numHidden, m, n, exponent)
searchArchitecturesUniform = (d0, dL, numHidden, m, n, exponent) -> (
    archs := architecturesUniform(d0, dL, numHidden, m, n);
    searchArchitectures(archs, exponent)
);

-- searchArchitecturesVariable(d0, dL, bounds, exponent)
searchArchitecturesVariable = (d0, dL, bounds, exponent) -> (
    archs := architecturesVariable(d0, dL, bounds);
    searchArchitectures(archs, exponent)
);

------------------------------------------------------------
-- Filtering helpers
------------------------------------------------------------

-- fillingArchitecturesFromResults(results)
-- Keep only those with defect 0
fillingArchitecturesFromResults = results -> select(results, res -> isFillingResult res);

-- nonFillingArchitecturesFromResults(results)
nonFillingArchitecturesFromResults = results -> select(results, res -> not isFillingResult res);

-- architectureListFromResults(results)
architectureListFromResults = results -> apply(results, res -> resultSizes res);

-- fillingArchitectureList(results)
fillingArchitectureList = results -> architectureListFromResults(fillingArchitecturesFromResults results);

------------------------------------------------------------
-- Simple sorting helpers
------------------------------------------------------------

-- parameterCount(arch)
-- Number of weights (biases are zero in the current model)
parameterCount = arch -> (
    sum apply(#arch - 1, i -> arch#i * arch#(i + 1))
);

-- totalWidth(arch)
totalWidth = arch -> sum arch;

-- compare architectures lexicographically via string representation
archString = arch -> toString arch;

sortResultsByArchitecture = results -> sort(results, (a,b) -> archString(resultSizes a) < archString(resultSizes b));
sortResultsByDefect = results -> sort(results, (a,b) -> resultDefect(a) < resultDefect(b));
sortResultsByDimension = results -> sort(results, (a,b) -> resultDimension(a) < resultDimension(b));
sortResultsByParameterCount = results -> sort(results, (a,b) -> parameterCount(resultSizes a) < parameterCount(resultSizes b));

------------------------------------------------------------
-- Pretty-print helpers
------------------------------------------------------------

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

printFillingResults = results -> printResults(fillingArchitecturesFromResults results);

------------------------------------------------------------
-- Search summaries
------------------------------------------------------------

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

------------------------------------------------------------
-- Minimality relative to a searched set
------------------------------------------------------------

-- coordinateWiseLEQ(a,b): true iff a_i <= b_i for all i
coordinateWiseLEQ = (a, b) -> (
    if #a =!= #b then error "coordinateWiseLEQ: lists must have same length";
    all(#a, i -> a#i <= b#i)
);

-- isMinimalInResults(res, results)
-- A result is minimal in the searched set if it is filling and there is no
-- different filling architecture of the same length that is coordinate-wise <= it.
isMinimalInResults = (res, results) -> (
    if not isFillingResult res then return false;
    arch := resultSizes res;
    fills := fillingArchitecturesFromResults results;
    smallerOrEqual := select(fills, s -> #resultSizes(s) == #arch and coordinateWiseLEQ(resultSizes s, arch));
    -- Only itself should be <= itself among filling results
    #smallerOrEqual == 1
);

minimalFillingResults = results -> select(results, r -> isMinimalInResults(r, results));

------------------------------------------------------------
-- One-stop convenience wrappers
------------------------------------------------------------

-*
runUniformSearch = (d0, dL, numHidden, m, n, exponent) -> (
    results := searchArchitecturesUniform(d0, dL, numHidden, m, n, exponent);
    printSearchSummary results;
    results
);
*-

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

-*
runVariableSearch = (d0, dL, bounds, exponent) -> (
    results := searchArchitecturesVariable(d0, dL, bounds, exponent);
    printSearchSummary results;
    results
);
*-

runVariableSearch = (d0, dL, bounds, exponent) -> (
    << "Running variable-bounds search over architectures of the form" << endl;
    << "  {" << toString d0 << ", a1, ..., a" << toString (#bounds) << ", " << toString dL << "}" << endl;
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
-- Suggested examples
--
-- 1) Load Step 2 first, then this file:
--    load "step2_compute_dimension.m2"
--    load "step3_architecture_search.m2"
--
-- 2) Uniform search over one hidden layer with widths in [2,4]:
--    results = runUniformSearch(2,1,1,2,4,2)
--    printResults results
--
-- 3) Uniform search over two hidden layers, widths in [2,3]:
--    results2 = runUniformSearch(2,1,2,2,3,2)
--    printFillingResults results2
--    mins = minimalFillingResults results2
--    printResults mins
--
-- 4) Variable-bounds search:
--    bounds = {{2,3},{3,4},{2,5}}
--    results3 = runVariableSearch(2,1,bounds,2)
--
-- 5) Get only the filling architectures:
--    fillingArchitectureList results2
------------------------------------------------------------



------------------------------------------------------------
-- step3_unimodality_addon.m2
-- Add-on for Step 3 architecture search utilities:
-- unimodality checks and counterexample filters
--
-- Load after:
--   load "step2_compute_dimension.m2"
--   load "step3_architecture_search.m2"
------------------------------------------------------------

------------------------------------------------------------
-- Basic unimodality helpers
------------------------------------------------------------

-- isWeaklyIncreasing(L): true iff L_i <= L_{i+1} for all i
isWeaklyIncreasing = L -> (
    if #L <= 1 then true else all(#L - 1, i -> L#i <= L#(i + 1))
);

-- isWeaklyDecreasing(L): true iff L_i >= L_{i+1} for all i
isWeaklyDecreasing = L -> (
    if #L <= 1 then true else all(#L - 1, i -> L#i >= L#(i + 1))
);

-- isUnimodal(L): true iff L is weakly increasing up to some index and
-- then weakly decreasing afterwards.
--
-- Examples:
--   isUnimodal {2,3,5,4,1}  --> true
--   isUnimodal {2,3,3,3,1}  --> true
--   isUnimodal {2,3,2,4,1}  --> false
isUnimodal = L -> (
    n := #L;
    if n <= 2 then return true;
    any(0 .. n - 1, k -> (
        isWeaklyIncreasing(L_(toList(0 .. k))) and
        isWeaklyDecreasing(L_(toList(k .. n - 1)))
    ))
);

------------------------------------------------------------
-- Architecture-level unimodality
------------------------------------------------------------

-- hiddenLayerWidths({d0,a1,...,ak,dL}) = {a1,...,ak}
hiddenLayerWidths = arch -> (
    if #arch <= 2 then {} else arch_(toList(1 .. #arch - 2))
);

-- Choose one of these two conventions depending on your use case:
--   * isUnimodalArchitecture(arch): test the full architecture
--   * isUnimodalHiddenLayers(arch): test only hidden widths
isUnimodalArchitecture = arch -> isUnimodal arch;
isUnimodalHiddenLayers = arch -> isUnimodal(hiddenLayerWidths arch);

------------------------------------------------------------
-- Filters for search results
--
-- Assumes Step 3 helpers such as resultSizes, isFillingResult,
-- architectureListFromResults, and printResults are already loaded.
------------------------------------------------------------

unimodalResults = results -> select(results, r -> isUnimodalArchitecture(resultSizes r));
nonUnimodalResults = results -> select(results, r -> not isUnimodalArchitecture(resultSizes r));

unimodalArchitectureList = results -> architectureListFromResults(unimodalResults results);
nonUnimodalArchitectureList = results -> architectureListFromResults(nonUnimodalResults results);

-- Candidate counterexamples inside a searched set:
-- filling but non-unimodal.
counterexampleCandidates = results -> select(results,
    r -> isFillingResult r and not isUnimodalArchitecture(resultSizes r)
);

printCounterexampleCandidates = results -> printResults(counterexampleCandidates results);

------------------------------------------------------------
-- Suggested tests
--
-- load "step2_compute_dimension.m2"
-- load "step3_architecture_search.m2"
-- load "step3_unimodality_addon.m2"
--

------------------------------------------------------------


end

load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/step2_compute_dimension.m2"
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/step3_architecture_search.m2"
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/step4_frontier_search.m2"
results = runUniformSearch(2, 1, 1, 2, 4, 2)
printResults results

bounds = {{2,5},{2,5},{2,5}}
results3 = runVariableSearch(2, 1, bounds, 2)
printResults results3


queryExample = (QD,rDeg) ->(
    out1 := timing computeDimension(QD, rDeg);
    print out1;
    out2 := for i from 1 to #QD-2 list(
	print i;
	decreasedQD =replace(i,(QD_i)-1,QD);
	print decreasedQD;
	timing outB:=computeDimension(decreasedQD, rDeg);
	print outB;
	outB
	);
    out1=>out2
    )

isUnimodal {2,3,4,5,4,1}
isUnimodal {2,3,4,3,5,1}
hiddenLayerWidths {2,3,4,5,4,1}
isUnimodalHiddenLayers {2,3,4,5,4,1}
results = runUniformSearch(2,1,2,2,4,2)
printCounterexampleCandidates results3

QD = {2, 4, 3, 4, 1} 
netList last queryExample (QD,2)
isUnimodalArchitecture(QD)


bounds = {{2,3},{3,4},{2,5}}
results = runVariableSearch(2, 1, bounds, 2)


searchArchitectures ({{2,3,3,2,1}}, 2)

for i from 3 to 30 list searchArchitectures ({{2,3,2,i,1}}, 2)

startTime = currentTime()
out = runFrontierSearch(6, 2, 1, 2, 5, 2, 100000, 12345)
printFrontierFillingResults out
endTime = currentTime()
print(endTime-startTime|" seconds")

startTime = currentTime()
out = runFrontierSearch(7, 2, 1, 2, 7, 2, 10000, 12345)
printFrontierFillingResults out
endTime = currentTime()
print(endTime-startTime|" seconds")

load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/step4_dual_ideal_example.m2"
demoDualBookkeeping()
