# Package

version       = "0.1.0"
author        = "lune4090"
description   = "kodama: Kinetics optimizer / Dynamics Analyzer with Machine-learning Algorithms"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["kodama"]


# Dependencies

requires "nim >= 2.0.2", "fidget", "arraymancer", "numericalnim", "unchained", "plotly", "chroma"
