# std
import math, sequtils, sugar
# outer
import numericalnim, unchained 

type
  # simulation parameters (non-specific to systems)
  SimParams* = object
    timespan*: Second
    Δt*: MilliSecond
    datanum*: int
    t_seq*: seq[Second]

proc newSimParams*(timespan: float, Δt: float): SimParams =
  var num = toInt(timespan/Δt.ms.to(Second).toFloat)
  return SimParams(
    timespan: timespan.s,
    Δt: Δt.ms,
    datanum: num,
    t_seq: linspace(0.0, timespan, num).map(t => t.s),
  )
