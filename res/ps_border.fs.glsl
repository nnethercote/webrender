/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// draw a circle at position aDesiredPos with a aRadius
vec4 drawCircle(vec2 aPixel, vec2 aDesiredPos, float aRadius, vec3 aColor) {
  float farFromCenter = length(aDesiredPos - aPixel) - aRadius;
  float pixelInCircle = 1.00 - clamp(farFromCenter, 0.0, 1.0);
  return vec4(aColor, pixelInCircle);
}

// We want to be in the center of the tile along the axis we're
// repeating the circle but at the top for X axis and left for Y axis.
// e.g. we only care about being equal spacing between circles for the edge we're drawing along
// and snap the other axis to the top or left.
vec2 adjust_dotted_padding(float radius) {
  switch (vBorderPart) {
    // These are the layer tile part PrimitivePart as uploaded by the tiling.rs
    case PST_TOP_LEFT:
    case PST_TOP_RIGHT:
    case PST_BOTTOM_LEFT:
    case PST_BOTTOM_RIGHT:
      return vec2(0.0, 0.0);
    case PST_BOTTOM:
    case PST_TOP:
      return vec2(0, -radius);
    case PST_LEFT:
    case PST_RIGHT:
      return vec2(-radius, 0);
  }
}

void draw_dotted_border(void) {
  // Everything here should be in device pixels.
  // We want the dot to be roughly the size of the whole border spacing
  // 2.2 was picked because it's roughly what Firefox is using.
  float spacing_fudge = 2.2;
  float border_spacing = min(vBorders.z - vBorders.x, vBorders.w - vBorders.y);
  float radius = floor(border_spacing / spacing_fudge);
  float diameter = radius * 2.0;
  float circleSpacing = diameter * 2.0;

  vec2 size = vec2(vBorders.z - vBorders.x, vBorders.w - vBorders.y);
  // Get our position within this specific segment
  vec2 position = vPos - vBorders.xy;

  // Break our position into square tiles with circles in them.
  vec2 circleCount = size / circleSpacing;
  vec2 distBetweenCircles = size / circleCount;
  vec2 circleCenter = distBetweenCircles / 2.0;

  // Find out which tile this pixel belongs to.
  vec2 destTile = floor(position / distBetweenCircles);
  destTile = destTile * distBetweenCircles;

  // Where we want to draw the actual circle.
  vec2 tileCenter = destTile + circleCenter;
  tileCenter += adjust_dotted_padding(radius);

  // Find the position within the tile
  vec2 positionInTile = mod(position, distBetweenCircles);
  vec2 finalPosition = positionInTile + destTile;

  vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
  vec3 black = vec3(0.0, 0.0, 0.0);
  // See if we should draw a circle or not
  vec4 circleColor = drawCircle(finalPosition, tileCenter, radius, black);

  oFragColor = mix(white, circleColor, circleColor.a);
}

void main(void) {
	if (vRadii.x > 0.0 &&
		(distance(vRefPoint, vPos) > vRadii.x ||
		 distance(vRefPoint, vPos) < vRadii.z)) {
		discard;
	}

  switch (vBorderStyle) {
    case BORDER_STYLE_DOTTED:
      draw_dotted_border();
      break;
    case BORDER_STYLE_NONE:
    case BORDER_STYLE_SOLID:
    {
      float color = step(0.0, vF);
      oFragColor = mix(vColor1, vColor0, color);
      break;
    }
  }
}
