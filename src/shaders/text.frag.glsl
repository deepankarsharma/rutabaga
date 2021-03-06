/* =========================================================================
 * Freetype GL - A C OpenGL Freetype engine
 * Platform:    Any
 * WWW:         http://code.google.com/p/freetype-gl/
 * -------------------------------------------------------------------------
 * Copyright 2011 Nicolas P. Rougier. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY NICOLAS P. ROUGIER ''AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL NICOLAS P. ROUGIER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are
 * those of the authors and should not be interpreted as representing official
 * policies, either expressed or implied, of Nicolas P. Rougier.
 * ========================================================================= */

#version 150

uniform sampler2D tx_sampler;
uniform vec3 atlas_pixel;
uniform float gamma;
in float shift;

in vec2 uv;
in vec4 front_color;
out vec4 frag_color;

void main()
{
	// LCD Off
	if (atlas_pixel.z == 1.0) {
		float a = texture(tx_sampler, uv).r;
		frag_color = front_color * pow(a, 1.0 / gamma);
		return;
	}

	// LCD On
	vec4 current  = texture(tx_sampler, uv);
	vec4 previous = texture(tx_sampler, uv + vec2(-1.,0.) * atlas_pixel.xy);
	vec4 next     = texture(tx_sampler, uv + vec2(+1.,0.) * atlas_pixel.xy);

	current = pow(current,  vec4(1.0 / gamma));
	previous= pow(previous, vec4(1.0 / gamma));

	float r = current.r;
	float g = current.g;
	float b = current.b;

	if (shift <= 0.333) {
		float z = shift / 0.333;
		r = mix(current.r, previous.b, z);
		g = mix(current.g, current.r,  z);
		b = mix(current.b, current.g,  z);
	} else if (shift <= 0.666) {
		float z = (shift - 0.33) / 0.333;
		r = mix(previous.b, previous.g, z);
		g = mix(current.r,  previous.b, z);
		b = mix(current.g,  current.r,  z);
	} else if (shift < 1.0) {
		float z = (shift - 0.66) / 0.334;
		r = mix(previous.g, previous.r, z);
		g = mix(previous.b, previous.g, z);
		b = mix(current.r,  previous.b, z);
	}

	float t = max(max(r,g),b);
	vec4 color = vec4(front_color.rgb, (r+g+b)/3.0);
	color = t*color + (1.0-t)*vec4(r,g,b, min(min(r,g),b));
	frag_color = vec4( color.rgb, front_color.a*color.a);
}
