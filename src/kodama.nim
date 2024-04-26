#[
  CAUTION
  - object使う場合は、必ずそのモジュール内にコンストラクタ的なprocを書いて、それを呼ぶこと。何かunchainedはモジュールまたぐと独自型呼び出しがバグるし、この形が自然だとも思う
  TODO
  - パラメータ群のオブジェクト化による視認性向上
    - 特にシミュレーション時間設定、伝達関数決定、初期条件周りはオブジェクトにすべき
]#
################
# Initial setting
################

import arraymancer, math, sequtils, sugar, fidget, numericalnim, unchained
import ./plot

import ./systems # Newtonを含むobjectをmodule内から呼ぶとなぜか値を設定できないため、泣く泣くここだけinclude文にした


################
# Parameters
################

# immutable parameters
let
  # simulation span setting
  timespan = 10.0
  Δt = 1.ms
  datanum = toInt(timespan/Δt.to(Second).toFloat)
  t_seq_unitless = linspace(0.0, timespan, datanum)


# mutable parameters
var
  t_seq = newSeqOfCap[Second](datanum)

  x_init = 0.1.m
  ω_amp = 1.s⁻¹
  f_amp = 0.01.N

  # test data
  force_sinwave = t_seq_unitless.map(t => sin(ω_amp*t.s) * f_amp)

  # input & output definition
  input_F  = force_sinwave
  output_X: seq[Meter]
  output_V = newSeqOfCap[Meter•Second⁻¹](datanum)
  output_A = newSeqOfCap[Meter•Second⁻²](datanum)

  # figure specific setting
  color_in1  = @[Color(r: 0.6, g: 0.6, b: 0.6, a: 0.8)]
  color_out1 = @[Color(r: 0.6, g: 0.2, b: 0.2, a: 0.8)]
  color_out2 = @[Color(r: 0.2, g: 0.6, b: 0.2, a: 0.8)]
  color_out3 = @[Color(r: 0.2, g: 0.2, b: 0.6, a: 0.8)]

for t in t_seq_unitless:
  t_seq.add(t.s)

# filling first few args
output_V.add(0.m•s⁻¹)
output_A.add(0.m•s⁻²)
output_A.add(0.m•s⁻²)


# variable setting for plotting
# ここ
var system_test = new_mass_spring_dumper(1.0, 0.5, 5.0)

################
# Simulation
################

# calculate system reaction
output_X = mass_spring_dumper_responces_to_sin_kt(
    system_test,
    t_seq,
    f_amp,
    ω_amp,
    x_init
  )

# variables to calculate system responce
var
  x1_out = 0.0.m
  x2_out = 0.0.m

for i, x in output_X.pairs:
  if i >= 1:
    output_V.add(GetVfromX(Δt.to(Second), x, x1_out))
  if i >= 2:
    output_A.add(GetAfromX(Δt.to(Second), x, x1_out, x2_out))
  x2_out = x1_out
  x1_out = x


################
# Plotting
################

plot_inF_outXVA(
  t_seq,
  input_F,
  output_X,
  output_V,
  output_A,
  color_in1,
  color_out1,
  color_out2,
  color_out3,
)
