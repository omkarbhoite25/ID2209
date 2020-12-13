/**
* Name: FinalAssignment
* Based on the internal empty template. 
* Author: Filip
* Tags: 
*/

model FinalAssignment
global{
	init{
		create Zombie number: 20;
		create Soldier number: 5;
		create Guest number: 1;
		create Technician number: 1;
		//create Hero number: 1;
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
		do wander amplitude:90.0;
	}
}

//Used to categorize all humans, as opposed to zombies.
species Human parent: Base_Person {
	list<string> funnyDeaths <- ["Blergh", "Oh no!", "Argh!", "Cruel world!", "Damn!", "I died!"];
	
	action descriptiveDeath{
		write name+":"+one_of(funnyDeaths)+"X(";
		do die;
	}
	list zombiesInSight <- zombiesInSight() update:zombiesInSight();

	//Updates zombiesInSight
	list<Zombie> zombiesInSight {
		return list<Zombie>(agents_at_distance(sightRange) where((each is Zombie)));
	}
}

//Wants to eat people
species Zombie parent: Base_Person {
	rgb myColor <- #black;
	init{
		speed <- rnd(0.6,0.8);
		write "Brains!";
	}
	
	//Keeps track of how many cycles remain to consume a person
	int eatingCounter <-0;
	
	//Range at which Zombie can eat people
	float killRange <- 2.0;
	
	//List of nearby Humans
	list humansInSight <- humansInSight() update:humansInSight();
	
	//Humans that we can eat
	list eatableHumans <- humansInRange() update:humansInRange();
	
	//Updates humansInSight
	list<Human> humansInSight {
		return list<Human>(agents_at_distance(sightRange) where(!(each is Zombie)));
	}
	
	//Updates eatableHumans
	list<Human> humansInRange{
		return list<Human>(agents_at_distance(killRange) where(!(each is Zombie)));
	}
	
	//Hunt nearest person in sight
	reflex huntPeople when: !empty(humansInSight) and eatingCounter = 0{
		Base_Person target <- humansInSight closest_to location; 
		do goto target:target;
		textBubble <- "Hunting";
		isIdle <-false;
	}
	
	//Kill and eat a person, and delay for a few cycles while eating them
	reflex killPerson when: !empty(eatableHumans) {
		Human target <- eatableHumans closest_to location;
		isIdle <-false; 
		eatingCounter <-10;//Time to make eat and make new zombie
		ask target{
			do descriptiveDeath;
		}
		write name+": Nom nom nom";
	}
	
	//Wait around a bit after killing someone.
	reflex eatPerson when: eatingCounter !=0{
		//Gory animation
		textBubble <- "Eating";
		eatingCounter<- eatingCounter -1;
		if(eatingCounter = 0){
			create Zombie with:(location:location+{-3,0,0});
		}
	}
	
	//When no humans in sight, wander around
	reflex becomeIdle when: empty(humansInSight) and eatingCounter = 0{
		textBubble <- "Brains";
		isIdle <- true;
	}
}

//Avoids zombies
//needs to eat (not people)
species Guest parent: Human {
	rgb myColor <- #green;
	//Avoid zombies
	
	//Naively flees from zombie, by running in same direction.
	reflex fleeFromZombies when: !empty(zombiesInSight){
		textBubble <- "Fleeing";
		isIdle <-false;
		Zombie enemy <- one_of(zombiesInSight);
		float newHeading <- atan2(enemy.location.y-location.y, enemy.location.x-location.x);
		//If we are at an edge, we should avoid moving into the wall..
		//if location.y = 0{
			
		//} else if location.y {
			
		//}
		//if location.x = 0{
			
		//} else if location.x {
			
		//}
		do move heading:-newHeading ;		
	}
	
	reflex becomeIdle when: empty(zombiesInSight){
		textBubble <-"";
		isIdle<-true;
	}
	//Head towards stores
}

// Follows technicians
// Attacks zombies, for power damage at range range.
species Soldier parent: Human{
	float range <- rnd(5.0,10.0);
	float accuracy <- rnd(0.5,0.85); //Optional, this could affect the shooting at zombies. They could fail to shoot zombie.
	rgb myColor <- #blue;
	//Small timer to prevent soldier from firing every cycle. Reloading or aiming.
	int reloadingCounter <- 0 update: reloadingCounter-1 min:0;
	bool readyToFire <- true update: really();

	bool really {
		return reloadingCounter = 0;
	}
	list<Zombie> zombiesWithinRange <- checkZombiesInRange() update:checkZombiesInRange();	
	//Updates above list on every cycle.
	list<Zombie> checkZombiesInRange {
		return Zombie where(each.location distance_to location < range);
	}
	
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
		reloadingCounter <- 5;
	}
	
	//Optional reflex, for what to do when zombie is near but gun is not loaded
	reflex sayOhShit when: (!empty(zombiesWithinRange) and !readyToFire) {
		//Could flee from zombie, or stand ground while reloading.
		
	}
	
	//If you want Soldiers to hunt zomibes, change to zombiesInSight.
	reflex becomeIdle when: empty(zombiesWithinRange){
		textBubble <- "";
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
	float soldierRange<-10.0;
	bool TowardsTower<-false;
	rgb myColor <- #yellow;
	list nearbySoldiers -> {Soldier where(each.location distance_to location<sightRange)};
	
	reflex askSoldierToAccompany when: !empty(nearbySoldiers){
		ask nearbySoldiers closest_to location{
			self.location<-myself.location+rnd(2,10);
			write name+' protecting '+myself.name;
		}
		TowardsTower<- true;
	}
	
	reflex becomeIdle when: empty(nearbySoldiers){
		isIdle <- true;
	}
	
	reflex GotoTower when:TowardsTower{
		do goto target:{50,50};
	}
	
}

//Acts like Guest
//
species Hero parent: Human{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	rgb myColor <- #orange;
}

experiment main type: gui{
	output{
		display map type: opengl{
			species Zombie aspect: default;
			species Soldier aspect: default;
			species Guest aspect: default; 
			species Technician aspect:default;
			species Hero aspect:default;
			
		}
	}
}


/* Insert your model definition here */
