#[
  TODO:
  - l1803
    - run/learn Reservoirに際して、リザバー内部状態が初期化されないまま諸々の処理が行われている
      - これはおそらくリザバー側が関数呼び出し時に自動的に内部状態を初期化しておくべきだと思う
  - Overall
    - 現状、エラー処理が場当たり的すぎて前後の処理が影響されてしまっている
      - Result型によるエラー処理を徹底
    - SinForces/ConstForcesについて、今後Sin波以外の入力波形を入れたいとなった際の拡張性を担保するため、静的に動的ディスパッチっぽいことがしたい
      - Forcesという型に統一して、内部に波形情報(wavetype="sin"みたいな)を入れよう
    - 全体的な方針として、「オブジェクトを生のまま扱う」のはやめたい
    - for文で回せないから、複数のデータを扱いたいときに書き換える場所が増える
      - seq[obj]を基本の型にすることで、性能への影響を最小限にしつつ開放閉鎖原則を守ろう
]#

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

  KNOB_GAP = 20
  TEXTINPUT_HEIGHT = 24
  TEXTINPUT_GAP = 12

  DATANUMω_MIN = 1
  DATANUMω_MAX = 100
  DATANUMF_MIN = 1
  DATANUMF_MAX = 100

var

  # Frags
  selectedTab = "InputSettings"

  isholdingReservoir = false
  isholdingSimIns = false
  isholdingInputF = false
  isholdingRefOutputX = false
  isholdingReservoirOutX = false

  datanumω = 12
  datanumF = 8
  datanumω_str = ""
  datanumF_str = ""
  mode_ω_span = false
  mode_F_span = false

  # States of GUI
  simParamsInsSeq: seq[SimParams]
  reservoirIns: ReservoirSystem
  inputFsinInsSeq: seq[SinForces]
  refOutputXSeq_unitless: seq[seq[float]]
  reservoirOutputXSeq_unitless: seq[seq[float]]

  # for simulator
  time = 30.0
  Δt = 0.1

  # for input (force)
  sliderω = false
  sliderω1 = false
  sliderω2 = false
  sliderF = false
  sliderF1 = false
  sliderF2 = false
  sliderω_knob = 60
  sliderF_knob = 60

  sliderω1_knob = 20
  sliderω2_knob = 60
  sliderF1_knob = 20
  sliderF2_knob = 60

  ωfrac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderω_knob-1)/(SLIDER_LENGTH-1)
  Ffrac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderF_knob-1)/(SLIDER_LENGTH-1)
  ωexp: int = 0
  Fexp: int = 0

  ω1frac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderω_knob-1)/(SLIDER_LENGTH-1)
  ω2frac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderω_knob-1)/(SLIDER_LENGTH-1)
  F1frac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderF_knob-1)/(SLIDER_LENGTH-1)
  F2frac: float = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderF_knob-1)/(SLIDER_LENGTH-1)
  ω1exp: int = 0
  ω2exp: int = 0
  F1exp: int = 0
  F2exp: int = 0

  ωexp_str = ""
  Fexp_str = ""
  ωfrac_str = ""
  Ffrac_str = ""

  ω1exp_str = ""
  ω2exp_str = ""
  F1exp_str = ""
  F2exp_str = ""
  ω1frac_str = ""
  ω2frac_str = ""
  F1frac_str = ""
  F2frac_str = ""

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

  group "mode_ω_span":
    box 175, 230, 91, 20
    onClick:
      mode_ω_span = not mode_ω_span
    rectangle "square":
      box 0, 2, 16, 16

      if mode_ω_span:
        fill "#9FE7F8"
      else:
        fill "#ffffff"
      stroke "#70bdcf"
      cornerRadius 5
      strokeWeight 1
    text "text":
      box 21, 0, 70, 20

      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hLeft, vCenter
      characters "ω_span"

  group "datanum_ω":
    box 175, 260, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding datanumω_str
      try:
        if datanumω_str != "":
          let tmp = datanumω_str.parseInt
          if DATANUMω_MIN <= tmp and tmp <= DATANUMω_MAX:
            datanumω = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
      
      except ValueError:
        if len($datanumω) >= 5:
          datanumω_str = ($datanumω)[0..4]
        else:
          datanumω_str = $datanumω 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if datanumω_str == "":
        if len($datanumω) >= 5:
          characters ($datanumω)[0..4]
        else:
          characters $datanumω

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1


  group "mode_F_span":
    box 275, 230, 91, 20
    onClick:
      mode_F_span = not mode_F_span
    rectangle "square":
      box 0, 2, 16, 16

      if mode_F_span:
        fill "#9FE7F8"
      else:
        fill "#ffffff"
      stroke "#70bdcf"
      cornerRadius 5
      strokeWeight 1
    text "text":
      box 21, 0, 70, 20

      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 12, 200, 0, hLeft, vCenter
      characters "F_span"


  group "datanum_F":
    box 275, 260, 50, 24
    text "text":
      box 4, 2, 42, 20
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      binding datanumF_str
      try:
        if datanumF_str != "":
          let tmp = datanumF_str.parseInt
          if DATANUMF_MIN <= tmp and tmp <= DATANUMF_MAX:
            datanumF = tmp
          else:
            var e: ref ValueError
            new(e)
            raise(e) 
      
      except ValueError:
        if len($datanumF) >= 5:
          datanumF_str = ($datanumF)[0..4]
        else:
          datanumF_str = $datanumF 

    text "textPlaceholder":
      box 4, 2, 42, 20
      fill "#46607e", 0.5
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      if datanumF_str == "":
        if len($datanumF) >= 5:
          characters ($datanumF)[0..4]
        else:
          characters $datanumF

    rectangle "bg":
      box 0, 0, 50, 24
      stroke "#72bdd0"
      cornerRadius 5
      strokeWeight 1


  if not mode_ω_span:
    group "sliderω":
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

      rectangle "knob":
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

    # fraction
    group "input_ω":
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

    group "label":
      box 450, 74, 20, 30
      text "Text field:":
        box 0, 0, 20, 30
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
        characters "e"

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

  else:
    group "sliderω1":
      box 240, 80, SLIDER_LENGTH, 10
      onMouseDown:
        sliderω1 = true

      if sliderω1:
        sliderω1_knob = int(mouse.pos.x - current.screenBox.x)
        sliderω1_knob = clamp(sliderω1_knob, 1, SLIDER_LENGTH)
  
        ω1frac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderω1_knob-1)/(SLIDER_LENGTH-1)
        if len($ω1frac) >= 5:
          ω1frac_str = ($ω1frac)[0..4]
        else:
          ω1frac_str = $ω1frac

        sliderω1 = buttonDown[MOUSE_LEFT]

      rectangle "knob":
        box sliderω1_knob, 0, 10, 10
        fill "#72bdd0"
        cornerRadius 5
      rectangle "fill":
        box 0, 3, sliderω1_knob, 4
        fill "#70bdcf"
        cornerRadius 2
        strokeWeight 1
      rectangle "bg":
        box 0, 3, SLIDER_LENGTH, 4
        fill "#c2e3eb"
        cornerRadius 2
        strokeWeight 1


    # fraction
    group "input_ω1":
      box 400, 75, 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding ω1frac_str
        try:
          if ω1frac_str != "":
            let tmp = ω1frac_str.parseFloat
            if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
              ω1frac = tmp
              sliderω1_knob = ((ω1frac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
            else:
              var e: ref ValueError
              new(e)
              raise(e) 
        
        except ValueError:
          if len($ω1frac) >= 5:
            ω1frac_str = ($ω1frac)[0..4]
          else:
            ω1frac_str = $ω1frac 

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if ω1frac_str == "":
          if len($ω1frac) >= 5:
            characters ($ω1frac)[0..4]
          else:
            characters $ω1frac

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1

    group "label":
      box 450, 74, 20, 30
      text "Text field:":
        box 0, 0, 20, 30
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
        characters "e"

    # exponent
    group "input":
      box 470, 75, 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding ω1exp_str

        try:
          if ω1exp_str != "":
            let tmp = ω1exp_str.parseInt
            if EXP_MIN <= tmp and tmp <= EXP_MAX:
              ω1exp = tmp
            else:
              var e: ref ValueError
              new(e)
              raise(e)         
        except ValueError:
          ω1exp_str = $ω1exp

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if ω1exp_str == "":
          characters $ω1exp

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1


    group "sliderω2":
      box 240, 80 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), SLIDER_LENGTH, 10
      onMouseDown:
        sliderω2 = true

      if sliderω2:
        sliderω2_knob = int(mouse.pos.x - current.screenBox.x)
        sliderω2_knob = clamp(sliderω2_knob, 1, SLIDER_LENGTH)
  
        ω2frac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderω2_knob-1)/(SLIDER_LENGTH-1)
        if len($ω2frac) >= 5:
          ω2frac_str = ($ω2frac)[0..4]
        else:
          ω2frac_str = $ω2frac

        sliderω2 = buttonDown[MOUSE_LEFT]

      rectangle "knob":
        box sliderω2_knob, 0, 10, 10
        fill "#72bdd0"
        cornerRadius 5
      rectangle "fill":
        box 0, 3, sliderω2_knob, 4
        fill "#70bdcf"
        cornerRadius 2
        strokeWeight 1
      rectangle "bg":
        box 0, 3, SLIDER_LENGTH, 4
        fill "#c2e3eb"
        cornerRadius 2
        strokeWeight 1


    # fraction
    group "input_ω2":
      box 400, 75 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding ω2frac_str
        try:
          if ω2frac_str != "":
            let tmp = ω2frac_str.parseFloat
            if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
              ω2frac = tmp
              sliderω2_knob = ((ω2frac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
            else:
              var e: ref ValueError
              new(e)
              raise(e) 
        
        except ValueError:
          if len($ω2frac) >= 5:
            ω2frac_str = ($ω2frac)[0..4]
          else:
            ω2frac_str = $ω2frac 

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if ω2frac_str == "":
          if len($ω2frac) >= 5:
            characters ($ω2frac)[0..4]
          else:
            characters $ω2frac

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1

    group "label":
      box 450, 74 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 20, 30
      text "Text field:":
        box 0, 0, 20, 30
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
        characters "e"

    # exponent
    group "input":
      box 470, 75 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding ω2exp_str

        try:
          if ω2exp_str != "":
            let tmp = ω2exp_str.parseInt
            if EXP_MIN <= tmp and tmp <= EXP_MAX:
              ω2exp = tmp
            else:
              var e: ref ValueError
              new(e)
              raise(e)         
        except ValueError:
          ω2exp_str = $ω2exp

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if ω2exp_str == "":
          characters $ω2exp

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1

  if not mode_F_span:
    group "sliderF":
      box 240, 130 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), SLIDER_LENGTH, 10
      onMouseDown:
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

      rectangle "knob":
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

    # fraction
    group "input_F":
      box 400, 125 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 50, 24
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

    group "label":
      box 450, 124 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 20, 30
      text "Text field:":
        box 0, 0, 20, 30
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
        characters "e"

    # exponent
    group "input":
      box 470, 125 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 50, 24
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
        if Fexp_str == "":
          characters $Fexp

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1

  else:
    group "sliderF1":
      box 240, 130 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), SLIDER_LENGTH, 10
      onMouseDown:
        sliderF1 = true
      if sliderF1:
        sliderF1_knob = int(mouse.pos.x - current.screenBox.x)
        sliderF1_knob = clamp(sliderF1_knob, 1, SLIDER_LENGTH)
  
        F1frac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderF1_knob-1)/(SLIDER_LENGTH-1)
        if len($F1frac) >= 5:
          F1frac_str = ($F1frac)[0..4]
        else:
          F1frac_str = $F1frac

        sliderF1 = buttonDown[MOUSE_LEFT]

      rectangle "knob":
        box sliderF1_knob, 0, 10, 10
        fill "#72bdd0"
        cornerRadius 5
      rectangle "fill":
        box 0, 3, sliderF1_knob, 4
        fill "#70bdcf"
        cornerRadius 2
        strokeWeight 1
      rectangle "bg":
        box 0, 3, SLIDER_LENGTH, 4
        fill "#c2e3eb"
        cornerRadius 2
        strokeWeight 1


    # fraction
    group "input_F1":
      box 400, 125 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding F1frac_str
        try:
          if F1frac_str != "":
            let tmp = F1frac_str.parseFloat
            if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
              F1frac = tmp
              sliderF1_knob = ((F1frac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
            else:
              var e: ref ValueError
              new(e)
              raise(e) 
        
        except ValueError:
          if len($F1frac) >= 5:
            F1frac_str = ($F1frac)[0..4]
          else:
            F1frac_str = $F1frac 

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if F1frac_str == "":
          if len($F1frac) >= 5:
            characters ($F1frac)[0..4]
          else:
            characters $F1frac

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1

    group "label":
      box 450, 124 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 20, 30
      text "Text field:":
        box 0, 0, 20, 30
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
        characters "e"

    # exponent
    group "input":
      box 470, 125 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding F1exp_str

        try:
          if F1exp_str != "":
            let tmp = F1exp_str.parseInt
            if EXP_MIN <= tmp and tmp <= EXP_MAX:
              F1exp = tmp
            else:
              var e: ref ValueError
              new(e)
              raise(e)         
        except ValueError:
          F1exp_str = $F1exp

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if F1exp_str == "":
          characters $F1exp

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1


    group "sliderF2":
      box 240, 130 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP)*2, SLIDER_LENGTH, 10
      onMouseDown:
        sliderF2 = true
      if sliderF2:
        sliderF2_knob = int(mouse.pos.x - current.screenBox.x)
        sliderF2_knob = clamp(sliderF2_knob, 1, SLIDER_LENGTH)
  
        F2frac = FRAC_MIN + (FRAC_MAX-FRAC_MIN)*(sliderF2_knob-1)/(SLIDER_LENGTH-1)
        if len($F2frac) >= 5:
          F2frac_str = ($F2frac)[0..4]
        else:
          F2frac_str = $F2frac

        sliderF2 = buttonDown[MOUSE_LEFT]

      rectangle "knob":
        box sliderF2_knob, 0, 10, 10
        fill "#72bdd0"
        cornerRadius 5
      rectangle "fill":
        box 0, 3, sliderF2_knob, 4
        fill "#70bdcf"
        cornerRadius 2
        strokeWeight 1
      rectangle "bg":
        box 0, 3, SLIDER_LENGTH, 4
        fill "#c2e3eb"
        cornerRadius 2
        strokeWeight 1


    # fraction
    group "input_F2":
      box 400, 125 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP)*2, 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding F2frac_str
        try:
          if F2frac_str != "":
            let tmp = F2frac_str.parseFloat
            if FRAC_MIN <= tmp and tmp <= FRAC_MAX:
              F2frac = tmp
              sliderF2_knob = ((F2frac-FRAC_MIN)/(FRAC_MAX-FRAC_MIN)*(SLIDER_LENGTH-1)).toInt+1
            else:
              var e: ref ValueError
              new(e)
              raise(e) 
        
        except ValueError:
          if len($F2frac) >= 5:
            F2frac_str = ($F2frac)[0..4]
          else:
            F2frac_str = $F2frac 

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if F2frac_str == "":
          if len($F2frac) >= 5:
            characters ($F2frac)[0..4]
          else:
            characters $F2frac

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1

    group "label":
      box 450, 124 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP)*2, 20, 30
      text "Text field:":
        box 0, 0, 20, 30
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 16, 200, 0, hCenter, vCenter
        characters "e"

    # exponent
    group "input":
      box 470, 125 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP)*2, 50, 24
      text "text":
        box 4, 2, 42, 20
        fill "#46607e"
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        binding F2exp_str

        try:
          if F2exp_str != "":
            let tmp = F2exp_str.parseInt
            if EXP_MIN <= tmp and tmp <= EXP_MAX:
              F2exp = tmp
            else:
              var e: ref ValueError
              new(e)
              raise(e)         
        except ValueError:
          F2exp_str = $F2exp

      text "textPlaceholder":
        box 4, 2, 42, 20
        fill "#46607e", 0.5
        strokeWeight 1
        font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
        if F2exp_str == "":
          characters $F2exp

      rectangle "bg":
        box 0, 0, 50, 24
        stroke "#72bdd0"
        cornerRadius 5
        strokeWeight 1


  group "button":
    box 420, 250, 90, 20
    cornerRadius 5    
    fill "#72bdd0"
    onHover:
      fill "#5C8F9C"
    onDown:
      fill "#3E656F"
      if not mode_ω_span:
        datanumω = 1
      if not mode_F_span:
        datanumF = 1
      var
        ω = newSeq[float](datanumω)
        ω_min = ω1frac*10.0.pow(ω1exp.toFloat)
        ω_max = ω2frac*10.0.pow(ω2exp.toFloat)
      for i in 0..<datanumω:
        ω[i] = ω_min + i/(datanumω-1)*(ω_max-ω_min)

      var
        F = newSeq[float](datanumF)
        F_min = F1frac*10.0.pow(F1exp.toFloat)
        F_max = F2frac*10.0.pow(F2exp.toFloat)
      for i in 0..<datanumF:
        F[i] = F_min + i/(datanumF-1)*(F_max-F_min)

      simParamsInsSeq = newSeq[SimParams](datanumω*datanumF)
      inputFsinInsSeq = newSeq[SinForces](datanumω*datanumF)

      for i in 0..<datanumω:
        for j in 0..<datanumF:
          var idx = i*(datanumF-1)+j
          simParamsInsSeq[idx] = (newSimParams(time, Δt))
          inputFsinInsSeq[idx] = (newSinForces(ω[i], F[j], simParamsInsSeq[idx].t_seq.map(x => x.toFloat)))
      echo "simulator parameters spawned"

      isholdingSimIns = true
      isholdingInputF = true

    text "text":
      box 0, 0, 90, 20
      fill "#ffffff"
      font "IBM Plex Sans", 12, 200, 0, hCenter, vCenter
      characters "spawn"

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
    box 150, 120 + (TEXTINPUT_HEIGHT+TEXTINPUT_GAP), 60, 30
    text "Text field:":
      box 0, 0, 360, 30
      fill "#46607e"
      strokeWeight 1
      font "IBM Plex Sans", 15, 200, 0, hLeft, vCenter
      characters "F [N]"

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

    rectangle "knob":
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

    rectangle "knob":
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

    rectangle "knob":
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

        refOutputXSeq_unitless = newSeq[newSeq[float]()]()
        for i in 0..<len(simParamsInsSeq):
          var
            output = simulateReferenceSystem(M, K, D, simParamsInsSeq[i], inputFsinInsSeq[i], isPlotting=false)
          if output[0][0..5] != "ERROR:":
            echo output[0]
            refOutputXSeq_unitless.add(output[1].map(x => x.toFloat))
            isholdingRefOutputX = true
          else:
            echo output[0]
      else:
        echo "simulator setting is not done yet"

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
          for i in 0..<len(simParamsInsSeq):
            var
              output = reservoirIns.simulateReservoirSystem(readinSize, reservoirSize, readoutSize, sparsity, seednum, simParamsInsSeq[i], inputFsinInsSeq[i], isPlotting=true)
            if output[0][0..5] != "ERROR:":
              echo output[0]
              reservoirOutputXSeq_unitless.add(output[1].map(x => x.toFloat))
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
        var tmpXs = newSeq[newSeq[float]()]()
        var tmpFs = newSeq[newSeq[float]()]()
        for i in 0..<len(inputFsinInsSeq):
          tmpXs.add(refOutputXSeq_unitless[i])
          tmpFs.add(inputFsinInsSeq[i].Fseq.map(x => x.toFloat))
        var output = reservoirIns.simulateReservoirLearning(
          tmpXs, 
          tmpFs, 
          iter=N, η=η
        )

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

    rectangle "knob":
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

    rectangle "knob":
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
  startFidget(drawMain, w = 720, h = 400)
