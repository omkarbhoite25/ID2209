/**
* Name: FinalAssignment
* Based on the internal empty template. 
* Author: Filip
* Tags: 
*/

//Need 2 different places people can meet.
//Show number of zombies over time
//Vs peple and soldiers

model FinalAssignment
global{
	geometry shape <- square(200#m);
	int zombies -> {length(Zombie)};
    int humans -> {length(agents where(each is Human))};
	init{
		int scenario <- 3 ;
		if scenario = 0{
			create FoodStall number:3;
			create Zombie number: 5;
			create Guest number: 40;
			create Soldier number: 1;
		} else if scenario = 1 {
			//Testing a single soldier shooting & fleeing.
			create Zombie with: (location:{50,60,0});
			create Soldier with: (location:{50,50,0});
			create Zombie with: (location:{50,40,0});
		} else if scenario = 2 {
			//Testing Technician with Protecting Soldier, vs Zombies.
			//Soldier should not flee?
			create Zombie number:10;
			create Soldier number:3;
			create Technician ;
			//create Zombie;
		} else if scenario = 3{
			create FoodStall number:3;
			create Zombie number: 5;
			create Guest number: 10;
			create Soldier number: 3;
			create Bunker number:1 with:(location:{200,200,0});
			create RadioMast number:1;
			create Technician number:1;
		} else if scenario = 4{
			//Test having people inside the bunker
			create Bunker with: (location:{100,100,0}, isActive:true);
			//Zombie should die on tick 1
			create Zombie number: 1 with: (location:{90,90,0});
			//Human should be fed
			create Guest number: 1 with: (location:{110,110,0}, hunger:498, safetyBunker:one_of(Bunker));
		}
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
species Base_Person skills:[moving]{
	init{
		speed <- 1.0;	
	}
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
species Human parent: Base_Person skills:[fipa]{
	Bunker safetyBunker <- nil;
	list<string> funnyDeaths <- ["Blergh", "Oh no!", "Argh!", "Cruel world!", "Damn!", "I died!"];
	
	action descriptiveDeath{
		write name+":"+one_of(funnyDeaths)+"X(";
		do die;
	}
	list zombiesInSight -> { list<Zombie>(Zombie at_distance(sightRange))};
	
	list<FoodStall> stallsWithinSight -> {FoodStall where(each.location distance_to location < sightRange)};
	FoodStall targetFoodStall <- nil;

	//When people get hungry, they start looking for food
	bool isHungry -> hunger > 299;
	
	//Everyone begins knowing about a random food stall.
	list<FoodStall> knownFoodPlaces <- [one_of(FoodStall)];
	
	//When a guest becomes hungry, they pick a place to eat food.
	reflex pickFoodStall when: (isHungry and targetFoodStall = nil){
		targetFoodStall <- knownFoodPlaces closest_to location;
	}
	
	//When a human is hungry, and safe from zombies, they head towards a food place	
	reflex moveTowardsFood when: (empty(zombiesInSight) and isHungry and safetyBunker  = nil){
		textBubble <- "Hungry";
		isIdle <-false;
		do goto (targetFoodStall.location);
	}
	
	//Head Towards bunker until you are inside.
	reflex headTowardsBunker when: (empty(zombiesInSight) and safetyBunker != nil and !(agents_inside(safetyBunker) contains(self))){
		isIdle <-false;
		do goto(safetyBunker);
	}
	
	//Wander around in bunker.
	reflex wanderInBunker when:(safetyBunker != nil and agents_inside(safetyBunker) contains(self)) {
		textBubble <-"Safe";
		do wander bounds:safetyBunker.shape amplitude:90.0;
	}
	
	//While at food stall, eat food until no longer hungry
	reflex eatFood when:(targetFoodStall != nil and hunger !=0 and location distance_to targetFoodStall < 2) {
		hunger <- hunger - 10;
		textBubble <- "Eating";
		isIdle <- false;
	}
	
	//Remembers new food stalls when they are in sight.
	reflex learnNewFoodPlace when: !empty(stallsWithinSight){
		loop newFoodPlace over: (stallsWithinSight where(!(knownFoodPlaces contains(each)))){
			knownFoodPlaces <- knownFoodPlaces + newFoodPlace;
		}
	}
	
	//Resets target food stall when not hungry, or run away from zombies 
	reflex resetTargetFoodStall when:(targetFoodStall != nil and (hunger=0 or !empty(zombiesInSight))){
		targetFoodStall <-  nil;
	}
	
	//When the guest becomes too hungry, they die of starvation.
	reflex starveToDeath when: hunger = starvationLevel {
		write name+": Died of starvation";
		do die;
		if(flip(0.10)){create Zombie number: 1 with:(location:location);}
	}
	
	//Level at which this person will starve to death
	int starvationLevel <- 500;
	int hunger <- rnd(0,100) update: hunger + rnd(0,1) max: starvationLevel min:0;
	action fleeFromZombies{
		if(agents_inside(safetyBunker) contains (self)){
			return;
		}
		isIdle <-false;
		textBubble <- "Fleeing";
		//Zombie enemy <- zombiesInSight closest_to(location);
		float newHeading <- 0.0;
		
		//Naive way of handling multiple zombies, where we look to find avoid every zombie equally. 
		//Will run to opposite direction with 1 zombie, succesfully avoid 2 opposite each other, and attempt to handle more.
		//Could be elaborated with weights depending on enemy distance to ourselves.
		loop enemy over: zombiesInSight{
			//Opposite of angle towards enemy
			float oppositeOfEnemy <- 180+(atan2(enemy.location.y-location.y, enemy.location.x-location.x));
			newHeading <- newHeading+oppositeOfEnemy;
		}
		//Take the mean of all angles that avoid zombies. Simplistic, but works for a lot of cases.
		newHeading <- newHeading / length(zombiesInSight);
		
		//If we are at a world edge, we should avoid moving into the wall..
		int x <- 90;
		if location.y <= 2 { //top wall
			newHeading <- newHeading+x;
		} else if location.y >= world.shape.height-2 {//bottom wall
			newHeading <- newHeading+x;
		}
		if location.x <= 2{//left wall
			newHeading <- newHeading+x;
		} else if location.x >= world.shape.width-2{
			newHeading <- newHeading+x;//right wall
		}
		do move heading:newHeading ;
	}

	reflex learnOfBunker when:(!empty(informs)){
		message inform <- informs at 0;
		safetyBunker <- list(inform.contents)[0];
	}
}

//Wants to eat people
species Zombie parent: Base_Person {
	rgb myColor <- #black;
	init{
		sightRange <- rnd(15.0,20.0);
		speed <- rnd(0.8,0.9);
		write "Brains!";
	}
	
	//Keeps track of how many cycles remain to consume a person
	int eatingCounter <-0;
	
	//Range at which Zombie can eat people
	float killRange <- 2.0;
	
	//List of nearby Humans
	list<Human>  humansInSight -> {list<Human>(agents_at_distance(sightRange) where(each is Human))};
	
	//Humans that we can eat
	list<Human>  eatableHumans -> {list<Human>(agents_at_distance(killRange) where(each is Human))};
	
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
		eatingCounter <-50;//Time to eat and then make new zombie
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
			create Zombie with:(location:location+{0,0,0});
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
	
	//Flee from zombies, by running in opposite direction..
	reflex avoidZombies when: !empty(zombiesInSight){
		do fleeFromZombies;		
	}
	
	//When not hungry and safe.
	reflex becomeIdle when: (empty(zombiesInSight) and !isHungry){
		textBubble <-"";
		isIdle<-true;
	}
	
}

// Follows technicians.
// Attacks zombies.
// Shoots at people near the radio tower.
species Soldier parent: Human{
	point escort<-nil;
	int Offset<-0;
	int Update<-0;
	bool MovingTowardsTechnician<-false;
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
	reflex fleeWhileReloading when: (!empty(zombiesInSight) and !readyToFire) {
		//Could flee from zombie, or stand ground while reloading.
		do fleeFromZombies;	
	}

	//If you want Soldiers to hunt zomibes, change to zombiesInSight.
	reflex becomeIdle when: empty(zombiesInSight){
		if(!readyToFire){
			textBubble <- "reloading";
		} else {
			textBubble <- "";
		}
		isIdle <-true;
	}
	reflex EscortTechnician when:MovingTowardsTechnician{
		point Escort<-escort;
		isIdle<-false;
		if self.location!=Escort{
			do goto target:Escort;
		}
		
	}
}

//Stays a distance away from zombies based on "bravery"
//Goal is to get to a radio tower, and repair it based on engineering_skill
//Then get to bunker
species Technician parent: Human{
	float bravery <- rnd(0.8,5.0); //How far away you stay from Zombies
	float engineering_skill <- rnd(0.5,2.0); //How fast they repair the tower
	float ProtectRange<-(5.0);
	float soldierRange<-10.0;
	bool TowardsTower<-false;
	rgb myColor <- #yellow;
	bool AlsoMove<-false;
	list nearbySoldiers -> {Soldier where(each.location distance_to location<sightRange)};
	//Happen every tick when there are soldiers nearby
	reflex FixTheRadioMast{
		if self.location={100,100}{
			write'*****At the tower*********';
			ask RadioMast{
				signal<-true;
				
			}
		}
	}
	/*//Move to bunker when everyone is in the bunker 
	reflex GoToBunker when:AlsoMove{
		do goto target:{200,200,0};
	}*/
	reflex FeedMyself when:hunger>=100{
		hunger<-0;
	}
	reflex askSoldierToAccompany when: !empty(nearbySoldiers){
		float arc <- 0.0;
		list SoldierNear<-[];
		loop soldier over: nearbySoldiers{
				arc<-30.0*length(SoldierNear);
				SoldierNear<-SoldierNear+soldier;
				float a<-sin(arc)*5;
				float b<-cos(arc)*5;
				float new_x<-location.x+b;
				float new_y<-location.y+a;
				ask soldier{
					MovingTowardsTechnician<-true;
					write name+' protecting '+myself.name;
					escort<-{new_x, new_y,0};
			}
			loop a over: nearbySoldiers{
			ask a {
				hunger <- 0;
			}
		}
			
		}

		TowardsTower<-true;
		isIdle<-false;
	}
	
	reflex becomeIdle when: empty(nearbySoldiers){
		isIdle <- true;
	}
	
	reflex GotoTower when:TowardsTower{
		do goto target:{100,100};
	}
	
	
}

//A place where people can get food.
species FoodStall {
	int foodStorage <- 10000 min:0;
	float rowdiness <- 0.0;
	
	aspect default {
		draw square(5) at: location color: #green;
	}
}

//Saves people and kills Zombies
species Bunker skills:[fipa]{
	int size <- 20;
	init {
		shape<-circle(size);
		//shape <- cylinder(size,15);
	}
	list<Human> humansInBunker -> {list<Human>(agents_inside(shape) where(each is Human))};
	list<Zombie> zombiesInBunker -> {list<Zombie>(agents_inside(shape) where(each is Zombie))};
	bool isActive <- false;
	
	//Bunker has enough food to last a long, long, long time.
	reflex feedPeople when:(!empty(humansInBunker) and isActive){
		loop human over: humansInBunker{
			ask human {
				hunger <- 0;
				isIdle<-true;
			}
			ask RadioMast{
				progress<-true;
			}
		}
	}
	//Automated Turrets kill all zombies inside the bunker
	reflex killPeople when:(!empty(zombiesInBunker) and isActive){
		loop zombie over: zombiesInBunker{
			ask zombie {
				do die;
			}
		}
	}
	
	reflex activate when:(!empty(informs)){
		string trash <- (informs at 0).contents;//Trash message
		isActive <- true;
	}
	
	aspect default {
		if(isActive){
			draw shape at: location color: #gold;	
		}
	}
}

//Needs to be fixed/configured by a technician, so that it can broadcast the location of a safe space to everyone.
//Technicians know the location of the RadioMast 
species RadioMast skills:[fipa]{
	//Progress to broadcast
	bool signal<-false;
	bool progress<-false;
	//Only 1 broadcast will be sent out.
	bool broadCastSent <- false;
	Bunker safeSpace;
	
	/*reflex move when:progress=true{
		ask Technician{
			write'fffffff';
			AlsoMove<-true;
		}
	}*/
	
	init {
		safeSpace <- one_of(Bunker);
	}
	
	//Send a message to all humans about the location of the safe space
	reflex sendMessage when: (signal = true and !broadCastSent){
		write "Sending broadcast. Salvation is at hand!";
		do start_conversation to: list(safeSpace) protocol: 'no-protocol' performative: 'inform' contents: [];
		do start_conversation to: list(agents where(each is Human)) protocol: 'no-protocol' performative: 'inform' contents: [safeSpace];
		broadCastSent <- true;
	}
	aspect default{
		draw cylinder(3.5,15) at:{100,100} color:#green;
		draw cylinder(5,5) at:{100,100,15} color:#green;
	}
	
}

experiment main type: gui{
	output{

		display map type: opengl{
			species Zombie aspect: default;
			species Soldier aspect: default;
			species Guest aspect: default; 
			species Technician aspect:default;
			species FoodStall aspect: default;
			species Bunker aspect:default;
			species RadioMast;
		}
//		display Population_Information {
//			chart "Population" type: series size: {1,0.5} position: {0, 0} {
//  				 data "Zombies" value: zombies color: #black ;
//				 data "Humans" value: humans color: #green ;
//   		}
//		}
	}
}


/* Insert your model definition here */
