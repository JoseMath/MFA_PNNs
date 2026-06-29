------------------------------------------------------------
-- MinimalFillingArchitecturesV7a.m2
-- 
-- A Macaulay2-style package for searching for minimal filling
-- architectures in polynomial neural networks.
------------------------------------------------------------

-- This V6 cleanup preserves the V5 functionality while applying a low-risk
-- refactor: normalized package metadata, exact-block bookkeeping fixes,
-- cleaner certificate output, and removal of a few brittle / redundant
-- fields. The canonical-cut certification path is intended as the main
-- maintained workflow; advanced pattern/orthant/visualization tools are
-- preserved but should be considered optional layers on top of the core.
------------------------------------------------------------

newPackage(
    "MinimalFillingArchitecturesV7a",
    Version => "0.7",
    Date => "June 20, 2026",
    Authors => {{Name => "Jose Israel Rodriguez"}},
    Headline => "Search tools for minimal filling architectures of polynomial neural networks",
    DebuggingMode => true
)

export {
    "makeNetwork","basisVector","backprop",
    "impliedFilling",
    "allHiddenTuplesInBox",
    "orthantCellCertifiedNonfillingByBlocks",
    "printBlockwiseRecursiveCertificate",
    "printUpperShellBlockCertificationSummary",
    "certifyAllUpperShellOrthantCellsByBlocks",
    "blockwiseRecursiveUpperBoundFromAnchor",
    "MinimalFillingSearchState",
    "PrintSummary",

    ----------------------------------------------------------------
    -- Core dimension / search workflow
    ----------------------------------------------------------------

    -- architectureStatistics(arch, r):
    -- Input: full architecture list arch = {d0, a1, ..., ak, dL}, exponent r.
    -- Output: {arch, r, ambientDim, expectedDim, actualDim, defect, codim}.
    "architectureStatistics",


    ----------------------------------------------------------------
    -- Frontier state + search
    ----------------------------------------------------------------

    -- makeFrontierState(depth, d0, dL, m, n, r):
    -- Input: search-box / architecture parameters.
    -- Output: mutable frontier state storing Fmin, Nmax, seen tuples, counters, and caches.
    "makeFrontierState",

    -- initializeFrontierWithArchitectures(state, tuples):
    -- Input: frontier state and a list of hidden tuples to evaluate first.
    -- Output: updated state after seeding the frontier with those tuples.
    "initializeFrontierWithArchitectures",

    -- runFrontierSearchResume(state, B, seed):
    -- Input: existing frontier state, additional budget B, optional random seed.
    -- Output: updated state after random frontier search continuation.
    "runFrontierSearchResume",

    -- runGuidedFrontierSearchResume(state, B, seed):
    -- Input: existing frontier state, additional budget B, optional random seed.
    -- Output: updated state after guided frontier search continuation.
    "runGuidedFrontierSearchResume",

    -- runFrontierSearch(depth, d0, dL, m, n, r, B, seed):
    -- Input: fresh search parameters.
    -- Output: new frontier state after random frontier search from scratch.
    "runFrontierSearch",

    -- runGuidedFrontierSearch(depth, d0, dL, m, n, r, B, seed):
    -- Input: fresh search parameters.
    -- Output: new frontier state after guided frontier search from scratch.
    "runGuidedFrontierSearch",

    ----------------------------------------------------------------
    -- Remaining regions / shell anchors
    ----------------------------------------------------------------

    -- unresolvedTuplesInState(state):
    -- Input: frontier state.
    -- Output: unresolved hidden tuples still remaining inside the bounded search box.
    "unresolvedTuplesInState",

    -- unresolvedUpperShellTuplesInState(state):
    -- Input: frontier state.
    -- Output: unresolved upper-shell hidden tuples (shell anchors) on the box boundary.
    "unresolvedUpperShellTuplesInState",

    -- isFrontierExhausted(state):
    -- Input: frontier state.
    -- Output: true iff no unresolved hidden tuples remain in the bounded search box.
    "isFrontierExhausted",

    ----------------------------------------------------------------
    -- Canonical-cut certification (main certification API)
    ----------------------------------------------------------------

    -- testCanonicalCutsFromUpperShellAnchor(state, shellAnchor):
    -- Input: frontier state and an upper-shell hidden tuple.
    -- Output: region certificate using the canonical cuts induced by the free entries.
    "testCanonicalCutsFromUpperShellAnchor",

    -- regionBlockUpperBoundFromCuts(state, anchorHidden, freePositions, cuts):
    -- Input: frontier state, minimal hidden anchor, free hidden positions, valid cut set.
    -- Output: full blockwise recursive upper-bound certificate for that region.
    "regionBlockUpperBoundFromCuts",

    -- certifyRegionNonfillingByCuts(state, anchorHidden, freePositions, cuts):
    -- Input: same region data as regionBlockUpperBoundFromCuts.
    -- Output: boolean: true iff the region is certified nonfilling by that cut decomposition.
    "certifyRegionNonfillingByCuts",

    ----------------------------------------------------------------
    -- Pretty printing / summaries
    ----------------------------------------------------------------

    -- printSearchSummary(results):
    -- Input: list of dimension results.
    -- Output: prints summary statistics for a finite architecture search.
    "printSearchSummary",

    -- printFrontierSummary(state):
    -- Input: frontier state after random frontier search.
    -- Output: prints Fmin/Nmax summary, counts, and skipped/evaluated statistics.
    "printFrontierSummary",

    -- printFrontierFillingResults(state):
    -- Input: frontier state.
    -- Output: prints the filling architectures/results currently stored in Fmin.
    "printFrontierFillingResults",

    -- printGuidedFrontierSummary(state):
    -- Input: frontier state after guided frontier search.
    -- Output: prints guided/random proposal counts and frontier summary.
    "printGuidedFrontierSummary",

    -- printGuidedFrontierFillingResults(state):
    -- Input: guided frontier state.
    -- Output: prints the filling architectures/results currently stored in Fmin.
    "printGuidedFrontierFillingResults",

    -- printRegionBlockCertificate(info):
    -- Input: certificate returned by regionBlockUpperBoundFromCuts or testCanonicalCutsFromUpperShellAnchor.
    -- Output: prints the full block decomposition and certification data.
    "printRegionBlockCertificate",

    -- printCanonicalCutSummary(info):
    -- Input: certificate returned by the canonical-cut workflow.
    -- Output: prints a short summary of the canonical cut certificate.
    "printCanonicalCutSummary",

    -- printExactBlocksUsed(info):
    -- Input: region certificate.
    -- Output: prints the exact blocks recorded in the certificate whose dim < expected.
    "printExactBlocksUsed",

    ----------------------------------------------------------------
    -- Optional user-facing utilities
    ----------------------------------------------------------------

    -- minimalFillingResults(results):
    -- Input: list of dimension results.
    -- Output: sublist consisting of coordinatewise-minimal filling architectures.
    "minimalFillingResults",

    -- fillingArchitecturesFromResults(results):
    -- Input: list of dimension results.
    -- Output: sublist of results with defect = 0.
    "fillingArchitecturesFromResults",

    -- nonFillingArchitecturesFromResults(results):
    -- Input: list of dimension results.
    -- Output: sublist of results with defect != 0.
    "nonFillingArchitecturesFromResults",

    -- hiddenLayerWidths(arch):
    -- Input: full architecture.
    -- Output: hidden-width tuple obtained by removing input and output widths.
    "hiddenLayerWidths",

    -- isUnimodal(L):
    -- Input: list of integers.
    -- Output: true iff L is weakly increasing then weakly decreasing.
    "isUnimodal",

    -- isUnimodalArchitecture(arch):
    -- Input: full architecture.
    -- Output: true iff the full architecture list is unimodal.
    "isUnimodalArchitecture",

    -- isUnimodalHiddenLayers(arch):
    -- Input: full architecture.
    -- Output: true iff the hidden-width sublist is unimodal.
    "isUnimodalHiddenLayers",

    -- counterexampleCandidates(results):
    -- Input: list of dimension results.
    -- Output: filling architectures that are not unimodal as full architecture lists.
    "counterexampleCandidates",

    "getDimensionCached"
}


ArchitectureStatistics = new Type of MutableHashTable;

------------------------------------------------------------
-- Display for ArchitectureStatistics
------------------------------------------------------------

net ArchitectureStatistics := stats -> (
    net(
        "ArchitectureStatistics\n" |
        "  architecture = " | toString(stats#0) | "\n" |
        "  exponent     = " | toString(stats#1) | "\n" |
        "  ambientDim   = " | toString(stats#2) | "\n" |
        "  expectedDim  = " | toString(stats#3) | "\n" |
        "  actualDim    = " | toString(stats#4) | "\n" |
        "  defect       = " | toString(stats#5) | "\n" |
        "  codim        = " | toString(stats#6)
    )
);

architectureStatistics = (networkWidths, networkExponent) -> (
    primes := {100003, 100153};
    dims := {};

    for p in primes do (
        nn := makeNetwork(networkWidths, networkExponent, p);
        sizes := nn#"sizes";
        K := nn#"K";
        inDim := sizes#0;
        outDim := sizes#(#sizes - 1);
        degree := nn#"degree";

        numParams := sum apply(#sizes - 1,
            i -> sizes#i * sizes#(i + 1)
        );

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

    ambientDim :=
        binomial(networkExponent^(#networkWidths - 2) + networkWidths#0 - 1,
                 networkWidths#0 - 1)
        * networkWidths#(#networkWidths - 1);

    naiveBound :=
        (sum apply(#networkWidths - 1,
            i -> (networkWidths#i - 1) * networkWidths#(i + 1)))
        + networkWidths#(#networkWidths - 1);

    expectedDim := min(ambientDim, naiveBound);
    actualDim := dims#0;
    defect := expectedDim - actualDim;
    codim := ambientDim - actualDim;

    new ArchitectureStatistics from new MutableHashTable from {
        0 => networkWidths,
        1 => networkExponent,
        2 => ambientDim,
        3 => expectedDim,
        4 => actualDim,
        5 => defect,
        6 => codim,
        "Legend" => hashTable {
            0 => "architecture",
            1 => "exponent",
            2 => "ambientDim",
            3 => "expectedDim",
            4 => "actualDim",
            5 => "defect",
            6 => "codim"
        }
    }
);
-----helpers





------------------------------------------------------------
-- Search-state type for minimal filling architecture search
------------------------------------------------------------

MinimalFillingSearchState = new Type of MutableHashTable;

------------------------------------------------------------
-- Display for MinimalFillingSearchState
------------------------------------------------------------

net MinimalFillingSearchState := searchState -> (
    nUnresolved :=
        if searchState#? "unresolvedCount" and searchState#"unresolvedCount" =!= null
        then searchState#"unresolvedCount"
        else "unknown";

    candNmax :=
        if searchState#? "CandidateNmax"
        then searchState#"CandidateNmax"
        else "<not set>";

    candFmin :=
        if searchState#? "CandidateFmin"
        then searchState#"CandidateFmin"
        else "<not set>";

    net(
        "MinimalFillingSearchState\n" |
        "  depth            = " | toString(searchState#"depth") | "\n" |
        "  architecture     = {" | toString(searchState#"d0") | ", a1, ..., a"
            | toString((searchState#"depth") - 1) | ", " | toString(searchState#"dL") | "}\n" |
        "  range            = " | toString(searchState#"range") | "\n" |
        "  exponent         = " | toString(searchState#"exponent") | "\n" |
        "  candidate Nmax   = " | toString(candNmax) | "\n" |
        "  candidate Fmin   = " | toString(candFmin) | "\n" |
        "  |FminTuples|     = " | toString(#(searchState#"FminTuples")) | "\n" |
        "  |NmaxTuples|     = " | toString(#(searchState#"NmaxTuples")) | "\n" |
        "  evaluated        = " | toString(searchState#"nEvaluated") | "\n" |
        "  guided proposals = " | toString(searchState#"nGuidedProposals") | "\n" |
        "  random proposals = " | toString(searchState#"nRandomProposals") | "\n" |
        "  unresolved count = " | toString(nUnresolved) | "\n" |
        "  exhausted        = " | toString(searchState#"exhausted")| "\n" |
	"  timing           = " | toString(searchState#"Timing") 
    )
);



finishWithTiming = (state,startTime) -> (
    endTime := currentTime();
    oldTiming := if state#? "Timing" then state#"Timing" else 0;
    state#"Timing" = oldTiming + (endTime - startTime);
    state
);


printCanonicalCutSummary = info -> (
    << "Canonical cut summary" << endl;
    << "  architecture = " << toString(info#"architecture") << endl;
    << "  cuts = " << toString(info#"cuts") << endl;
    << "  upper bound = " << toString(info#"upperBound") << endl;
    << "  expected at minimal anchor = " << toString(info#"expectedDimAtMinimalAnchor") << endl;
    << "  certified nonfilling region? " << toString(info#"certifiedNonfillingRegion") << endl;
);

------------------------------------------------------------
-- Fixed positions adjacent to free positions
------------------------------------------------------------
fixedPositionsFromFreePositions = (k, freePositions) -> (
    select(toList(0 .. k - 1), i -> not member(i, freePositions))
);

minimalAnchorFromUpperShellAnchor = (shellAnchor, m, n) -> (
    apply(shellAnchor, x -> if x == n then n else m)
);

adjacentFixedPositions = (k, freePositions) -> (
    fixedPositions := fixedPositionsFromFreePositions(k, freePositions);

    select(fixedPositions, i ->
        any(freePositions, j -> j == i - 1 or j == i + 1)
    )
);

------------------------------------------------------------
-- Canonical cut set determined by free positions
--
-- Hidden positions are 0..k-1
-- Full architecture indices are:
--   0     = input
--   1..k  = hidden coordinates
--   k+1   = output
--
-- So a hidden cut at position i becomes full index i+1.
------------------------------------------------------------

canonicalCutsFromFreePositions = (k, freePositions) -> (
    adjFixed := adjacentFixedPositions(k, freePositions);
    sort unique join({0, k + 1}, apply(adjFixed, i -> i + 1))
);

------------------------------------------------------------
-- Canonical cuts for a region described by
--   anchorHidden, freePositions
------------------------------------------------------------

canonicalCutsFromRegion = (anchorHidden, freePositions) -> (
    canonicalCutsFromFreePositions(#anchorHidden, freePositions)
);

------------------------------------------------------------
-- Test the unique canonical cut set for a region
------------------------------------------------------------

testCanonicalCutsForRegion = (state, anchorHidden, freePositions) -> (
    cuts := canonicalCutsFromRegion(anchorHidden, freePositions);
    regionBlockUpperBoundFromCuts(state, anchorHidden, freePositions, cuts)
);

------------------------------------------------------------
-- Convenience wrapper from an upper-shell anchor
------------------------------------------------------------

testCanonicalCutsFromUpperShellAnchor = (state, shellAnchor) -> (
    m := (state#"range")#0;
    n := (state#"range")#1;

    freePositions := freePositionsFromAnchor(shellAnchor, n);
    anchorHidden := minimalAnchorFromUpperShellAnchor(shellAnchor, m, n);

    testCanonicalCutsForRegion(state, anchorHidden, freePositions)
);

------------------------------------------------------------
-- Record exact block dimensions used in certification
------------------------------------------------------------

recordExactBlockResult = (state, block, res) -> (
    key := archKey block;
    cache := state#"ExactBlockCache";

    if not (cache#? key) then (
        cache#key = hashTable {
            "blockArchitecture" => block,
            "dimension" => resultDimension res,
            "expectedDimension" => resultExpectedDim res,
            "defect" => resultDefect res,
            "codim" => resultCodim res,
            "result" => res
        };
    );

    cache#key
);

------------------------------------------------------------
-- Generic region certificate from an arbitrary set of cuts
--
-- Region data:
--   anchorHidden   = minimal hidden tuple
--   freePositions  = 0-based positions in the hidden tuple that may increase
--
-- Cuts are full-architecture indices:
--   0 = input
--   1..k = hidden coordinates
--   k+1 = output
--
-- Requirement:
--   internal cuts must occur only at fixed hidden coordinates
------------------------------------------------------------

regionBlockUpperBoundFromCuts = (state, anchorHidden, freePositions, cuts) -> (
    d0 := state#"d0";
    dL := state#"dL";
    r := state#"exponent";

    k := #anchorHidden;
    fullArch := architectureFromHidden(d0, dL, anchorHidden);

    -- basic cut validation
    if first cuts =!= 0 then
        error "regionBlockUpperBoundFromCuts: cuts must begin with 0";
    if last cuts =!= k + 1 then
        error "regionBlockUpperBoundFromCuts: cuts must end with #anchorHidden+1";

    for s from 1 to #cuts - 2 do (
        idx := cuts#s;
        hiddenPos := idx - 1;
        if member(hiddenPos, freePositions) then
            error "regionBlockUpperBoundFromCuts: internal cuts must be at fixed hidden coordinates";
    );

    blockInfos := {};
    exactBlocksUsed := {};  
    upperSum := 0;

    for s from 0 to #cuts - 2 do (
        i := cuts#s;
        j := cuts#(s + 1);

        block := fullArch_(toList(i .. j));
    exactBlockEntry := null;

        -- determine whether this block contains any free hidden coordinate in its interior
        hasFreeInterior := false;
        left := max(1, i);
        right := min(k, j);

        if left <= right then (
            for t from left to right do (
                if member(t - 1, freePositions) then hasFreeInterior = true;
            );
        );

        if hasFreeInterior then (
            ub := ambientUpperBoundArchitecture(block, r);
            blockType := "ambient-upper-bound";
        ) else (
            res := getDimensionCached(state, block);
            ub = resultDimension res;
            blockType = "exact-dimension";
            exactBlockEntry = recordExactBlockResult(state, block, res);
            if resultDimension res < resultExpectedDim res then (
                exactBlocksUsed = join(exactBlocksUsed, {exactBlockEntry});
            );
        );

        upperSum = upperSum + ub;

        blockInfos = join(blockInfos, {
            hashTable {
                "startIndex" => i,
                "endIndex" => j,
                "blockArchitecture" => block,
                "blockType" => blockType,
                "blockUpperBound" => ub,
        "exactBlockEntry" => exactBlockEntry,
        }
        });
    );

    -- subtract overlap widths at internal cuts
    overlapCorrection := 0;
    if #cuts > 2 then (
        for s from 1 to #cuts - 2 do (
            overlapCorrection = overlapCorrection + fullArch#(cuts#s);
        );
    );

    upperBound := upperSum - overlapCorrection;

    fullRes := getDimensionCached(state, fullArch);

    expectedMin := resultExpectedDim fullRes;
    actualAtAnchor := resultDimension fullRes;
    ambientAtAnchor := resultAmbientDim fullRes;
    defectAtAnchor := resultDefect fullRes;
    codimAtAnchor := resultCodim fullRes;

    hashTable {
        "anchorHidden" => anchorHidden,
        "architecture" => fullArch,
        "freePositions" => freePositions,
        "cuts" => cuts,
        "blockInfos" => blockInfos,
    "exactBlocksUsed" => exactBlocksUsed,
    "sumBlockBounds" => upperSum,
        "overlapCorrection" => overlapCorrection,
        "upperBound" => upperBound,
        "expectedDimAtMinimalAnchor" => expectedMin,
        "actualDimAtMinimalAnchor" => actualAtAnchor,
        "ambientDimAtMinimalAnchor" => ambientAtAnchor,
        "defectAtMinimalAnchor" => defectAtAnchor,
        "codimAtMinimalAnchor" => codimAtAnchor,
        "certifiedNonfillingRegion" => (upperBound < expectedMin)
    }
);

------------------------------------------------------------
-- Print exact blocks used in a certificate
------------------------------------------------------------

printExactBlocksUsed = info -> (
    if not (info#? "exactBlocksUsed") then (
        << "No exactBlocksUsed field present in this certificate." << endl;
    ) else (
        E := info#"exactBlocksUsed";

        << "Exact blocks with dim < expected used in certification:" << endl;
        if #E == 0 then (
            << "  <none>" << endl;
        ) else (
            scan(E, entry -> (
                << "  " << toString(entry#"blockArchitecture")
                   << "  -> dim = " << toString(entry#"dimension")
                   << ", expected = " << toString(entry#"expectedDimension")
                   << ", defect = " << toString(entry#"defect")
                   << ", codim = " << toString(entry#"codim")
                   << endl;
            ));
        );
    );
);

certifyRegionNonfillingByCuts = (state, anchorHidden, freePositions, cuts) -> (
    info := regionBlockUpperBoundFromCuts(state, anchorHidden, freePositions, cuts);
    info#"certifiedNonfillingRegion"
);

printRegionBlockCertificate = info -> (
    << "Region blockwise certificate" << endl;
    << "  anchor hidden tuple = " << toString(info#"anchorHidden") << endl;
    << "  full architecture = " << toString(info#"architecture") << endl;
    << "  free positions = " << toString(info#"freePositions") << endl;
    << "  cuts = " << toString(info#"cuts") << endl;
    << "  sum of block bounds = " << toString(info#"sumBlockBounds") << endl;
    << "  overlap correction = " << toString(info#"overlapCorrection") << endl;
    << "  total upper bound = " << toString(info#"upperBound") << endl;
    << "  expected dim at minimal anchor = " << toString(info#"expectedDimAtMinimalAnchor") << endl;
    << "  actual dim at minimal anchor = " << toString(info#"actualDimAtMinimalAnchor") << endl;
    << "  defect at minimal anchor = " << toString(info#"defectAtMinimalAnchor")
       << ", codim at minimal anchor = " << toString(info#"codimAtMinimalAnchor") << endl;
    << "  certified nonfilling region? " << toString(info#"certifiedNonfillingRegion") << endl;
    << endl;

    << "Blocks:" << endl;
    scan(info#"blockInfos", b -> (
        << "  [" << toString(b#"startIndex") << "," << toString(b#"endIndex") << "] "
           << toString(b#"blockArchitecture")
           << "  type = " << toString(b#"blockType")
           << "  bound = " << toString(b#"blockUpperBound")
           << endl;
    ));
    << endl;
    printExactBlocksUsed(info);
);

------------------------------------------------------------
-- Pretty printer for pattern-region certificates
------------------------------------------------------------

printPatternRegionCertificate = info -> (
    << "Pattern-region certificate" << endl;
    << "  free positions = " << toString(info#"freePositions") << endl;
    << "  fixed positions = " << toString(info#"fixedPositions") << endl;
    << "  representative anchor = " << toString(info#"representativeAnchor") << endl;
    << "  minimal anchor = " << toString(info#"minimalAnchor") << endl;
    << "  boundary antichain = " << toString(info#"boundary") << endl;
    << "  cuts = " << toString(info#"cuts") << endl;
    << "  sum of block bounds = " << toString(info#"sumBlockBounds") << endl;
    << "  overlap correction = " << toString(info#"overlapCorrection") << endl;
    << "  total recursive upper bound = " << toString(info#"upperBound") << endl;
    << "  expected dim at minimal anchor = " << toString(info#"expectedDimAtMinimalAnchor") << endl;
    << "  actual dim at minimal anchor = " << toString(info#"actualDimAtMinimalAnchor") << endl;
    << "  defect at minimal anchor = " << toString(info#"defectAtMinimalAnchor")
       << ", codim at minimal anchor = " << toString(info#"codimAtMinimalAnchor") << endl;
    << "  certified nonfilling region? "
       << toString(info#"certifiedNonfillingRegion") << endl;
    << endl;

    << "Blocks:" << endl;
    scan(info#"blockInfos", b -> (
        << "  [" << toString(b#"startIndex") << "," << toString(b#"endIndex") << "] "
           << toString(b#"representativeBlock")
           << "  type = " << toString(b#"blockType")
           << "  bound = " << toString(b#"blockUpperBound")
           << endl;
    ));
);

------------------------------------------------------------
-- Dominance helpers for antichains in fixed coordinates
------------------------------------------------------------

isDominatedTuple = (a, b) -> (
    if #a =!= #b then error "isDominatedTuple: length mismatch";
    all(toList(0 .. #a - 1), i -> a#i <= b#i)
);

maximalElementsByDominance = L -> (
    select(L, a -> not any(L, b -> (not (a === b)) and isDominatedTuple(a, b)))
);

------------------------------------------------------------
-- Free positions: coordinates equal to n
------------------------------------------------------------

freePositionsFromAnchor = (anchor, n) -> (
    select(toList(0 .. #anchor - 1), i -> anchor#i == n)
);

------------------------------------------------------------
-- Reconstruct full shell anchor from a pattern and fixed-coordinate values
------------------------------------------------------------

boundaryPointToAnchor = (freePositions, fixedPositions, fixedValues, n, k) -> (
    if #fixedPositions =!= #fixedValues then
        error "boundaryPointToAnchor: fixedPositions / fixedValues mismatch";

    anchor := new MutableList from apply(k, i -> n);

    for t from 0 to #fixedPositions - 1 do (
        anchor#(fixedPositions#t) = fixedValues#t;
    );

    toList anchor
);

------------------------------------------------------------
-- Build pattern boundary table from unresolved upper-shell anchors
--
-- Each entry is a mutable hash table with keys:
--   "freePositions"
--   "fixedPositions"
--   "boundary"
--
-- where "boundary" is the maximal antichain in the fixed coordinates.
------------------------------------------------------------

patternBoundaryTableFromUpperShell = state -> (
    anchors := unresolvedUpperShellTuplesInState(state);
    n := (state#"range")#1;

    table := new MutableHashTable from  {};

    for a in anchors do (
        F := freePositionsFromAnchor(a, n);
        k := #a;
        C := select(toList(0 .. k - 1), i -> not member(i, F));
        Cvals := apply(C, i -> a#i);

        key := toString(F);

        if table#? key then (
            entry := table#key;
            entry#"boundary" = join(entry#"boundary", {Cvals});
        ) else (
            entry = new MutableHashTable from {
                "freePositions" => F,
                "fixedPositions" => C,
                "boundary" => {Cvals}
            };
            table#key = entry;
        );
    );

    -- compress each pattern to the maximal antichain in fixed coordinates
    for key in keys table do (
        entry := table#key;
        entry#"boundary" = maximalElementsByDominance(entry#"boundary");
    );

    table
);

------------------------------------------------------------
-- Boolean wrapper for one pattern region
------------------------------------------------------------

certifyPatternBoundaryRegion = (state, entry) -> (
    info := patternRegionUpperBound(state, entry);
    info#"certifiedNonfillingRegion"
);

------------------------------------------------------------
-- Certify all pattern regions from the upper-shell table
------------------------------------------------------------

certifyAllPatternBoundaryRegions = state -> (
    table := patternBoundaryTableFromUpperShell(state);

    infos := {};
    certified := {};
    uncertified := {};

    for key in keys table do (
        entry := table#key;
        info := patternRegionUpperBound(state, entry);

        infos = join(infos, {info});

        if info#"certifiedNonfillingRegion" then
            certified = join(certified, {info})
        else
            uncertified = join(uncertified, {info});
    );

    hashTable {
        "numPatterns" => #keys table,
        "infoList" => infos,
        "certifiedList" => certified,
        "uncertifiedList" => uncertified,
        "numCertified" => #certified,
        "numUncertified" => #uncertified,
        "allCertified" => (#uncertified == 0)
    }
);

------------------------------------------------------------
-- Pretty printer for pattern-region certification
------------------------------------------------------------

printPatternBoundaryRegionCertificationSummary = cert -> (
    << "Pattern-region certification summary" << endl;
    << "  pattern regions = " << toString(cert#"numPatterns") << endl;
    << "  certified nonfilling regions = " << toString(cert#"numCertified") << endl;
    << "  uncertified regions = " << toString(cert#"numUncertified") << endl;
    << "  all pattern regions certified? " << toString(cert#"allCertified") << endl;
    << endl;

    if cert#"numCertified" > 0 then (
        << "Certified regions:" << endl;
        scan(cert#"certifiedList", info -> (
            << "  free positions = " << toString(info#"freePositions")
               << ", minimal anchor = " << toString(info#"minimalAnchor")
               << ", upper bound = " << toString(info#"upperBound")
               << ", expected at minimal anchor = " << toString(info#"expectedDimAtMinimalAnchor")
               << endl;
        ));
        << endl;
    );

    if cert#"numUncertified" > 0 then (
        << "Uncertified regions:" << endl;
        scan(cert#"uncertifiedList", info -> (
            << "  free positions = " << toString(info#"freePositions")
               << ", minimal anchor = " << toString(info#"minimalAnchor")
               << ", upper bound = " << toString(info#"upperBound")
               << ", expected at minimal anchor = " << toString(info#"expectedDimAtMinimalAnchor")
               << endl;
        ));
    );
);

------------------------------------------------------------
-- Uniform recursive upper bound for an entire pattern region
--
-- entry is one value from patternBoundaryTableFromUpperShell(state):
--   entry#"freePositions"
--   entry#"fixedPositions"
--   entry#"boundary"
------------------------------------------------------------

patternRegionUpperBound = (state, entry) -> (
    d0 := state#"d0";
    dL := state#"dL";
    m := (state#"range")#0;
    n := (state#"range")#1;
    r := state#"exponent";

    F := entry#"freePositions";
    C := entry#"fixedPositions";
    boundary := entry#"boundary";

    k := #F + #C;

    -- representative anchor to determine cuts and block structure
    repAnchor := boundaryPointToAnchor(F, C, first boundary, n, k);
    repArch := anchorArchitectureFromHidden(d0, dL, repAnchor);
    cuts := recursiveCutsFromAnchor(repAnchor, n);

    -- minimal anchor in the whole region
    minAnchor := patternMinimalAnchor(F, C, m, n, k);
    minArch := anchorArchitectureFromHidden(d0, dL, minAnchor);
    minRes := getDimensionCached(state, minArch);

    expectedMin := resultExpectedDim minRes;
    ambientMin := resultAmbientDim minRes;
    actualMin := resultDimension minRes;
    defectMin := resultDefect minRes;
    codimMin := resultCodim minRes;

    blockInfos := {};
    upperSum := 0;

    -- for each block between consecutive cuts
    for s from 0 to #cuts - 2 do (
        i := cuts#s;
        j := cuts#(s + 1);

        repBlock := subArchitectureByIndices(repArch, i, j);
        hasFree := blockContainsFreeHidden(repAnchor, n, i, j);

        if hasFree then (
            ub := ambientUpperBoundArchitecture(repBlock, r);
            blockType := "ambient-upper-bound";
        ) else (
            -- exact block, but take the MAX over the boundary antichain
            blockDims := apply(boundary, bC -> (
                a := boundaryPointToAnchor(F, C, bC, n, k);
                arch := anchorArchitectureFromHidden(d0, dL, a);
                block := subArchitectureByIndices(arch, i, j);
                res := getDimensionCached(state, block);
                resultDimension res
            ));

            ub = max blockDims;
            blockType = "max-exact-dimension-on-boundary";
        );

        upperSum = upperSum + ub;

        blockInfos = join(blockInfos, {
            hashTable {
                "startIndex" => i,
                "endIndex" => j,
                "representativeBlock" => repBlock,
                "blockType" => blockType,
                "blockUpperBound" => ub
            }
        });
    );

    -- overlap correction: use MIN over the whole region.
    -- Since fixed coordinates vary downward to m and free coordinates stay at n,
    -- the minimum value at an internal cut is:
    --   m if that cut is a fixed coordinate,
    --   n if that cut is a free coordinate.
    overlapCorrection := 0;
    if #cuts > 2 then (
        for s from 1 to #cuts - 2 do (
            idx := cuts#s;
            -- idx is a full architecture hidden index in 1..k
            hiddenPos := idx - 1;

            if member(hiddenPos, F) then
                overlapCorrection = overlapCorrection + n
            else
                overlapCorrection = overlapCorrection + m;
        );
    );

    ubTotal := upperSum - overlapCorrection;

    hashTable {
        "freePositions" => F,
        "fixedPositions" => C,
        "boundary" => boundary,
        "representativeAnchor" => repAnchor,
        "minimalAnchor" => minAnchor,
        "cuts" => cuts,
        "blockInfos" => blockInfos,
        "sumBlockBounds" => upperSum,
        "overlapCorrection" => overlapCorrection,
        "upperBound" => ubTotal,
        "expectedDimAtMinimalAnchor" => expectedMin,
        "ambientDimAtMinimalAnchor" => ambientMin,
        "actualDimAtMinimalAnchor" => actualMin,
        "defectAtMinimalAnchor" => defectMin,
        "codimAtMinimalAnchor" => codimMin,
        "certifiedNonfillingRegion" => (ubTotal < expectedMin)
    }
);
------------------------------------------------------------
-- Minimal anchor for a free-pattern region
------------------------------------------------------------

patternMinimalAnchor = (freePositions, fixedPositions, m, n, k) -> (
    anchor := new MutableList from apply(k, i -> n);

    for i in fixedPositions do (
        anchor#i = m;
    );

    toList anchor
);

------------------------------------------------------------
-- Recursive upper bounds for orthant cells
--
-- Interpretation:
--   anchor = hidden tuple in the upper shell
--   anchor_i < n   => that hidden coordinate is fixed
--   anchor_i = n   => that hidden coordinate is free upward
--
-- We split the full architecture at fixed hidden coordinates and use:
--   - exact dimension on fully fixed blocks
--   - ambient dimension on blocks containing a free coordinate
------------------------------------------------------------

------------------------------------------------------------
-- Basic architecture slicing helpers
------------------------------------------------------------

-- prefixArchitecture(arch, k)
-- returns {d0,...,dk}
prefixArchitecture = (arch, k) -> (
    if k < 0 or k > #arch - 1 then
        error "prefixArchitecture: split index out of range";
    arch_(toList(0 .. k))
);

-- suffixArchitecture(arch, k)
-- returns {dk,...,dL}
suffixArchitecture = (arch, k) -> (
    if k < 0 or k > #arch - 1 then
        error "suffixArchitecture: split index out of range";
    arch_(toList(k .. #arch - 1))
);

-- turn a hidden tuple into a full architecture
anchorArchitectureFromHidden = (d0, dL, anchor) -> (
    architectureFromHidden(d0, dL, anchor)
);

------------------------------------------------------------
-- Identify fixed hidden positions
--
-- anchor has length k = depth-1
-- hidden coordinates in the full architecture are at indices 1..k
------------------------------------------------------------

fixedHiddenPositionsFromAnchor = (anchor, n) -> (
    select(toList(0 .. #anchor - 1), i -> anchor#i < n)
);

------------------------------------------------------------
-- Cut positions for recursive splitting
--
-- Full architecture indices:
--   0          = input d0
--   1..k       = hidden widths
--   k+1        = output dL
--
-- We always include:
--   0 and k+1
-- and we include i+1 whenever anchor_i is fixed (< n)
------------------------------------------------------------

recursiveCutsFromAnchor = (anchor, n) -> (
    hiddenFixed := fixedHiddenPositionsFromAnchor(anchor, n);
    sort unique join({0, #anchor + 1}, apply(hiddenFixed, i -> i + 1))
);

------------------------------------------------------------
-- Extract a contiguous subarchitecture arch[i..j]
------------------------------------------------------------

subArchitectureByIndices = (arch, i, j) -> (
    if i < 0 or j > #arch - 1 or i > j then
        error "subArchitectureByIndices: invalid indices";
    arch_(toList(i .. j))
);

------------------------------------------------------------
-- Ambient dimension for a block architecture
--
-- If block = {e0,...,et}, then degree = r^(t-1)
-- ambient dim = (# degree-r monomials in e0 vars) * output dimension
------------------------------------------------------------

ambientUpperBoundArchitecture = (arch, r) -> (
    degree := r^(#arch - 2);
    binomial(degree + arch#0 - 1, arch#0 - 1) * arch#(#arch - 1)
);

------------------------------------------------------------
-- Does a block [i..j] contain any free hidden coordinate?
--
-- full hidden positions are 1..#anchor in full architecture indexing
-- anchor positions are 0..#anchor-1
------------------------------------------------------------

blockContainsFreeHidden = (anchor, n, i, j) -> (
    freeQ := false;

    -- the hidden coordinates contributing to this block are the full
    -- architecture indices 1..#anchor, intersected with [i..j]
    left := max(1, i);
    right := min(#anchor, j);

    if left <= right then (
        for t from left to right do (
            if anchor#(t - 1) == n then freeQ = true;
        );
    );

    freeQ
);

------------------------------------------------------------
-- Main certificate: blockwise recursive upper bound from an anchor
------------------------------------------------------------

blockwiseRecursiveUpperBoundFromAnchor = (state, anchor) -> (
    d0 := state#"d0";
    dL := state#"dL";
    n := (state#"range")#1;
    r := state#"exponent";

    arch := anchorArchitectureFromHidden(d0, dL, anchor);
    cuts := recursiveCutsFromAnchor(anchor, n);

    blockInfos := {};
    upperSum := 0;

    -- Build blocks between consecutive cut indices
    for s from 0 to #cuts - 2 do (
        i := cuts#s;
        j := cuts#(s + 1);

        block := subArchitectureByIndices(arch, i, j);
        hasFree := blockContainsFreeHidden(anchor, n, i, j);

        if hasFree then (
            ub := ambientUpperBoundArchitecture(block, r);
            blockType := "ambient-upper-bound";
        ) else (
            res := getDimensionCached(state, block);
            ub = resultDimension res;
            blockType = "exact-dimension";
        );

        upperSum = upperSum + ub;

        blockInfos = join(blockInfos, {
            hashTable {
                "startIndex" => i,
                "endIndex" => j,
                "blockArchitecture" => block,
                "blockType" => blockType,
                "blockUpperBound" => ub
            }
        });
    );

    -- overlap correction from recursive lemma:
    -- subtract d_(cut index) at internal cuts
    overlapCorrection := 0;
    if #cuts > 2 then (
        for s from 1 to #cuts - 2 do (
            overlapCorrection = overlapCorrection + arch#(cuts#s);
        );
    );

    ubTotal := upperSum - overlapCorrection;

    -- Evaluate anchor architecture itself (cached)
    fullRes := getDimensionCached(state, arch);

    expected := resultExpectedDim fullRes;
    actual := resultDimension fullRes;
    ambient := resultAmbientDim fullRes;
    defect := resultDefect fullRes;
    codim := resultCodim fullRes;

    hashTable {
        "anchor" => anchor,
        "architecture" => arch,
        "cuts" => cuts,
        "blockInfos" => blockInfos,
        "sumBlockBounds" => upperSum,
        "overlapCorrection" => overlapCorrection,
        "upperBound" => ubTotal,
        "ambientDim" => ambient,
        "expectedDimAtAnchor" => expected,
        "actualDimAtAnchor" => actual,
        "defectAtAnchor" => defect,
        "codimAtAnchor" => codim,
        "certifiedNonfillingOrthantCell" => (ubTotal < expected)
    }
);

------------------------------------------------------------
-- Boolean wrapper
------------------------------------------------------------

orthantCellCertifiedNonfillingByBlocks = (state, anchor) -> (
    infor := blockwiseRecursiveUpperBoundFromAnchor(state, anchor);
    infor#"certifiedNonfillingOrthantCell"
);

------------------------------------------------------------
-- Pretty-printer
------------------------------------------------------------

printBlockwiseRecursiveCertificate = infor -> (
    << "Blockwise recursive certificate" << endl;
    << "  anchor hidden tuple = " << toString(infor#"anchor") << endl;
    << "  full architecture = " << toString(infor#"architecture") << endl;
    << "  cuts = " << toString(infor#"cuts") << endl;
    << "  sum of block bounds = " << toString(infor#"sumBlockBounds") << endl;
    << "  overlap correction = " << toString(infor#"overlapCorrection") << endl;
    << "  total recursive upper bound = " << toString(infor#"upperBound") << endl;
    << "  expected dim at anchor = " << toString(infor#"expectedDimAtAnchor") << endl;
    << "  actual dim at anchor = " << toString(infor#"actualDimAtAnchor") << endl;
    << "  defect at anchor = " << toString(infor#"defectAtAnchor")
       << ", codim at anchor = " << toString(infor#"codimAtAnchor") << endl;
    << "  certified nonfilling for entire orthant cell? "
       << toString(infor#"certifiedNonfillingOrthantCell") << endl;
    << endl;

    << "Blocks:" << endl;
    scan(infor#"blockInfos", b -> (
        << "  [" << toString(b#"startIndex") << "," << toString(b#"endIndex") << "] "
           << toString(b#"blockArchitecture")
           << "  type = " << toString(b#"blockType")
           << "  bound = " << toString(b#"blockUpperBound")
           << endl;
    ));
);

---Remaining to explore
------------------------------------------------------------
-- Upper-shell parameterization of unresolved regions
-- outside the bounded box [m,n]^(depth-1)
------------------------------------------------------------

-- All hidden tuples in the upper shell:
-- at least one coordinate is equal to n
upperShellTuples = (depth, m, n) -> (
    k := depth - 1;
    select(allTuples(k, rangeList(m, n)),
        a -> any(#a, i -> a#i == n)
    )
);

-- Upper-shell points not implied filling.
-- These parameterize the outside orthant cells still unresolved
-- with respect to the current filling frontier.
unresolvedUpperShellTuples = (depth, m, n, Fmin) -> (
    select(upperShellTuples(depth, m, n),
        a -> not impliedFilling(a, Fmin)
    )
);

unresolvedUpperShellTuplesInState = state -> (
    depth := state#"depth";
    m := (state#"range")#0;
    n := (state#"range")#1;
    Fmin := state#"FminTuples";

    unresolvedUpperShellTuples(depth, m, n, Fmin)
);

------------------------------------------------------------
-- Each shell point b determines one orthant cell outside the box:
--
--   E(b) = { a in Z_{>0}^k :
--            a_i = b_i if b_i < n,
--            a_i >= n  if b_i = n }
--
-- We encode that as:
--   "fixedPositions" : list of coordinate indices where b_i < n
--   "fixedValues"    : corresponding fixed values
--   "freePositions"  : list of coordinate indices where b_i = n
--   "anchor"         : the shell point b
------------------------------------------------------------

orthantCellFromShellPoint = (b, n) -> (
    fixedPos := {};
    fixedVals := {};
    freePos := {};

    for i from 0 to #b - 1 do (
        if b#i == n then (
            freePos = join(freePos, {i});
        ) else (
            fixedPos = join(fixedPos, {i});
            fixedVals = join(fixedVals, {b#i});
        );
    );

    hashTable {
        "anchor" => b,
        "fixedPositions" => fixedPos,
        "fixedValues" => fixedVals,
        "freePositions" => freePos
    }
);

orthantCellsFromUpperShell = (depth, m, n, Fmin) -> (
    apply(unresolvedUpperShellTuples(depth, m, n, Fmin),
        b -> orthantCellFromShellPoint(b, n)
    )
);

orthantCellsFromUpperShellInState = state -> (
    depth := state#"depth";
    m := (state#"range")#0;
    n := (state#"range")#1;
    Fmin := state#"FminTuples";

    orthantCellsFromUpperShell(depth, m, n, Fmin)
);

------------------------------------------------------------
-- Pretty printer
------------------------------------------------------------

printOrthantCellsFromUpperShell = state -> (
    cells := orthantCellsFromUpperShellInState(state);
    n := (state#"range")#1;

    << "Outside-box unresolved orthant cells (parameterized by upper shell):" << endl;
    << "  number of cells = " << toString(#cells) << endl;
    << endl;

    scan(cells, cell -> (
        << "  anchor = " << toString(cell#"anchor")
           << ", free positions (>= " << toString(n) << ") = " << toString(cell#"freePositions")
           << ", fixed positions = " << toString(cell#"fixedPositions")
           << ", fixed values = " << toString(cell#"fixedValues")
           << endl;
    ));
)

---Dimension cache
------------------------------------------------------------
-- Safe architecture key builder
------------------------------------------------------------

archKey = arch -> (
    if class arch =!= List then
        error("archKey: expected a List architecture, got class " | toString class arch);

    out := "{";
    for i from 0 to #arch - 1 do (
        out = out | toString(arch#i);
        if i < #arch - 1 then out = out | ",";
    );
    out | "}"
);

hasDimensionCached = (state, arch) -> (
    myCache := state#"DimensionCache";
    myCache#? archKey arch
);

getDimensionCached = (state, arch) -> (
    if class arch =!= List then
        error("getDimensionCached: expected architecture as List, got class " | toString class arch);

    key := archKey arch;
    cache := state#"DimensionCache";

    if cache#? key then (
        if state#? "nCacheHits" then
            state#"nCacheHits" = state#"nCacheHits" + 1;
        cache#key
    ) else (
        if state#? "nCacheMisses" then
            state#"nCacheMisses" = state#"nCacheMisses" + 1;
        res := architectureStatistics(arch, state#"exponent");
        cache#key = res;
        res
    )
);
---

------------------------------------------------------------
-- Exhaustion helpers
------------------------------------------------------------

-- All hidden tuples in the box [m,n]^(depth-1)
allHiddenTuplesInBox = (depth, m, n) -> (
    k := depth - 1;
    allTuples(k, rangeList(m, n))
);

-- Hidden tuples not yet implied by Fmin or Nmax
unresolvedTuples = (depth, m, n, Fmin, Nmax) -> (
    select(allHiddenTuplesInBox(depth, m, n),
        a -> not impliedFilling(a, Fmin) and not impliedNonFilling(a, Nmax)
    )
);

-- State-based version
unresolvedTuplesInState = state -> (
    depth := state#"depth";
    m := (state#"range")#0;
    n := (state#"range")#1;
    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";

    unresolvedTuples(depth, m, n, Fmin, Nmax)
);

-- Exact exhaustion test
isFrontierExhausted = state -> (
    #unresolvedTuplesInState(state) == 0
);

------------------------------------------------------------
-- Combined staircase diagram for the two-hidden-layer case
--
-- depth = 3  <=> hidden tuple length = 2
-- architectures have the form {d0, a1, a2, dL}
--
-- Colors:
--   blue   = implied filling only
--   red    = implied non-filling only
--   gray   = unresolved
--   purple = implied both (inconsistent frontier data)
------------------------------------------------------------

frontierRegionTypeTwoHidden = (a, Fmin, Nmax) -> (
    fillQ := impliedFilling(a, Fmin);
    nonfillQ := impliedNonFilling(a, Nmax);

    if fillQ and nonfillQ then return "both";
    if fillQ then return "filling";
    if nonfillQ then return "nonfilling";
    "unresolved"
);



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

------------------------------------------------------------
-- Search utilities
------------------------------------------------------------

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
resultCodim       = res -> res#6;
isFillingResult   = res -> resultDefect(res) == 0;


fillingArchitecturesFromResults = results -> select(results, res -> isFillingResult res);
nonFillingArchitecturesFromResults = results -> select(results, res -> not isFillingResult res);
architectureListFromResults = results -> apply(results, res -> resultSizes res);

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
        scan(L, a -> << "  " << toString a << endl)
    );
);

printStep2ResultHelper = res -> (
    << "architecture = " << toString(resultSizes res)
       << ", r = " << toString(resultExponent res)
       << ", ambient = " << toString(resultAmbientDim res)
       << ", expected = " << toString(resultExpectedDim res)
       << ", dim = " << toString(resultDimension res)
       << ", defect = " << toString(resultDefect res)
       << endl;
);

frontierSearchHidden = (depth, d0, dL, m, n, r, B, seed) -> (
    state := makeFrontierState(depth, d0, dL, m, n, r);
    runFrontierSearchResume(state, B, seed)
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

runFrontierSearch = (depth, d0, dL, m, n, r, B, seed) -> (
    startTime:=currentTime();
    out := frontierSearchHidden(depth, d0, dL, m, n, r, B, seed);
    printFrontierSummary out;
    out;
    finishWithTiming(out,startTime)
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

midpointScore = pair -> (
    q := pair#0;
    f := pair#1;

    gaps := apply(#q, i -> f#i - q#i);

    vol := product apply(#q, i -> gaps#i + 1);
    minGap := min gaps;
    sumGap := sum gaps;

    -- heuristic weights
    vol + 10 * minGap + sumGap
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

    buildCombos := (i, partial) -> (
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

    perturbOne := (a, i) -> uniqueTuples select({
        apply(#a, j -> if j == i then a#j - 1 else a#j),
        apply(#a, j -> if j == i then a#j + 1 else a#j)
    }, b -> coordinateWiseStrictInterior(b, q, f));

    uniqueTuples flatten apply(mids, a -> flatten apply(bigCoords, i -> perturbOne(a, i)))
);

chooseGuidedCandidateFiltered = (Fmin, Nmax) -> (
    thePairs := comparablePairs(Nmax, Fmin);
    if #thePairs == 0 then return null;
    --orderedPairs := sort(pairs, (A, B) -> pairGapVolume(A) > pairGapVolume(B));
    --orderedPairs := reverse sort(pairs, p -> pairGapVolume p);
    orderedPairs := reverse sort(thePairs, p -> midpointScore p);
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
    state := makeFrontierState(depth, d0, dL, m, n, r);
    runGuidedFrontierSearchResume(state, B, seed)
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
    startTime:=currentTime();
    out := frontierSearchHiddenGuided(depth, d0, dL, m, n, r, B, seed);
    printGuidedFrontierSummary out;
    finishWithTiming(out,startTime)
);

------------------------------------------------------------
-- ✅ Initialize frontier with user-specified architectures
------------------------------------------------------------

------------------------------------------------------------
-- Initialize frontier with user-specified hidden tuples
------------------------------------------------------------

initializeFrontierWithArchitectures = (state, tuples) -> (

    d0 := state#"d0";
    dL := state#"dL";
    r := state#"exponent";

    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";
    FminResults := state#"FminResults";
    Seen := state#"SeenTuples";
    nEvaluated := state#"nEvaluated";

    for a in tuples do (

        if any(Seen, s -> tupleEQ(s, a)) then (
            << "Skipping already-seen tuple " << toString a << endl;
        ) else (
            Seen = join(Seen, {a});

            if impliedFilling(a, Fmin) then (
                << "Skipping (implied filling): " << toString a << endl;
            ) else if impliedNonFilling(a, Nmax) then (
                << "Skipping (implied non-filling): " << toString a << endl;
            ) else (
                arch := architectureFromHidden(d0, dL, a);
                << "Evaluating seeded architecture " << toString arch << endl;

                --res := architectureStatistics(arch, r);
        res := getDimensionCached(state, arch);
        nEvaluated = nEvaluated + 1;

                << "  -> dim = " << toString(resultDimension res)
                   << ", defect = " << toString(resultDefect res) << endl;

                if isFillingResult(res) then (
                    Fmin = updateMinimalAntichain(Fmin, a);

                    FminResults = select(FminResults,
                        rr -> not tupleGT(hiddenLayerWidths(resultSizes rr), a)
                    );

                    if not any(FminResults, rr -> tupleEQ(hiddenLayerWidths(resultSizes rr), a)) then
                        FminResults = join(FminResults, {res});

                    << "  classified as filling" << endl;
                ) else (
                    Nmax = updateMaximalAntichain(Nmax, a);
                    << "  classified as non-filling" << endl;
                );
            );
        );

        << endl;
    );

    state#"FminTuples" = Fmin;
    state#"NmaxTuples" = Nmax;
    state#"FminResults" = FminResults;
    state#"SeenTuples" = Seen;
    state#"nEvaluated" = nEvaluated;

    state
);



------------------------------------------------------------
-- Certify all unresolved upper-shell orthant cells
-- using the blockwise recursive upper-bound method
------------------------------------------------------------

certifyAllUpperShellOrthantCellsByBlocks = state -> (
    anchors := unresolvedUpperShellTuplesInState(state);

    infos := apply(anchors, a -> blockwiseRecursiveUpperBoundFromAnchor(state, a));

    certified := select(infos, infor -> infor#"certifiedNonfillingOrthantCell");
    uncertified := select(infos, infor -> not infor#"certifiedNonfillingOrthantCell");

    hashTable {
        "anchors" => anchors,
        "numAnchors" => #anchors,
        "infoList" => infos,
        "certifiedList" => certified,
        "uncertifiedList" => uncertified,
        "numCertified" => #certified,
        "numUncertified" => #uncertified,
        "allCertified" => (#uncertified == 0)
    }
);

------------------------------------------------------------
-- Pretty printer for upper-shell block certification
------------------------------------------------------------

printUpperShellBlockCertificationSummary = cert -> (
    << "Upper-shell orthant cell certification summary" << endl;
    << "  number of unresolved upper-shell anchors = " << toString(cert#"numAnchors") << endl;
    << "  certified nonfilling orthant cells = " << toString(cert#"numCertified") << endl;
    << "  uncertified orthant cells = " << toString(cert#"numUncertified") << endl;
    << "  all unresolved upper-shell cells certified nonfilling? "
       << toString(cert#"allCertified") << endl;
    << endl;

    if cert#"numCertified" > 0 then (
        << "Certified anchors:" << endl;
        scan(cert#"certifiedList", infor -> (
            << "  " << toString(infor#"anchor")
               << "  with upper bound " << toString(infor#"upperBound")
               << " < expected " << toString(infor#"expectedDimAtAnchor")
               << endl;
        ));
        << endl;
    );

    if cert#"numUncertified" > 0 then (
        << "Uncertified anchors:" << endl;
        scan(cert#"uncertifiedList", infor -> (
            << "  " << toString(infor#"anchor")
               << "  with upper bound " << toString(infor#"upperBound")
               << ", expected " << toString(infor#"expectedDimAtAnchor")
               << endl;
        ));
    );
);

------------------------------------------------------------
-- MinimalFillingArchitecturesV6_candidateFrontier_patch.m2
--
-- Load AFTER MinimalFillingArchitecturesV6.m2
--
-- This patch adds candidate frontier bounds for frontier search.
-- Candidate bounds are SEARCH RESTRICTIONS only:
--   CandidateNmax = lower search bounds
--   CandidateFmin = upper search bounds
-- They are NOT treated as already-proved frontier data.
--
-- Main additions:
--   initializeCandidateFrontierBounds(state, candidateNmax, candidateFmin)
--   unresolvedTuplesWithinCandidates(...)
--   unresolvedTuplesWithinCandidatesInState(state)
--   runSearchBetweenCandidates(...)
--
-- and patched versions of:
--   makeFrontierState
--   runFrontierSearchResume
--   runGuidedFrontierSearchResume
------------------------------------------------------------

------------------------------------------------------------
-- Frontier state with candidate bounds
------------------------------------------------------------


makeFrontierState = (depth, d0, dL, m, n, r) -> (
    new MinimalFillingSearchState from new MutableHashTable from hashTable{
        "depth" => depth,
        "d0" => d0,
        "dL" => dL,
        "range" => {m, n},
        "exponent" => r,

        "FminTuples" => {},
        "NmaxTuples" => {},
        "FminResults" => {},
        "SeenTuples" => {},

        "CandidateFmin" => {},
        "CandidateNmax" => {},

        "nEvaluated" => 0,
        "nSkippedByFilling" => 0,
        "nSkippedByNonFilling" => 0,
        "nGuidedProposals" => 0,
        "nRandomProposals" => 0,

        "exhausted" => false,
        "unresolvedCount" => null,

        "DimensionCache" => new MutableHashTable from {},
        "ExactBlockCache" => new MutableHashTable from {},
        "nCacheHits" => 0,
        "nCacheMisses" => 0,
	"Timing" => 0
    }
);

------------------------------------------------------------
-- Candidate-bound initialization
------------------------------------------------------------

export{"initializeCandidateFrontierBounds"}
initializeCandidateFrontierBounds = (state, candidateNmax, candidateFmin) -> (
    state#"CandidateNmax" = candidateNmax;
    state#"CandidateFmin" = candidateFmin;
    state
);


------------------------------------------------------------
-- Uniform random tuple between two comparable tuples q <= f
------------------------------------------------------------

randomTupleBetween = (q, f) -> (
    if #q =!= #f then
        error "randomTupleBetween: q and f must have the same length";
    if not tupleLEQ(q, f) then
        error "randomTupleBetween: require q <= f coordinatewise";

    apply(#q, i -> q#i + random(f#i - q#i + 1))
);

------------------------------------------------------------
-- Propose one candidate hidden tuple without exhaustive lists
--
-- Returns:
--   a hidden tuple, or null if no proposal is found
--
-- Assumes:
--   CandidateFmin and CandidateNmax are both nonempty
------------------------------------------------------------

nextCandidateTuple = state -> (
    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";
    Seen := state#"SeenTuples";
    candidateNmax := state#"CandidateNmax";
    candidateFmin := state#"CandidateFmin";

    if #candidateFmin == 0 then return null;
    if #candidateNmax == 0 then return null;

    --------------------------------------------------------
    -- Helper: try to get a good tuple between q and f
    --------------------------------------------------------
    tryPair := (q, f) -> (
        if not tupleLEQ(q, f) then return null;
        if tupleEQ(q, f) then return null;

        -- Try a few random points inside the interval [q,f]
        for trial from 1 to 20 do (
            a := randomTupleBetween(q, f);

            if admissibleByCandidateBounds(a, candidateNmax, candidateFmin)
               and not impliedFilling(a, Fmin)
               and not impliedNonFilling(a, Nmax)
               and not any(Seen, s -> tupleEQ(s, a))
            then return a;
        );

        null
    );

    --------------------------------------------------------
    -- Phase 0: bootstrap between candidateNmax and candidateFmin
    --------------------------------------------------------
    for trial from 1 to 50 do (
        i := random(#candidateFmin);
        j := random(#candidateNmax);

        q := candidateNmax#j;
        f := candidateFmin#i;

        a := tryPair(q, f);
        if a =!= null then return a;
    );

    --------------------------------------------------------
    -- Phase 1: main search between proved Nmax and proved Fmin
    --------------------------------------------------------
    if #Fmin > 0 and #Nmax > 0 then (
        for trial from 1 to 50 do (
            i := random(#Fmin);
            j := random(#Nmax);

            q := Nmax#j;
            f := Fmin#i;

            a := tryPair(q, f);
            if a =!= null then return a;
        );
    );

    --------------------------------------------------------
    -- Phase 2: between proved Fmin and candidateFmin
    --------------------------------------------------------
    if #Fmin > 0 then (
        for trial from 1 to 50 do (
            i := random(#candidateFmin);
            j := random(#Fmin);

            q := Fmin#j;
            f := candidateFmin#i;

            a := tryPair(q, f);
            if a =!= null then return a;
        );
    );

    --------------------------------------------------------
    -- Phase 3: between candidateNmax and proved Nmax
    --------------------------------------------------------
    if #Nmax > 0 then (
        for trial from 1 to 50 do (
            i := random(#Nmax);
            j := random(#candidateNmax);

            q := candidateNmax#j;
            f := Nmax#i;

            a := tryPair(q, f);
            if a =!= null then return a;
        );
    );

    null
);

------------------------------------------------------------
-- Candidate-bound admissibility
------------------------------------------------------------

admissibleByCandidateBounds = (a, candidateNmax, candidateFmin) -> (
    lowerOK := (#candidateNmax == 0) or any(candidateNmax, q -> tupleGEQ(a, q));
    upperOK := (#candidateFmin == 0) or any(candidateFmin, f -> tupleLEQ(a, f));
    lowerOK and upperOK
);

unresolvedTuplesWithinCandidates = (depth, m, n, Fmin, Nmax, candidateNmax, candidateFmin) -> (
    select(
        unresolvedTuples(depth, m, n, Fmin, Nmax),
        a -> admissibleByCandidateBounds(a, candidateNmax, candidateFmin)
    )
);

unresolvedTuplesWithinCandidatesInState = state -> (
    depth := state#"depth";
    m := (state#"range")#0;
    n := (state#"range")#1;
    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";
    candidateNmax := if state#? "CandidateNmax" then state#"CandidateNmax" else {};
    candidateFmin := if state#? "CandidateFmin" then state#"CandidateFmin" else {};

    unresolvedTuplesWithinCandidates(depth, m, n, Fmin, Nmax, candidateNmax, candidateFmin)
);

------------------------------------------------------------
-- Guided candidate choice restricted to candidate bounds
------------------------------------------------------------

chooseGuidedCandidateFilteredWithinCandidates = (Fmin, Nmax, candidateNmax, candidateFmin) -> (
    thePairs := comparablePairs(Nmax, Fmin);
    if #thePairs == 0 then return null;

    orderedPairs := reverse sort(thePairs, p -> midpointScore p);

    for pair in orderedPairs do (
        mids := midpointCandidates pair;
        goodMid := select(mids,
            a -> not impliedFilling(a, Fmin)
                 and not impliedNonFilling(a, Nmax)
                 and admissibleByCandidateBounds(a, candidateNmax, candidateFmin)
        );
        if #goodMid > 0 then return first goodMid;

        near := nearbyInteriorCandidates pair;
        goodNear := select(near,
            a -> not impliedFilling(a, Fmin)
                 and not impliedNonFilling(a, Nmax)
                 and admissibleByCandidateBounds(a, candidateNmax, candidateFmin)
        );
        if #goodNear > 0 then return first goodNear;
    );

    null
);

------------------------------------------------------------
-- Patched random frontier resume search restricted to candidates
------------------------------------------------------------

runFrontierSearchResume = (state, B, seed) -> (
    startTime := currentTime();

    depth := state#"depth";
    d0 := state#"d0";
    dL := state#"dL";
    m := (state#"range")#0;
    n := (state#"range")#1;
    r := state#"exponent";

    k := depth - 1;
    if seed =!= null then setRandomSeed seed;

    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";
    FminResults := state#"FminResults";
    Seen := state#"SeenTuples";

    candidateFmin := if state#? "CandidateFmin" then state#"CandidateFmin" else {};
    candidateNmax := if state#? "CandidateNmax" then state#"CandidateNmax" else {};

    nEvaluated := state#"nEvaluated";
    nSkippedByFilling := state#"nSkippedByFilling";
    nSkippedByNonFilling := state#"nSkippedByNonFilling";
    nGuidedProposals := state#"nGuidedProposals";
    nRandomProposals := state#"nRandomProposals";

    << "Resuming frontier search using nextCandidateTuple:" << endl;
    << "  depth = " << toString depth << endl;
    << "  architecture form = {" << toString d0 << ", a1, ..., a"
       << toString k << ", " << toString dL << "}" << endl;
    << "  hidden widths in [" << toString m << ", " << toString n << "]" << endl;
    << "  exponent r = " << toString r << endl;
    << "  additional budget B = " << toString B << endl;
    if #candidateNmax > 0 then << "  candidate Nmax = " << toString candidateNmax << endl;
    if #candidateFmin > 0 then << "  candidate Fmin = " << toString candidateFmin << endl;
    if seed =!= null then << "  seed = " << toString seed << endl;
    << endl;

    -- Since we are no longer enumerating the full unresolved set,
    -- exact unresolvedCount/exhausted are not maintained here.
    state#"unresolvedCount" = null;
    state#"exhausted" = null;

    for t from 1 to B do (
        a := nextCandidateTuple(state);

        if a === null then (
            << "No further candidate tuple found by nextCandidateTuple." << endl;

            state#"FminTuples" = Fmin;
            state#"NmaxTuples" = Nmax;
            state#"FminResults" = FminResults;
            state#"SeenTuples" = Seen;
            state#"nEvaluated" = nEvaluated;
            state#"nSkippedByFilling" = nSkippedByFilling;
            state#"nSkippedByNonFilling" = nSkippedByNonFilling;
            state#"nGuidedProposals" = nGuidedProposals;
            state#"nRandomProposals" = nRandomProposals;

            state#"unresolvedCount" = null;
            state#"exhausted" = null;

            return finishWithTiming(state, startTime);
        );

        nRandomProposals = nRandomProposals + 1;

        << "Resume iteration " << toString t << " / " << toString B
           << ": proposed hidden widths " << toString a
           << " (from nextCandidateTuple)" << endl;

        if any(Seen, s -> tupleEQ(s, a)) then (
            nSkippedByFilling = nSkippedByFilling + 0;
            nSkippedByNonFilling = nSkippedByNonFilling + 0;
            << "  skipped (already seen in earlier search)" << endl;
            << endl;
        ) else if impliedFilling(a, Fmin) then (
            nSkippedByFilling = nSkippedByFilling + 1;
            << "  skipped (implied filling)" << endl;
            << endl;
        ) else if impliedNonFilling(a, Nmax) then (
            nSkippedByNonFilling = nSkippedByNonFilling + 1;
            << "  skipped (implied non-filling)" << endl;
            << endl;
        ) else (
            Seen = join(Seen, {a});

            arch := architectureFromHidden(d0, dL, a);
            << "  evaluating architecture " << toString arch << endl;

            res := getDimensionCached(state, arch);
            nEvaluated = nEvaluated + 1;

            << "  -> dim = " << toString(resultDimension res)
               << ", defect = " << toString(resultDefect res)
               << ", codim = " << toString(resultCodim res) << endl;

            if isFillingResult(res) then (
                Fmin = updateMinimalAntichain(Fmin, a);

                FminResults = select(FminResults,
                    rr -> not tupleGT(hiddenLayerWidths(resultSizes rr), a)
                );
                if not any(FminResults, rr -> tupleEQ(hiddenLayerWidths(resultSizes rr), a)) then
                    FminResults = join(FminResults, {res});

                << "  classified as filling; updated Fmin" << endl;
            ) else (
                Nmax = updateMaximalAntichain(Nmax, a);
                << "  classified as non-filling; updated Nmax" << endl;
            );

            state#"FminTuples" = Fmin;
            state#"NmaxTuples" = Nmax;
            state#"FminResults" = FminResults;
            state#"SeenTuples" = Seen;
            state#"nEvaluated" = nEvaluated;
            state#"nSkippedByFilling" = nSkippedByFilling;
            state#"nSkippedByNonFilling" = nSkippedByNonFilling;
            state#"nGuidedProposals" = nGuidedProposals;
            state#"nRandomProposals" = nRandomProposals;

            << endl;
        );
    );

    state#"FminTuples" = Fmin;
    state#"NmaxTuples" = Nmax;
    state#"FminResults" = FminResults;
    state#"SeenTuples" = Seen;
    state#"nEvaluated" = nEvaluated;
    state#"nSkippedByFilling" = nSkippedByFilling;
    state#"nSkippedByNonFilling" = nSkippedByNonFilling;
    state#"nGuidedProposals" = nGuidedProposals;
    state#"nRandomProposals" = nRandomProposals;

    state#"unresolvedCount" = null;
    state#"exhausted" = null;

    finishWithTiming(state, startTime)
);
------------------------------------------------------------
-- Patched guided frontier resume search restricted to candidates
------------------------------------------------------------

runGuidedFrontierSearchResume = (state, B, seed) -> (
    startTime := currentTime();

    depth := state#"depth";
    d0 := state#"d0";
    dL := state#"dL";
    m := (state#"range")#0;
    n := (state#"range")#1;
    r := state#"exponent";

    k := depth - 1;
    if seed =!= null then setRandomSeed seed;

    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";
    FminResults := state#"FminResults";
    Seen := state#"SeenTuples";

    candidateFmin := if state#? "CandidateFmin" then state#"CandidateFmin" else {};
    candidateNmax := if state#? "CandidateNmax" then state#"CandidateNmax" else {};

    nEvaluated := state#"nEvaluated";
    nSkippedByFilling := state#"nSkippedByFilling";
    nSkippedByNonFilling := state#"nSkippedByNonFilling";
    nGuidedProposals := state#"nGuidedProposals";
    nRandomProposals := state#"nRandomProposals";

    << "Resuming guided frontier search with candidate bounds:" << endl;
    << "  depth = " << toString depth << endl;
    << "  architecture form = {" << toString d0 << ", a1, ..., a" << toString k << ", " << toString dL << "}" << endl;
    << "  hidden widths in [" << toString m << ", " << toString n << "]" << endl;
    << "  exponent r = " << toString r << endl;
    << "  additional budget B = " << toString B << endl;
    if #candidateNmax > 0 then << "  candidate Nmax = " << toString candidateNmax << endl;
    if #candidateFmin > 0 then << "  candidate Fmin = " << toString candidateFmin << endl;
    if seed =!= null then << "  seed = " << toString seed << endl;
    << endl;

    for t from 1 to B do (
        unresolved := unresolvedTuplesWithinCandidates(depth, m, n, Fmin, Nmax, candidateNmax, candidateFmin);

        if #unresolved == 0 then (
            << "Search exhausted: no unresolved hidden tuples remain in the candidate-restricted box region." << endl;
            state#"exhausted" = true;
            state#"unresolvedCount" = 0;

            state#"FminTuples" = Fmin;
            state#"NmaxTuples" = Nmax;
            state#"FminResults" = FminResults;
            state#"SeenTuples" = Seen;
            state#"nEvaluated" = nEvaluated;
            state#"nSkippedByFilling" = nSkippedByFilling;
            state#"nSkippedByNonFilling" = nSkippedByNonFilling;
            state#"nGuidedProposals" = nGuidedProposals;
            state#"nRandomProposals" = nRandomProposals;
            return  finishWithTiming(state,startTime);
        );

        state#"unresolvedCount" = #unresolved;

        guided := chooseGuidedCandidateFilteredWithinCandidates(Fmin, Nmax, candidateNmax, candidateFmin);
        a := null;
        proposalType := null;

        if guided === null then (
            a = unresolved#(random(#unresolved));
            proposalType = "random-from-candidate-restricted-unresolved";
            nRandomProposals = nRandomProposals + 1;
        ) else (
            a = guided;
            proposalType = "guided";
            nGuidedProposals = nGuidedProposals + 1;
        );

        << "Resume iteration " << toString t << " / " << toString B
           << ": proposed hidden widths " << toString a
           << " (" << proposalType << ")" << endl;

        if any(Seen, s -> tupleEQ(s, a)) then (
            << "  skipped (already seen in earlier search)" << endl;
            << endl;
        ) else (
            Seen = join(Seen, {a});

            arch := architectureFromHidden(d0, dL, a);
            << "  evaluating architecture " << toString arch << endl;
            res := getDimensionCached(state, arch);
            nEvaluated = nEvaluated + 1;

            << "  -> dim = " << toString(resultDimension res)
               << ", defect = " << toString(resultDefect res)
               << ", codim = " << toString(resultCodim res) << endl;

            if isFillingResult(res) then (
                Fmin = updateMinimalAntichain(Fmin, a);

                FminResults = select(FminResults,
                    rr -> not tupleGT(hiddenLayerWidths(resultSizes rr), a)
                );
                if not any(FminResults, rr -> tupleEQ(hiddenLayerWidths(resultSizes rr), a)) then
                    FminResults = join(FminResults, {res});

                << "  classified as filling; updated Fmin" << endl;
            ) else (
                Nmax = updateMaximalAntichain(Nmax, a);
                << "  classified as non-filling; updated Nmax" << endl;
            );

            << endl;
        );
    );

    state#"FminTuples" = Fmin;
    state#"NmaxTuples" = Nmax;
    state#"FminResults" = FminResults;
    state#"SeenTuples" = Seen;
    state#"nEvaluated" = nEvaluated;
    state#"nSkippedByFilling" = nSkippedByFilling;
    state#"nSkippedByNonFilling" = nSkippedByNonFilling;
    state#"nGuidedProposals" = nGuidedProposals;
    state#"nRandomProposals" = nRandomProposals;

    unresolvedFinal := unresolvedTuplesWithinCandidates(depth, m, n, Fmin, Nmax, candidateNmax, candidateFmin);
    state#"unresolvedCount" = #unresolvedFinal;
    state#"exhausted" = (#unresolvedFinal == 0);


    endTime := currentTime();
    oldTiming := if state#? "Timing" then state#"Timing" else 0;
    state#"Timing" = oldTiming + (endTime - startTime);
    finishWithTiming(state,startTime)
);



------------------------------------------------------------
-- Convenience wrapper:
-- run frontier search between candidate Nmax and candidate Fmin
------------------------------------------------------------

export{"runSearchBetweenCandidates"}
runSearchBetweenCandidates = (d0, dL, candidateNmax, candidateFmin, r, B, seed, guided, seedTuples) -> (
    candidates := join(candidateNmax, candidateFmin);
    if #candidates == 0 then
        error "runSearchBetweenCandidates: at least one candidate lower or upper tuple must be given";

    firstTuple := first candidates;
    k := #firstTuple;

    if any(candidates, a -> #a =!= k) then
        error "runSearchBetweenCandidates: all candidate tuples must have the same hidden length";

    m := min flatten candidates;
    n := max flatten candidates;

    state := makeFrontierState(k + 1, d0, dL, m, n, r);
    state = initializeCandidateFrontierBounds(state, candidateNmax, candidateFmin);

    if #seedTuples > 0 then (
        state = initializeFrontierWithArchitectures(state, seedTuples);
    );

    if guided then
        runGuidedFrontierSearchResume(state, B, seed)
    else
        runFrontierSearchResume(state, B, seed)
);


end

restart
load "/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV7a.m2"

state = runSearchBetweenCandidates(
    2, 1,
    {{2,2,2,2,8}},
    {{2,2,2,2,12}},
    2, 50, 12345, true, {}
)


state = makeFrontierState(6, 2, 1, 2, 12, 2)
state = initializeCandidateFrontierBounds(
    state,
    {{2,2,2,2,8}},
    {{2,2,2,2,12}}
)
state = runGuidedFrontierSearchResume(state, 50, 12345)
peek state


----
state = runSearchBetweenCandidates(
    2, 1,
    {{2,2,2,2,2}},
    {{6,6,6,6,6}},
    2, 50, 12345, true, {}
)


state = makeFrontierState(6, 2, 1, 2, 12, 2)
state = initializeCandidateFrontierBounds(
    state,
    {{2,2,2,2,2}},
    {{6,6,6,6,6}}
)
state = runGuidedFrontierSearchResume(state, 50, 12345)
state = runGuidedFrontierSearchResume(state, 10, 123456);
state = runGuidedFrontierSearchResume(state, 10, 12345699);

state = runGuidedFrontierSearchResume(state, 50, 1299);
printGuidedFrontierSummary(state);
printGuidedFrontierFillingResults(state);


end
restart
load "/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV7a.m2"
stats = architectureStatistics({2,2,1}, 2)
print stats
stats#0
stats#4
stats#"Legend"
(stats#"Legend")#4
state = makeFrontierState(3, 2, 1, 2, 3, 2);
resi = getDimensionCached(state, {2,2,1});
print resi;




end--
restart
load "/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV7a.m2"

B=50
isGuided=false
state = runSearchBetweenCandidates(
    2, 1,
    {{2,2,2}},
    {{10,10,10}},
    2, 50, 12345, isGuided, {}
)
printFrontierSummary state
state
runFrontierSearchResume(state, B, 12334456)
printFrontierSummary state



numHidden=5
B=10
isGuided=false         --timing           = 125
--isGuided=true   

state = runSearchBetweenCandidates(
    2, 1,
    {apply(numHidden, i->2)},
    {apply(numHidden, i->7)},
    2, B, 12345, isGuided, {}
)
B=1000
printFrontierSummary state
runFrontierSearchResume(state, B, 12334456)
printFrontierSummary state
state = makeFrontierState(3, 2, 1, 2, 3, 2);

peek state
NFA = first state#"NmaxTuples"
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);

anchorCert
printBlockwiseRecursiveCertificate(anchorCert);
orthantCellCertifiedNonfillingByBlocks(state, NFA)
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA)

printBlockwiseRecursiveCertificate(anchorCert)
orthantCellCertifiedNonfillingByBlocks(state, NFA)

all(state#"NmaxTuples",
    NFA->(
	print NFA;
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	anchorCert;
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA);
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA)))

-----


---TALK
---BIG COMPUTATION
numHidden=5
B=0
isGuided=false         --timing           = 125
--isGuided=true   

state = runSearchBetweenCandidates(
    2, 1,
    {apply(numHidden, i->2)},
    {apply(numHidden, i->5)},
    2, B, 12345, isGuided, {}
)
B=100000
printFrontierSummary state
runFrontierSearchResume(state, B, 12334456)
--printFrontierSummary state
all(state#"NmaxTuples",
    NFA->(
	print NFA;
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	anchorCert;
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA);
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA)))
NFA = first state#"NmaxTuples"
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);

anchorCert
printBlockwiseRecursiveCertificate(anchorCert);
orthantCellCertifiedNonfillingByBlocks(state, NFA)
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA)

printBlockwiseRecursiveCertificate(anchorCert)
orthantCellCertifiedNonfillingByBlocks(state, NFA)



---
---TALK
---BIG COMPUTATION
numHidden=6
maxBound=7
B=0
isGuided=false        
--isGuided=true
precomputedKnownMFA={{2, 3, 4, 5, 4, 6, 4, 1},{2, 3, 4, 5, 6, 4, 2, 1},
{2, 3, 3, 4, 5, 6, 3, 1}, {2, 3, 4, 5, 5, 5, 2, 1},
{2, 3, 3, 5, 6, 4, 4, 1},{2, 3, 3, 5, 7, 4, 2, 1},
{2, 3, 3, 4, 6, 5, 2, 1},{2, 3, 4, 5, 5, 4, 4, 1},
{2, 3, 4, 4, 5, 5, 4, 1},{2, 3, 3, 6, 6, 4, 3, 1},
{2, 3, 3, 5, 5, 5, 4, 1},{2, 3, 4, 6, 5, 4, 3, 1},
{2, 3, 5, 5, 5, 4, 3, 1}}
precomputedKnownMFA = for i in precomputedKnownMFA list for j from 1 to #i-2 list i_j
precomputedKnownMNF = flatten for hid in precomputedKnownMFA list apply(#hid,i->replace(i,hid_i-1,hid))

state = runSearchBetweenCandidates(
    2, 1,
    {apply(numHidden, i->2)},
    {apply(numHidden, i->maxBound)},
    2, B, 12345, isGuided, precomputedKnownMFA|precomputedKnownMNF
)
--- use two primes

scan(10,i->(
    B=100;
    printFrontierSummary state;
    state = runFrontierSearchResume(state, B, random(1,10000));
    ))

all(state#"NmaxTuples",
    NFA->(
	print NFA;
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	anchorCert;
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA);
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA)))
NFA = first state#"NmaxTuples"
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);

anchorCert
printBlockwiseRecursiveCertificate(anchorCert);
orthantCellCertifiedNonfillingByBlocks(state, NFA)
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA)

printBlockwiseRecursiveCertificate(anchorCert)
orthantCellCertifiedNonfillingByBlocks(state, NFA)






state = makeFrontierState(3, 2, 1, 2, 3, 2);

peek state
NFA = first state#"NmaxTuples"
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);

anchorCert
printBlockwiseRecursiveCertificate(anchorCert);
orthantCellCertifiedNonfillingByBlocks(state, NFA)
anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA)

printBlockwiseRecursiveCertificate(anchorCert)
orthantCellCertifiedNonfillingByBlocks(state, NFA)

all(state#"NmaxTuples",
    NFA->(
	print NFA;
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	anchorCert;
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA);
	anchorCert = blockwiseRecursiveUpperBoundFromAnchor(state, NFA);
	printBlockwiseRecursiveCertificate(anchorCert);
	orthantCellCertifiedNonfillingByBlocks(state, NFA)))


{{2, 3, 4, 5, 4, 6, 4, 1},{2, 3, 4, 5, 6, 4, 2, 1},
{2, 3, 3, 4, 5, 6, 3, 1}, (2, 3, 4, 5, 5, 5, 2, 1},
{2, 3, 3, 5, 6, 4, 4, 1},(2, 3, 3, 5, 7, 4, 2, 1},
{2, 3, 3, 4, 6, 5, 2, 1},(2, 3, 4, 5, 5, 4, 4, 1},
{2, 3, 4, 4, 5, 5, 4, 1},(2, 3, 3, 6, 6, 4, 3, 1},
{2, 3, 3, 5, 5, 5, 4, 1},(2, 3, 4, 6, 5, 4, 3, 1},
{2, 3, 5, 5, 5, 4, 3, 1}}


peek state

state = makeFrontierState(6, 2, 1, 2, 12, 2)
state = initializeCandidateFrontierBounds(
    state,
    {{2,2,2,2,8}},
    {{2,2,2,2,12}}
)
state = runGuidedFrontierSearchResume(state, 50, 12345)


---
restart
load "/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV7a.m2"

state = makeFrontierState(3, 2, 1, 2, 3, 2)



restart
load "/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV7a.m2"

state = makeFrontierState(3, 2, 1, 2, 3, 2);
state#"Timing"

state = runGuidedFrontierSearchResume(state, 2, 12345);

state#"Timing"
state




restart
--BIIGGGG
load "/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV7a.m2"

numHidden=6
maxBound=7
B=0
isGuided=false        
--isGuided=true
precomputedKnownMFA={{2, 3, 4, 5, 4, 6, 4, 1},{2, 3, 4, 5, 6, 4, 2, 1},
{2, 3, 3, 4, 5, 6, 3, 1}, {2, 3, 4, 5, 5, 5, 2, 1},
{2, 3, 3, 5, 6, 4, 4, 1},{2, 3, 3, 5, 7, 4, 2, 1},
{2, 3, 3, 4, 6, 5, 2, 1},{2, 3, 4, 5, 5, 4, 4, 1},
{2, 3, 4, 4, 5, 5, 4, 1},{2, 3, 3, 6, 6, 4, 3, 1},
{2, 3, 3, 5, 5, 5, 4, 1},{2, 3, 4, 6, 5, 4, 3, 1},
{2, 3, 5, 5, 5, 4, 3, 1}}
precomputedKnownMFA = for i in precomputedKnownMFA list for j from 1 to #i-2 list i_j
--precomputedKnownMNF = flatten for hid in precomputedKnownMFA list apply(#hid,i->replace(i,hid_i-1,hid))




immediateUpperNeighborsInBox = (a, n) -> (
    flatten apply(#a, i ->
        if a#i < n then {
            apply(#a, j -> if j == i then a#j + 1 else a#j)
        } else {}
    )
);

isMaximalNonfillingFromFmin = (a, Fmin, n) -> (
    not impliedFilling(a, Fmin) and
    all(immediateUpperNeighborsInBox(a, n), b -> impliedFilling(b, Fmin))
);

maximalNonfillingTuplesFromFmin = (depth, m, n, Fmin) -> (
    select(
        allHiddenTuplesInBox(depth, m, n),
        a -> isMaximalNonfillingFromFmin(a, Fmin, n)
    )
);

-- Example: suppose these are ALL minimal fillings in the box
Nmax = maximalNonfillingTuplesFromFmin(7, 2, maxBound, precomputedKnownMFA);
Nmax

state = runSearchBetweenCandidates(
    2, 1,
    {apply(numHidden, i->2)},
    {apply(numHidden, i->maxBound)},
    2, B, 12345, isGuided, precomputedKnownMFA|Nmax
)
state = runGuidedFrontierSearchResume(state, 5, 12345)

a = first state#"NmaxTuples"
apply(state#"NmaxTuples",
    a->(
	certData = testCanonicalCutsFromUpperShellAnchor(state, a);
	certData#"certifiedNonfillingRegion";
	printCanonicalCutSummary(certData);
	printRegionBlockCertificate(certData);
	)
    )

apply(pairs state#"ExactBlockCache", (k,v)->(
    if v#"expectedDimension"=!=v#"dimension" then k
	))





stats = architectureStatistics({2,1,1}, 3)
stats = architectureStatistics({2,2,1}, 3)
stats = architectureStatistics({2,2,2,2,2,1}, 2)
stats = architectureStatistics({2,3,1}, 3)

