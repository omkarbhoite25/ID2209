/**
* Name: FinalAssignment
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/


model FinalAssignment
global{
	init{
		create Zombie number: 3;
		create Soldier number: 3;
		create Guest number: 10;
		
		create Technician number: 1;
		create Hero number: 1;
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
species Base_Person {
	float speed <- 1.0;
	rgb myColor <- #aqua;
	
	aspect default{
		draw sphere(1) at: {location.x,location.y,location.z+2} color:myColor;
		draw pyramid(2) at: location color:myColor;		
	}
}

species Zombie parent: Base_Person {
	rgb myColor <- #black;
	
}

//Avoids zombies
//needs to eat
species Guest parent: Base_Person {
	rgb myColor <- #green;
	
}

// Follows technicians
// Attacks zombies, for power damage at range range.
species Soldier parent: Base_Person{
	float power <- rnd(0.8,5.0);
	float range <- rnd(5.0,10.0);
	rgb myColor <- #blue;
}

//Stays a distance away from zombies based on "bravery"
//Goal is to get to a radio tower, and repair it based on engineering_skill
//Then get to bunker
species Technician parent: Base_Person{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	rgb myColor <- #yellow;
}

//Acts like Guest
//
species Hero parent: Base_Person{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	rgb myColor <- #orange;
}

experiment main type: gui{
	output{
		display map type: opengl background: #lightpink{
			species Zombie aspect: default;
			species Soldier aspect: default;
			species Guest aspect: default; 
			species Technician aspect:default;
			species Hero aspect:default;
			
		}
	}
}


/* Insert your model definition here */

