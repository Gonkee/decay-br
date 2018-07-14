shader_type spatial;

uniform sampler2D noisetex;
uniform float start_time;
uniform float dissolve_duration;
uniform float edge_highlight;
uniform vec3 albedo;

void fragment(){
	ALBEDO = albedo;
	
	float alpha_value = texture(noisetex, UV * 0.5).b;
	float threshold = (TIME - start_time) / dissolve_duration;
	if(alpha_value > threshold){
		ALPHA = 0.75;
	} else {
		ALPHA = 0.0;
	}
	if( (alpha_value > (threshold - edge_highlight/2.0) ) && (alpha_value < (threshold + edge_highlight/2.0) ) ){
		ALPHA = 1.0;
	}
}