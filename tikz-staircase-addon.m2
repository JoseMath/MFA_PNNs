export{
"frontierRegionTypeThreeHidden",
    "writeCombinedFrontierStaircaseTikzThreeHidden",
    "writeCombinedFrontierStaircaseStandaloneTexThreeHidden",
--
--
    "writeFrontierStaircaseTikzTwoHidden",
    "writeFrontierStaircaseStandaloneTexTwoHidden",
    "frontierColorTypeTwoHidden",
    --
    "writeCombinedFrontierStaircaseTikzTwoHidden",
    "writeCombinedFrontierStaircaseStandaloneTexTwoHidden",
    "frontierRegionTypeTwoHidden"
    }
    -- --



    ------------------------------------------------------------
-- 3D combined staircase diagram for the depth = 4 case
--
-- depth = 4  <=> hidden tuple length = 3
-- architectures have the form {d0, a1, a2, a3, dL}
--
-- Region colors:
--   blue   = implied filling only
--   red    = implied non-filling only
--   gray   = unresolved
--   purple = implied both (inconsistent frontier data)
------------------------------------------------------------

frontierRegionTypeThreeHidden = (a, Fmin, Nmax) -> (
    fillQ := impliedFilling(a, Fmin);
    nonfillQ := impliedNonFilling(a, Nmax);

    if fillQ and nonfillQ then return "both";
    if fillQ then return "filling";
    if nonfillQ then return "nonfilling";
    "unresolved"
);

------------------------------------------------------------
-- Draw one unit cube in TikZ using 3 visible faces
-- Assumes a 3D coordinate system has been set in the tikzpicture.
------------------------------------------------------------

writeUnitCubeTikz = (f, x, y, z, faceColor) -> (
    -- front face
    f << "  \\fill[" << faceColor << "] (" << toString x << "," << toString y << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString y << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString z
      << ") -- (" << toString x << "," << toString(y+1) << "," << toString z
      << ") -- cycle;" << endl;

    -- side face
    f << "  \\fill[" << faceColor << "!85!black] (" << toString(x+1) << "," << toString y << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString(z+1)
      << ") -- (" << toString(x+1) << "," << toString y << "," << toString(z+1)
      << ") -- cycle;" << endl;

    -- top face
    f << "  \\fill[" << faceColor << "!60] (" << toString x << "," << toString(y+1) << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString(z+1)
      << ") -- (" << toString x << "," << toString(y+1) << "," << toString(z+1)
      << ") -- cycle;" << endl;

    -- outline
    f << "  \\draw[black!55] (" << toString x << "," << toString y << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString y << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString z
      << ") -- (" << toString x << "," << toString(y+1) << "," << toString z
      << ") -- cycle;" << endl;

    f << "  \\draw[black!55] (" << toString(x+1) << "," << toString y << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString y << "," << toString(z+1) << ");" << endl;
    f << "  \\draw[black!55] (" << toString(x+1) << "," << toString(y+1) << "," << toString z
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString(z+1) << ");" << endl;
    f << "  \\draw[black!55] (" << toString x << "," << toString(y+1) << "," << toString z
      << ") -- (" << toString x << "," << toString(y+1) << "," << toString(z+1) << ");" << endl;

    f << "  \\draw[black!55] (" << toString(x+1) << "," << toString y << "," << toString(z+1)
      << ") -- (" << toString(x+1) << "," << toString(y+1) << "," << toString(z+1)
      << ") -- (" << toString x << "," << toString(y+1) << "," << toString(z+1) << ");" << endl;
);

------------------------------------------------------------
-- Combined 3D staircase TikZ writer
------------------------------------------------------------

writeCombinedFrontierStaircaseTikzThreeHidden = (state, filename) -> (
    depth := state#"depth";
    if depth =!= 4 then
        error "writeCombinedFrontierStaircaseTikzThreeHidden: requires depth = 4 (three hidden layers)";

    m := (state#"range")#0;
    n := (state#"range")#1;

    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";

    f := openOut filename;

    f << "\\begin{tikzpicture}[" << endl;
    f << "  x={(1cm,0cm)}," << endl;
    f << "  y={(0.72cm,0.36cm)}," << endl;
    f << "  z={(0cm,0.95cm)}" << endl;
    f << "]" << endl;

    f << "  % Combined 3D staircase diagram" << endl;

    -- draw cubes back-to-front for better visibility
    -- draw cubes back-to-front for better visibility
    for z from m to n do (
	scan(reverse toList(m .. n), y -> (
		for x from m to n do (
		    a := {x,y,z};
		    t := frontierRegionTypeThreeHidden(a, Fmin, Nmax);
		    baseColor :=
		    if t === "filling" then "blue"
		    else if t === "nonfilling" then "red"
		    else if t === "both" then "purple"
		    else "gray";
		    writeUnitCubeTikz(f, x-m, y-m, z-m, baseColor);
		    );
		));
	);
    size := n - m + 1;

    -- outer wireframe box
    f << "  % Bounding box" << endl;
    f << "  \\draw[black, thick] (0,0,0) -- (" << toString size << ",0,0) -- ("
      << toString size << "," << toString size << ",0) -- (0," << toString size << ",0) -- cycle;" << endl;
    f << "  \\draw[black, thick] (0,0," << toString size << ") -- (" << toString size << ",0," << toString size
      << ") -- (" << toString size << "," << toString size << "," << toString size
      << ") -- (0," << toString size << "," << toString size << ") -- cycle;" << endl;
    f << "  \\draw[black, thick] (0,0,0) -- (0,0," << toString size << ");" << endl;
    f << "  \\draw[black, thick] (" << toString size << ",0,0) -- (" << toString size << ",0," << toString size << ");" << endl;
    f << "  \\draw[black, thick] (" << toString size << "," << toString size << ",0) -- (" << toString size << "," << toString size << "," << toString size << ");" << endl;
    f << "  \\draw[black, thick] (0," << toString size << ",0) -- (0," << toString size << "," << toString size << ");" << endl;

    -- mark Fmin points
    scan(Fmin, a -> (
        x := a#0 - m + 0.5;
        y := a#1 - m + 0.5;
        z := a#2 - m + 0.5;
        f << "  \\filldraw[blue!85!black] (" << toString x << "," << toString y << "," << toString z
          << ") circle (2.0pt);" << endl;
    ));

    -- mark Nmax points
    scan(Nmax, a -> (
        x := a#0 - m + 0.5;
        y := a#1 - m + 0.5;
        z := a#2 - m + 0.5;
        f << "  \\draw[red!85!black, fill=red!85!black] (" << toString(x-0.08) << "," << toString(y-0.08) << "," << toString z
          << ") rectangle (" << toString(x+0.08) << "," << toString(y+0.08) << "," << toString z << ");" << endl;
    ));

    -- title and axis labels
    f << "  \\node at (" << toString(size/2) << "," << toString(size+1.5) << "," << toString(size+0.8)
      << ") {Combined staircase diagram for depth $=4$};" << endl;

    f << "  \\node at (" << toString(size/2) << ",-1.0,0) {$a_1$};" << endl;
    f << "  \\node at (" << toString(size+0.9) << "," << toString(size/2) << ",0) {$a_2$};" << endl;
    f << "  \\node at (0," << toString(size+0.1) << "," << toString(size/2) << ") {$a_3$};" << endl;

    -- tick labels
    for t from 0 to size-1 do (
        label := t + m;
        f << "  \\node[below] at (" << toString(t+0.5) << ",0,0) {" << toString label << "};" << endl;
        f << "  \\node[right] at (" << toString size << "," << toString(t+0.5) << ",0) {" << toString label << "};" << endl;
        f << "  \\node[left] at (0," << toString size << "," << toString(t+0.5) << ") {" << toString label << "};" << endl;
    );

    -- legend
    f << "  % Legend" << endl;
    f << "  \\begin{scope}[shift={(" << toString(size+2.3) << ",0,0)}]" << endl;
    f << "    \\fill[blue!25] (0,0,0) rectangle +(0.5,0.35);" << endl;
    f << "    \\node[right] at (0.6,0.175,0) {implied filling};" << endl;

    f << "    \\fill[red!25] (0,-0.8,0) rectangle +(0.5,0.35);" << endl;
    f << "    \\node[right] at (0.6,-0.625,0) {implied non-filling};" << endl;

    f << "    \\fill[gray!15] (0,-1.6,0) rectangle +(0.5,0.35);" << endl;
    f << "    \\node[right] at (0.6,-1.425,0) {unresolved};" << endl;

    f << "    \\fill[purple!30] (0,-2.4,0) rectangle +(0.5,0.35);" << endl;
    f << "    \\node[right] at (0.6,-2.225,0) {implied both};" << endl;

    f << "    \\filldraw[blue!85!black] (0.25,-3.2,0) circle (2.0pt);" << endl;
    f << "    \\node[right] at (0.6,-3.2,0) {$F_{\\min}$ point};" << endl;

    f << "    \\draw[red!85!black, fill=red!85!black] (0.17,-4.08,0) rectangle (0.33,-3.92,0);" << endl;
    f << "    \\node[right] at (0.6,-4.0,0) {$N_{\\max}$ point};" << endl;

    f << "  \\end{scope}" << endl;

    f << "\\end{tikzpicture}" << endl;
    close f;

    filename
);




------------------------------------------------------------
-- TikZ staircase diagrams for the two-hidden-layer case
--
-- Convention:
--   depth = 3  <=> hidden tuple length = 2
--   architectures have form {d0, a1, a2, dL}
--
-- The diagram is drawn in the (a1,a2)-plane over the box [m,n]^2.
--
-- We produce two side-by-side staircase plots:
--   left  = filling staircase determined by Fmin
--   right = non-filling staircase determined by Nmax
--
-- Cells are colored as:
--   filling    : blue
--   non-filling: red
--   unresolved : gray
------------------------------------------------------------

frontierColorTypeTwoHidden = (a, Fmin, Nmax) -> (
    if impliedFilling(a, Fmin) then return "filling";
    if impliedNonFilling(a, Nmax) then return "nonfilling";
    "unresolved"
);

writeFrontierStaircaseTikzTwoHidden = (state, filename) -> (
    depth := state#"depth";
    if depth =!= 3 then
        error "writeFrontierStaircaseTikzTwoHidden: requires depth = 3 (two hidden layers)";

    m := (state#"range")#0;
    n := (state#"range")#1;

    Fmin := state#"FminTuples";
    Nmax := state#"NmaxTuples";

    f := openOut filename;

    -- Header for a bare tikzpicture (not full LaTeX document)
    f << "\\begin{tikzpicture}[scale=0.9]" << endl;
    f << "  % Left panel: filling staircase (Fmin)" << endl;
    f << "  \\begin{scope}[shift={(0,0)}]" << endl;

    -- Fill cells for the left panel
    for i from m to n do (
        for j from m to n do (
            a := {i,j};
            t := frontierColorTypeTwoHidden(a, Fmin, Nmax);

            if t === "filling" then (
                f << "    \\fill[blue!25] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            ) else if t === "unresolved" then (
                f << "    \\fill[gray!15] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            );
        );
    );

    -- Grid and axes labels for left panel
    f << "    \\draw[step=1cm,black!50] (" << toString(m-1) << "," << toString(m-1)
      << ") grid (" << toString(n) << "," << toString(n) << ");" << endl;
    f << "    \\node at (" << toString((m-1+n)/2) << "," << toString(n+0.8)
      << ") {$F_{\\min}$ staircase};" << endl;
    f << "    \\node at (" << toString((m-1+n)/2) << "," << toString(m-1-0.8)
      << ") {$a_1$};" << endl;
    f << "    \\node[rotate=90] at (" << toString(m-1-0.8) << "," << toString((m-1+n)/2)
      << ") {$a_2$};" << endl;

    -- Tick labels in original coordinates
    for i from m to n do (
        f << "    \\node[below] at (" << toString(i-0.5) << "," << toString(m-1)
          << ") {" << toString i << "};" << endl;
        f << "    \\node[left] at (" << toString(m-1) << "," << toString(i-0.5)
          << ") {" << toString i << "};" << endl;
    );

    -- Mark Fmin points
    scan(Fmin, a -> (
        i := a#0;
        j := a#1;
        f << "    \\filldraw[blue!70!black] (" << toString(i-0.5) << "," << toString(j-0.5)
          << ") circle (2.2pt);" << endl;
    ));

    f << "  \\end{scope}" << endl;
    f << endl;

    -- Right panel: non-filling staircase
    shiftX := (n - m + 3); -- gap between the two panels

    f << "  % Right panel: non-filling staircase (Nmax)" << endl;
    f << "  \\begin{scope}[shift={(" << toString shiftX << ",0)}]" << endl;

    for i from m to n do (
        for j from m to n do (
            a := {i,j};
            t := frontierColorTypeTwoHidden(a, Fmin, Nmax);

            if t === "nonfilling" then (
                f << "    \\fill[red!25] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            ) else if t === "unresolved" then (
                f << "    \\fill[gray!15] (" << toString(i-1) << "," << toString(j-1)
                  << ") rectangle (" << toString(i) << "," << toString(j) << ");" << endl;
            );
        );
    );

    -- Grid and axes labels for right panel
    f << "    \\draw[step=1cm,black!50] (" << toString(m-1) << "," << toString(m-1)
      << ") grid (" << toString(n) << "," << toString(n) << ");" << endl;
    f << "    \\node at (" << toString((m-1+n)/2) << "," << toString(n+0.8)
      << ") {$N_{\\max}$ staircase};" << endl;
    f << "    \\node at (" << toString((m-1+n)/2) << "," << toString(m-1-0.8)
      << ") {$a_1$};" << endl;
    f << "    \\node[rotate=90] at (" << toString(m-1-0.8) << "," << toString((m-1+n)/2)
      << ") {$a_2$};" << endl;

    for i from m to n do (
        f << "    \\node[below] at (" << toString(i-0.5) << "," << toString(m-1)
          << ") {" << toString i << "};" << endl;
        f << "    \\node[left] at (" << toString(m-1) << "," << toString(i-0.5)
          << ") {" << toString i << "};" << endl;
    );

    -- Mark Nmax points
    scan(Nmax, a -> (
        i := a#0;
        j := a#1;
        f << "    \\filldraw[red!70!black] (" << toString(i-0.5) << "," << toString(j-0.5)
          << ") rectangle ++(0.12,0.12);" << endl;
        -- More visible square marker:
        f << "    \\draw[red!70!black, fill=red!70!black] (" << toString(i-0.5-0.09)
          << "," << toString(j-0.5-0.09) << ") rectangle ("
          << toString(i-0.5+0.09) << "," << toString(j-0.5+0.09) << ");" << endl;
    ));

    f << "  \\end{scope}" << endl;
    f << endl;

    -- Simple legend
    legendX := shiftX/2;
    f << "  % Legend" << endl;
    f << "  \\begin{scope}[shift={(" << toString(legendX) << "," << toString(n+1.6) << ")}]" << endl;
    f << "    \\fill[blue!25] (0,0) rectangle (0.5,0.35);" << endl;
    f << "    \\node[right] at (0.6,0.175) {implied filling};" << endl;
    f << "    \\fill[red!25] (3.0,0) rectangle (3.5,0.35);" << endl;
    f << "    \\node[right] at (3.6,0.175) {implied non-filling};" << endl;
    f << "    \\fill[gray!15] (6.7,0) rectangle (7.2,0.35);" << endl;
    f << "    \\node[right] at (7.3,0.175) {unresolved};" << endl;
    f << "  \\end{scope}" << endl;

    f << "\\end{tikzpicture}" << endl;
    close f;

    filename
);

------------------------------------------------------------
-- Write a standalone LaTeX document containing the TikZ figure
------------------------------------------------------------

writeFrontierStaircaseStandaloneTexTwoHidden = (state, filename) -> (
    f := openOut filename;
    f << "\\documentclass[tikz,border=5pt]{standalone}" << endl;
    f << "\\usepackage{tikz}" << endl;
    f << "\\begin{document}" << endl;
    close f;

    -- append the tikzpicture body
    tmpName := filename | ".tikzbody";
    writeFrontierStaircaseTikzTwoHidden(state, tmpName);

    body := get tmpName;
    f2 := openOut filename;
    f2 << "\\documentclass[tikz,border=5pt]{standalone}" << endl;
    f2 << "\\usepackage{tikz}" << endl;
    f2 << "\\begin{document}" << endl;
    scan(lines body, s -> f2 << s << endl);
    f2 << "\\end{document}" << endl;
    close f2;

    filename
);

------------------------------------------------------------
-- Standalone LaTeX wrapper
------------------------------------------------------------

writeCombinedFrontierStaircaseStandaloneTexThreeHidden = (state, filename) -> (
    bodyName := filename | ".tikzbody";
    writeCombinedFrontierStaircaseTikzThreeHidden(state, bodyName);

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

