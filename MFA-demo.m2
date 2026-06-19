# MinimalFillingArchitectures_patched.m2

restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitectures_patched.m2"
computeDimension({2,3,1}, 2)

results = runUniformSearch(2, 1, 1, 2, 3, 2)
printResults results

mins = minimalFillingResults results
printResults mins

out = runFrontierSearch(6, 2, 1, 2, 5, 2, 100000, 12345)
printGuidedFrontierFillingResults out

--Depending on your Macaulay2 installation, you may still need to adjust `setRandomSeed seed`.
--If `random(K)` over `ZZ/p` is problematic, replace `randElt = K -> random(K)` by `randElt = K -> lift(random(1000), K)`.
restart
load"/Users/joserodriguez/Documents/GitHub/MFA_PNNs/MinimalFillingArchitecturesV3.m2"
state0 = makeFrontierState(3,2,1,2,4,2)

state1 = runGuidedFrontierSearchResume(state0, 10, 12345)

state2 = runGuidedFrontierSearchResume(state1, 10, 67890)

state2#"FminTuples"
state2#"NmaxTuples"
seedTuples = {
    {2,2},
    {3,3},
    {4,2},
    {2,4}
}

state1 = initializeFrontierWithArchitectures(state0, seedTuples)
``
