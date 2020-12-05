/**
* Name: FinalAssignment
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/


model FinalAssignment
global{
	init{
		create Zombie number: 100;
		create Soldier number: 4;
		create Guest number: 10;
		create Technician number: 1;
		create Hero number: 1;
		create WatchTower number:1;
		
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

//Wants to eat people
species Zombie parent: Base_Person skills:[moving] {
	rgb myColor <-  #black;
	
	
	}

//Avoids zombies
//needs to eat (not people)
species Guest parent: Base_Person {
	rgb myColor <- #green;
	
}

// Follows technicians
// Attacks zombies, for power damage at range range.
species Soldier parent: Base_Person skills:[moving]{
	float power <- rnd(0.8,5.0);
	float range <- rnd(5.0,30.0);
	//float accuracy <_ rnd(0.5,0.99) //Optional, this could affect the shooting at zombies. They could fail to shoot zombie.
	rgb myColor <- #blue;
	point m<-location;
	
	reflex moveAlongWithTechnician{
		ask Technician{
		point p<-self.location;
		Soldier[0].location<-{p.x+2.5,p.y+2.5};
		Soldier[1].location<-{p.x-2.5,p.y-2.5};
		Soldier[2].location<-{p.x+2.5,p.y-2.5};
		Soldier[3].location<-{p.x-2.5,p.y+2.5};
		}
	}
	
	reflex shootAtZombie {
		list<Zombie> zombiesWithinRange<- Zombie where(each.location distance_to location <range);
		ask zombiesWithinRange {
			do wander;
		 	do die;
		 }
	}
	reflex wander{
		do wander speed:0.4 ;
	}
}

//Stays a distance away from zombies based on "bravery"
//Goal is to get to a radio tower, and repair it based on engineering_skill
//Then get to bunker
species Technician parent: Base_Person skills:[moving]{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	rgb myColor <- #yellow;
	
	reflex wander {
		//do wander;
		do goto target:{50,50} speed:0.1;
	}
}

//Acts like Guest
//
species Hero parent: Base_Person{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	rgb myColor <- #orange;
}
species WatchTower{
	aspect default{
		draw cylinder(3.5,15) at:{50,50} color:#green;
		draw cylinder(5,5) at:{50,50,15} color:#green;
		//draw pyramid(10) at:{50,50,30} color:#green;
	}
}

experiment main type: gui{
	output{
		display my_display type: opengl background: #lightpink{
			species Zombie ;
			species Soldier;
			species Guest ; 
			species Technician ;
			species Hero ;
			species WatchTower;
			
		}
	}
}


/* Insert your model definition here */
