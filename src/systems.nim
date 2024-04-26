import unchained, math

defUnit(Meter•Second⁻¹)
defUnit(Meter•Second⁻²)
defUnit(Newton•Meter⁻¹) # バネ定数
defUnit(Newton•s•Meter⁻¹) # ダンパー係数

################
# Systems
################

# objects
type
  mass_spring_dumper* = object
    M*: KiloGram
    K*: Newton•Meter⁻¹
    D*: Newton•s•Meter⁻¹

proc new_mass_spring_dumper*(m: float, k: float, d: float): mass_spring_dumper =
  return mass_spring_dumper(M: m.kg, K: k.N•m⁻¹, D: d.N•s•m⁻¹) 

# functions
proc GetVfromX*(Δt: Second, x0: Meter, x1: Meter): Velocity =
  let V = (x1 - x0)/Δt
  return V

proc GetAfromX*(Δt: Second, x0: Meter, x1: Meter, x2: Meter): Acceleration =
  let A = ((x0-x1)-(x1-x2))/Δt^2
  return A

# シンプルなバネマスダンパー系から成る2階非同次微分方程式
# M*(d²x/dt²) + D*(dx/dt) + k*x = f(.const)を解き、軌跡seq[Meter]を得る 
proc mass_spring_dumper_responces_to_f*(sys: mass_spring_dumper, ts: seq[Second], f: Newton, x0: Meter): seq[Meter] =
  let M = sys.M
  let K = sys.K
  let D = sys.D
  let λ1: Second⁻¹ = (-D/(2*M)) + sqrt(((D/(4*M))^2 - K/M))
  let λ2: Second⁻¹ = (-D/(2*M)) - sqrt(((D/(4*M))^2 - K/M))
  let c1: Meter = (λ2/(λ2-λ1))*x0
  let c2: Meter = (λ1/(λ1-λ2))*x0

  var ans = newSeqofCap[Meter](len(ts))

  for t in items(ts):
    ans.add(c1*exp(λ1*t) + c2*exp(λ2*t) + f/K)

  return ans

# シンプルなバネマスダンパー系から成る2階非同次微分方程式
# M*(d²x/dt²) + D*(dx/dt) + k*x = f*sin(kt)を解き、軌跡seq[Meter]を得る 
proc mass_spring_dumper_responces_to_sin_kt*(sys: mass_spring_dumper, ts: seq[Second], f: Newton, ω: Second⁻¹, x0: Meter): seq[Meter] =
  let M = sys.M
  let K = sys.K
  let D = sys.D
  let λ1: Second⁻¹ = (-D/(2*M)) + sqrt(((D/(4*M))^2 - K/M))
  let λ2: Second⁻¹ = (-D/(2*M)) - sqrt(((D/(4*M))^2 - K/M))
  let c1: Meter = (λ2/(λ2-λ1))*x0
  let c2: Meter = (λ1/(λ1-λ2))*x0
  let tmp1: Kilogram•Second⁻² = K - ω^2 * M
  let tmp2: Kilogram•Second⁻² = ω*D

  var ans = newSeqofCap[Meter](len(ts))

  for t in items(ts):
    ans.add(c1*exp(λ1*t) + c2*exp(λ2*t) + tmp1/(tmp1^2 + tmp2^2) * f * sin(ω*t) + tmp2/(tmp1^2 + tmp2^2) * f * cos(ω*t))

  return ans
