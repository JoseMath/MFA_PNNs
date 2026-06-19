------------------------------------------------------------
-- MinimalFillingArchitecturesV3.m2
-- Unified package with:
--   - dimension computation
--   - frontier search
--   - guided frontier search
--   - resume capability
--   - midpoint scoring heuristic
------------------------------------------------------------

newPackage(
    "MinimalFillingArchitecturesV3",
    Version => "0.2",
    Date => "June 2026"
)

export {
    "computeDimension",
    "architectureFromHidden",
    "randomHiddenTuple",

    "frontierSearchHidden",
    "frontierSearchHiddenGuided",

    "runFrontierSearchResume",
    "runGuidedFrontierSearchResume",
    "makeFrontierState",

    "midpointScore"
}

------------------------------------------------------------
-- Basic helpers
------------------------------------------------------------

architectureFromHidden = (d0, dL, hidden) -> join({d0}, join(hidden, {dL}));

randomHiddenTuple = (k, m, n) -> apply(k, i -> m + random(n - m + 1));

tupleEQ = (a,b) -> all(#a, i -> a#i == b#i);
tupleLEQ = (a,b) -> all(#a, i -> a#i <= b#i);
tupleGEQ = (a,b) -> tupleLEQ(b,a);
tupleLT = (a,b) -> tupleLEQ(a,b) and not tupleEQ(a,b);
tupleGT = (a,b) -> tupleGEQ(a,b) and not tupleEQ(a,b);

------------------------------------------------------------
-- Filling classification
------------------------------------------------------------

resultSizes = res -> res#0;
resultDimension = res -> res#4;
resultExpectedDim = res -> res#3;
resultDefect = res -> res#5;

isFillingResult = res -> resultDefect(res) == 0;

------------------------------------------------------------
-- Dummy dimension (replace with your full version)
------------------------------------------------------------

computeDimension = (arch, r) -> (
    -- placeholder for your real dimension code
    expected := 10 + sum arch;
    actual := expected - random(2);
    {
        arch,
        r,
        0,
        expected,
        actual,
        expected - actual
    }
);

------------------------------------------------------------
-- Frontier logic
------------------------------------------------------------

impliedFilling = (a, Fmin) -> any(Fmin, f -> tupleGEQ(a,f));
impliedNonFilling = (a, Nmax) -> any(Nmax, q -> tupleLEQ(a,q));

updateMinimalAntichain = (Fmin, a) -> (
    kept := select(Fmin, f -> not tupleGT(f,a));
    join(kept,{a})
);

updateMaximalAntichain = (Nmax, a) -> (
    kept := select(Nmax, q -> not tupleLT(q,a));
    join(kept,{a})
);

------------------------------------------------------------
-- ✅ Midpoint score (NEW)
------------------------------------------------------------

midpointScore = pair -> (
    q := pair#0;
    f := pair#1;

    gaps := apply(#q, i -> f#i - q#i);

    vol := product apply(#q, i -> gaps#i + 1);
    minGap := min gaps;
    sumGap := sum gaps;

    vol + 10 * minGap + sumGap
);

------------------------------------------------------------
-- Guided search helpers
------------------------------------------------------------

comparablePairs = (Nmax, Fmin) -> flatten apply(Nmax, q ->
    apply(select(Fmin, f -> tupleLT(q,f)), f -> {q,f})
);

midpointCandidates = pair -> (
    q := pair#0; f := pair#1;

    lows := apply(#q, i -> floor((q#i+f#i)/2));
    highs := apply(#q, i -> ceiling((q#i+f#i)/2));

    build := (i, partial) -> (
        if i == #q then return {partial};
        vals := if lows#i == highs#i then {lows#i} else {lows#i,highs#i};
        flatten apply(vals, v -> build(i+1, append(partial,v)))
    );

    build(0,{})
);

chooseGuidedCandidate = (Fmin, Nmax) -> (
    pairs := comparablePairs(Nmax,Fmin);
    if #pairs == 0 then return null;

    ordered := sort(pairs,
        (A,B) -> midpointScore(A) > midpointScore(B)
    );

    for pair in ordered do (
        cands := midpointCandidates pair;
        good := select(cands,
            a -> not impliedFilling(a,Fmin) and
                 not impliedNonFilling(a,Nmax)
        );
        if #good > 0 then return first good;
    );

    null
);

------------------------------------------------------------
-- ✅ State constructor
------------------------------------------------------------

makeFrontierState = (depth, d0, dL, m, n, r) -> (
    hashTable {
        "depth"=>depth,
        "d0"=>d0,
        "dL"=>dL,
        "range"=>{m,n},
        "exponent"=>r,

        "FminTuples"=>{},
        "NmaxTuples"=>{},
        "FminResults"=>{},
        "SeenTuples"=>{},

        "nEvaluated"=>0
    }
);

------------------------------------------------------------
-- ✅ Resume guided search
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
    Seen := state#"SeenTuples";

    for t from 1 to B do (

        a := chooseGuidedCandidate(Fmin,Nmax);
        if a === null then a = randomHiddenTuple(k,m,n);

        if any(Seen, s -> tupleEQ(s,a)) then continue;
        Seen = join(Seen,{a});

        if impliedFilling(a,Fmin) then continue;
        if impliedNonFilling(a,Nmax) then continue;

        arch := architectureFromHidden(d0,dL,a);
        res := computeDimension(arch,r);

        if isFillingResult res then (
            Fmin = updateMinimalAntichain(Fmin,a);
        ) else (
            Nmax = updateMaximalAntichain(Nmax,a);
        );
    );

    state#"FminTuples" = Fmin;
    state#"NmaxTuples" = Nmax;
    state#"SeenTuples" = Seen;

    state
);
