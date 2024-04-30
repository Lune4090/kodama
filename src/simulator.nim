# std
import sequtils, sugar, math
# outer
import unchained, chroma, arraymancer
# original
import plot, parameters, dynamics, reservoir

proc simulateReferenceSystem*(M: float, K: float, D: float, sim: SimParams, f: SinForces): tuple =
  let
    sys_test = newMassSpringDumper(M, K, D)

  var
    # input & output definition
    outputV = newSeqOfCap[Meter•Second⁻¹](sim.datanum)
    outputA = newSeqOfCap[Meter•Second⁻²](sim.datanum)

  # filling first few args
  outputV.add(0.m•s⁻¹)
  outputA.add(0.m•s⁻²)
  outputA.add(0.m•s⁻²)

  var
    # calculate system reaction, dispatched by f.
    outputX = sys_test.responcesToForce(f, sim, x0=0.0.m)

    # variables to calculate system responce
    x1_out = 0.0.m
    x2_out = 0.0.m

  for i, x in outputX.pairs:
    if i >= 1:
      outputV.add(getVfromX(sim.Δt, x, x1_out))
    if i >= 2:
      outputA.add(getAfromX(sim.Δt, x, x1_out, x2_out))
    x2_out = x1_out
    x1_out = x


  ################
  # Plotting
  ################

  var
    # figure specific setting
    color_inF  = @[Color(r: 0.6, g: 0.6, b: 0.6, a: 0.8)]
    color_outX = @[Color(r: 0.6, g: 0.2, b: 0.2, a: 0.8)]
    color_outV = @[Color(r: 0.2, g: 0.6, b: 0.2, a: 0.8)]
    color_outA = @[Color(r: 0.2, g: 0.2, b: 0.6, a: 0.8)]

  plot_inF_outXVA(
    sim.t_seq,
    f.Fseq,
    outputX,
    outputV,
    outputA,
    color_inF,
    color_outX,
    color_outV,
    color_outA,
  )

  return ("Simulation Ended", outputX, outputV, outputA)

proc simulateReservoirSystem*(sys: var ReservoirSystem, I: int, R: int, O: int, sp: float, seednum: int, sim: SimParams, f: SinForces ): tuple =

  var
    # input & output definition
    outputV = newSeqOfCap[Meter•Second⁻¹](sim.datanum)
    outputA = newSeqOfCap[Meter•Second⁻²](sim.datanum)

  # filling first few args
  outputV.add(0.m•s⁻¹)
  outputA.add(0.m•s⁻²)
  outputA.add(0.m•s⁻²)

  ################
  # Simulation
  ################

  var
    # calculate system reaction
    fs = f.Fseq.map(x=>x.toFloat)
    outputX = newSeq[Meter](sim.datanum)

  for i, x in pairs(fs):
    var inx = newSeq[float](I).map(x => fs[i]).toTensor.reshape(I)
    outputX[i] = sys.responcesToInput(inx).toSeq1D[0].m

  # variables to calculate system responce
  var
    x1_out = 0.0.m
    x2_out = 0.0.m

  for i, x in outputX.pairs:
    if i >= 1:
      outputV.add(getVfromX(sim.Δt, x, x1_out))
    if i >= 2:
      outputA.add(getAfromX(sim.Δt, x, x1_out, x2_out))
    x2_out = x1_out
    x1_out = x

  ################
  # Plotting
  ################

  var
    # figure specific setting
    color_inF  = @[Color(r: 0.6, g: 0.6, b: 0.6, a: 0.8)]
    color_outX = @[Color(r: 0.6, g: 0.2, b: 0.2, a: 0.8)]
    color_outV = @[Color(r: 0.2, g: 0.6, b: 0.2, a: 0.8)]
    color_outA = @[Color(r: 0.2, g: 0.2, b: 0.6, a: 0.8)]

  plot_inF_outXVA(
    sim.t_seq,
    f.Fseq,
    outputX,
    outputV,
    outputA,
    color_inF,
    color_outX,
    color_outV,
    color_outA,
  )

  return ("Simulation Ended", outputX, outputV, outputA, sys)

proc simulateReservoirLearning*(sys: var ReservoirSystem, teacherdata: Tensor[float], inputdata: Tensor[float]; iter: int = 100, η: range[0.0..1.0] = 0.01): tuple =
  var rseSeq = newseq[float]()
  for i in 0..<iter:
    var rse = 0.0
    for i, data in pairs(inputdata.toSeq1D):
      var inx = newSeq[float](sys.readin.shape[1]).map(x => data).toTensor
      var pred = sys.responcesToInput(inx)

      sys.learnFromTeacher(pred, @[teacherdata[i]].toTensor, η)
      for i in 0..<pred.shape[0]:
        rse += (pred[i] - (@[teacherdata[i]].toTensor)[i])^2
    echo rse
    rseSeq.add(rse)

  return ("Learning Ended", rseSeq, sys)
