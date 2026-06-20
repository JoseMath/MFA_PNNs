------------------------------------------------------------
-- MinimalFillingArchitectures_patched.m2
--
-- A Macaulay2-style package for searching for minimal filling
-- architectures in polynomial neural networks.
------------------------------------------------------------

newPackage(
    "MinimalFillingArchitecturesV4",
    Version => "0.1",
    Date => "June 18, 2026",
    Authors => {{Name => "M365 Copilot (generated package scaffold)"}},
    Headline => "Search tools for minimal filling architectures of polynomial neural networks",
    DebuggingMode => true
)

export {
    "adjacentFixedPositions",
    "canonicalCutsFromFreePositions",
    "canonicalCutsFromRegion",
    "testCanonicalCutsForRegion",
    "testCanonicalCutsFromUpperShellAnchor",
    "printCanonicalCutSummary",
    --
    "regionBlockUpperBoundFromCuts",
    "certifyRegionNonfillingByCuts",
    "printRegionBlockCertificate",
    --
    "printPatternRegionCertificate",
    "freePositionsFromAnchor",
    "boundaryPointToAnchor",
    "patternBoundaryTableFromUpperShell",    
    "patternMinimalAnchor",
    "patternRegionUpperBound",
    "certifyPatternBoundaryRegion",
    "certifyAllPatternBoundaryRegions",
    "printPatternBoundaryRegionCertificationSummary",
    "isDominatedTuple",
    "maximalElementsByDominance",
    --
    "certifyAllUpperShellOrthantCellsByBlocks",
    "printUpperShellBlockCertificationSummary",
    --
    "prefixArchitecture",
    "suffixArchitecture",
    "anchorArchitectureFromHidden",
    "fixedHiddenPositionsFromAnchor",
    "recursiveCutsFromAnchor",
    "subArchitectureByIndices",
    "ambientUpperBoundArchitecture",
    "blockContainsFreeHidden",
    "blockwiseRecursiveUpperBoundFromAnchor",
    "orthantCellCertifiedNonfillingByBlocks",
    "printBlockwiseRecursiveCertificate",
    --
    "upperShellTuples",
    "unresolvedUpperShellTuples",
    "unresolvedUpperShellTuplesInState",
    "orthantCellsFromUpperShell",
    "orthantCellsFromUpperShellInState",
    "printOrthantCellsFromUpperShell",
    --
    "allHiddenTuplesInBox",
    "unresolvedTuples",
    "unresolvedTuplesInState",
    "isFrontierExhausted",
    "midpointScore",
    "makeFrontierState",
    "runFrontierSearchResume",
    "runGuidedFrontierSearchResume",
    "initializeFrontierWithArchitectures",
    "isFillingResult",
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
    defectiveBlocksUsed := {};  
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
	    exactBlocksUsed = join(exactBlocksUsed, {exactBlockEntry});

	    if resultDimension res < resultExpectedDim res then (
		defectiveBlocksUsed = join(defectiveBlocksUsed, {exactBlockEntry});	    
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
		"defectiveBlocksUsed" => defectiveBlocksUsed
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
    if not (info#? "ExactBlocksUsed") then (
        << "No exactBlocksUsed field present in this certificate." << endl;
    ) else (
        E := info#"ExactBlocksUsed";

        << "Exact block architectures used in certification:" << endl;
        if #E == 0 then (
            << "  <none>" << endl;
        ) else (
            scan(E, entry -> (
                << "  " << toString(entry#"blockArchitecture")
                   << "  -> dim = " << toString(entry#"dimension")
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
        res := computeDimension(arch, state#"exponent");
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
-- Mutable frontier state
------------------------------------------------------------

makeFrontierState = (depth, d0, dL, m, n, r) -> (
    new MutableHashTable from  hashTable{
        "depth" => depth,
        "d0" => d0,
        "dL" => dL,
        "range" => {m, n},
        "exponent" => r,

        "FminTuples" => {},
        "NmaxTuples" => {},
        "FminResults" => {},
        "SeenTuples" => {},

        "nEvaluated" => 0,
        "nSkippedByFilling" => 0,
        "nSkippedByNonFilling" => 0,
        "nGuidedProposals" => 0,
        "nRandomProposals" => 0,

	"exhausted" => false,
	"unresolvedCount" => null,

	"DimensionCache" => new MutableHashTable from {},
	"nCacheHits" => 0,
	"nCacheMisses" => 0,
	"ExactBlockCache" => new MutableHashTable from {}
	}
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

writeCombinedFrontierStaircaseTikzTwoHidden = (state, filename) -> (
    depth := state#"depth";
    if depth =!= 3 then
        error "writeCombinedFrontierStaircaseTikzTwoHidden: requires depth = 3 (two hidden layers)";

    m := (state#"range")#0;
    n := (state#"range")#1;

    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";

    f := openOut filename;

    f << "\\begin{tikzpicture}[scale=0.9]" << endl;
    f << "  % Combined staircase diagram" << endl;

    -- Fill cells according to region type
    for i from m to n do (
        for j from m to n do (
            a := {i,j};
            t := frontierRegionTypeTwoHidden(a, Fmin, Nmax);

            if t === "filling" then (
                f << "  \\fill[blue!25] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            ) else if t === "nonfilling" then (
                f << "  \\fill[red!25] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            ) else if t === "both" then (
                f << "  \\fill[purple!30] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            ) else (
                f << "  \\fill[gray!15] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            );
        );
    );

    -- Grid
    f << "  \\draw[step=1cm,black!50] (" << toString(m-1) << "," << toString(m-1)
      << ") grid (" << toString(n) << "," << toString(n) << ");" << endl;

    -- Title and axis labels
    f << "  \\node at (" << toString((m-1+n)/2) << "," << toString(n+1.0)
      << ") {Combined staircase diagram for $F_{\\min}$ and $N_{\\max}$};" << endl;
    f << "  \\node at (" << toString((m-1+n)/2) << "," << toString(m-1-0.9)
      << ") {$a_1$};" << endl;
    f << "  \\node[rotate=90] at (" << toString(m-1-0.9) << "," << toString((m-1+n)/2)
      << ") {$a_2$};" << endl;

    -- Tick labels
    for i from m to n do (
        f << "  \\node[below] at (" << toString(i-0.5) << "," << toString(m-1)
          << ") {" << toString i << "};" << endl;
        f << "  \\node[left] at (" << toString(m-1) << "," << toString(i-0.5)
          << ") {" << toString i << "};" << endl;
    );

    -- Mark Fmin points as blue filled circles
    scan(Fmin, a -> (
        i := a#0;
        j := a#1;
        f << "  \\filldraw[blue!80!black] (" << toString(i-0.5) << "," << toString(j-0.5)
          << ") circle (2.2pt);" << endl;
    ));

    -- Mark Nmax points as red filled squares
    scan(Nmax, a -> (
        i := a#0;
        j := a#1;
        f << "  \\draw[red!80!black, fill=red!80!black] ("
          << toString(i-0.5-0.09) << "," << toString(j-0.5-0.09)
          << ") rectangle ("
          << toString(i-0.5+0.09) << "," << toString(j-0.5+0.09) << ");" << endl;
    ));

    -- If a point belongs to both Fmin and Nmax, overmark it
    scan(Fmin, a -> (
        if any(Nmax, b -> tupleEQ(a,b)) then (
            i := a#0;
            j := a#1;
            f << "  \\draw[purple!90!black, very thick] ("
              << toString(i-0.5-0.16) << "," << toString(j-0.5-0.16)
              << ") -- (" << toString(i-0.5+0.16) << "," << toString(j-0.5+0.16) << ");" << endl;
            f << "  \\draw[purple!90!black, very thick] ("
              << toString(i-0.5-0.16) << "," << toString(j-0.5+0.16)
              << ") -- (" << toString(i-0.5+0.16) << "," << toString(j-0.5-0.16) << ");" << endl;
        );
    ));

    -- Legend
    f << "  % Legend" << endl;
    f << "  \\begin{scope}[shift={(0," << toString(n+1.8) << ")}]" << endl;

    f << "    \\fill[blue!25] (0,0) rectangle (0.5,0.35);" << endl;
    f << "    \\node[right] at (0.6,0.175) {implied filling};" << endl;

    f << "    \\fill[red!25] (3.3,0) rectangle (3.8,0.35);" << endl;
    f << "    \\node[right] at (3.9,0.175) {implied non-filling};" << endl;

    f << "    \\fill[gray!15] (7.4,0) rectangle (7.9,0.35);" << endl;
    f << "    \\node[right] at (8.0,0.175) {unresolved};" << endl;

    f << "    \\fill[purple!30] (10.9,0) rectangle (11.4,0.35);" << endl;
    f << "    \\node[right] at (11.5,0.175) {implied both (inconsistent)};" << endl;

    f << "    \\filldraw[blue!80!black] (0,-0.8) circle (2.2pt);" << endl;
    f << "    \\node[right] at (0.3,-0.8) {$F_{\\min}$ point};" << endl;

    f << "    \\draw[red!80!black, fill=red!80!black] (3.3,-0.9) rectangle (3.5,-0.7);" << endl;
    f << "    \\node[right] at (3.8,-0.8) {$N_{\\max}$ point};" << endl;

    f << "  \\end{scope}" << endl;

    f << "\\end{tikzpicture}" << endl;
    close f;

    filename
);

------------------------------------------------------------
-- Write a standalone LaTeX file containing the combined TikZ figure
------------------------------------------------------------

writeCombinedFrontierStaircaseStandaloneTexTwoHidden = (state, filename) -> (
    bodyName := filename | ".tikzbody";
    writeCombinedFrontierStaircaseTikzTwoHidden(state, bodyName);

    bodyText := get bodyName;
    f := openOut filename;

    f << "\\documentclass[tikz,border=5pt]{standalone}" << endl;
    f << "\\usepackage{tikz}" << endl;
    f << "\\begin{document}" << endl;

    scan(lines bodyText, s -> f << s << endl);

    f << "\\end{document}" << endl;
    close f;

    filename
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
        exDim - dims#0,
	ambientDim - dims#0
    }
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

searchArchitectures = (archList, exponent) -> (
    total := #archList;
    apply(0 .. total - 1, i -> (
        arch := archList#i;
        << "Evaluating architecture " << toString(i + 1)
           << " of " << toString total
           << ": " << toString arch << endl;
        res := computeDimension(arch, exponent);
	--res := getDimensionCached(state, arch);
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
       << ", codim = " << toString(resultCodim res)
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
    out := frontierSearchHiddenGuided(depth, d0, dL, m, n, r, B, seed);
    printGuidedFrontierSummary out;
    out
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

                --res := computeDimension(arch, r);
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
-- Resume plain random frontier search
------------------------------------------------------------

runFrontierSearchResume = (state, B, seed) -> (

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

    nEvaluated := state#"nEvaluated";
    nSkippedByFilling := state#"nSkippedByFilling";
    nSkippedByNonFilling := state#"nSkippedByNonFilling";
    nGuidedProposals := state#"nGuidedProposals";
    nRandomProposals := state#"nRandomProposals";

    << "Resuming random frontier search with:" << endl;
    << "  depth = " << toString depth << endl;
    << "  architecture form = {" << toString d0 << ", a1, ..., a" << toString k << ", " << toString dL << "}" << endl;
    << "  hidden widths in [" << toString m << ", " << toString n << "]" << endl;
    << "  exponent r = " << toString r << endl;
    << "  additional budget B = " << toString B << endl;
    if seed =!= null then << "  seed = " << toString seed << endl;
    << endl;

    for t from 1 to B do (

        unresolved := unresolvedTuples(depth, m, n, Fmin, Nmax);

        if #unresolved == 0 then (
            << "Search exhausted: no unresolved hidden tuples remain in the box." << endl;
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

            return state;
        );

        state#"unresolvedCount" = #unresolved;

        -- choose random candidate only from unresolved region
        a := unresolved#random(#unresolved);
        nRandomProposals = nRandomProposals + 1;

        << "Resume iteration " << toString t << " / " << toString B
           << ": proposed hidden widths " << toString a
           << " (random from unresolved set)" << endl;

        if any(Seen, s -> tupleEQ(s, a)) then (
            << "  skipped (already seen in earlier search)" << endl;
            << endl;
        ) else (
            Seen = join(Seen, {a});

            arch := architectureFromHidden(d0, dL, a);
            << "  evaluating architecture " << toString arch << endl;

            --res := computeDimension(arch, r);
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

    unresolvedFinal := unresolvedTuples(depth, m, n, Fmin, Nmax);
    state#"unresolvedCount" = #unresolvedFinal;
    state#"exhausted" = (#unresolvedFinal == 0);

    state
);


------------------------------------------------------------
-- Resume guided frontier search
------------------------------------------------------------

runGuidedFrontierSearchResume = (state, B, seed) -> (

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

    nEvaluated := state#"nEvaluated";
    nSkippedByFilling := state#"nSkippedByFilling";
    nSkippedByNonFilling := state#"nSkippedByNonFilling";
    nGuidedProposals := state#"nGuidedProposals";
    nRandomProposals := state#"nRandomProposals";

    << "Resuming guided frontier search with:" << endl;
    << "  depth = " << toString depth << endl;
    << "  architecture form = {" << toString d0 << ", a1, ..., a" << toString k << ", " << toString dL << "}" << endl;
    << "  hidden widths in [" << toString m << ", " << toString n << "]" << endl;
    << "  exponent r = " << toString r << endl;
    << "  additional budget B = " << toString B << endl;
    if seed =!= null then << "  seed = " << toString seed << endl;
    << endl;

    for t from 1 to B do (

        unresolved := unresolvedTuples(depth, m, n, Fmin, Nmax);

        if #unresolved == 0 then (
            << "Search exhausted: no unresolved hidden tuples remain in the box." << endl;
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

            return state;
        );

        state#"unresolvedCount" = #unresolved;

        guided := chooseGuidedCandidateFiltered(Fmin, Nmax);

        a := null;
        proposalType := null;

        if guided === null then (
            a = unresolved#(random(#unresolved));
            proposalType = "random-from-unresolved";
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

            --res := computeDimension(arch, r);
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

    unresolvedFinal := unresolvedTuples(depth, m, n, Fmin, Nmax);
    state#"unresolvedCount" = #unresolvedFinal;
    state#"exhausted" = (#unresolvedFinal == 0);

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
end
restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV4.m2"
state0 = makeFrontierState(3, 2, 1, 2, 4, 2)
seedTuples = {
    {2,2},
    {3,3},
    {4,2} }
state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 20, 12345)

lowerBound=2
upperBound =5
pnnDepth=6
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)
seedTuples = transpose for i to pnnDepth-2 list {lowerBound,upperBound}
seedTuples = transpose for i to pnnDepth-2 list {upperBound}

state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 10000, 12345)


 -- setting random seed to 12345
Resuming guided frontier search with:
  depth = 3
  architecture form = {2, a1, ..., a2, 1}
  hidden widths in [2, 4]
  exponent r = 2
  additional budget B = 20
  seed = 12345

Search exhausted: no unresolved hidden tuples remain in the box.

o5 = MutableHashTable{...16...}

o5 : MutableHashTable

i6 :      lowerBound=2
upperBound =5

o6 = 2

i7 : 
o7 = 5

i8 : pnnDepth=6
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)

o8 = 6

i9 : 
o9 = MutableHashTable{...16...}

o9 : MutableHashTable

i10 : seedTuples = transpose for i to pnnDepth-2 list {lowerBound,upperBound}


o10 = {{2, 2, 2, 2, 2}, {5, 5, 5, 5, 5}}

o10 : List

i11 :       state1 = initializeFrontierWithArchitectures(state0, seedTuples)
Evaluating seeded architecture {2, 2, 2, 2, 2, 2, 1}
state2 = runGuidedFrontierSearchResume(state1, 10000, 12345)
  -> dim = 11, defect = 1
  classified as non-filling

Evaluating seeded architecture {2, 5, 5, 5, 5, 5, 1}
  -> dim = 33, defect = 0
  classified as filling


o11 = MutableHashTable{...16...}

o11 : MutableHashTable

i12 :  -- setting random seed to 12345
Resuming guided frontier search with:
  depth = 6
  architecture form = {2, a1, ..., a5, 1}
  hidden widths in [2, 5]
  exponent r = 2
  additional budget B = 10000
  seed = 12345

Resume iteration 1 / 10000: proposed hidden widths {3, 3, 3, 3, 3} (guided)
  evaluating architecture {2, 3, 3, 3, 3, 3, 1}
  -> dim = 24, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 2 / 10000: proposed hidden widths {4, 4, 4, 4, 4} (guided)
  evaluating architecture {2, 4, 4, 4, 4, 4, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 3 / 10000: proposed hidden widths {3, 3, 3, 3, 4} (guided)
  evaluating architecture {2, 3, 3, 3, 3, 4, 1}
  -> dim = 24, defect = 9
  classified as non-filling; updated Nmax

Resume iteration 4 / 10000: proposed hidden widths {3, 3, 3, 4, 4} (guided)
  evaluating architecture {2, 3, 3, 3, 4, 4, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 5 / 10000: proposed hidden widths {3, 3, 4, 4, 4} (guided)
  evaluating architecture {2, 3, 3, 4, 4, 4, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 6 / 10000: proposed hidden widths {4, 5, 4, 3, 4} (random-from-unresolved)
  evaluating architecture {2, 4, 5, 4, 3, 4, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax

Resume iteration 7 / 10000: proposed hidden widths {4, 4, 2, 5, 3} (random-from-unresolved)
  evaluating architecture {2, 4, 4, 2, 5, 3, 1}
  -> dim = 13, defect = 20
  classified as non-filling; updated Nmax

Resume iteration 8 / 10000: proposed hidden widths {2, 2, 5, 2, 2} (random-from-unresolved)
  evaluating architecture {2, 2, 2, 5, 2, 2, 1}
  -> dim = 11, defect = 10
  classified as non-filling; updated Nmax

Resume iteration 9 / 10000: proposed hidden widths {4, 4, 5, 3, 2} (random-from-unresolved)
  evaluating architecture {2, 4, 4, 5, 3, 2, 1}
  -> dim = 29, defect = 4
  classified as non-filling; updated Nmax

Resume iteration 10 / 10000: proposed hidden widths {2, 3, 5, 5, 2} (random-from-unresolved)
  evaluating architecture {2, 2, 3, 5, 5, 2, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 11 / 10000: proposed hidden widths {5, 5, 5, 3, 4} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 5, 3, 4, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax

Resume iteration 12 / 10000: proposed hidden widths {4, 3, 3, 4, 3} (random-from-unresolved)
  evaluating architecture {2, 4, 3, 3, 4, 3, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 13 / 10000: proposed hidden widths {4, 3, 3, 5, 3} (random-from-unresolved)
  evaluating architecture {2, 4, 3, 3, 5, 3, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 14 / 10000: proposed hidden widths {3, 2, 4, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 3, 2, 4, 5, 5, 1}
  -> dim = 13, defect = 20
  classified as non-filling; updated Nmax

Resume iteration 15 / 10000: proposed hidden widths {2, 4, 5, 4, 2} (random-from-unresolved)
  evaluating architecture {2, 2, 4, 5, 4, 2, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 16 / 10000: proposed hidden widths {2, 5, 5, 2, 5} (random-from-unresolved)
  evaluating architecture {2, 2, 5, 5, 2, 5, 1}
  -> dim = 13, defect = 20
  classified as non-filling; updated Nmax

Resume iteration 17 / 10000: proposed hidden widths {5, 2, 5, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 2, 5, 5, 5, 1}
  -> dim = 13, defect = 20
  classified as non-filling; updated Nmax

Resume iteration 18 / 10000: proposed hidden widths {3, 5, 5, 5, 2} (random-from-unresolved)
  evaluating architecture {2, 3, 5, 5, 5, 2, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 19 / 10000: proposed hidden widths {2, 4, 5, 5, 2} (guided)
  evaluating architecture {2, 2, 4, 5, 5, 2, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 20 / 10000: proposed hidden widths {2, 5, 5, 5, 2} (guided)
  evaluating architecture {2, 2, 5, 5, 5, 2, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 21 / 10000: proposed hidden widths {4, 3, 3, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 4, 3, 3, 3, 5, 1}
  -> dim = 24, defect = 9
  classified as non-filling; updated Nmax

Resume iteration 22 / 10000: proposed hidden widths {5, 5, 2, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 2, 5, 5, 1}
  -> dim = 13, defect = 20
  classified as non-filling; updated Nmax

Resume iteration 23 / 10000: proposed hidden widths {2, 5, 3, 4, 3} (random-from-unresolved)
  evaluating architecture {2, 2, 5, 3, 4, 3, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 24 / 10000: proposed hidden widths {5, 3, 3, 4, 2} (random-from-unresolved)
  evaluating architecture {2, 5, 3, 3, 4, 2, 1}
  -> dim = 23, defect = 10
  classified as non-filling; updated Nmax

Resume iteration 25 / 10000: proposed hidden widths {5, 3, 4, 2, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 3, 4, 2, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 26 / 10000: proposed hidden widths {3, 3, 3, 4, 5} (random-from-unresolved)
  evaluating architecture {2, 3, 3, 3, 4, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 27 / 10000: proposed hidden widths {3, 3, 5, 2, 5} (random-from-unresolved)
  evaluating architecture {2, 3, 3, 5, 2, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 28 / 10000: proposed hidden widths {5, 4, 3, 2, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 3, 2, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 29 / 10000: proposed hidden widths {5, 4, 3, 4, 2} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 3, 4, 2, 1}
  -> dim = 23, defect = 10
  classified as non-filling; updated Nmax

Resume iteration 30 / 10000: proposed hidden widths {4, 5, 4, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 4, 5, 4, 3, 5, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax

Resume iteration 31 / 10000: proposed hidden widths {4, 3, 5, 5, 3} (random-from-unresolved)
  evaluating architecture {2, 4, 3, 5, 5, 3, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 32 / 10000: proposed hidden widths {4, 3, 4, 5, 3} (guided)
  evaluating architecture {2, 4, 3, 4, 5, 3, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 33 / 10000: proposed hidden widths {5, 4, 5, 2, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 5, 2, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 34 / 10000: proposed hidden widths {2, 5, 5, 4, 3} (random-from-unresolved)
  evaluating architecture {2, 2, 5, 5, 4, 3, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 35 / 10000: proposed hidden widths {2, 5, 4, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 2, 5, 4, 5, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 36 / 10000: proposed hidden widths {2, 5, 5, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 2, 5, 5, 3, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 37 / 10000: proposed hidden widths {3, 3, 3, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 3, 3, 3, 5, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 38 / 10000: proposed hidden widths {4, 3, 3, 5, 4} (random-from-unresolved)
  evaluating architecture {2, 4, 3, 3, 5, 4, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 39 / 10000: proposed hidden widths {2, 4, 5, 4, 4} (random-from-unresolved)
  evaluating architecture {2, 2, 4, 5, 4, 4, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 40 / 10000: proposed hidden widths {3, 3, 5, 4, 2} (random-from-unresolved)
  evaluating architecture {2, 3, 3, 5, 4, 2, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 41 / 10000: proposed hidden widths {3, 4, 4, 4, 3} (random-from-unresolved)
  evaluating architecture {2, 3, 4, 4, 4, 3, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 42 / 10000: proposed hidden widths {5, 4, 3, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 3, 3, 5, 1}
  -> dim = 24, defect = 9
  classified as non-filling; updated Nmax

Resume iteration 43 / 10000: proposed hidden widths {4, 5, 5, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 4, 5, 5, 3, 5, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax

Resume iteration 44 / 10000: proposed hidden widths {5, 5, 3, 5, 2} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 3, 5, 2, 1}
  -> dim = 23, defect = 10
  classified as non-filling; updated Nmax

Resume iteration 45 / 10000: proposed hidden widths {3, 3, 4, 5, 3} (random-from-unresolved)
  evaluating architecture {2, 3, 3, 4, 5, 3, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 46 / 10000: proposed hidden widths {5, 3, 4, 5, 2} (random-from-unresolved)
  evaluating architecture {2, 5, 3, 4, 5, 2, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 47 / 10000: proposed hidden widths {2, 3, 5, 4, 5} (random-from-unresolved)
  evaluating architecture {2, 2, 3, 5, 4, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 48 / 10000: proposed hidden widths {4, 5, 3, 4, 4} (random-from-unresolved)
  evaluating architecture {2, 4, 5, 3, 4, 4, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 49 / 10000: proposed hidden widths {5, 4, 3, 4, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 3, 4, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 50 / 10000: proposed hidden widths {2, 4, 5, 5, 3} (random-from-unresolved)
  evaluating architecture {2, 2, 4, 5, 5, 3, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 51 / 10000: proposed hidden widths {3, 5, 3, 5, 4} (random-from-unresolved)
  evaluating architecture {2, 3, 5, 3, 5, 4, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 52 / 10000: proposed hidden widths {5, 3, 3, 5, 3} (random-from-unresolved)
  evaluating architecture {2, 5, 3, 3, 5, 3, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 53 / 10000: proposed hidden widths {5, 5, 3, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 3, 3, 5, 1}
  -> dim = 24, defect = 9
  classified as non-filling; updated Nmax

Resume iteration 54 / 10000: proposed hidden widths {3, 4, 4, 4, 2} (random-from-unresolved)
  evaluating architecture {2, 3, 4, 4, 4, 2, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 55 / 10000: proposed hidden widths {3, 3, 4, 4, 3} (random-from-unresolved)
  evaluating architecture {2, 3, 3, 4, 4, 3, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 56 / 10000: proposed hidden widths {2, 3, 5, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 2, 3, 5, 5, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 57 / 10000: proposed hidden widths {2, 5, 5, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 2, 5, 5, 5, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 58 / 10000: proposed hidden widths {4, 4, 3, 5, 4} (random-from-unresolved)
  evaluating architecture {2, 4, 4, 3, 5, 4, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 59 / 10000: proposed hidden widths {5, 5, 3, 5, 4} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 3, 5, 4, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 60 / 10000: proposed hidden widths {5, 5, 4, 2, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 4, 2, 5, 1}
  -> dim = 19, defect = 14
  classified as non-filling; updated Nmax

Resume iteration 61 / 10000: proposed hidden widths {5, 4, 4, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 4, 3, 5, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax

Resume iteration 62 / 10000: proposed hidden widths {5, 3, 3, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 3, 3, 5, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 63 / 10000: proposed hidden widths {4, 3, 4, 4, 2} (random-from-unresolved)
  evaluating architecture {2, 4, 3, 4, 4, 2, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 64 / 10000: proposed hidden widths {3, 5, 3, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 3, 5, 3, 5, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 65 / 10000: proposed hidden widths {4, 4, 3, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 4, 4, 3, 5, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 66 / 10000: proposed hidden widths {3, 3, 4, 4, 2} (random-from-unresolved)
  evaluating architecture {2, 3, 3, 4, 4, 2, 1}
  -> dim = 33, defect = 0
  classified as filling; updated Fmin

Resume iteration 67 / 10000: proposed hidden widths {5, 5, 3, 4, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 3, 4, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 68 / 10000: proposed hidden widths {5, 3, 5, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 3, 5, 3, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 69 / 10000: proposed hidden widths {5, 4, 3, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 3, 5, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 70 / 10000: proposed hidden widths {5, 4, 5, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 4, 5, 3, 5, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax

Resume iteration 71 / 10000: proposed hidden widths {5, 5, 3, 5, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 3, 5, 5, 1}
  -> dim = 27, defect = 6
  classified as non-filling; updated Nmax

Resume iteration 72 / 10000: proposed hidden widths {5, 5, 4, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 4, 3, 5, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax

Resume iteration 73 / 10000: proposed hidden widths {5, 5, 5, 3, 5} (random-from-unresolved)
  evaluating architecture {2, 5, 5, 5, 3, 5, 1}
  -> dim = 30, defect = 3
  classified as non-filling; updated Nmax




  ---
  lowerBound=2
upperBound =3
pnnDepth=7
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)
seedTuples = transpose for i to pnnDepth-2 list {}

state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 10, 12345)

state3 = runGuidedFrontierSearchResume(state2, 10000, 12345)


o25 = MutableHashTable{d0 => 2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       }
                       depth => 7
                       dL => 1
                       exhausted => true
                       exponent => 2
                       FminResults => {{{2, 3, 3, 4, 6, 5, 2, 1}, 2, 65, 65, 65, 0}, {{2, 3, 4, 5, 6, 4, 2, 1}, 2, 65, 65, 65, 0}, {{2, 3, 3, 5, 6, 4, 4, 1}, 2, 65, 65, 65, 0}, {{2, 3, 4, 4, 5, 5, 4, 1}, 2, 65, 65, 65, 0}, {{2, 3, 3, 5, 5, 5, 4, 1}, 2, 65, 65, 65, 0}, {{2, 3, 4, 5, 5, 4, 4, 1}, 2, 65, 65, 65, 0}, {{2, 3, 4, 6, 5, 4, 3, 1}, 2, 65, 65, 65, 0}, {{2, 3, 4, 5, 5, 5, 2, 1}, 2, 65, 65, 65, 0}, {{2, 3, 5, 5, 5, 4, 3, 1}, 2, 65, 65, 65, 0}, {{2, 3, 3, 6, 6, 4, 3, 1}, 2, 65, 65, 65, 0}, {{2, 3, 3, 5, 7, 4, 2, 1}, 2, 65, 65, 65, 0}, {{2, 3, 3, 4, 5, 6, 3, 1}, 2, 65, 65, 65, 0}, {{2, 3, 4, 5, 4, 6, 4, 1}, 2, 65, 65, 65, 0}}
                       FminTuples => 
                       nEvaluated => 748
                       nGuidedProposals => 61
                       NmaxTuples => {{7, 7, 7, 4, 5, 7}, {7, 2, 7, 7, 7, 7}, {7, 3, 7, 6, 4, 2}, {7, 3, 7, 5, 5, 3}, {7, 3, 7, 5, 7, 2}, {7, 3, 5, 6, 4, 3}, {7, 7, 4, 4, 7, 7}, {7, 7, 7, 3, 7, 7}, {7, 7, 4, 5, 7, 2}, {7, 4, 5, 5, 4, 3}, {7, 7, 7, 7, 3, 7}, {7, 7, 7, 5, 4, 2}, {7, 7, 7, 4, 7, 3}, {7, 7, 4, 7, 4, 7}, {7, 7, 4, 5, 5, 3}, {7, 7, 3, 7, 7, 7}, {7, 3, 7, 5, 4, 7}, {7, 3, 7, 4, 7, 7}, {2, 7, 7, 7, 7, 7}, {7, 3, 4, 5, 5, 7}}
                       nRandomProposals => 687
                       nSkippedByFilling => 0
                       nSkippedByNonFilling => 0
                       range => {2, 7}
                       SeenTuples => {{2, 5, 2, 7, 5, 3}, {4, 3, 7, 6, 5, 3}, {7, 7, 5, 2, 2, 6}, {7, 3, 5, 3, 6, 6}, {3, 5, 4, 7, 3, 6}, {2, 6, 2, 4, 5, 4}, {7, 3, 2, 6, 7, 6}, {2, 2, 3, 3, 5, 7}, {4, 6, 4, 6, 2, 6}, {7, 6, 3, 2, 4, 2}, {2, 3, 7, 4, 7, 3}, {3, 4, 3, 2, 6, 4}, {2, 5, 3, 3, 4, 3}, {7, 6, 4, 4, 7, 4}, {3, 7, 6, 6, 5, 3}, {4, 7, 2, 4, 6, 7}, {7, 5, 2, 6, 7, 4}, {6, 6, 5, 4, 2, 3}, {2, 6, 6, 5, 6, 4}, {3, 3, 7, 5, 5, 5}, {2, 5, 6, 7, 6, 3}, {7, 4, 3, 7, 2, 6}, {6, 5, 6, 2, 4, 5}, {3, 5, 3, 6, 6, 4}, {5, 3, 4, 6, 5, 2}, {2, 6, 6, 4, 7, 3}, {2, 4, 7, 3, 7, 5}, {6, 7, 7, 4, 7, 7}, {4, 4, 5, 3, 6, 7}, {6, 6, 6, 3, 5, 6}, {6, 6, 6, 4, 4, 5}, {5, 5, 6, 3, 6, 7}, {4, 5, 7, 4, 7, 5}, {3, 4, 7, 4, 7, 4}, {2, 3, 7, 4, 7, 4}, {2, 4, 7, 4, 7, 4}, {2, 3, 3, 6, 4, 6}, {2, 2, 7, 5, 6, 7}, {2, 4, 4, 4, 3, 7}, {5, 2, 3, 6, 3, 4}, {6, 7, 3, 4, 2, 4}, {3, 5, 7, 6, 7, 3}, {4, 3, 7, 2, 3, 6}, {2, 3, 5, 7, 7, 5}, {5, 7, 7, 4, 6, 2}, {2, 7, 6, 2, 5, 6}, {4, 7, 4, 4, 2, 7}, {3, 5, 3, 4, 6, 5}, {7, 7, 7, 4, 2, 5}, {6, 7, 2, 2, 7, 7}, {5, 2, 4, 6, 3, 4}, {2, 6, 6, 5, 5, 5}, {6, 7, 4, 3, 2, 6}, {5, 5, 5, 2, 7, 6}, {7, 3, 7, 5, 3, 6}, {5, 2, 7, 7, 6, 6}, {5, 6, 2, 5, 7, 5}, {4, 3, 4, 4, 6, 7}, {7, 2, 4, 6, 6, 5}, {5, 6, 3, 7, 2, 4}, {2, 5, 7, 4, 3, 5}, {3, 3, 4, 5, 5, 7}, {5, 6, 2, 6, 6, 2}, {7, 4, 2, 4, 4, 6}, {4, 4, 6, 7, 2, 7}, {7, 6, 7, 3, 5, 6}, {4, 7, 4, 3, 7, 5}, {3, 2, 7, 4, 2, 7}, {4, 4, 2, 5, 3, 6}, {4, 4, 4, 3, 7, 7}, {3, 5, 3, 5, 5, 6}, {7, 2, 4, 7, 4, 6}, {4, 2, 5, 4, 3, 7}, {2, 7, 6, 2, 6, 6}, {3, 3, 5, 7, 5, 4}, {5, 5, 7, 4, 6, 3}, {7, 7, 5, 5, 5, 6}, {5, 5, 3, 5, 4, 6}, {7, 5, 3, 4, 4, 6}, {6, 6, 4, 5, 4, 6}, {6, 7, 4, 4, 3, 6}, {5, 6, 4, 5, 5, 6}, {4, 5, 3, 5, 5, 6}, {4, 5, 4, 5, 5, 6}, {2, 7, 7, 7, 5, 7}, {7, 4, 7, 4, 4, 6}, {5, 6, 6, 4, 6, 4}, {4, 7, 3, 3, 4, 6}, {7, 7, 7, 4, 4, 4}, {5, 7, 4, 2, 3, 7}, {6, 2, 6, 5, 4, 6}, {6, 2, 5, 7, 5, 4}, {6, 5, 4, 6, 3, 7}, {7, 6, 3, 2, 5, 7}, {5, 5, 5, 5, 7, 3}, {3, 7, 4, 7, 6, 6}, {3, 6, 3, 5, 6, 5}, {3, 6, 3, 6, 6, 5}, {3, 6, 3, 6, 6, 6}, {3, 6, 4, 7, 4, 6}, {3, 6, 3, 7, 6, 6}, {3, 6, 4, 7, 5, 6}, {2, 7, 6, 6, 6, 7}, {6, 6, 7, 4, 6, 3}, {2, 4, 7, 5, 6, 2}, {2, 4, 7, 5, 6, 3}, {2, 4, 7, 5, 7, 3}, {2, 4, 7, 6, 7, 3}, {2, 5, 7, 6, 7, 3}, {6, 6, 2, 7, 7, 5}, {7, 2, 7, 7, 3, 4}, {6, 4, 5, 2, 5, 7}, {7, 3, 3, 3, 4, 7}, {7, 5, 3, 5, 7, 2}, {5, 5, 5, 6, 4, 5}, {2, 6, 7, 7, 7, 4}, {7, 6, 2, 6, 3, 6}, {3, 7, 6, 2, 3, 5}, {4, 5, 3, 6, 5, 3}, {7, 6, 4, 6, 3, 7}, {3, 4, 7, 4, 5, 6}, {4, 7, 3, 7, 4, 6}, {3, 6, 7, 4, 7, 2}, {6, 3, 7, 3, 5, 7}, {3, 6, 5, 3, 5, 7}, {6, 4, 3, 2, 7, 6}, {7, 2, 7, 6, 5, 4}, {7, 5, 7, 4, 5, 2}, {3, 5, 2, 4, 7, 7}, {3, 6, 6, 5, 4, 3}, {7, 7, 4, 4, 6, 3}, {4, 6, 3, 5, 5, 7}, {6, 2, 3, 4, 4, 7}, {5, 6, 3, 6, 7, 7}, {7, 2, 7, 7, 4, 2}, {5, 7, 2, 6, 5, 7}, {2, 6, 6, 4, 7, 6}, {7, 3, 6, 5, 7, 2}, {7, 2, 7, 6, 5, 5}, {5, 4, 6, 6, 2, 3}, {5, 7, 3, 6, 3, 2}, {3, 4, 5, 7, 3, 4}, {6, 4, 3, 6, 7, 6}, {3, 6, 7, 2, 6, 7}, {3, 6, 5, 6, 3, 3}, {7, 6, 7, 5, 2, 4}, {5, 5, 7, 7, 3, 2}, {6, 7, 5, 7, 4, 3}, {5, 7, 4, 6, 3, 2}, {4, 6, 5, 6, 3, 3}, {5, 7, 4, 6, 3, 3}, {5, 6, 5, 6, 3, 3}, {5, 6, 5, 6, 4, 3}, {6, 7, 5, 3, 6, 3}, {6, 3, 6, 7, 3, 4}, {6, 3, 4, 3, 7, 5}, {7, 5, 7, 5, 5, 3}, {7, 5, 7, 4, 5, 3}, {3, 2, 6, 5, 7, 4}, {6, 5, 3, 7, 3, 5}, {5, 7, 3, 7, 3, 6}, {7, 4, 7, 5, 6, 2}, {7, 4, 7, 7, 2, 4}, {4, 7, 2, 7, 5, 4}, {3, 6, 4, 5, 5, 4}, {4, 4, 7, 2, 7, 5}, {3, 4, 6, 7, 5, 2}, {6, 6, 3, 7, 6, 3}, {4, 2, 6, 6, 5, 7}, {6, 4, 5, 6, 4, 2}, {6, 2, 7, 7, 6, 7}, {4, 2, 4, 6, 7, 3}, {7, 2, 5, 5, 7, 5}, {6, 4, 7, 2, 7, 5}, {7, 5, 4, 2, 6, 5}, {2, 2, 2, 7, 7, 6}, {4, 4, 4, 7, 7, 3}, {4, 3, 4, 6, 7, 3}, {5, 7, 2, 7, 6, 5}, {7, 5, 7, 4, 7, 2}, {7, 6, 3, 7, 7, 2}, {7, 5, 7, 3, 7, 7}, {3, 3, 7, 6, 5, 4}, {6, 4, 4, 5, 6, 6}, {4, 4, 6, 5, 4, 5}, {4, 7, 4, 6, 4, 4}, {3, 4, 6, 7, 3, 6}, {6, 7, 2, 6, 3, 4}, {6, 7, 5, 3, 4, 6}, {4, 5, 5, 5, 3, 5}, {4, 5, 5, 5, 4, 5}, {4, 7, 5, 6, 5, 2}, {7, 5, 3, 7, 7, 4}, {7, 6, 5, 3, 7, 6}, {7, 5, 4, 4, 6, 5}, {5, 7, 4, 5, 4, 7}, {2, 7, 4, 7, 6, 4}, {7, 3, 6, 5, 5, 5}, {6, 4, 4, 7, 3, 5}, {6, 7, 4, 7, 2, 6}, {6, 2, 6, 6, 7, 6}, {4, 3, 7, 4, 5, 4}, {3, 7, 7, 6, 3, 7}, {3, 4, 6, 5, 5, 3}, {5, 6, 7, 2, 5, 7}, {4, 5, 5, 4, 6, 7}, {4, 4, 4, 4, 6, 7}, {4, 4, 5, 4, 6, 7}, {6, 6, 5, 3, 7, 7}, {7, 6, 6, 5, 3, 3}, {3, 4, 7, 4, 6, 5}, {7, 6, 4, 5, 7, 2}, {7, 7, 7, 7, 3, 5}, {5, 3, 7, 6, 4, 6}, {5, 7, 3, 6, 4, 7}, {4, 7, 5, 2, 5, 4}, {7, 7, 5, 3, 4, 6}, {7, 7, 6, 3, 2, 6}, {7, 7, 5, 3, 6, 3}, {6, 4, 4, 5, 4, 7}, {5, 5, 5, 5, 6, 2}, {3, 4, 5, 7, 7, 3}, {6, 7, 5, 4, 5, 6}, {7, 5, 7, 4, 7, 3}, {6, 3, 2, 7, 3, 6}, {7, 3, 6, 5, 4, 6}, {5, 4, 4, 5, 5, 3}, {5, 4, 4, 5, 5, 4}, {5, 6, 7, 6, 2, 7}, {6, 6, 2, 6, 6, 6}, {4, 7, 5, 4, 6, 4}, {7, 6, 3, 6, 4, 5}, {4, 7, 7, 4, 5, 7}, {2, 6, 7, 3, 6, 5}, {4, 7, 7, 2, 7, 4}, {5, 6, 2, 7, 4, 6}, {6, 4, 3, 7, 7, 7}, {4, 4, 4, 7, 3, 7}, {6, 7, 6, 4, 2, 6}, {2, 6, 6, 7, 6, 7}, {4, 6, 4, 6, 4, 5}, {7, 2, 6, 4, 6, 6}, {4, 6, 6, 3, 6, 5}, {3, 7, 7, 2, 7, 7}, {7, 4, 6, 5, 4, 4}, {6, 7, 3, 7, 5, 2}, {5, 2, 7, 6, 7, 6}, {7, 7, 6, 2, 3, 6}, {3, 5, 7, 7, 2, 6}, {3, 3, 7, 6, 7, 2}, {7, 5, 7, 5, 3, 7}, {5, 6, 5, 6, 3, 7}, {6, 5, 4, 7, 4, 6}, {4, 7, 5, 6, 3, 7}, {7, 7, 3, 5, 7, 4}, {6, 7, 6, 5, 2, 7}, {4, 7, 6, 4, 7, 3}, {7, 3, 5, 5, 7, 6}, {7, 2, 5, 5, 7, 6}, {4, 3, 5, 7, 4, 2}, {6, 6, 2, 6, 5, 7}, {7, 4, 2, 7, 3, 6}, {6, 7, 7, 2, 4, 5}, {5, 3, 4, 5, 6, 4}, {7, 7, 2, 6, 2, 7}, {3, 7, 3, 7, 3, 7}, {3, 6, 4, 5, 5, 3}, {7, 5, 6, 4, 5, 4}, {6, 3, 5, 5, 5, 5}, {4, 4, 5, 4, 6, 5}, {4, 6, 6, 4, 6, 4}, {6, 3, 7, 6, 4, 2}, {6, 2, 7, 7, 7, 3}, {5, 6, 4, 7, 3, 6}, {2, 4, 7, 7, 6, 7}, {4, 6, 4, 5, 7, 3}, {3, 6, 4, 5, 6, 3}, {5, 7, 3, 4, 6, 5}, {3, 4, 5, 6, 5, 5}, {3, 7, 3, 7, 5, 4}, {4, 7, 4, 7, 2, 7}, {7, 7, 2, 3, 3, 7}, {6, 7, 4, 3, 6, 6}, {7, 6, 7, 4, 7, 2}, {3, 3, 6, 5, 5, 4}, {6, 7, 3, 4, 6, 5}, {7, 5, 2, 4, 7, 7}, {6, 7, 6, 4, 3, 7}, {6, 6, 7, 2, 6, 4}, {6, 7, 2, 4, 4, 7}, {3, 3, 4, 6, 5, 2}, {7, 2, 7, 5, 6, 3}, {4, 5, 3, 7, 7, 5}, {5, 6, 4, 4, 6, 5}, {3, 7, 2, 7, 7, 3}, {5, 3, 6, 5, 6, 3}, {2, 7, 3, 7, 7, 3}, {5, 2, 4, 7, 7, 6}, {3, 7, 4, 6, 4, 7}, {4, 7, 4, 5, 7, 2}, {5, 5, 7, 4, 5, 5}, {2, 6, 2, 7, 7, 6}, {2, 6, 5, 6, 7, 7}, {3, 2, 6, 7, 7, 6}, {3, 4, 5, 5, 5, 6}, {5, 6, 3, 7, 5, 5}, {7, 4, 3, 4, 6, 6}, {6, 5, 7, 4, 6, 4}, {7, 2, 7, 4, 6, 6}, {7, 5, 4, 7, 3, 7}, {7, 6, 3, 5, 5, 6}, {4, 4, 7, 5, 6, 2}, {3, 4, 6, 7, 4, 5}, {6, 3, 7, 6, 4, 4}, {6, 3, 7, 6, 4, 3}, {7, 7, 4, 6, 3, 7}, {3, 5, 5, 6, 4, 6}, {2, 6, 5, 7, 7, 7}, {3, 6, 5, 7, 4, 3}, {5, 7, 3, 6, 5, 4}, {7, 4, 5, 5, 4, 4}, {7, 7, 6, 4, 6, 2}, {7, 2, 6, 7, 7, 3}, {4, 3, 7, 5, 4, 3}, {4, 3, 7, 5, 4, 4}, {4, 3, 7, 5, 4, 5}, {4, 3, 7, 5, 4, 6}, {4, 3, 7, 6, 4, 6}, {6, 6, 6, 3, 7, 7}, {7, 7, 4, 4, 6, 6}, {7, 6, 5, 4, 4, 7}, {4, 5, 4, 4, 7, 6}, {4, 4, 6, 6, 3, 7}, {6, 6, 2, 5, 7, 6}, {7, 6, 6, 3, 7, 3}, {4, 6, 6, 7, 2, 6}, {4, 7, 3, 3, 6, 7}, {6, 7, 4, 5, 5, 2}, {2, 6, 7, 5, 7, 7}, {6, 7, 2, 7, 7, 5}, {3, 4, 6, 4, 7, 5}, {6, 6, 5, 5, 4, 3}, {6, 7, 7, 3, 7, 2}, {6, 7, 3, 3, 5, 7}, {3, 6, 4, 7, 3, 7}, {7, 2, 6, 6, 7, 4}, {7, 7, 2, 5, 5, 5}, {4, 5, 6, 7, 2, 7}, {6, 5, 4, 4, 7, 6}, {6, 6, 3, 6, 5, 5}, {7, 7, 2, 7, 4, 4}, {6, 7, 2, 6, 5, 6}, {3, 5, 5, 5, 7, 2}, {6, 5, 5, 7, 3, 6}, {3, 3, 5, 5, 6, 4}, {2, 7, 7, 4, 7, 2}, {3, 6, 6, 7, 4, 2}, {5, 7, 7, 2, 3, 6}, {7, 2, 6, 6, 2, 7}, {6, 3, 4, 5, 5, 4}, {6, 3, 4, 5, 5, 5}, {2, 6, 7, 6, 6, 7}, {6, 7, 7, 5, 2, 6}, {5, 7, 5, 2, 7, 4}, {5, 7, 4, 7, 4, 6}, {6, 6, 3, 4, 7, 7}, {3, 7, 6, 4, 6, 5}, {6, 5, 3, 5, 7, 7}, {7, 6, 7, 7, 3, 7}, {5, 7, 3, 7, 7, 3}, {6, 6, 4, 6, 4, 2}, {7, 7, 4, 5, 5, 2}, {6, 7, 4, 7, 3, 6}, {6, 7, 6, 6, 3, 6}, {6, 7, 2, 4, 7, 6}, {7, 7, 5, 2, 2, 7}, {7, 5, 7, 4, 4, 5}, {7, 5, 3, 4, 5, 7}, {6, 4, 7, 4, 6, 4}, {3, 7, 3, 6, 5, 7}, {6, 3, 5, 5, 5, 4}, {7, 6, 7, 3, 6, 6}, {3, 3, 7, 5, 6, 2}, {3, 4, 7, 5, 6, 2}, {7, 4, 2, 5, 6, 5}, {4, 4, 7, 5, 4, 4}, {7, 7, 7, 3, 4, 6}, {6, 6, 3, 7, 4, 5}, {7, 5, 6, 4, 5, 7}, {7, 6, 3, 2, 6, 7}, {5, 6, 5, 5, 4, 4}, {5, 7, 4, 3, 7, 7}, {7, 7, 7, 7, 3, 6}, {2, 7, 5, 4, 7, 5}, {7, 7, 4, 5, 4, 5}, {4, 3, 5, 4, 6, 6}, {5, 6, 7, 3, 6, 7}, {2, 7, 7, 6, 6, 7}, {2, 2, 6, 6, 7, 7}, {4, 5, 7, 4, 6, 4}, {7, 6, 2, 7, 7, 5}, {7, 2, 7, 5, 7, 6}, {7, 5, 2, 5, 4, 7}, {4, 7, 2, 7, 3, 7}, {6, 7, 7, 4, 4, 5}, {6, 7, 4, 6, 4, 3}, {7, 4, 2, 7, 4, 6}, {7, 4, 3, 7, 6, 6}, {4, 3, 7, 5, 6, 3}, {3, 3, 7, 5, 6, 3}, {2, 2, 7, 7, 7, 7}, {6, 2, 7, 7, 7, 6}, {7, 7, 3, 7, 5, 5}, {7, 3, 6, 6, 4, 3}, {7, 5, 4, 5, 6, 3}, {6, 4, 4, 5, 5, 3}, {6, 4, 4, 5, 6, 3}, {4, 7, 6, 5, 6, 2}, {7, 7, 3, 7, 6, 2}, {6, 3, 5, 4, 7, 5}, {6, 3, 7, 5, 5, 3}, {5, 5, 5, 5, 4, 4}, {7, 5, 2, 7, 5, 6}, {2, 7, 3, 7, 7, 6}, {4, 7, 2, 5, 7, 6}, {7, 7, 4, 3, 4, 7}, {3, 3, 6, 4, 6, 4}, {4, 3, 6, 4, 6, 4}, {5, 3, 6, 4, 6, 4}, {5, 3, 7, 4, 6, 4}, {5, 4, 7, 4, 6, 4}, {5, 4, 5, 5, 5, 3}, {6, 3, 5, 4, 7, 7}, {7, 7, 7, 4, 5, 7}, {2, 7, 7, 3, 7, 5}, {6, 7, 2, 5, 4, 7}, {7, 5, 3, 7, 5, 6}, {7, 7, 2, 6, 6, 3}, {7, 7, 3, 7, 7, 4}, {7, 7, 2, 7, 5, 7}, {6, 7, 7, 3, 7, 7}, {4, 4, 5, 5, 6, 3}, {7, 5, 7, 5, 5, 2}, {5, 4, 7, 5, 4, 2}, {6, 4, 7, 5, 4, 2}, {6, 4, 7, 5, 5, 2}, {7, 7, 5, 6, 3, 7}, {5, 6, 4, 4, 7, 6}, {7, 6, 4, 6, 4, 2}, {3, 6, 5, 5, 4, 7}, {4, 4, 4, 5, 5, 7}, {3, 4, 4, 5, 5, 7}, {4, 4, 5, 5, 7, 2}, {7, 7, 3, 6, 4, 7}, {6, 7, 7, 4, 6, 2}, {3, 3, 6, 6, 4, 7}, {7, 7, 4, 6, 4, 3}, {2, 7, 2, 6, 7, 7}, {4, 7, 6, 5, 3, 7}, {6, 5, 2, 7, 6, 7}, {5, 2, 4, 7, 7, 7}, {2, 7, 7, 5, 7, 5}, {6, 7, 7, 5, 4, 2}, {6, 7, 6, 4, 7, 3}, {6, 3, 5, 5, 4, 7}, {3, 6, 6, 4, 6, 5}, {5, 6, 5, 4, 6, 4}, {7, 2, 7, 7, 5, 3}, {7, 4, 3, 4, 7, 5}, {3, 4, 4, 5, 6, 3}, {5, 7, 3, 5, 7, 5}, {5, 4, 5, 5, 4, 3}, {5, 5, 5, 5, 4, 3}, {6, 4, 5, 5, 4, 3}, {6, 4, 5, 5, 4, 4}, {7, 2, 4, 7, 7, 7}, {3, 5, 3, 7, 7, 6}, {3, 5, 7, 5, 4, 7}, {7, 4, 4, 7, 4, 2}, {4, 5, 3, 7, 6, 7}, {4, 7, 3, 7, 7, 5}, {5, 3, 7, 5, 7, 2}, {3, 3, 7, 6, 4, 3}, {2, 5, 7, 7, 6, 7}, {7, 5, 4, 7, 4, 2}, {7, 3, 7, 5, 4, 3}, {7, 5, 2, 5, 7, 7}, {7, 3, 6, 4, 7, 6}, {5, 7, 2, 7, 7, 7}, {3, 7, 5, 4, 6, 4}, {5, 7, 3, 5, 7, 6}, {7, 2, 5, 7, 4, 7}, {5, 3, 7, 5, 4, 7}, {2, 5, 7, 6, 7, 7}, {3, 5, 7, 5, 4, 6}, {7, 6, 7, 4, 7, 3}, {7, 6, 3, 6, 6, 5}, {3, 5, 5, 5, 4, 6}, {5, 7, 3, 6, 5, 6}, {7, 7, 4, 6, 4, 4}, {3, 4, 5, 6, 4, 2}, {7, 4, 5, 5, 5, 2}, {6, 2, 7, 6, 7, 7}, {4, 4, 4, 7, 4, 7}, {7, 2, 7, 7, 6, 4}, {6, 7, 2, 5, 7, 7}, {2, 7, 7, 7, 7, 2}, {2, 7, 7, 7, 6, 5}, {6, 4, 4, 6, 4, 7}, {7, 2, 5, 7, 6, 7}, {4, 7, 6, 6, 3, 7}, {3, 7, 4, 5, 5, 3}, {7, 4, 2, 7, 7, 7}, {7, 6, 2, 5, 6, 7}, {7, 2, 7, 7, 7, 7}, {6, 5, 2, 7, 7, 6}, {6, 7, 6, 5, 5, 2}, {5, 3, 5, 5, 5, 7}, {4, 3, 4, 5, 5, 7}, {4, 3, 5, 5, 5, 7}, {5, 3, 4, 5, 6, 3}, {7, 5, 2, 7, 6, 7}, {7, 7, 6, 3, 6, 4}, {7, 4, 4, 5, 5, 3}, {6, 5, 3, 7, 7, 6}, {6, 3, 5, 6, 4, 3}, {6, 3, 6, 6, 4, 3}, {6, 7, 3, 7, 6, 7}, {6, 4, 6, 5, 4, 3}, {4, 7, 4, 6, 4, 7}, {6, 6, 4, 6, 4, 5}, {7, 4, 5, 5, 4, 2}, {3, 3, 6, 6, 4, 6}, {7, 5, 4, 6, 4, 6}, {6, 5, 4, 4, 6, 7}, {7, 4, 4, 4, 6, 7}, {7, 4, 5, 4, 6, 4}, {7, 6, 3, 5, 6, 7}, {3, 5, 5, 4, 7, 7}, {7, 3, 5, 4, 6, 7}, {3, 6, 6, 5, 5, 2}, {3, 5, 6, 4, 6, 4}, {2, 7, 7, 4, 7, 6}, {7, 3, 3, 7, 5, 7}, {6, 6, 4, 4, 7, 7}, {7, 7, 6, 4, 7, 2}, {2, 4, 6, 7, 7, 5}, {7, 7, 4, 5, 6, 2}, {7, 7, 7, 2, 6, 3}, {7, 7, 4, 4, 7, 4}, {4, 7, 4, 7, 3, 7}, {7, 4, 4, 7, 4, 4}, {7, 7, 4, 7, 4, 2}, {7, 4, 3, 6, 7, 7}, {6, 3, 7, 4, 7, 6}, {3, 7, 5, 5, 4, 5}, {7, 5, 4, 5, 5, 3}, {7, 6, 2, 4, 7, 7}, {3, 3, 5, 7, 4, 4}, {3, 7, 3, 5, 7, 7}, {7, 7, 3, 6, 5, 7}, {2, 7, 7, 7, 7, 6}, {7, 7, 6, 2, 7, 5}, {5, 3, 4, 5, 5, 6}, {7, 7, 2, 7, 7, 7}, {7, 7, 6, 3, 7, 3}, {6, 7, 6, 6, 3, 7}, {7, 7, 3, 7, 5, 6}, {3, 7, 7, 4, 7, 2}, {3, 4, 5, 5, 6, 2}, {5, 4, 4, 7, 4, 7}, {5, 6, 5, 5, 5, 2}, {3, 7, 5, 5, 4, 3}, {7, 5, 3, 7, 6, 5}, {7, 7, 7, 2, 7, 4}, {4, 4, 4, 5, 5, 6}, {7, 7, 7, 3, 6, 6}, {7, 6, 3, 7, 7, 6}, {3, 3, 5, 6, 4, 4}, {7, 5, 5, 5, 4, 2}, {7, 4, 3, 7, 6, 7}, {7, 3, 6, 5, 5, 3}, {4, 4, 7, 5, 4, 3}, {4, 7, 4, 4, 7, 5}, {4, 5, 5, 5, 5, 2}, {7, 7, 5, 4, 6, 3}, {5, 4, 5, 5, 4, 6}, {3, 5, 5, 4, 6, 4}, {7, 3, 5, 4, 7, 7}, {2, 7, 6, 4, 7, 7}, {5, 4, 6, 5, 5, 2}, {3, 3, 7, 7, 4, 2}, {7, 6, 7, 2, 7, 5}, {4, 3, 4, 5, 6, 6}, {2, 6, 7, 6, 7, 7}, {3, 3, 4, 5, 6, 7}, {2, 7, 4, 6, 7, 7}, {4, 4, 5, 5, 5, 4}, {6, 7, 3, 4, 7, 6}, {7, 3, 7, 4, 7, 4}, {6, 7, 3, 4, 7, 7}, {7, 7, 4, 2, 7, 6}, {7, 3, 7, 6, 4, 2}, {6, 3, 6, 4, 7, 7}, {3, 3, 4, 5, 6, 4}, {6, 7, 3, 6, 7, 5}, {5, 6, 3, 7, 7, 7}, {3, 5, 5, 5, 5, 2}, {3, 3, 6, 5, 6, 3}, {4, 7, 4, 4, 7, 7}, {3, 5, 4, 5, 5, 5}, {7, 3, 7, 5, 5, 3}, {7, 6, 4, 2, 6, 7}, {6, 7, 4, 5, 5, 3}, {7, 6, 3, 3, 7, 7}, {3, 7, 7, 7, 2, 7}, {3, 4, 6, 5, 4, 4}, {3, 4, 5, 4, 6, 5}, {7, 7, 7, 5, 2, 7}, {4, 7, 7, 7, 2, 7}, {3, 5, 5, 5, 4, 5}, {7, 7, 4, 7, 4, 4}, {4, 7, 4, 7, 4, 7}, {7, 5, 3, 6, 7, 7}, {3, 4, 4, 5, 5, 4}, {7, 7, 3, 3, 7, 6}, {7, 6, 3, 6, 6, 7}, {7, 3, 7, 4, 7, 6}, {4, 3, 7, 4, 6, 7}, {6, 7, 5, 7, 2, 7}, {3, 3, 6, 7, 4, 2}, {4, 3, 5, 5, 7, 3}, {6, 5, 4, 6, 4, 7}, {3, 7, 5, 7, 3, 7}, {6, 3, 7, 5, 6, 2}, {7, 3, 7, 4, 6, 7}, {2, 6, 7, 7, 7, 7}, {7, 7, 3, 7, 7, 6}, {7, 7, 4, 7, 3, 7}, {7, 7, 3, 7, 6, 7}, {4, 3, 7, 4, 7, 7}, {3, 3, 5, 5, 5, 4}, {7, 7, 7, 2, 7, 7}, {6, 7, 5, 7, 3, 7}, {3, 5, 6, 5, 4, 3}, {7, 7, 6, 3, 6, 7}, {7, 3, 7, 5, 6, 2}, {7, 5, 4, 5, 4, 7}, {3, 4, 5, 5, 4, 7}, {7, 3, 5, 5, 4, 7}, {6, 4, 6, 4, 6, 4}, {7, 7, 6, 3, 7, 4}, {6, 7, 4, 4, 7, 5}, {6, 7, 7, 5, 3, 7}, {7, 6, 4, 5, 4, 6}, {6, 7, 7, 6, 2, 7}, {6, 3, 4, 5, 5, 6}, {7, 7, 4, 4, 7, 5}, {2, 7, 4, 7, 6, 7}, {7, 3, 7, 5, 7, 2}, {5, 7, 3, 6, 7, 7}, {7, 6, 4, 4, 6, 7}, {7, 3, 5, 6, 4, 3}, {3, 7, 3, 7, 7, 7}, {7, 3, 4, 7, 4, 6}, {6, 6, 4, 7, 4, 5}, {7, 5, 3, 7, 7, 7}, {7, 3, 6, 5, 4, 7}, {7, 3, 7, 5, 4, 6}, {7, 7, 7, 3, 7, 6}, {7, 7, 4, 4, 7, 6}, {7, 6, 7, 5, 4, 2}, {7, 5, 4, 7, 4, 6}, {3, 3, 5, 5, 7, 3}, {5, 5, 4, 7, 4, 7}, {5, 3, 7, 4, 7, 7}, {6, 4, 4, 7, 4, 7}, {6, 7, 3, 7, 7, 7}, {5, 3, 4, 5, 5, 7}, {7, 7, 3, 3, 7, 7}, {4, 4, 6, 5, 5, 2}, {4, 7, 7, 4, 7, 3}, {4, 3, 5, 5, 6, 3}, {7, 7, 7, 4, 7, 2}, {5, 7, 7, 7, 3, 7}, {7, 3, 4, 7, 4, 7}, {7, 7, 4, 4, 7, 7}, {4, 4, 5, 5, 4, 6}, {7, 6, 4, 7, 4, 7}, {7, 7, 7, 3, 7, 7}, {6, 3, 7, 4, 7, 7}, {7, 3, 6, 4, 7, 7}, {4, 6, 5, 5, 4, 3}, {3, 4, 5, 5, 4, 4}, {7, 7, 5, 5, 4, 2}, {7, 7, 4, 6, 4, 7}, {2, 7, 7, 4, 7, 7}, {3, 4, 6, 4, 6, 4}, {7, 6, 4, 5, 5, 3}, {7, 7, 6, 7, 3, 7}, {4, 3, 4, 5, 6, 3}, {6, 7, 7, 4, 7, 3}, {7, 7, 4, 5, 7, 2}, {6, 4, 5, 5, 5, 2}, {3, 6, 5, 5, 4, 3}, {4, 4, 5, 5, 5, 3}, {7, 4, 5, 5, 4, 3}, {3, 3, 5, 7, 4, 3}, {6, 4, 5, 4, 7, 4}, {7, 7, 7, 7, 3, 7}, {7, 7, 7, 5, 4, 2}, {4, 3, 6, 6, 4, 3}, {3, 4, 7, 5, 5, 2}, {4, 5, 5, 5, 4, 3}, {4, 4, 5, 4, 7, 4}, {2, 7, 6, 6, 7, 7}, {7, 7, 7, 4, 7, 3}, {7, 7, 3, 6, 7, 7}, {6, 4, 5, 4, 6, 4}, {5, 7, 4, 7, 4, 7}, {4, 4, 6, 5, 4, 3}, {6, 7, 4, 7, 4, 7}, {7, 3, 4, 5, 5, 6}, {7, 7, 4, 7, 4, 7}, {7, 7, 4, 5, 5, 3}, {3, 4, 6, 5, 5, 2}, {2, 7, 7, 5, 7, 7}, {3, 4, 6, 5, 4, 3}, {3, 4, 5, 5, 5, 2}, {3, 3, 4, 5, 7, 3}, {7, 6, 3, 7, 7, 7}, {3, 5, 5, 5, 4, 3}, {2, 7, 7, 6, 7, 7}, {2, 7, 6, 7, 6, 7}, {7, 7, 3, 7, 7, 7}, {6, 3, 4, 5, 5, 7}, {5, 4, 5, 4, 6, 4}, {7, 3, 7, 5, 4, 7}, {7, 3, 7, 4, 7, 7}, {4, 4, 5, 4, 6, 4}, {3, 4, 5, 4, 7, 4}, {3, 3, 6, 6, 4, 3}, {2, 7, 7, 7, 7, 7}, {7, 3, 4, 5, 5, 7}, {3, 3, 5, 7, 4, 2}, {3, 3, 5, 5, 6, 3}, {3, 3, 4, 5, 6, 3}, {3, 4, 5, 4, 6, 4}}
                       unresolvedCount => 0

i26 : #{{3, 3, 4, 6, 5, 2}, {3, 4, 5, 6, 4, 2}, {3, 3, 5, 6, 4, 4}, {3, 4, 4, 5, 5, 4}, {3, 3, 5, 5, 5, 4}, {3, 4, 5, 5, 4, 4}, {3, 4, 6, 5, 4, 3}, {3, 4, 5, 5, 5, 2}, {3, 5, 5, 5, 4, 3}, {3, 3, 6, 6, 4, 3}, {3, 3, 5, 7, 4, 2}, {3, 3, 4, 5, 6, 3}, {3, 4, 5, 4, 6, 4}}

restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV4.m2"
state0 = makeFrontierState(3,2,1,2,4,2)
state1 = initializeFrontierWithArchitectures(state0, {{2,2},{3,3}})
state2 = runGuidedFrontierSearchResume(state1, 10, 12345)
printResult last first pairs state2#"DimensionCache"

lowerBound=2
upperBound =4
pnnDepth=4
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)
seedTuples = transpose for i to pnnDepth-2 list {}

state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 10, 12345)
seedTuples = transpose for i to pnnDepth-2 list {}

unresolvedUpperShellTuplesInState(state2)
orthantCellsFromUpperShellInState(state2);
printOrthantCellsFromUpperShell(state2)


lowerBound=2
upperBound =5
pnnDepth=4
seedTuples = transpose for i to pnnDepth-2 list {}
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)
state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 10, 12345)

anchor = {3,5,5};
inf = blockwiseRecursiveUpperBoundFromAnchor(state2, anchor)
printBlockwiseRecursiveCertificate(inf)



restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV4.m2"
state0 = makeFrontierState(3,2,1,2,4,2)
state1 = initializeFrontierWithArchitectures(state0, {{2,2},{3,3}})
state2 = runGuidedFrontierSearchResume(state1, 10, 12345)
printResult last first pairs state2#"DimensionCache"

lowerBound=2
upperBound =10
pnnDepth=6
seedTuples = transpose for i to pnnDepth-2 list {lowerBound,upperBound}
seedTuples = transpose for i to pnnDepth-2 list {}
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)
state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 1000, 12345)

upperBound =10
state2 = runGuidedFrontierSearchResume(state2, 1000, 12345)


peek state2
cert = certifyAllPatternBoundaryRegions(state2);
printPatternBoundaryRegionCertificationSummary(cert);


inf = (cert#"certifiedList")#0;
printBlockwiseRecursiveCertificate(inf);
infor#"freePositions"
infor#"boundary"
infor#"blockInfos"
infor#"upperBound"
infor#"expectedDimAtMinimalAnchor"
upperBound < expectedDimAtMinimalAnchor


unresolvedUpperShellTuplesInState(state2)
cert = certifyAllUpperShellOrthantCellsByBlocks(state2);
printUpperShellBlockCertificationSummary(cert);


printBlockwiseRecursiveCertificate--- useless


info1 = blockwiseRecursiveUpperBoundFromAnchor(state2, {3,5,5});
printBlockwiseRecursiveCertificate(info1);


cert = certifyAllPatternBoundaryRegions(state2)
netList oo
peek cert

info2 = (cert#"certifiedList")#0;
printPatternRegionCertificate(info2);

for infor in cert list inform#

 cert#"uncertifiedList"
computeDimension({2,2,2,2,2,2},2)


---
restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV4.m2"

lowerBound=2
upperBound =10
pnnDepth=6
seedTuples = transpose for i to pnnDepth-2 list {lowerBound,upperBound}
seedTuples = transpose for i to pnnDepth-2 list {}
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)
state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 100, 12345)

shellAnchor = {2,2,2,2,10}

infor = testCanonicalCutsFromUpperShellAnchor(state2, shellAnchor);
printRegionBlockCertificate(infor);
keys state2


fixedPositionsFromFreePositions(5, {4})
minimalAnchorFromUpperShellAnchor({2,2,2,2,10}, 2, 10)

infor = regionBlockUpperBoundFromCuts(state2, {2,2,2,2,10}, {4}, {0,4,6});
printRegionBlockCertificate(infor);


restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV4.m2"
lowerBound=2
upperBound =4
pnnDepth=6
seedTuples = transpose for i to pnnDepth-2 list {lowerBound,upperBound}
seedTuples = transpose for i to pnnDepth-2 list {}
state0 = makeFrontierState(pnnDepth, 2, 1, lowerBound, upperBound, 2)
state1 = initializeFrontierWithArchitectures(state0, seedTuples)
state2 = runGuidedFrontierSearchResume(state1, 1000, 12345)

shellAnchors = unresolvedUpperShellTuplesInState(state2);
#shellAnchors
anchorInfos = apply(shellAnchors, a -> testCanonicalCutsFromUpperShellAnchor(state2, a));
certified = select(anchorInfos, info -> info#"certifiedNonfillingRegion");
uncertified = select(anchorInfos, info -> not info#"certifiedNonfillingRegion");
#certified
#uncertified
peek state2#"ExactBlockCache"
select(pairs state2, x->(last x)#"defect">0)

(select(pairs state2#"ExactBlockCache", x->(last x)#"defect">0))/first 

stateX = makeFrontierState(6, 2, 1, 2, 10, 2)

class stateX
peek stateX
state0#"ExactBlockCache"
class(state0#"ExactBlockCache")
---

o26 = {{2,2,2,2,1}}
