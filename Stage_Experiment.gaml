/**
* Name: Stage
* Based on the internal empty template. 
* Author: fil
* Tags: 
*/


model Stage_Experiment

species Stage skills:[fipa]{
	//Lights, camera, band_fame, band_quality, ambience, audio_quality
	list concertAttributes <- [rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0)];
	int concertStartTime <- 1;
	int concertLength <- rnd(5,10);
	bool concertIsOn <- false;
	rgb colour <- #black;
	
	reflex startConcert when: time = concertStartTime{
		write name + " has started their concert";
		concertIsOn <- true;
	}
	
	reflex endConcert when: time = concertStartTime + concertLength{
		write name + " concert has ended";
		do endConcert();
		do prepareNewConcert();
	}
	
	action endConcert{
		concertIsOn <- false;
		//Tell everyone the show is over!	
	}
	
	action prepareNewConcert{
		concertAttributes <- [rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0)];
		concertStartTime <- int(time) + rnd(20,30);
		concertLength <- rnd(5,10);
		write name + " next concert at : "+concertStartTime;
	}
	
	reflex handle_request when: !empty(requests){
		message request <- requests at 0;
		do inform message: request contents:concertAttributes;
	}
	
	aspect default{
		draw square(20) at: location color:colour;
	}
	//Has a location that guests can travel to.
	//Hosts an act for a specific period of time
	//An act has specific attributes with different values
	//Can answer Guest questions over FIPA
	// 4+ stages
	//Every cnocert changes variable values
	//Challenge 1 : Add "crowd mass" to stage // concert
}

species Guest skills:[fipa]{
	list attributeLikes <- [rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0)];
	Stage concert <- nil;
	
	reflex prepareToGoToNewConcert when: concert = nil or !concert.concertIsOn{
		//Ask for concert information
		do start_conversation to: list(Stage) protocol: 'no-protocol' performative: 'request' contents: [];
	}
	
	reflex evaluateNextConcert when:!empty(informs) {
		concert <- nil;
		float highestUtility <- 0.0;
		write name +": Got "+length(informs) +" Messages";
		loop p over: informs {
			list propConcertAttributes <- p.contents;
			float propUtility <- calculateUtility(propConcertAttributes);
			if propUtility > highestUtility {
				concert <- p.sender;
				highestUtility <- propUtility;
			}
		}
		write name + " Chose concert " + concert;
		//TODO : Waiting for concert....
		location <- concert.location;
	}
	
	float calculateUtility(list proposed){
		//6 is number of variables
		float total <- 0.0;
		loop i from:0 to:5 {
			total <- total + float(proposed[i])* float(attributeLikes[i]);
		}
		
		return total;
	}
	
	aspect default{
		draw pyramid(2) at: location color:#green;
		draw sphere(1) at: {location.x,location.y,1.5} color:#green; 
	}
	//Can travel to Stage
	//Ask Stages about their attributes over FIPA/
	//Calculate utility of happiness for each stage
	//GOTO best stage.
	//6 + variables on stage.
	//Preferences do not change over time.
	/*Challenge 1:
	 * However, if only two agents are at an act and one of them prefers a crowd while the other one prefers less crowd, the former one should switch acts to maximize both agent‘s utility value
	 * 
	 * Maximize global utility, i.e highest happiness for everyone.
	 */
}

/* Insert your model definition here */

global {
	init{
		create Guest number: 2;
		create Stage with: (location: {20,20}, colour:#red);
		create Stage with: (location: {50,20}, colour:#blue);
		create Stage with: (location: {20,50}, colour:#purple);
		create Stage with: (location: {50,50}, colour:#orange);
	}
}

experiment MyExperiment type: gui {
	output {
		display default type:opengl {
			species Stage aspect: default;
			species Guest aspect: default;
		}
	}
}
