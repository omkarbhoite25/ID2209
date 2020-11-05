/**
* Name: NewModel
* Based on the internal skeleton template. 
* Author: fil
* Tags: 
*/

model NewModel
species FestivalGuest skills:[moving]{
	point targetPoint <- nil;
	rgb myColor <- #green;
	int thirst <- rnd(0,50) update: thirst + rnd(0,4) max: 200 min: 0;
	int hunger <- rnd(0,80) update: hunger + rnd(0,2) max: 200 min: 0;
	list<point> knownFoodPlaces <- [];
	list<point> knownJuicePlaces <- [];
	bool isBadApple <- false;
	point badAppleLocation <- nil;
		
	bool isHungry{
		return hunger > 199;
	}
	
	bool isThirsty{
		return thirst > 199;
	}
	
	list<FestivalGuest> nearbyBadApples {
		return FestivalGuest where(each.isBadApple and each.location distance_to location <5);
	}
	
	bool isNearBadApple{
		 return !empty(nearbyBadApples);
	}
	
	aspect default{
		draw pyramid(2) at: location color: myColor;
		draw sphere(1) at: location + {0,0,1} color: myColor;
	}
	
	reflex reportBadApple when: isNearBadApple(){
		list<FestivalGuest> badApples <- nearbyBadApples();
		ask one_of(badApples){
		 		myself.badAppleLocation <- location;
		}
		do headTowardsInformationCenter;
	}
	
	reflex beIdle when: !isBadApple and targetPoint = nil{
		do wander;
	}
	
	reflex becomeBadApple when: thirst = 0 and flip(0.01){
		isBadApple <- true;
		myColor <- #black;
	}
	
	action setSailForThisJuiceStand(point newJuicePlace){
		if !(knownJuicePlaces contains(newJuicePlace)){
			knownJuicePlaces <- knownJuicePlaces + newJuicePlace;	
		}
		targetPoint <- newJuicePlace; 
		myColor <- #aqua;
	}
	
	action setSailForThisFoodStand(point newFoodPlace){
	 	if !(knownFoodPlaces contains(newFoodPlace)){
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
					juice <- one_of(newJuicePlaces);
				}
				write "Neighbor told me to goto" + juice;
				do setSailForThisJuiceStand(juice);
			} else if isHungry() and !empty(foodKnowers){
				point food <- nil;
				ask one_of(foodKnowers){
					list<point> newFoodPlaces <- knownFoodPlaces where(!(myself.knownFoodPlaces contains(each)));
					food <- one_of(newFoodPlaces);
				}
				write "Neighbor told me to goto" + food;
				do setSailForThisFoodStand(food);
			}
		}
	}
	
	//Enter store when hunger/thirst is below threshold, and close to store
	reflex pickUpFoodOrAskForDirectiosn when: !isBadApple and targetPoint != nil and location distance_to(targetPoint) <5{
		if targetPoint = {50,50}{
			point juice <- nil;
			point food <- nil;
			if isThirsty() and isHungry() {
				if flip(0.5){
					ask one_of(InformationCenter){ juice <-getAJuiceShop();} 
				} else {
					ask one_of(InformationCenter){food <-getAFoodShop();} 
				}
			} else if isThirsty() {
			 	ask one_of(InformationCenter){ juice <-getAJuiceShop();} 
			} else {
				ask one_of(InformationCenter){food <-getAFoodShop();} 
			}
			if juice != nil {
				do setSailForThisJuiceStand(juice);
			} else {
				do setSailForThisFoodStand(food);
			}
		} else {
			ask Shop closest_to targetPoint{
				if isFoodShop{
					myself.hunger<-0;
				} else {
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
			do setSailForThisJuiceStand(one_of(knownJuicePlaces));
		} else if isHungry() and !empty(knownFoodPlaces) and !isSeekingNewFood{
			do setSailForThisFoodStand(one_of(knownFoodPlaces));
		} else {
			//Discover new place.
			do headTowardsInformationCenter;	
		}
	}
	
	action headTowardsInformationCenter{
		myColor <- #red; // Have need & is questing for new information.
		targetPoint <- {50,50}; 
		// Going to InformationCenter
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
	
	reflex beIdle when: targetPoint = nil{
		do wander;
	}
	
	list<FestivalGuest> nearbyBadApples {
		return FestivalGuest where(each.isBadApple and each.location distance_to location <5);
	}
	
	bool isNearBadApple{
		 return !empty(nearbyBadApples);
	}
	
	reflex killBadApple when: isNearBadApple(){
		list<FestivalGuest> badApples <- nearbyBadApples();
		ask one_of(badApples){
		 		do die;
		}
	}
	
	reflex goBackToIdle when: targetPoint != nil and location = targetPoint {
		targetPoint <- nil;
	}
	
	action goToBadApple(point badAppleLocation) {
		targetPoint <- badAppleLocation;
	}
	
	reflex moveToTarget when: targetPoint != nil{
		do goto target:targetPoint;
	}	
}

species Shop {
	bool isFoodShop <- flip(0.5);
	aspect default{
		if(isFoodShop){
			draw circle(3) at: location color: #hotpink;	
		} else {
			draw circle(3) at: location color: #aqua;
		}
		
	}
}

species InformationCenter {
	init {
     location <- {50,50};
     //list<Shop> all_shops <- prey inside (my_cell);
    }
	aspect default{
		draw square(10) at: location color: #orange;
	}
	
	point getAFoodShop{
		return one_of(Shop where (each.isFoodShop)).location;
	}
	
	point getAJuiceShop{
		return one_of(Shop where (!each.isFoodShop)).location;
	} 
}

global {
	init {
		create FestivalGuest number: 100;
		create Shop number: 5;
		create InformationCenter number: 1;
		create SecurityGuard number:5;
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
