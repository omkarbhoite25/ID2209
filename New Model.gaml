/**
* Name: NewModel
* Based on the internal skeleton template. 
* Author: Filip de Figueiredo (Personal Number 19930708-3973)  & Omkar Bhoite (Student ID:07579162)
* Tags: 
*/

model NewModel
species FestivalGuest skills:[moving]{
	point targetPoint <- nil;
	rgb myColor <- #green;
	int thirst <- rnd(0,50) update: thirst + rnd(0,4) max: 300 min: 0;
	int hunger <- rnd(0,80) update: hunger + rnd(0,2) max: 200 min: 0;
	list<point> knownFoodPlaces <- [];
	list<point> knownJuicePlaces <- [];
	bool isBadApple <- false;
	point badAppleLocation <- nil;
	float distance <-0.0;
		
	bool isHungry{
		return hunger > 199;
	}
	
	bool isThirsty{
		return thirst > 199;
	}
	
	list<FestivalGuest> nearbyBadApples {
		return FestivalGuest where(each.isBadApple and each.location distance_to location <3);
	}
	
	bool isNearBadApple{
		 return !empty(nearbyBadApples());
	}
	
	aspect default{
		draw pyramid(2) at: location color: myColor;
		draw sphere(1) at: location + {0,0,1} color: myColor;
		//If this guest knows of all the food & juice places, give them a teapot hat.
		if (length (Shop where(each.isFoodShop)) = length(knownFoodPlaces)) and length (Shop where(!each.isFoodShop)) = length(knownJuicePlaces) {
			draw teapot(1/2) at:location + {0,0,3.5} color: #yellow;	
		}
	}
	
	reflex reportBadApple when: !isBadApple and badAppleLocation = nil  and isNearBadApple(){
		list<FestivalGuest> badApples <- nearbyBadApples();
		ask one_of(badApples){
		 	myself.badAppleLocation <- location;
		}
		do headTowardsInformationCenter;
		write name+" is reporting a bad apple";
		myColor <- #white;
	}
	
	reflex beIdle when: !isBadApple and targetPoint = nil{
		do wander;
		distance <- distance + speed; //distance moved while wandering.
	}
	
	reflex becomeBadApple when: copScenario and thirst = 299 and flip(0.25){
		write name+" has become a bad apple!";
		isBadApple <- true;
		targetPoint <- nil;
		myColor <- #black;
	}
	
	action setSailForThisJuiceStand(point newJuicePlace){
		if memoryScenario and !(knownJuicePlaces contains(newJuicePlace)){
			knownJuicePlaces <- knownJuicePlaces + newJuicePlace;	
		}
		targetPoint <- newJuicePlace; 
		myColor <- #aqua;
	}
	
	action setSailForThisFoodStand(point newFoodPlace){
	 	if memoryScenario and !(knownFoodPlaces contains(newFoodPlace)){
	 		knownFoodPlaces <- knownFoodPlaces + newFoodPlace;
	 	}
		targetPoint <- newFoodPlace; 
		myColor <- #hotpink;
	}
	
	//Using targetPoint = infoCenter to determine location
	reflex askForDirections when: targetPoint = {50,50} and !isBadApple{
		list<FestivalGuest> guests <- FestivalGuest where(each.location distance_to location <5);
		if(!empty(guests)){
			list<FestivalGuest> juiceKnowers <- guests where(!empty(each.knownJuicePlaces) and !(knownJuicePlaces contains_all each.knownJuicePlaces));
			list<FestivalGuest> foodKnowers <- guests where(!empty(each.knownFoodPlaces) and !(knownFoodPlaces contains_all each.knownFoodPlaces));
			if isThirsty() and !empty(juiceKnowers){
				point juice <- nil;
				ask one_of(juiceKnowers){
					list<point> newJuicePlaces <- knownJuicePlaces where(!(myself.knownJuicePlaces contains(each)));
					write name + " gave " + myself.name + " the location of a new juice shop!";
					juice <- one_of(newJuicePlaces);
				}
				
				do setSailForThisJuiceStand(juice);
			} else if isHungry() and !empty(foodKnowers){
				point food <- nil;
				ask one_of(foodKnowers){
					list<point> newFoodPlaces <- knownFoodPlaces where(!(myself.knownFoodPlaces contains(each)));
					write name + " gave " + myself.name + " the location of a new food shop!";
					food <- one_of(newFoodPlaces);
				}
				do setSailForThisFoodStand(food);
			}
		}
	}
	
	//Enter store when hunger/thirst is below threshold, and close to store
	reflex pickUpFoodOrAskForDirectiosn when: !isBadApple and targetPoint != nil and location distance_to(targetPoint) <5{
		if badAppleLocation != nil {
			if targetPoint = {50,50}{
				ask one_of(InformationCenter) {
					myself.targetPoint <- getCopLocation();					
				}
				write name + " is heading towards a cop's last known location";
			} else if targetPoint = badAppleLocation{
				//have arrived with cop to badAppleLocation
				targetPoint <- nil;
				badAppleLocation <- nil;
				write name + " is done doing their civic duty";
			} else if (SecurityGuard closest_to location).location distance_to location < 5{
				//arrived close to cop
				targetPoint <- badAppleLocation;
				ask (SecurityGuard closest_to location){
					do goToBadApple(myself.badAppleLocation);
				}
				write name + " is reporting bad behaviour to a cop" ;				
			} else {
				//Lost track of cop..... Give up on reporting
				targetPoint <- nil;
				badAppleLocation <- nil;
				write name + " could not find a cop at their last known location, and is giving up on their civic duty";
			}
		} else if targetPoint = {50,50}{
			point juice <- nil;
			point food <- nil;
			if isThirsty() and isHungry() {
				if flip(0.5){
					ask one_of(InformationCenter){ juice <-getANewJuiceShop(myself.location, myself.knownJuicePlaces);} 
				} else {
					ask one_of(InformationCenter){food <-getANewFoodShop(myself.location, myself.knownFoodPlaces);} 
				}
			} else if isThirsty() {
			 	ask one_of(InformationCenter){ juice <-getANewJuiceShop(myself.location, myself.knownJuicePlaces);} 
			} else {
				ask one_of(InformationCenter){food <-getANewFoodShop(myself.location, myself.knownFoodPlaces);}  
			}
			if juice != nil {
				do setSailForThisJuiceStand(juice);
			} else {
				do setSailForThisFoodStand(food);
			}
		} else {
			ask Shop closest_to targetPoint{
				if isFoodShop{
					write name + " took care of their hunger!";
					myself.hunger<-0;
				} else {
					write name + " took care of their thirst!";
					myself.thirst<-0;
				}
			} 
			targetPoint <-  nil;
			myColor <- #green;
		}
	}
	
	//75 chance to go to known location, 25% chance to go to info center for a new location
	//If they don't know about any place, they will head to the info center.
	reflex handleNeeds when: !isBadApple and targetPoint = nil and ( isHungry() or isThirsty()) {
		//Curiostiy + do I know of all the locations?
		bool isSeekingNewFood <- flip(0.25) and length (Shop where(each.isFoodShop)) > length(knownFoodPlaces);
		bool isSeekingNewJuice <- flip(0.25) and length (Shop where(!each.isFoodShop)) > length(knownJuicePlaces);
		if isThirsty() and !empty(knownJuicePlaces) and !isSeekingNewJuice{
			write name + "is thirsty, and is heading for a juice place they know";
			do setSailForThisJuiceStand(one_of(knownJuicePlaces));
		} else if isHungry() and !empty(knownFoodPlaces) and !isSeekingNewFood{
			do setSailForThisFoodStand(one_of(knownFoodPlaces));
			write name + "is hungry, and is heading for a food place they know";
		} else {
			//Discover new place.
			if memoryScenario{
				write name + " is hungry/thirsty but wants to go to a new place";
			} else {
				write name + " is hungry/thirsty and is heading to the information center to find the nearest shop.";
			}
			do headTowardsInformationCenter;	
		}
	}
	
	action headTowardsInformationCenter{
		myColor <- #red; // Have need & is questing for new information.
		targetPoint <- {50,50}; 
	}
	
	reflex moveToTarget when: targetPoint != nil{
		do goto target:targetPoint;
	}	

}

species SecurityGuard skills:[moving]{
	point targetPoint <- nil;
	
	aspect default{
		draw hexagon(2) at: location color: #blue;
		
	}
	
	list<FestivalGuest> nearbyBadApples {
		return FestivalGuest where(each.isBadApple and each.location distance_to location <5);
	}
	
	bool isNearBadApple{
		 return !empty(nearbyBadApples());
	}
	
	reflex killBadApple when: isNearBadApple(){
		list<FestivalGuest> badApples <- nearbyBadApples();
		ask one_of(badApples){
			write myself.name + " is taking care of bad apple " + name;
		 	do die;
		}
	}
	
	reflex goBackToIdle when: targetPoint != nil and location = targetPoint {
		targetPoint <- nil;
	}
	
	action goToBadApple(point badAppleLocation) {
		write name + " is heading towards a bad apple";
		targetPoint <- badAppleLocation;
	}
	
	reflex moveToTarget when: targetPoint != nil{
		do goto target:targetPoint;
	}	
}

species Shop {
	//Randomly decides on being a food or drinks place.
	bool isFoodShop <- flip(0.5);
	aspect default{
		if(isFoodShop){
			draw pyramid(5) at: location color: #hotpink;	
		} else {
			draw pyramid(5) at: location color: #aqua;
		}
		
	}
}

species InformationCenter {
	init {
      location <- {50,50};
    }
	aspect default{
		draw cube(5) at: location color: #orange;
		draw pyramid(5) at: location + {0,0,5} color: #orange;
	}
	
	point getANewFoodShop(point origin, list<point> oldLocations){
		return closest_to(Shop where (each.isFoodShop and !contains(oldLocations, each.location)), origin).location;
	}
	
	point getANewJuiceShop(point origin, list<point> oldLocations){
		return closest_to(Shop where (!each.isFoodShop and !contains(oldLocations, each.location)), origin).location;
	} 
	
	point getClosestFoodShop(point origin){
		return closest_to(Shop where (each.isFoodShop), origin).location;
	}
	
	point getClosestJuiceShop(point origin){
		return closest_to(Shop where (!each.isFoodShop), origin).location;
	}
	
	point getCopLocation{
		return one_of(SecurityGuard).location;
	}
}

global {
	//Turns cop scenario on/off
	bool copScenario <- true;
	
	//Turns memory challenge on/off
	bool memoryScenario <- true;
	init {
		create FestivalGuest number: 100;
		create Shop number: 2 with: (isFoodShop: true);
		create Shop number: 2 with: (isFoodShop: false);
		create Shop number: 2;
		
		create InformationCenter number: 1;
		if copScenario {
			create SecurityGuard number:3;
		}
	}
	/** Insert the global definitions, variables and actions here */
}

experiment NewModel type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map type: opengl {
			species FestivalGuest aspect: default; 
			species Shop aspect: default;
			species InformationCenter aspect:default;
			species SecurityGuard aspect:default;
		}
	}
}
