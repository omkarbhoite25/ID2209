/**
* Name: FinalAssignment
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/


model FinalAssignment
global{
	init{
		create Journalist number:10;
		create Rock_Music_Lover number:10;
		create Chillax_dudes number:10;
		create Party_dudes number:10;
		create Food_lovers number:10;
		create Security_Guard number:10;
		create Food_Shops number:4;
		create concerts number:3;
		create bars number:5;
		create police_station number:2;
		create gaming_booth number:3;
		
		
		
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species Food_Shops{
	aspect default{
		draw "Food Shop " at: {location.x,location.y,location.z+12}   color: #black font: font('Default', 18, #bold)  ;
		draw pyramid(5) at: {location.x,location.y,location.z+5} color: #green;
		draw cube(5) at: location color: #green;
		
	}
}
species concerts{
	aspect default{
		draw "Concert " at: {location.x,location.y,location.z+13}   color: #black font: font('Default', 18, #bold)  ;
		draw pyramid(5) at: {location.x,location.y,location.z+5} color:#red;
		draw cube(5) at: location color: flip(0.5)? #purple :#red;
		
	}
}
species bars{
	aspect default{
		draw "Bar " at: {location.x,location.y,location.z+12.5}   color: #black font: font('Default', 18, #bold)  ;
		draw pyramid(5) at: {location.x,location.y,location.z+5} color: #blue;
		draw cube(5) at: location color: flip(0.5)? #purple :#blue;
		
	}
}
species police_station{
	aspect default{
		draw "Police Station " at: {location.x,location.y,location.z+11}   color: #black font: font('Default', 18, #bold)  ;
		draw pyramid(5) at: {location.x,location.y,location.z+5} color: #black;
		draw cube(5) at: location color: flip(0.5)? #purple :#black;
		
	}
}
species gaming_booth{
	aspect default{
		draw "Gaming Booth " at: {location.x,location.y,location.z+13.5}   color: #black font: font('Default', 18, #bold)  ;
		draw pyramid(5) at: {location.x,location.y,location.z+5} color: #green;
		draw cube(5) at: location color: flip(0.5)? #purple :#green;
		
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species Journalist{
	list traits<-[rnd(1,10),rnd(1,10),rnd(1,10)]; //trait solitary, consistent, friendly
	
	aspect default{
		draw sphere(1) at: {location.x,location.y,location.z+2} color:#green;
		draw pyramid(2) at: location color:#green;
		
	}
}
species Rock_Music_Lover{
	list traits<-[rnd(1,10),rnd(1,10),rnd(1,10)];//trait hyper/temper, too loudy, taklative
	aspect default{
		draw sphere(1) at: {location.x,location.y,location.z+2} color:#blue;
		draw pyramid(2) at: location color:#blue;
		
	}
}
species Chillax_dudes{
	list trait<-[rnd(1,10),rnd(1,10),rnd(1,10)];//trait calm, gullible, sensitive 
	aspect default{
		draw sphere(1) at: {location.x,location.y,location.z+2} color:#aqua;
		draw pyramid(2) at: location color:#aqua;
		
	}
}
species Party_dudes{
	list traits<-[rnd(1,10),rnd(1,10),rnd(1,10)];// energetic, generous, friendly
	aspect default{
		draw sphere(1) at: {location.x,location.y,location.z+2} color:#brown;
		draw pyramid(2) at: location color:#brown;
		
	}
}
species Food_lovers{
	list traits<-[rnd(1,10),rnd(1,10),rnd(1,10)];// hyper, energetic, solitary
	aspect default{
		draw sphere(1) at: {location.x,location.y,location.z+2} color:#yellow;
		draw pyramid(2) at: location color:#yellow;
		
	}
}
species Security_Guard{aspect default{
	list traits<-[rnd(1,10),rnd(1,10),rnd(1,10)];// confident, organized, cautious
		draw sphere(1) at: {location.x,location.y,location.z+2} color:#red;
		draw pyramid(2) at: location color:#red;
		
	}}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
experiment main type: gui{
	output{
		display map type: opengl background: #lightpink{
			species Journalist;
			species Rock_Music_Lover;
			species Chillax_dudes;
			species Party_dudes;
			species Food_lovers;
			species Security_Guard;
			species concerts;
			species Food_Shops;
			species gaming_booth;
			species bars;
			species police_station;
			
			
		}
	}
}


/* Insert your model definition here */

