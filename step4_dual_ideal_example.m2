------------------------------------------------------------
-- step4_dual_ideal_example.m2
-- Illustrative finite-box dual bookkeeping for frontier search
------------------------------------------------------------

tupleEQ = (a, b) -> (
    if #a =!= #b then false else all(#a, i -> a#i == b#i)
);

tupleLEQ = (a, b) -> (
    if #a =!= #b then error "tupleLEQ: tuples must have same length";
    all(#a, i -> a#i <= b#i)
);

tupleLT = (a, b) -> tupleLEQ(a, b) and not tupleEQ(a, b);
tupleGEQ = (a, b) -> tupleLEQ(b, a);
tupleGT = (a, b) -> tupleGEQ(a, b) and not tupleEQ(a, b);

rangeList = (m, n) -> apply(n - m + 1, i -> m + i);

allBoundedTuples = bounds -> (
    if #bounds == 0 then return {{}};
    firstBounds := first bounds;
    tailBounds := drop(bounds, 1);
    vals := rangeList(firstBounds#0, firstBounds#1);
    tails := allBoundedTuples(tailBounds);
    flatten apply(vals, v -> apply(tails, t -> prepend(v, t)))
);

--bookkeepingRing = k -> QQ[apply(k,i -> symbol ("z"|toString(i+1)) )];
z=symbol z
bookkeepingRing = k -> QQ[apply(k,i -> z_(i+1)) ];

ringVarsList = R -> flatten entries vars R; 

shiftTuple = (a, m) -> apply(#a, i -> a#i - m);

reverseTupleInBox = (u, c) -> apply(#u, i -> c#i - u#i);

encodeShiftedTuple = (u, R) -> (
    Z := ringVarsList R;
    product apply(#u, i -> Z#i^(u#i))
);

fillingIdealFromFmin = (Fmin, m, R) -> (
    if #Fmin == 0 then monomialIdeal 0_R
    else monomialIdeal apply(Fmin, a -> encodeShiftedTuple(shiftTuple(a, m), R))
);

impliedByShiftedFrontier = (u, shiftedFrontier) -> (
    any(shiftedFrontier, g -> tupleGEQ(u, g))
);

maximalComplementTuplesInBox = (shiftedFrontier, c) -> (
    bounds := apply(#c, i -> {0, c#i});
    allTuples := allBoundedTuples(bounds);
    unresolved := select(allTuples, u -> not impliedByShiftedFrontier(u, shiftedFrontier));
    select(unresolved, u -> not any(unresolved, v -> tupleGT(v, u)))
);

dualIdealFromFminInBox = (Fmin, m, n, R) -> (
    if #Fmin == 0 then return monomialIdeal 0_R;
    shiftedF := apply(Fmin, a -> shiftTuple(a, m));
    c := apply(#(first shiftedF), i -> n - m);
    maxComp := maximalComplementTuplesInBox(shiftedF, c);
    if #maxComp == 0 then monomialIdeal 0_R
    else monomialIdeal apply(maxComp, u -> encodeShiftedTuple(reverseTupleInBox(u, c), R))
);

printIdealGenerators = (label, I) -> (
    << label << endl;
    if numColumns gens I == 0 then (
        << "  <no generators>" << endl;
    ) else (
        scan(flatten entries gens I, g -> << "  " << toString g << endl)
    )
);

-- Example data: box [2,5]^2 and Fmin = {{2,3},{4,2}}
demoDualBookkeeping = () -> (
    m := 2;
    n := 5;
    k := 2;
    R := bookkeepingRing k;
    Fmin := {{2,3}, {4,2}};
    IF := fillingIdealFromFmin(Fmin, m, R);
    DF := dualIdealFromFminInBox(Fmin, m, n, R);
    << "Search box = [" << toString m << "," << toString n << "]^" << toString k << endl;
    << "Fmin tuples = " << toString Fmin << endl;
    printIdealGenerators("Filling ideal IF generators:", IF);
    printIdealGenerators("Dual/complement bookkeeping ideal DF generators:", DF);
    {Fmin, IF, DF}
);
