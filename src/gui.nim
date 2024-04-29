################
# Initial setting
################

# std
import math, strutils
# import sequtils, sugar
# outer
import unchained, fidget
# original
import simulator

loadFont("IBM Plex Sans", "IBMPlexSans-Regular.ttf")
loadFont("IBM Plex Sans Bold", "IBMPlexSans-Bold.ttf")

const
  SLIDER_LENGTH = 150
  FRAC_LIM_MIN = 1.0
  FRAC_LIM_MAX = 10.0
  EXP_LIM_MIN = -10
  EXP_LIM_MAX = 10

  READIN_LIM_MIN = 1
  READIN_LIM_MAX = 10_000
  RESERVOIR_LIM_MIN = 1
  RESERVOIR_LIM_MAX = 10_000
  READOUT_LIM_MIN = 1
  READOUT_LIM_MAX = 1
  SPARSITY_LIM_MIN = 0.0
  SPARSITY_LIM_MAX = 1.0

var

  selectedTab = "ReferenceSystem"
  sliderM = false
  sliderK = false
  sliderD = false
  sliderM_knob = 40
  sliderK_knob = 60
  sliderD_knob = 90

  Mfrac: float = FRAC_LIM_MIN + (FRAC_LIM_MAX-FRAC_LIM_MIN)*(sliderM_knob-1)/(SLIDER_LENGTH-1)
  Kfrac: float = FRAC_LIM_MIN + (FRAC_LIM_MAX-FRAC_LIM_MIN)*(sliderK_knob-1)/(SLIDER_LENGTH-1)
  Dfrac: float = FRAC_LIM_MIN + (FRAC_LIM_MAX-FRAC_LIM_MIN)*(sliderD_knob-1)/(SLIDER_LENGTH-1)
  Mexp: int = 1
  Kexp: int = 1
  Dexp: int = 1

  Mfrac_str = ""
  Kfrac_str = ""
  Dfrac_str = ""
  Mexp_str = ""
  Kexp_str = ""
  Dexp_str = ""

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

proc reservoirSystemControls() =

  # Run button
  group "button":
    box 420, 250, 90, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      var
        message = simulateReservoirSystem(readinSize, reservoirSize, readoutSize, sparsity, seednum)
      echo message

    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "Run Reservoir"

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
          if READIN_LIM_MIN <= tmp and tmp <= READIN_LIM_MAX:
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
          if RESERVOIR_LIM_MIN <= tmp and tmp <= RESERVOIR_LIM_MAX:
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
          if READOUT_LIM_MIN <= tmp and tmp <= READOUT_LIM_MAX:
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
          if SPARSITY_LIM_MIN <= tmp and tmp <= SPARSITY_LIM_MAX:
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
      characters "reservoir system control panel"

proc referenceSystemControls() =

  group "slider":
    box 240, 80, SLIDER_LENGTH, 10
    onMouseDown:
      sliderM = true

    if sliderM:
      sliderM_knob = int(mouse.pos.x - current.screenBox.x)
      sliderM_knob = clamp(sliderM_knob, 1, SLIDER_LENGTH)
      sliderM = buttonDown[MOUSE_LEFT]
      
      Mfrac = FRAC_LIM_MIN + (FRAC_LIM_MAX-FRAC_LIM_MIN)*(sliderM_knob-1)/(SLIDER_LENGTH-1)
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

      Kfrac = FRAC_LIM_MIN + (FRAC_LIM_MAX-FRAC_LIM_MIN)*(sliderK_knob-1)/(SLIDER_LENGTH-1)
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

      Dfrac = FRAC_LIM_MIN + (FRAC_LIM_MAX-FRAC_LIM_MIN)*(sliderD_knob-1)/(SLIDER_LENGTH-1)
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


  # Run button
  group "button":
    box 420, 250, 90, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      var
        M = Mfrac*10.0.pow(Mexp.toFloat)
        K = Kfrac*10.0.pow(Kexp.toFloat)
        D = Dfrac*10.0.pow(Dexp.toFloat)
        message = simulateReferenceSystem(M, K, D)
      echo message

    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "Run RefSys"

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
          if FRAC_LIM_MIN <= tmp and tmp <= FRAC_LIM_MAX:
            Mfrac = tmp
            sliderM_knob = ((Mfrac-FRAC_LIM_MIN)/(FRAC_LIM_MAX-FRAC_LIM_MIN)*(SLIDER_LENGTH-1)).toInt+1
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
          if FRAC_LIM_MIN <= tmp and tmp <= FRAC_LIM_MAX:
            Kfrac = tmp
            sliderK_knob = ((Kfrac-FRAC_LIM_MIN)/(FRAC_LIM_MAX-FRAC_LIM_MIN)*(SLIDER_LENGTH-1)).toInt+1
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
          if FRAC_LIM_MIN <= tmp and tmp <= FRAC_LIM_MAX:
            Dfrac = tmp
            sliderD_knob = ((Dfrac-FRAC_LIM_MIN)/(FRAC_LIM_MAX-FRAC_LIM_MIN)*(SLIDER_LENGTH-1)).toInt+1
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
          if EXP_LIM_MIN <= tmp and tmp <= EXP_LIM_MAX:
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
          if EXP_LIM_MIN <= tmp and tmp <= EXP_LIM_MAX:
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
          if EXP_LIM_MIN <= tmp and tmp <= EXP_LIM_MAX:
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
      characters "reference system control panel"

proc drawMain() =
  setTitle("kodama GUI")

  # There are no relation between component size & windowsize at defaut. 
  # component, frame, recなどは左上(0, 0)基準

  component "ice-UI":
    box root.box
    fill "#ffffff"
    
    frame "verticalTabs":
      box 0, 15, 100, 100
      layout lmVertical
      counterAxisSizingMode csAuto
      horizontalPadding 0
      verticalPadding 0
      itemSpacing 0

      for tabName in ["Readme", "ReservoirSystem", "ReferenceSystem"]:
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
      of "ReferenceSystem":
        referenceSystemControls()
      of "ReservoirSystem":
        reservoirSystemControls()
      of "Readme":
        basicText()

proc drawWindow*() =
  # なんでかわからんがstartFidgetの(w, h)は左下基準っぽい
  startFidget(drawMain, w = 530, h = 300)
