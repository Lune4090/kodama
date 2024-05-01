# std
import random, sugar
# outer
import arraymancer

type
  ReservoirSystem* = object
    readin*: Tensor[float]
    reservoir*: Tensor[float]
    reservoirUpdate*: Tensor[float]
    readout*: Tensor[float]

proc newReservoir*(readinSize: int, reservoirSize: int, readoutSize: int, sparsity: range[0.0..1.0], seednum: int): ReservoirSystem =
  var
    readin_seq = newSeq[float](readinSize*reservoirSize)
    reservoir_seq = newSeq[float](reservoirSize)
    reservoir_update_seq = newSeq[float](reservoirSize*reservoirSize)
    readout_seq = newSeq[float](reservoirSize*readoutSize)
    seed = initRand(seednum)

  for x in mitems(readin_seq):
    x = rand(seed, 2.0)-1.0
  for x in mitems(reservoir_seq):
    if rand(seed, 1.0) > sparsity:
      x = rand(seed, 2.0)-1.0
    else: 
      x = 0.0
  for x in mitems(reservoir_update_seq):
    if rand(seed, 1.0) > sparsity:
      x = rand(seed, 2.0)-1.0
    else: 
      x = 0.0
  for x in mitems(readout_seq):
    x = rand(seed, 2.0)-1.0

  return ReservoirSystem(
    readin: readin_seq.toTensor.reshape(reservoirSize, readinSize),
    reservoir: reservoir_seq.toTensor.reshape(reservoirSize),
    reservoirUpdate: reservoir_update_seq.toTensor.reshape(reservoirSize, reservoirSize),
    readout: readout_seq.toTensor.reshape(readoutSize, reservoirSize)
  )

proc responcesToInput*(sys: var ReservoirSystem, input: Tensor[float]): Tensor[float] =

  # reservoir update rule
  sys.reservoir = (sys.readin * input + sys.reservoirUpdate * sys.reservoir)
  # read answer only from reservoir (no highway)
  return (sys.readout * sys.reservoir).map(x => tanh(x))

proc learnFromTeacher*(sys: var ReservoirSystem, pred: Tensor[float], teacherdata: Tensor[float], η: range[0.0..1.0]) =
  for row in 0..<sys.readout.shape[0]:
    for col in 0..<sys.readout.shape[1]:
      sys.readout[row, col] -= η*sys.reservoir[col]*(pred[row]-teacherdata[row])
