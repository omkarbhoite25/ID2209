/**
* Name: FinalAssignment
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/
model FinalAssignment
global{
	int NumberofSoldier<-2;
	init{
		create Zombie number: 5;
		create Soldier number: NumberofSoldier;
		create Guest number: 10;
		create Technician number: 1;
		create Hero number: 1;
		//create WatchTower number:1;
	}
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
species Base_Person skills:[moving]{
	float speed <- 1.0;
	rgb myColor <- #aqua;
	float sightRange <- 20.0;
	bool isIdle <- true;
	string textBubble <-"";
	
	aspect default{
		draw sphere(1) at: {location.x,location.y,location.z+2} color:myColor;
		draw pyramid(2) at: location color:myColor;		
		draw string(textBubble) at:location+{-3,0,4};
	}
	
	reflex beIdle when: isIdle{
		do wander amplitude: speed;
	}
}
//Wants to eat people
species Zombie parent: Base_Person {
	rgb myColor <- #black;
}

//Avoids zombies
//needs to eat
//needs to eat (not people)
species Guest parent: Base_Person {
	rgb myColor <- #green;

}
// Follows technicians
// Attacks zombies, for power damage at range range.
species Soldier parent: Human{
	//Range of firing gun
	float range <- rnd(5.0,10.0);
	//Percent chance of hitting target
	float accuracy <- rnd(0.5,0.85);
	rgb myColor <- #blue;
	
	//Small timer to prevent soldier from firing every cycle. Reloading or aiming.
	int reloadingCounter <- 0 update: reloadingCounter-1 min:0;
	
	//Is the gun ready to fire?
	bool readyToFire <- true update: reloadingCounter = 0;
	
	//Zombies we can shoot	
	list<Zombie> zombiesWithinRange -> {Zombie where(each.location distance_to location < range)};	

	//Shoots at closest zombie in shooting range, if we are ready to fire.
	reflex shootAtZombie when: (!empty(zombiesWithinRange) and readyToFire) {
		isIdle <-false;
		textBubble <- "Shooting";
		write "Time to shoot";
		if(flip(accuracy)){
			write name+": Hit";
			ask zombiesWithinRange closest_to location{
				do die;
			}
		} else {
			write name+": Missed";
		}
		reloadingCounter <- 8;
	}
	
	//Optional reflex, for what to do when zombie is near but gun is not loaded
	reflex sayOhShit when: (!empty(zombiesWithinRange) and !readyToFire) {
		//Could flee from zombie, or stand ground while reloading.
		textBubble <-"Reloading";
	}

	//If you want Soldiers to hunt zomibes, change to zombiesInSight.
	reflex becomeIdle when: empty(zombiesWithinRange){
		if(!readyToFire){
			textBubble <- "reloading";
		} else {
			textBubble <- "";
		}
		isIdle <-true;
	}
}



//Stays a distance away from zombies based on "bravery"
//Goal is to get to a radio tower, and repair it based on engineering_skill
//Then get to bunker
species Technician parent: Base_Person{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	float ProtectRange<-(5.0);
	rgb myColor <- #yellow;
	list nearbySoldiers -> {Soldier where(each.location distance_to location<sightRange)};
	
	reflex askSoldierToAccompany when: !empty(nearbySoldiers){
		ask nearbySoldiers closest_to location{
			write 'Dying :'+name; 
			do die;
		}
		isIdle<- false;
	}
	
	reflex becomeIdle when: empty(nearbySoldiers){
		isIdle <- true;
	}
	/*reflex ProtectTechnicia{
		ask (Soldier(RandomSoldierSelection)){
			write self.name+' protecting the technician ';
			do goto target:myself.location+rnd(3,7);
		}
		
	
	}
	reflex GotoTower{
		do goto target:{50,50};
	}*/
	
}

//Acts like Guest

species Hero parent: Base_Person{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	rgb myColor <- #orange;
}
/*species WatchTower {
	aspect default{
		draw cylinder(3.5,15) at:{50,50} color:#green;
		draw cylinder(5,5) at:{50,50,15} color:#green;
	}
}*/
experiment main type: gui{
	output{
		display map type: opengl background: #lightgreen{
			species Zombie aspect: default;
			species Soldier aspect: default;
			//species Guest aspect: default; 
			species Technician aspect:default;
			//species Hero aspect:default;
			//species WatchTower aspect:default;
		}
	}
}
/* Insert your model definition here */
