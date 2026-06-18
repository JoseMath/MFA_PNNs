# MinimalFillingArchitectures_patched.m2

Patched package version of the minimal filling architecture search code.

## Main fixes relative to the first package scaffold
- removed package-level `begin` / `end`
- replaced private `hiddenWidths` references by exported `hiddenLayerWidths`
- nested helper functions now use local `:=` bindings (`buildCombos`, `perturbOne`)
- guided frontier loop predeclares `a` and `proposalType` to avoid shielding warnings

## Suggested usage in Macaulay2

```m2
load "MinimalFillingArchitectures_patched.m2"

computeDimension({2,3,1}, 2)

results = runUniformSearch(2, 1, 1, 2, 3, 2)
printResults results

mins = minimalFillingResults results
printResults mins

out = runGuidedFrontierSearch(3, 2, 1, 2, 4, 2, 10, 12345)
printGuidedFrontierFillingResults out
```

## Notes
- Depending on your Macaulay2 installation, you may still need to adjust `setRandomSeed seed`.
- If `random(K)` over `ZZ/p` is problematic, replace `randElt = K -> random(K)` by `randElt = K -> lift(random(1000), K)`.
