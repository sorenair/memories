shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform vec2 flame_size = vec2(0.9,1.5);
uniform float intensity = 1.0;
uniform float animation_speed = 1.0;
uniform float wind = 0.12;
uniform float fire_phase = 0.0;
uniform vec4 core_color : source_color;
uniform vec4 flame_color : source_color;
uniform vec4 tip_color : source_color;
uniform float glow_strength = 0.3;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float tongue(vec2 p,float height,float width,float lane,float time) {
	float h=clamp(p.y/height,0.0,1.0);
	float center=lane*(1.0-h*0.4)+wind*h*h;
	center+=sin(h*4.8-time*1.5+lane*4.0)*h*h*0.22+sin(h*8.0+time*0.9)*h*0.06;
	float broad=noise(vec2(p.y*3.3-time*0.65,lane*8.0+fire_phase));
	float radius=width*pow(max(1.0-h,0.0),0.7)*(0.87+broad*0.26);
	radius+=sin(h*8.0-time*1.8+lane)*sin(h*3.14159)*0.055;
	return max(abs(p.x-center)-max(radius,0.0),(p.y-height)*0.8);
}
void vertex() {
	vec3 right=INV_VIEW_MATRIX[0].xyz;right.y=0.0;
	right=normalize(right);
	vec3 origin=MODEL_MATRIX[3].xyz;
	float sx=length(MODEL_MATRIX[0].xyz);
	float sy=length(MODEL_MATRIX[1].xyz);
	vec3 world=origin+right*(UV.x-0.5)*flame_size.x*1.8*sx+vec3(0,1,0)*(1.0-UV.y)*flame_size.y*1.18*sy;
	VERTEX=(inverse(MODEL_MATRIX)*vec4(world,1.0)).xyz;
}
void fragment() {
	float t=TIME*animation_speed+fire_phase;
	vec2 p=vec2((UV.x-0.5)*2.4,(1.0-UV.y)*1.18);
	p.y/=mix(0.65,1.0,intensity);
	float height=0.95+sin(t*1.1)*0.035+sin(t*2.3)*0.02;
	float d=tongue(p,height,0.6,0.0,t);
	d=min(d,tongue(p,0.65+sin(t*1.3)*0.08,0.27,-0.32,t+1.4));
	d=min(d,tongue(p,0.78+sin(t*0.9)*0.06,0.26,0.3,t-0.8));
	// Two broad rising scoops carve curling edges, rather than noisy pixel flames.
	for (int i=0;i<2;i++) {
		float fi=float(i);
		float rise=fract(t*0.19+fi*0.53);
		float y=0.24+rise*0.85;
		float side=i==0 ? -1.0 : 1.0;
		float x=side*(0.43-rise*0.24)+wind*rise*rise;
		float hole=length((p-vec2(x,y))*vec2(1.0,0.85))-(0.11+sin(rise*3.14159)*0.07);
		d=max(d,-hole-(1.0-smoothstep(0.0,0.15,rise))*0.3);
	}
	float aa=max(fwidth(d),0.004);
	float flame=1.0-smoothstep(-aa,aa,d);
	float pigment=noise(vec2(p.x*3.0,p.y*3.8-t*0.65)+fire_phase);
	float heat=clamp(1.0-p.y*0.87-abs(p.x-wind*p.y*p.y)*0.5+(pigment-0.5)*0.18,0.0,1.0);
	vec3 color=mix(tip_color.rgb,flame_color.rgb,smoothstep(0.17,0.53,heat));
	color=mix(color,core_color.rgb,smoothstep(0.55,0.85,heat));
	float inner=tongue(p,0.6+sin(t*1.6)*0.055,0.29,-0.04,t+2.4);
	float heart=(1.0-smoothstep(-aa,aa,inner))*smoothstep(0.45,0.75,heat);
	color=mix(color,mix(core_color.rgb,vec3(1.0),0.32),heart*0.85);
	color*=0.98+pigment*0.04;
	float halo=exp(-max(d,0.0)*18.0)*0.12*glow_strength*(1.0-flame);
	ALBEDO=mix(flame_color.rgb,color,flame);
	ALPHA=clamp(flame+halo,0.0,1.0)*smoothstep(0.0,0.02,p.y)*intensity;
}
