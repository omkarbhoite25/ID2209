/**
* Name: NewModel7
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/


model NewModel7

species Stage skills:[fipa]{
	//Lights, camera, band_fame, band_quality, ambience, audio_quality, crowdmass
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
	list attributeLikes <- [rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(0.1,1.0), rnd(6,10)];
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


species leader skills:[fipa]{
	float utility<-0.0;
	float new_utility<-0.0;
	list<int> goals<-[];
	
		reflex new_goal when:!empty(informs){
			list new_goal<-informs;
			if length(new_goal)=length(Guest){
				list guest_at_all_stages<-[];
				list crowd_level<-[];
				loop a over: new_goal{
					new_utility <- new_utility + float(a.contents);/////messed up
				}
				if new_utility>utility{
					utility<-new_utility;
					new_utility<-0.0;
					goals<-[];
					loop a over: new_goal{
						add int(a.contents) to: goals;
						}
					loop a from: 0 to: (length(Stage)-1){
							add 0 to: guest_at_all_stages;	
							add 0 to: crowd_level;
							}
					loop a over: new_goal{
						float v<-list(a.contents)[0];
						int b <- guest_at_all_stages[v];
						guest_at_all_stages[v] <- b + 1;
						}
					loop a from: 0 to: length(guest_at_all_stages) - 1{
						if string(guest_at_all_stages[a])as_int 10 >= N{
							crowd_level[a] <- 1;
						}
					}			
				do start_conversation with: [ to::list(Guest), protocol:: 'no-protocol', performative :: 'inform', contents::[crowd_level]];
					
			}else{
				
				write 'the utility is not better. move to the goal from the last solution!';
				write goals;
				
				
				do start_conversation with: [ to::list(Guest), protocol:: 'no-protocol', performative :: 'request', contents::goals];
				utility <- 0.0;
				new_utility <- 0.0;
				goals <- [];
				}	
				}
				
			}
			aspect default{
				draw pyramid(2) at: location color:#black;
				draw sphere(1) at: {location.x,location.y,1.5} color:#black;
			}
			
		}
	


/* Insert your model definition here */

global {
	int N<-10;
	init{
		create Guest number: N;
		create Stage with: (location: {20,20}, colour:#red);
		create Stage with: (location: {50,20}, colour:#blue);
		create Stage with: (location: {20,50}, colour:#purple);
		create Stage with: (location: {50,50}, colour:#orange);
		create leader number:1;
	}
}

experiment MyExperiment type: gui {
	output {
		display default type:opengl{
			species Stage aspect: default;
			species Guest aspect: default;
			species leader;
		}
	}
}

/* Insert your model definition here */

