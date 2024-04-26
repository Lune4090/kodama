import bumpy, pixie, font, rasterizer, tables, unicode, vmath

const
  normalLineHeight* = 0 ## Default line height of font.size * 1.2

type
  Font = font.Font

  Span* = object
    ## Represents a run of litter of same size and font.
    font: Font
    fontSize: float32
    # lineHeight: float32
    # tracking: float32
    text: string

  GlyphPosition* = object
    ## Represents a glyph position after typesetting.
    font*: Font
    fontSize*: float32
    subPixelShift*: float32
    rect*: Rect       # Where to draw the image character.
    selectRect*: Rect # Were to draw or hit selection.
    character*: string
    rune*: Rune
    count*: int
    index*: int

  HAlignMode* = enum
    ## Horizontal alignment mode.
    Left
    Center
    Right

  VAlignMode* = enum
    ## Vertical alignment mode.
    Top
    Middle
    Bottom

  TextCase* = enum
    tcNormal
    tcUpper
    tcLower
    tcTitle
    # tcSmallCaps
    # tcSmallCapsForced

proc convertTextCase*(s: string, textCase: TextCase): string =
  case textCase:
  of tcNormal: s
  of tcUpper: s.toUpper()
  of tcLower: s.toLower()
  of tcTitle: s.title()

proc kerningAdjustment*(font: Font, prev, c: string): float32 =
  ## Get Kerning Adjustment between two letters.
  if prev != "":
    var key = (prev, c)
    if font.typeface.kerning.hasKey(key):
      var kerning = font.typeface.kerning[key]
      return kerning

proc canWrap(rune: Rune): bool =
  if rune == Rune(32): return true # Early return for ascii space.
  if rune.isWhiteSpace(): return true
  if not rune.isAlpha(): return true

proc typeset*(
  font: Font,
  runes: seq[Rune],
  pos: Vec2 = vec2(0, 0),
  size: Vec2 = vec2(0, 0),
  hAlign: HAlignMode = Left,
  vAlign: VAlignMode = Top,
  clip = true,
  wrap = true,
  kern = true,
  textCase = tcNormal,
  tabWidth: float32 = 0.0,
  boundsMin: var Vec2,
  boundsMax: var Vec2
): seq[GlyphPosition] =
  ## Typeset runes and return glyph positions that is ready to draw.

  assert font.size != 0
  assert font.typeface != nil
  assert font.typeface.unitsPerEm != 0

  var
    at = pos
    lineStart = pos.x
    prev = ""
    ## Figure out why some times the scale is ignored this way:
    #scale = font.size / (font.ascent - font.descent)
    glyphCount = 0
    tabWidth = tabWidth

  if tabWidth == 0.0:
    tabWidth = font.size * 4

  var
    strIndex = 0
    glyphIndex = 0
    lastCanWrap = 0
    lineHeight = font.lineHeight

  if lineHeight == normalLineHeight:
    lineHeight = font.size

  let selectionHeight = max(font.size, lineHeight)

  at.y += font.baseline

  for rune in runes:
    var c = $rune
    if rune == Rune(10): # New line "\n".
      # Add special small width glyph on this line.
      var selectRect = rect(
        floor(at.x),
        floor(at.y) - font.baseline,
        font.typeface.glyphs[" "].advance * font.scale,
        selectionHeight
      )
      result.add GlyphPosition(
        font: font,
        fontSize: font.size,
        subPixelShift: 0,
        rect: rect(0, 0, 0, 0),
        selectRect: selectRect,
        rune: rune,
        character: c,
        count: glyphCount,
        index: strIndex
      )
      prev = c
      inc glyphCount
      strIndex += c.len

      at.x = lineStart
      at.y += lineHeight
      continue
    elif rune == Rune(9): # tab \t
      at.x = ceil(at.x / tabWidth) * tabWidth
      continue

    if canWrap(rune):
      lastCanWrap = glyphIndex + 1

    if c notin font.typeface.glyphs:
      # TODO: Make missing glyphs work better.
      c = " " # If glyph is missing use space for now.
      if c notin font.typeface.glyphs:
        ## Space is missing!?
        continue

    var glyph = font.typeface.glyphs[c]
    if kern:
      at.x += font.kerningAdjustment(prev, c) * font.scale

    let q =
      if font.size < 20: 0.1
      elif font.size < 25: 0.2
      elif font.size < 30: 0.5
      else: 1.0
    var subPixelShift = quantize(at.x - floor(at.x), q)
    var glyphPos = vec2(floor(at.x), floor(at.y))
    var glyphSize = font.getGlyphSize(glyph)

    if rune == Rune(32):
      glyphSize.x = glyph.advance * font.scale

    if glyphSize.x != 0 and glyphSize.y != 0:
      # Does it need to wrap?
      if wrap and size.x != 0 and at.x - pos.x + glyphSize.x > size.x:
        # Wrap to next line.
        let goBack = lastCanWrap - glyphIndex
        if lastCanWrap != -1 and goBack < 0:
          lastCanWrap = -1
          at.y += lineHeight
          if clip and size.y != 0 and at.y - pos.y > size.y:
            # Delete glyphs that would wrap into next line
            # that is clipped.
            result.setLen(result.len + goBack)
            return

          # Wrap glyphs on prev line down to next line.
          let shift = result[result.len + goBack].rect.x - pos.x
          for i in result.len + goBack ..< result.len:
            result[i].rect.x -= shift
            result[i].rect.y += lineHeight
            result[i].selectRect.x -= shift
            result[i].selectRect.y += lineHeight

          at.x -= shift
        else:
          at.y += lineHeight
          at.x = lineStart

        glyphPos = vec2(floor(at.x), floor(at.y))

      if clip and size.y != 0 and at.y - pos.y > size.y:
        # Reached the bottom of the area, clip.
        return

    var selectRect = rect(
      floor(at.x),
      floor(at.y) - font.baseline,
      glyphSize.x,
      selectionHeight
    )

    if result.len > 0:
      # Adjust selection rect width to next character
      if result[^1].selectRect.y == selectRect.y:
        result[^1].selectRect.w = floor(at.x) - result[^1].selectRect.x

    result.add GlyphPosition(
      font: font,
      fontSize: font.size,
      subPixelShift: subPixelShift,
      rect: rect(glyphPos, glyphSize),
      selectRect: selectRect,
      character: c,
      rune: rune,
      count: glyphCount,
      index: strIndex
    )
    if glyphCount == 0:
      # First glyph.
      boundsMax.x = selectRect.x + selectRect.w
      boundsMin.x = selectRect.x
      boundsMax.y = selectRect.y + selectRect.h
      boundsMin.y = selectRect.y
    else:
      boundsMax.x = max(boundsMax.x, selectRect.x + selectRect.w)
      boundsMin.x = min(boundsMin.x, selectRect.x)
      boundsMax.y = max(boundsMax.y, selectRect.y + selectRect.h)
      boundsMin.y = min(boundsMin.y, selectRect.y)

    inc glyphIndex
    at.x += glyph.advance * font.scale
    prev = c
    inc glyphCount
    strIndex += c.len

  ## Shifts layout by alignMode.
  if result.len == 0: return

  let boundsSize = boundsMax - boundsMin

  if hAlign == Right:
    let offset = floor(size.x - boundsSize.x)
    for pos in result.mitems:
      pos.rect.x += offset
      pos.selectRect.x += offset

  if hAlign == Center:
    let offset = floor((size.x - boundsSize.x) / 2.0)
    for pos in result.mitems:
      pos.rect.x += offset
      pos.selectRect.x += offset

  if vAlign == Bottom:
    let offset = floor(size.y - boundsSize.y)
    for pos in result.mitems:
      pos.rect.y += offset
      pos.selectRect.y += offset

  if vAlign == Middle:
    let offset = floor((size.y - boundsSize.y) / 2.0)
    for pos in result.mitems:
      pos.rect.y += offset
      pos.selectRect.y += offset

proc typeset*(
    font: Font,
    text: string,
    pos: Vec2 = vec2(0, 0),
    size: Vec2 = vec2(0, 0),
    hAlign: HAlignMode = Left,
    vAlign: VAlignMode = Top,
    clip = true,
    wrap = true,
    kern = true,
    textCase = tcNormal,
    tabWidth: float32 = 0.0
  ): seq[GlyphPosition] =
  ## Typeset string and return glyph positions that is ready to draw.
  var
    ignoreBoundsMin: Vec2
    ignoreBoundsMax: Vec2
  typeset(
    font, toRunes(convertTextCase(text, textCase)), pos, size,
    hAlign, vAlign,
    clip, wrap, kern, textCase,
    tabWidth,
    ignoreBoundsMin, ignoreBoundsMax
  )

proc drawText*(image: var Image, layout: seq[GlyphPosition]) =
  ## Draws layout.
  for pos in layout:
    var font = pos.font
    if pos.character in font.typeface.glyphs:
      var glyph = font.typeface.glyphs[pos.character]
      var glyphOffset: Vec2
      let img = font.getGlyphImage(
        glyph,
        glyphOffset,
        subPixelShift = pos.subPixelShift
      )
      image.draw(
        img,
        translate(vec2(pos.rect.x + glyphOffset.x, pos.rect.y + glyphOffset.y))
      )

proc drawText*(font: Font, image: var Image, pos: Vec2, text: string) =
  ## Draw text string
  var layout = font.typeset(text, pos)
  image.drawText(layout)

proc getSelection*(layout: seq[GlyphPosition], start, stop: int): seq[Rect] =
  ## Given a layout gives selection from start to stop in glyph positions.
  ## If start == stop returns [].
  if start == stop:
    return
  for g in layout:
    if g.count >= start and g.count < stop:
      if result.len > 0:
        let onSameLine = result[^1].y == g.selectRect.y and result[^1].h == g.selectRect.h
        let notTooFar = g.selectRect.x - result[^1].x < result[^1].w * 2
        if onSameLine and notTooFar:
          result[^1].w = g.selectRect.x - result[^1].x + g.selectRect.w
          continue
      result.add g.selectRect

proc pickGlyphAt*(layout: seq[GlyphPosition], pos: Vec2): GlyphPosition =
  ## Given X,Y coordinate, return the GlyphPosition picked.
  ## If direct click not happened finds closest to the right.
  var minG: GlyphPosition
  var minDist = -1.0
  for i, g in layout:
    if g.selectRect.y <= pos.y and pos.y < g.selectRect.y + g.selectRect.h:
      # on same line
      let dist = abs(pos.x - (g.selectRect.x))
      # closet character
      if minDist < 0 or dist < minDist:
        # min distance here
        minDist = dist
        minG = g
  return minG

proc textBounds*(layout: seq[GlyphPosition]): Vec2 =
  ## Given a layout, return the bounding rectangle.
  ## You can use this to get text width or height.
  for i, g in layout:
    result.x = max(result.x, g.selectRect.x + g.selectRect.w)
    result.y = max(result.y, g.selectRect.y + g.selectRect.h)

proc textBounds*(font: Font, text: string): Vec2 =
  ## Given a font and text, return the bounding rectangle.
  ## You can use this to get text width or height.
  var layout = font.typeset(text)
  return layout.textBounds()
