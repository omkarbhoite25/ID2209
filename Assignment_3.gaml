/**
* Name: Stage
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/

model Stage_Experiment

species Stage skills:[fipa]{
	//Lights, camera, band_fame, band_quality, ambience, audio_quality
	list concertAttributes <- [rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0)];
	bool beginNewConcert <- true;
	float concertEndTime <- -1.0;
	bool concertIsOn <- false;
	rgb colour <- #black;
	int concertNumber <- 0;
	
	init {
		do prepareNewConcert();
	}
	
	reflex startConcert when: beginNewConcert{
		write name + " has started their concert";
		concertIsOn <- true;
		beginNewConcert <- false;
	}
	
	reflex endConcert when: time = concertEndTime {
		write name + " concert has ended";
		do concertCleanup();
		do prepareNewConcert();
	}
	
	action concertCleanup{
		concertIsOn <- false;
		//Tell everyone the show is over!	
	}
	
	action prepareNewConcert{
		concertNumber <-concertNumber +1;
		concertAttributes <- [rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0)];
		beginNewConcert <- true;
		concertEndTime <- time+rnd(10,30);//Concert last between 5 and 10 cycles
	}
	
	reflex handle_request when: !empty(requests){
		message request <- requests at 0;
		do inform message: request contents:concertAttributes;
	}
	
	aspect default{
		int size <- 20;
		draw square(size) at: location color:colour;
		draw string(concertNumber) at:location - {size/2,size/2 -2,0} color:#black;
		loop i from:0 to:5 {
			draw string(concertAttributes[i]) at:location - {size/2,size/2 -4 -(2*i),0} color:#black;	
		}
		
		//draw string(concertAttributes[1]) at:location - {size/2,size/2 -4,0} color:#black;
		//draw string(concertAttributes[2]) at:location color:#black;
	}
	//Has a location that guests can travel to.
	//Hosts an act for a specific period of time
	//An act has specific attributes with different values
	//Can answer Guest questions over FIPA
	// 4+ stages
	//Every cnocert changes variable values
	//Challenge 1 : Add "crowd mass" to stage // concert
}

species Guest skills:[fipa,moving]{
	list attributeLikes <- [rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(1,10)];
	Stage concert <- nil;
	float currentUtility <- -1.0;	
	bool notWaiting <- true;
	point offset <- {0,0,0};
	float crowdFactor <-0.0;
	int crowd_mass<-0;
	bool concertendTimeforStage0<-false;
	bool concertendTimeforStage1<-false;
	bool concertendTimeforStage2<-false;
	bool concertendTimeforStage3<-false;
	bool beginNewConcert<-false;
	list<string> GuestAtStage0<-[];
	list<string> GuestAtStage1<-[];
	list<string> GuestAtStage2<-[];
	list<string> GuestAtStage3<-[];
	float GlobalUtility<-0.0;
	rgb colour <- #green;
//////////////////////////////////Fil access the concert starttime via fipa in bool format to make it true to start challenge and can you also add if there are to guest at the stage/////////////////	

	action challenge(int cp){
		add Guest to:GuestAtStage0 at:Stage(0).location+offset;
		add Guest to:GuestAtStage1 at:Stage(1).location+offset;
		add Guest to:GuestAtStage2 at:Stage(2).location+offset;
		add Guest to:GuestAtStage3 at:Stage(3).location+offset;
		int a<-length(GuestAtStage0);
		int b<-length(GuestAtStage1);
		int c<-length(GuestAtStage2);
		int d<-length(GuestAtStage3);
		int z<-max([a,b,c,d]);
		crowd_mass<-z;///////we know the stage at which more guest are there.
		if cp>=crowd_mass and crowd_mass=a{
				do goto target:Stage(0).location;
		}else if cp>=crowd_mass and crowd_mass=b{
				do goto target:Stage(1).location;
		}else if cp>=crowd_mass and crowd_mass=b{
				do goto target:Stage(2).location;
		}else if cp>=crowd_mass and crowd_mass=b{
				do goto target:Stage(3).location;
		}
	}
	
	
	
//////////////////////////////////Fil access the concert endtime via fipa in bool format atmake it true to clear the list/////////////////
	reflex clear_guest_list{
		if concertendTimeforStage0=true{
			GuestAtStage0<-[];
		}else if concertendTimeforStage1=true{
			GuestAtStage1<-[];
		}else if concertendTimeforStage2=true{
			GuestAtStage2<-[];
		}else if concertendTimeforStage3=true{
			GuestAtStage3<-[];
		}
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	init {
		if(flip(0.5)){
			//Dislikes crowds
			colour <- #aqua;
			crowdFactor <- 0.5;
		} else {
			//Likes to party
			colour <- #hotpink;
			crowdFactor <- 2.0;
		}
		offset <- {xOffset,8,0};
		xOffset <- xOffset +3 ;
	}
	
	reflex prepareToGoToNewConcert when: (concert = nil or !concert.concertIsOn) and notWaiting{
		//Ask for concert information
		currentUtility <- 0.0;
		location <- offset;
		write name + " Preparing to go to a new concert";
		do start_conversation to: list(Stage) protocol: 'no-protocol' performative: 'request' contents: [];
		notWaiting <-false;
		
	}
	
	reflex evaluateNextConcert when:!empty(informs) {
		concert <- nil;
		int crowd_preference<-attributeLikes[6];///////////////////////how much crowd does guest preffer 
		write name +": Got "+length(informs) +" Messages";
		loop p over: informs {
			list propConcertAttributes <- p.contents;
			float propUtility <- calculateUtility(propConcertAttributes);
			if propUtility > currentUtility or challenge(crowd_preference){
				concert <- p.sender;
				currentUtility <- propUtility;
			}
		}
		write name + " Chose concert " + concert + " w/ utility "+currentUtility;
		notWaiting <-true;
		location <- concert.location + offset;
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
		draw pyramid(2) at: location color:colour;
		draw sphere(1) at: {location.x,location.y,1.5} color:colour; 
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
	int xOffset <- -9;
	int N<-6;
	init{
		create Guest number: N;
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
