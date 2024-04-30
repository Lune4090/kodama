################
# Initial setting
################

# std
import math, strutils, sequtils, sugar
# outer
import unchained, fidget, arraymancer
# original
import parameters, dynamics, simulator, reservoir

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")
loadFont("IBM Plex Sans Bold", "IBMPlexSans-Bold.ttf")

const
  SLIDER_LENGTH = 150
  FRAC_MIN = 1.0
  FRAC_MAX = 10.0
  EXP_MIN = -10
  EXP_MAX = 10

  READIN_MIN = 1
  READIN_MAX = 10_000
  RESERVOIR_MIN = 1
  RESERVOIR_MAX = 10_000
  READOUT_MIN = 1
  READOUT_MAX = 1
  SPARSITY_MIN = 0.0
  SPARSITY_MAX = 1.0

  LEARNINGRATE_MIN = 0.0
  LEARNINGRATE_MAX = 1.0
  ITERATION_MAX = 1000
  ITERATION_MIN = 1
  

var

  # Frags
  selectedTab = "InputSettings"

  isholdingReservoir = false
  isholdingSimIns = false
  isholdingInputF = false
  isholdingRefOutputX = false
  isholdingReservoirOutX = false

  # States of GUI
  simParamsIns: SimParams
  reservoirIns: ReservoirSystem
  inputFsinIns: SinForces
  refOutputX_unitless: seq[float]
  reservoirOutputX_unitless: seq[float]

  # for simulator
  time = 30.0
  Δt = 0.1

  # for input (force)
  sliderω = false
  sliderF = false
  sliderω_knob = 60
  sliderF_knob = 60

  ωfrac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderω_knob-1)/(SLIDER_LENGTH-1)
  Ffrac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderF_knob-1)/(SLIDER_LENGTH-1)
  ωexp: int = 0
  Fexp: int = 0

  ωexp_str = ""
  Fexp_str = ""
  ωfrac_str = ""
  Ffrac_str = ""

  # for output
  sliderM = false
  sliderK = false
  sliderD = false
  sliderM_knob = 40
  sliderK_knob = 60
  sliderD_knob = 90

  Mfrac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderM_knob-1)/(SLIDER_LENGTH-1)
  Kfrac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderK_knob-1)/(SLIDER_LENGTH-1)
  Dfrac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderD_knob-1)/(SLIDER_LENGTH-1)
  Mexp: int = 0
  Kexp: int = 0
  Dexp: int = 0

  Mfrac_str = ""
  Kfrac_str = ""
  Dfrac_str = ""
  Mexp_str = ""
  Kexp_str = ""
  Dexp_str = ""

  # for learning
  sliderη = false
  sliderN = false
  sliderη_knob = 60
  sliderN_knob = 60

  η: float = LEARNINGRATE_MIN + (LEARNINGRATE_MAX-LEARNINGRATE_MIN)*(sliderη_knob-1)/(SLIDER_LENGTH-1)
  N: int = ITERATION_MIN + ((ITERATION_MAX-ITERATION_MIN)*(sliderN_knob-1)/(SLIDER_LENGTH-1)).toInt

  η_str = ""
  N_str = ""

  readinSize: int = 10
  reservoirSize: int = 10
  readoutSize: int = 1
  sparsity: range[0.0..1.0] = 0.95
  seednum: int = 0

  readinSize_str: string = ""
  reservoirSize_str: string = ""
  readoutSize_str: string = ""
  sparsity_str: string = ""
  seednum_str: string = ""

proc basicText() =
  frame "autoLayoutText":
    box 130, 0, root.box.w - 130, 491
    fill "#ffffff"
    layout lmVertical
    counterAxisSizingMode csFixed
    horizontalPadding 30
    verticalPadding 30
    itemSpacing 10
    text "p1":
      box 30, 72, 326, 100
      fill "#000000"
      font "IBM Plex Sans", 14, 400, 20, hLeft, vTop
      characters "This is library documents."
      textAutoResize tsHeight
      layoutAlign laStretch
    text "title1":
      box 30, 30, 326, 32
      fill "#000000"
      font "IBM Plex Sans", 20, 400, 32, hLeft, vTop
      characters "hoge"
      textAutoResize tsHeight
      layoutAlign laStretch


proc inputSettings() =

  group "slider":
    box 240, 80, SLIDER_LENGTH, 10
    onMouseDown:
      sliderω = true

    if sliderω:
      sliderω_knob = int(mouse.pos.x - current.screenBox.x)
      sliderω_knob = clamp(sliderω_knob, 1, SLIDER_LENGTH)
      sliderω = buttonDown[MOUSE_LEFT]
      
      ωfrac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderω_knob-1)/(SLIDER_LENGTH-1)
      if len($ωfrac) >= 5:
        ωfrac_str = ($ωfrac)[0..4]
      else:
        ωfrac_str = $ωfrac

    rectangle "pip":
      box sliderω_knob, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, sliderω_knob, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, SLIDER_LENGTH, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1

  group "slider":
    box 240, 130, SLIDER_LENGTH, 10
    onClick:
      sliderF = true

    if sliderF:
      sliderF_knob = int(mouse.pos.x - current.screenBox.x)
      sliderF_knob = clamp(sliderF_knob, 1, SLIDER_LENGTH)
      sliderF = buttonDown[MOUSE_LEFT]

      Ffrac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderF_knob-1)/(SLIDER_LENGTH-1)
      if len($Ffrac) >= 5:
        Ffrac_str = ($Ffrac)[0..4]
      else:
        Ffrac_str = $Ffrac

    rectangle "pip":
      box sliderF_knob, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, sliderF_knob, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, SLIDER_LENGTH, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1

  group "button":
    box 420, 250, 90, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      var
        F = Ffrac*10.0.pow(Fexp.toFloat)
        ω = ωfrac*10.0.pow(ωexp.toFloat)

      simParamsIns = newSimParams(time, Δt)
      inputFsinIns = newSinForces(ω, F, simParamsIns.t_seq.map(x => x.toFloat))

      isholdingSimIns = true
      isholdingInputF = true
      echo "simulator parameters spawned"

    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "spawn"

  # fraction
  group "input":
    box 400, 75, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding ωfrac_str
      try:
        if ωfrac_str != "":
          let tmp = ωfrac_str.parseFloat
          if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
            ωfrac = tmp
            sliderω_knob = ((ωfrac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        if len($ωfrac) >= 5:
          ωfrac_str = ($ωfrac)[0..4]
        else:
          ωfrac_str = $ωfrac 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if ωfrac_str == "":
        if len($ωfrac) >= 5:
          characters ($ωfrac)[0..4]
        else:
          characters $ωfrac

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  # exponent
  group "input":
    box 470, 75, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding ωexp_str

      try:
        if ωexp_str != "":
          let tmp = ωexp_str.parseInt
          if EXP_MIN <= tmp and tmp <= EXP_MAX:
            ωexp = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e)         
      except ValueError:
        ωexp_str = $ωexp

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if ωexp_str == "":
        characters $ωexp

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if ωexp_str == "":
        characters $ωexp

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  # fraction
  group "input":
    box 400, 125, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Ffrac_str
      try:
        if Ffrac_str != "":
          let tmp = Ffrac_str.parseFloat
          if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
            Ffrac = tmp
            sliderF_knob = ((Ffrac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        if len($Ffrac) >= 5:
          Ffrac_str = ($Ffrac)[0..4]
        else:
          Ffrac_str = $Ffrac 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Ffrac_str == "":
        if len($Ffrac) >= 5:
          characters ($Ffrac)[0..4]
        else:
          characters $Ffrac

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  # exponent
  group "input":
    box 470, 125, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Fexp_str

      try:
        if Fexp_str != "":
          let tmp = Fexp_str.parseInt
          if EXP_MIN <= tmp and tmp <= EXP_MAX:
            Fexp = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e)         
      except ValueError:
        Fexp_str = $Fexp

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if ωexp_str == "":
        characters $ωexp

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Fexp_str == "":
        characters $Fexp

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1
      
  # labels
  group "label":
    box 150, 70, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "ω [s⁻¹]"

  group "label":
    box 150, 120, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "F [N]"

  group "label":
    box 450, 74, 20, 30
    text "Text field:":
      box 0, 0, 20, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
      characters "e"

  group "label":
    box 450, 124, 20, 30
    text "Text field:":
      box 0, 0, 20, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
      characters "e"

  group "label":
    box 150, 20, 360, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 20, 200, 0, hLeft, vCenter
      characters "input setting control panel"

proc referenceSettings() =

  group "slider":
    box 240, 80, SLIDER_LENGTH, 10
    onMouseDown:
      sliderM = true

    if sliderM:
      sliderM_knob = int(mouse.pos.x - current.screenBox.x)
      sliderM_knob = clamp(sliderM_knob, 1, SLIDER_LENGTH)
      sliderM = buttonDown[MOUSE_LEFT]
      
      Mfrac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderM_knob-1)/(SLIDER_LENGTH-1)
      if len($Mfrac) >= 5:
        Mfrac_str = ($Mfrac)[0..4]
      else:
        Mfrac_str = $Mfrac

    rectangle "pip":
      box sliderM_knob, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, sliderM_knob, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, SLIDER_LENGTH, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1

  group "slider":
    box 240, 130, SLIDER_LENGTH, 10
    onClick:
      sliderK = true

    if sliderK:
      sliderK_knob = int(mouse.pos.x - current.screenBox.x)
      sliderK_knob = clamp(sliderK_knob, 1, SLIDER_LENGTH)
      sliderK = buttonDown[MOUSE_LEFT]

      Kfrac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderK_knob-1)/(SLIDER_LENGTH-1)
      if len($Kfrac) >= 5:
        Kfrac_str = ($Kfrac)[0..4]
      else:
        Kfrac_str = $Kfrac

    rectangle "pip":
      box sliderK_knob, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, sliderK_knob, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, SLIDER_LENGTH, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1

  group "slider":
    box 240, 180, SLIDER_LENGTH, 10
    onClick:
      sliderD = true

    if sliderD:
      sliderD_knob = int(mouse.pos.x - current.screenBox.x)
      sliderD_knob = clamp(sliderD_knob, 1, SLIDER_LENGTH)
      sliderD = buttonDown[MOUSE_LEFT]

      Dfrac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderD_knob-1)/(SLIDER_LENGTH-1)
      if len($Dfrac) >= 5:
        Dfrac_str = ($Dfrac)[0..4]
      else:
        Dfrac_str = $Dfrac

    rectangle "pip":
      box sliderD_knob, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, sliderD_knob, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, SLIDER_LENGTH, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1


  group "button":
    box 420, 250, 90, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      if isholdingSimIns == true and isholdingInputF == true:
        var
          M = Mfrac*10.0.pow(Mexp.toFloat)
          K = Kfrac*10.0.pow(Kexp.toFloat)
          D = Dfrac*10.0.pow(Dexp.toFloat)
          output = simulateReferenceSystem(M, K, D, simParamsIns, inputFsinIns)
        if output[0][0..5] != "ERROR:":
          echo output[0]
          refOutputX_unitless = output[1].map(x => x.toFloat)
          isholdingRefOutputX = true
        else:
          echo output[0]

    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "spawn"

  # fraction
  group "input":
    box 400, 75, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Mfrac_str
      try:
        if Mfrac_str != "":
          let tmp = Mfrac_str.parseFloat
          if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
            Mfrac = tmp
            sliderM_knob = ((Mfrac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        if len($Mfrac) >= 5:
          Mfrac_str = ($Mfrac)[0..4]
        else:
          Mfrac_str = $Mfrac 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Mfrac_str == "":
        if len($Mfrac) >= 5:
          characters ($Mfrac)[0..4]
        else:
          characters $Mfrac

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 400, 125, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Kfrac_str

      try:
        if Kfrac_str != "":
          let tmp = Kfrac_str.parseFloat
          if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
            Kfrac = tmp
            sliderK_knob = ((Kfrac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        if len($Kfrac) >= 5:
          Kfrac_str = ($Kfrac)[0..4]
        else:
          Kfrac_str = $Kfrac
          
    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Kfrac_str == "":
        if len($Kfrac) >= 5:
          characters ($Kfrac)[0..4]
        else:
          characters $Kfrac
    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 400, 175, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Dfrac_str

      try:
        if Dfrac_str != "":
          let tmp = Dfrac_str.parseFloat
          if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
            Dfrac = tmp
            sliderD_knob = ((Dfrac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        if len($Dfrac) >= 5:
          Dfrac_str = ($Dfrac)[0..4]
        else:
          Dfrac_str = $Dfrac

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Dfrac_str == "":
        if len($Dfrac) >= 5:
          characters ($Dfrac)[0..4]
        else:
          characters $Dfrac
    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  # exponent
  group "input":
    box 470, 75, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Mexp_str

      try:
        if Mexp_str != "":
          let tmp = Mexp_str.parseInt
          if EXP_MIN <= tmp and tmp <= EXP_MAX:
            Mexp = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e)         
      except ValueError:
        Mexp_str = $Mexp

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Mexp_str == "":
        characters $Mexp

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 470, 125, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Kexp_str

      try:
        if Kexp_str != "":
          let tmp = Kexp_str.parseInt
          if EXP_MIN <= tmp and tmp <= EXP_MAX:
            Kexp = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e)         
      except ValueError:
        Kexp_str = $Kexp

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Kexp_str == "":
        characters $Kexp

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 470, 175, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding Dexp_str

      try:
        if Dexp_str != "":
          let tmp = Dexp_str.parseInt
          if EXP_MIN <= tmp and tmp <= EXP_MAX:
            Dexp = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e)         
      except ValueError:
        Dexp_str = $Dexp

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if Dexp_str == "":
        characters $Dexp

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1


  # labels
  group "label":
    box 150, 70, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "M [m]"

  group "label":
    box 150, 120, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "K [N/m]"

  group "label":
    box 150, 170, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "D [N•s/m]"

  group "label":
    box 450, 74, 20, 30
    text "Text field:":
      box 0, 0, 20, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
      characters "e"

  group "label":
    box 450, 124, 20, 30
    text "Text field:":
      box 0, 0, 20, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
      characters "e"

  group "label":
    box 450, 174, 20, 30
    text "Text field:":
      box 0, 0, 20, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
      characters "e"

  group "label":
    box 150, 20, 360, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 20, 200, 0, hLeft, vCenter
      characters "reference setting control panel"

proc reservoirSettings() =

  group "button":
    box 420, 250, 90, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      if isholdingSimIns == true and isholdingInputF == true and isholdingRefOutputX == true:
        reservoirIns = newReservoir(readinSize, reservoirSize, readoutSize, sparsity, seednum)
        isholdingReservoir = true
        echo "reservoir instance spawned"

    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "spawn"


  # fraction
  group "input":
    box 250, 75, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding readinSize_str
      try:
        if readinSize_str != "":
          let tmp = readinSize_str.parseInt
          if READIN_MIN <= tmp and tmp <= READIN_MAX:
            readinSize = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        readinSize_str = $readinSize 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if readinSize_str == "":
        characters $readinSize

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 250, 125, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding reservoirSize_str
      try:
        if reservoirSize_str != "":
          let tmp = reservoirSize_str.parseInt
          if RESERVOIR_MIN <= tmp and tmp <= RESERVOIR_MAX:
            reservoirSize = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        reservoirSize_str = $reservoirSize 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if reservoirSize_str == "":
        characters $reservoirSize
    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 250, 175, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding readoutSize_str

      try:
        if readoutSize_str != "":
          let tmp = readoutSize_str.parseInt
          if READOUT_MIN <= tmp and tmp <= READOUT_MAX:
            readoutSize = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        readoutSize_str = $readoutSize 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if readoutSize_str == "":
        characters $readoutSize
    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 450, 75, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding sparsity_str
      try:
        if sparsity_str != "":
          let tmp = sparsity_str.parseFloat
          if SPARSITY_MIN <= tmp and tmp <= SPARSITY_MAX:
            sparsity = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        sparsity_str = $sparsity 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if sparsity_str == "":
        characters $sparsity
    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 450, 125, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding seednum_str

      try:
        if seednum_str != "":
          let tmp = seednum_str.parseInt
          seednum = tmp
        
      except ValueError:
        seednum_str = $seednum 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if seednum_str == "":
        characters $seednum
    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "label":
    box 150, 70, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "readin size"

  group "label":
    box 150, 120, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "reservoir size"

  group "label":
    box 150, 170, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "readout size"

  group "label":
    box 350, 70, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "sparsity(0~1)"

  group "label":
    box 350, 120, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "seed number"

  group "label":
    box 150, 20, 360, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 20, 200, 0, hLeft, vCenter
      characters "reservoir setting control panel"


proc reservoirRunAndLearn() =

  group "button":
    box 420, 250, 90, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      if isholdingSimIns == true and isholdingInputF == true and isholdingRefOutputX == true:
        if isholdingReservoir == true:
          var
            output = reservoirIns.simulateReservoirSystem(readinSize, reservoirSize, readoutSize, sparsity, seednum, simParamsIns, inputFsinIns)
          if output[0][0..5] != "ERROR:":
            echo output[0]
            reservoirOutputX_unitless = output[1].map(x => x.toFloat)
            reservoirIns = output[4]
            isholdingReservoir = true
          else:
            echo output[0]
        else:
          echo "You must create reservoir instance."
      else:
        echo "You must create input parameters / reference instances."

    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "run"

  group "button":
    box 150, 250, 100, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      if isholdingSimIns == true and isholdingInputF == true and isholdingRefOutputX == true and isholdingReservoir == true:
        var
          output = reservoirIns.simulateReservoirLearning(refOutputX_unitless.toTensor, inputFsinIns.Fseq.map(x => x.toFloat).toTensor, iter=N, η=η)
        if output[0][0..5] != "ERROR:":
          echo output[0]
          echo output[1]
          reservoirIns = output[2]

      else:
        echo "first generate input force and simulate the reference system responces to it, then generate and simulate reservoir, finally, you will be able to start reservoir learning."

    text "text":
      box 0, 0, 100, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "learn"

  group "slider":
    box 240, 80, SLIDER_LENGTH, 10
    onMouseDown:
      sliderη = true

    if sliderη:
      sliderη_knob = int(mouse.pos.x - current.screenBox.x)
      sliderη_knob = clamp(sliderη_knob, 1, SLIDER_LENGTH)
      sliderη = buttonDown[MOUSE_LEFT]
      
      η = LEARNINGRATE_MIN + (LEARNINGRATE_MAX-LEARNINGRATE_MIN)*(sliderη_knob-1)/(SLIDER_LENGTH-1)
      if len($η) >= 5:
        η_str = ($η)[0..4]
      else:
        η_str = $η

    rectangle "pip":
      box sliderη_knob, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, sliderη_knob, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, SLIDER_LENGTH, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1

  group "slider":
    box 240, 130, SLIDER_LENGTH, 10
    onClick:
      sliderN = true

    if sliderN:
      sliderN_knob = int(mouse.pos.x - current.screenBox.x)
      sliderN_knob = clamp(sliderN_knob, 1, SLIDER_LENGTH)
      sliderN = buttonDown[MOUSE_LEFT]

      N = (ITERATION_MIN + (ITERATION_MAX-ITERATION_MIN)*(sliderN_knob-1)/(SLIDER_LENGTH-1)).round.toInt
      N_str = $N

    rectangle "pip":
      box sliderN_knob, 0, 10, 10
      fill "#72bdd0"
      cornerRadius 5
    rectangle "fill":
      box 0, 3, sliderN_knob, 4
      fill "#70bdcf"
      cornerRadius 2
      strokeWeight 1
    rectangle "bg":
      box 0, 3, SLIDER_LENGTH, 4
      fill "#c2e3eb"
      cornerRadius 2
      strokeWeight 1

  group "input":
    box 440, 75, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding η_str
      try:
        if η_str != "":
          let tmp = η_str.parseFloat
          if LEARNINGRATE_MIN <= tmp and tmp <= LEARNINGRATE_MAX:
            η = tmp
            sliderη_knob = ((η-LEARNINGRATE_MIN)/(LEARNINGRATE_MAX-LEARNINGRATE_MIN)*(SLIDER_LENGTH-1)).toInt+1
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
        
      except ValueError:
        if len($η) >= 5:
          η_str = ($η)[0..4]
        else:
          η_str = $η 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if η_str == "":
        if len($η) >= 5:
          characters ($η)[0..4]
        else:
          characters $η

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "input":
    box 440, 125, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding N_str

      try:
        if N_str != "":
          let tmp = N_str.parseInt
          if ITERATION_MIN <= tmp and tmp <= ITERATION_MAX:
            N = tmp
            sliderN_knob = ((N-ITERATION_MIN)/(ITERATION_MAX-ITERATION_MIN)*(SLIDER_LENGTH-1)).toInt+1
          else:
            var e: ref ValueError
            new(e)
            raise(e)         
      except ValueError:
        N_str = $N

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if N_str == "":
        characters $N

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if N_str == "":
        characters $N

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1

  group "label":
    box 150, 70, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "learning rate"

  group "label":
    box 150, 120, 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "iteration"

  group "label":
    box 150, 20, 360, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 20, 200, 0, hLeft, vCenter
      characters "reservoir run & learn control panel"


proc drawMain() =
  setTitle("kodama GUI")

  # There are no relation between component size & windowsize at defaut. 
  # component, frame, recなどは左上(0, 0)基準

  component "kodama GUI system":
    box root.box
    fill "#ffffff"
    
    frame "verticalTabs":
      box 0, 15, 100, 100
      layout lmVertical
      counterAxisSizingMode csAuto
      horizontalPadding 0
      verticalPadding 0
      itemSpacing 0

      for tabName in ["Readme", "ReservoirR&L", "ReservoirSettings", "ReferenceSettings", "InputSettings"]:
        group "tab":
          box 0, 0, 130, 30
          layoutAlign laCenter
          onHover:
            fill "#70bdcf", 0.5
          if selectedTab == tabName:
            fill "#70bdcf"
          onClick:
            selectedTab = tabName
          text "text":
            box 15, 0, 115, 30
            if selectedTab == tabName:
              fill "#ffffff"
            else:
              fill "#46607e"
            font "IBM Plex Sans", 12, 400, 12, hLeft, vCenter
            characters tabName
    
    rectangle "bg":
      box 0, 0, 130, 100
      constraints cMin, cStretch
      fill "#e5f7fe"

    case selectedTab:
      of "InputSettings":
        inputSettings()
      of "ReferenceSettings":
        referenceSettings()
      of "ReservoirSettings":
        reservoirSettings()
      of "ReservoirR&L":
        reservoirRunAndLearn()
      of "Readme":
        basicText()

proc drawWindow*() =
  startFidget(drawMain, w = 530, h = 300)
