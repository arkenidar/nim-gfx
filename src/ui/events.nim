# ui/events.nim — shape hit-testing (pure geometry, zero deps).
#
# "Input geometry": does a point (in logical coordinates) land on a shape?
# These are the picking counterparts of the gfx drawing primitives, and they
# work in the SAME logical space gfx maps both drawing and input into.

proc hitRect*(px, py, x, y, w, h: float): bool =
  px >= x and px <= x + w and py >= y and py <= y + h

proc hitCircle*(px, py, cx, cy, r: float): bool =
  let dx = px - cx
  let dy = py - cy
  dx * dx + dy * dy <= r * r

proc hitRoundedRect*(px, py, x, y, w, h, r: float): bool =
  ## Point-in-rounded-rect; the 4 unfilled corners are NOT sensitive.
  if px < x or px > x + w or py < y or py > y + h: return false
  let rad = min(r, min(w, h) / 2.0)
  if px >= x + rad and px <= x + w - rad: return true
  if py >= y + rad and py <= y + h - rad: return true
  let cx = if px < x + rad: x + rad else: x + w - rad
  let cy = if py < y + rad: y + rad else: y + h - rad
  let dx = px - cx
  let dy = py - cy
  dx * dx + dy * dy <= rad * rad
