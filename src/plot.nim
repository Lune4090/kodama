import plotly, chroma, unchained, sequtils, sugar

proc plot_inF_outXVA*(ts: seq[Second], inF: seq[Newton], outX: seq[Meter], outV: seq[Meter•Second⁻¹], outA: seq[Meter•Second⁻²], color_in1: seq[Color], color_out1: seq[Color], color_out2: seq[Color], color_out3: seq[Color]) =

  var
    d1_in  = Trace[float](mode: PlotMode.Lines, `type`: PlotType.Scatter)
    d1_out = Trace[float](mode: PlotMode.Lines, `type`: PlotType.Scatter)
    d2_out = Trace[float](mode: PlotMode.Lines, `type`: PlotType.Scatter)
    d3_out = Trace[float](mode: PlotMode.Lines, `type`: PlotType.Scatter)

  d1_in.marker = Marker[float](color: color_in1)
  d1_in.xs = ts.map(t => t.toFloat)
  d1_in.ys = inF.map(x => x.toFloat)
  d1_out.marker = Marker[float](color: color_out1)
  d1_out.xs = ts.map(t => t.toFloat)
  d1_out.ys = outX.map(x => x.toFloat)
  d2_out.marker = Marker[float](color: color_out2)
  d2_out.xs = ts.map(t => t.toFloat)
  d2_out.ys = outV.map(v => v.toFloat)
  d3_out.marker = Marker[float](color: color_out3)
  d3_out.xs = ts.map(t => t.toFloat)
  d3_out.ys = outA.map(a => a.toFloat)

  let
    layout_out = Layout(title: "input_output in t-region", 
                    width: 1200, height: 400,
                    xaxis: Axis(title: "time [s]"),
                    yaxis: Axis(title: "amplitude [N, m, m/s, m/s²]"),
                    autosize: false)
    p_out = Plot[float](layout: layout_out, traces: @[d1_in, d1_out, d2_out, d3_out])

  p_out.show()
