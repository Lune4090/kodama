# std
import random
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
    reservoir: reservoir_seq.toTensor.reshape(reservoirSize, 1),
    reservoirUpdate: reservoir_update_seq.toTensor.reshape(reservoirSize, reservoirSize),
    readout: readout_seq.toTensor.reshape(readoutSize, reservoirSize)
  )

proc responcesToInput*(sys: var ReservoirSystem, inX: Tensor[float]): Tensor[float] =
  sys.reservoir = (sys.readin * inX + sys.reservoirUpdate * sys.reservoir)
  echo sys.readin
  echo inX
  echo sys.reservoir
  var
    val = sys.readout * sys.reservoir
  return val.reshape(val.shape[0]*val.shape[1])
