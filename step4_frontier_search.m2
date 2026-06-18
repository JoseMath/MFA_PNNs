------------------------------------------------------------
-- step4_frontier_search.m2
-- Frontier search for hidden-layer widths
--
-- This file implements a Macaulay2 version of the frontier-search
-- idea:
--   * maintain a minimal filling antichain Fmin
--   * maintain a maximal non-filling antichain Nmax
--   * sample candidates in [m,n]^(depth-1)
--   * skip candidates implied filling or non-filling by dominance
--   * evaluate only unresolved candidates using computeDimension
--
-- Prerequisite:
--   load "step2_compute_dimension.m2"
--
-- Optional:
--   load "step3_architecture_search.m2"
--   load "step3_unimodality_addon.m2"
--
-- Output convention for computeDimension:
--   {sizes, exponent, ambient_dim, expected_dim, dimension, defect}
------------------------------------------------------------

------------------------------------------------------------
-- Basic small helpers
------------------------------------------------------------

resultSizes       = res -> res#0;
resultExponent    = res -> res#1;
resultAmbientDim  = res -> res#2;
resultExpectedDim = res -> res#3;
resultDimension   = res -> res#4;
resultDefect      = res -> res#5;

isFillingResult = res -> resultDefect(res) == 0;

architectureFromHidden = (d0, dL, hidden) -> join({d0}, join(hidden, {dL}));

------------------------------------------------------------
-- Coordinate-wise comparisons on hidden-width tuples
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

------------------------------------------------------------
-- Antichain logic
------------------------------------------------------------

-- impliedFilling(a, Fmin): true iff there exists f in Fmin with a >= f
impliedFilling = (a, Fmin) -> any(Fmin, f -> tupleGEQ(a, f));

-- impliedNonFilling(a, Nmax): true iff there exists q in Nmax with a <= q
impliedNonFilling = (a, Nmax) -> any(Nmax, q -> tupleLEQ(a, q));

-- Insert a into a minimal antichain and remove anything strictly larger
updateMinimalAntichain = (Fmin, a) -> (
    if any(Fmin, f -> tupleEQ(f, a)) then return Fmin;
    kept := select(Fmin, f -> not tupleGT(f, a));
    join(kept, {a})
);

-- Insert a into a maximal antichain and remove anything strictly smaller
updateMaximalAntichain = (Nmax, a) -> (
    if any(Nmax, q -> tupleEQ(q, a)) then return Nmax;
    kept := select(Nmax, q -> not tupleLT(q, a));
    join(kept, {a})
);

------------------------------------------------------------
-- Random candidate generation
------------------------------------------------------------

-- randomHiddenTuple(k, m, n)
-- Return a random k-tuple with entries in {m,...,n}
randomHiddenTuple = (k, m, n) -> (
    if n < m then error "randomHiddenTuple: require m <= n";
    apply(k, i -> m + random(n - m + 1))
);

------------------------------------------------------------
-- Pretty-print helpers
------------------------------------------------------------

printStep2Result = res -> (
    << "architecture = " << toString(resultSizes res)
       << ", r = " << toString(resultExponent res)
       << ", ambient = " << toString(resultAmbientDim res)
       << ", expected = " << toString(resultExpectedDim res)
       << ", dim = " << toString(resultDimension res)
       << ", defect = " << toString(resultDefect res)
       << endl;
);

printTupleList = (label, L) -> (
    << label << endl;
    if #L == 0 then (
        << "  <empty>" << endl;
    ) else (
        scan(L, a -> << "  " << toString a << endl);
    );
);

------------------------------------------------------------
-- Frontier search core
------------------------------------------------------------

-- frontierSearchHidden(depth, d0, dL, m, n, r, B, seed)
--
-- depth = total number of weight matrices / layers minus 1 in the
-- notebook-style convention, so hidden tuple length is depth - 1.
--
-- We keep antichains in hidden-width coordinates only. The filling test
-- uses the full architecture {d0, a1, ..., a_{depth-1}, dL}.
--
-- Returns a hash table with the antichains, the filling results attached
-- to Fmin, and summary counts.
frontierSearchHidden = (depth, d0, dL, m, n, r, B, seed) -> (
    if depth < 1 then error "frontierSearchHidden: require depth >= 1";
    if n < m then error "frontierSearchHidden: require m <= n";

    -- hidden tuple length
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

------------------------------------------------------------
-- Hidden-layer extractor for full architectures
------------------------------------------------------------

hiddenWidths = arch -> (
    if #arch <= 2 then {} else arch_(toList(1 .. #arch - 2))
);

------------------------------------------------------------
-- Summary / reporting helpers for frontier search output
------------------------------------------------------------

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
        scan(out#"FminResults", res -> (
            << "  ";
            printStep2Result res;
        ));
    );
);

------------------------------------------------------------
-- Convenience wrapper with summary printing
------------------------------------------------------------

runFrontierSearch = (depth, d0, dL, m, n, r, B, seed) -> (
    out := frontierSearchHidden(depth, d0, dL, m, n, r, B, seed);
    printFrontierSummary out;
    out
);

------------------------------------------------------------
-- Suggested examples
--
-- load "step2_compute_dimension.m2"
-- load "step4_frontier_search.m2"
--
-- out = runFrontierSearch(3, 2, 1, 2, 4, 2, 10, 12345)
-- printFrontierFillingResults out
-- out#"FminArchitectures"
--
-- Notes:
-- * depth = 3 means hidden tuple length k = 2, so architectures have the
--   form {d0, a1, a2, dL}.
-- * This is a randomized frontier search with budget B, so it explores only
--   B proposed candidates, not the full box.
------------------------------------------------------------
