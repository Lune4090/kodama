# std
import sequtils, sugar
# outer
import unchained, math
# original
import simulator

defUnit(Meter•Second⁻¹)
defUnit(Meter•Second⁻²)
defUnit(Newton•Meter⁻¹) # バネ定数
defUnit(Newton•s•Meter⁻¹) # ダンパー係数

################
# Systems
################

# objects
type
  SinForces* = object
    ω*: Hertz
    amp*: Newton
    fs*: seq[Newton]

  ConstForces* = object
    amp*: Newton
    fs*: seq[Newton]

  MassSpringDumper* = object
    M*: KiloGram
    K*: Newton•Meter⁻¹
    D*: Newton•s•Meter⁻¹

proc newSinForces*(ω: float, amp: float, t_seq: seq[float]): SinForces =
  return SinForces(
    ω: ω.s⁻¹, 
    amp: amp.N, 
    fs: t_seq.map(t => sin(ω.s⁻¹*t.s)*amp.N)
  )

proc newConstForces*(amp: float, t_seq: seq[float]): SinForces =
  return SinForces(
    amp: amp.N, 
    fs: t_seq.map(t => t*amp.N)
  )

proc newMassSpringDumper*(m: float, k: float, d: float): MassSpringDumper =
  return MassSpringDumper(M: m.kg, K: k.N•m⁻¹, D: d.N•s•m⁻¹) 


# functions
proc getVfromX*(Δt: MilliSecond, x0: Meter, x1: Meter): Velocity =
  let V = (x0-x1)/Δt.to(Second)
  return V

proc getAfromX*(Δt: MilliSecond, x0: Meter, x1: Meter, x2: Meter): Acceleration =
  let A = ((x0-x1)-(x1-x2))/Δt.to(Second)^2
  return A

# シンプルなバネマスダンパー系から成る2階非同次微分方程式
# M*(d²x/dt²) + D*(dx/dt) + k*x = f(.const)を解き、軌跡seq[Meter]を得る 
proc responcesToForce*(sys: MassSpringDumper, force: ConstForces, sim: SimParams; x0 = 0.0.m): seq[Meter] =
  let
    M = sys.M
    K = sys.K
    D = sys.D
    F = force.amp
    cond = (D^2 - 4*M*K).toFloat

  var
    ans = newSeqofCap[Meter](sim.datanum)

  if cond > 0:
    let
      λ1: Second⁻¹ = (-D/(2*M)) + sqrt(((D/(2*M))^2 - K/M))
      λ2: Second⁻¹ = (-D/(2*M)) - sqrt(((D/(2*M))^2 - K/M))
      c1: Meter = (x0-F/K)*λ2/(λ2-λ1)
      c2: Meter = -c1*λ1/λ2

    for t in items(sim.t_seq):
      ans.add(c1*exp(λ1*t) + c2*exp(λ2*t) + F/K)

  elif cond == 0:
    let
      λ: Second⁻¹ = (-D/(2*M))
      c1: Meter = x0-F/K
      c2: Meter•Second⁻¹ = -c1*λ

    for t in items(sim.t_seq):
      ans.add(c1*exp(λ*t) + c2*t*exp(λ*t) + F/K)

  else:
    let
      λ1: Second⁻¹ = (-D/(2*M))
      λ2: Second⁻¹ = sqrt(-((D/(2*M))^2 - K/M))
      c1: Meter = x0-F/K
      c2: Meter = -c1*λ1/λ2

    for t in items(sim.t_seq):
      ans.add(exp(λ1*t)*(c1*cos(λ2*t)+c2*sin(λ2*t)) + F/K)
    
  return ans

# シンプルなバネマスダンパー系から成る2階非同次微分方程式
# M*(d²x/dt²) + D*(dx/dt) + k*x = f*sin(kt)を解き、軌跡seq[Meter]を得る 
proc responcesToForce*(sys: MassSpringDumper, force: SinForces, sim: SimParams ; x0 = 0.0.m): seq[Meter] =
  let
    M = sys.M
    K = sys.K
    D = sys.D
    ω = force.ω
    F = force.amp
    cond = (D^2 - 4*M*K).toFloat

    tmp1: Kilogram•Second⁻² = K - M*ω^2
    tmp2: Kilogram•Second⁻² = ω*D

    a = F*tmp1/(tmp1^2+tmp2^2)
    b = -F*tmp2/(tmp1^2+tmp2^2)

  var
    ans = newSeqofCap[Meter](sim.datanum)

  if cond > 0:
    let
      λ1: Second⁻¹ = (-D/(2*M)) + sqrt(((D/(2*M))^2 - K/M))
      λ2: Second⁻¹ = (-D/(2*M)) - sqrt(((D/(2*M))^2 - K/M))
      c1: Meter = ((b-x0)*λ2-a*ω)/(λ1-λ2)
      c2: Meter = -c1+x0-b

    for t in items(sim.t_seq):
      ans.add(c1*exp(λ1*t) + c2*exp(λ2*t) + a*sin(ω*t) + b*cos(ω*t))

  elif cond == 0:
    let
      λ: Second⁻¹ = (-D/(2*M))
      c1: Meter = x0-b
      c2: Meter•Second⁻¹ = -c1*λ-a*ω

    for t in items(sim.t_seq):
      ans.add(c1*exp(λ*t) + c2*t*exp(λ*t) + a*sin(ω*t) + b*cos(ω*t))

  else:
    let
      λ1: Second⁻¹ = (-D/(2*M))
      λ2: Second⁻¹ = sqrt(-((D/(2*M))^2 - K/M))
      c1: Meter = x0-b
      c2: Meter = -(a*ω+c1*λ1)/λ2

    for t in items(sim.t_seq):
      ans.add(exp(λ1*t)*(c1*cos(λ2*t)+c2*sin(λ2*t)) + a*sin(ω*t) + b*cos(ω*t))
    
  return ans
