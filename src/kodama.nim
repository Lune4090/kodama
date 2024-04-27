################
# Initial setting
################

# std
import sequtils, sugar 
# outer
import unchained, arraymancer, fidget 
# original
import plot, systems, simulator

################
# Parameters
################

let
  sim = newSimParams(30.0, 1.0)
  force_sin = newSinForces(1.0, 0.01, sim.t_seq.map(x => x.toFloat))
  sys_test = newMassSpringDumper(1.0, 3.0, 1.0)

var
  # input & output definition
  inputF  = force_sin
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
  outputX = sys_test.responcesToForce(force_sin, sim)

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
  inputF.fs,
  outputX,
  outputV,
  outputA,
  color_inF,
  color_outX,
  color_outV,
  color_outA,
)
