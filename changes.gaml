/**
* Name: Stage
* Based on the internal empty template. 
* Author: Omkar Bhoite
* Tags: 
*/
model NewModel

global {
	geometry shape <- square(120#m);
	point info_;
	list<Stage> Guest_at_stage;
	list<point> Stage_Location;
	int N;
	list<Guest> guestsAll;
	init {
		create Stage returns: d1 {location <- {20#m, 20#m};}
		Stage_Location <+ d1[0].location;
		create Stage returns: d2 {location <- {50#m, 20#m};}
		Stage_Location <+ d2[0].location;
		create Stage returns: d3 {location <- {20#m, 50#m};}
		Stage_Location <+ d3[0].location;
		create Stage returns: d4 {location <- {50#m, 50#m};}
		Stage_Location <+ d4[0].location;
		Guest_at_stage <+d1[0];
		Guest_at_stage <+d2[0];
		Guest_at_stage <+d3[0];
		Guest_at_stage <+d4[0];
		N <- 10;
		create Guest number: N-2 {
			location <- rnd({0, 0}, {120, 120});
			crowd_pref <- rnd(0.0,1.0,0.1);			
		}
		create Guest number: 2 {
			location <- rnd({0, 0}, {120, 120});
			crowd_pref <- -2.5;			
		}	
	}
	aspect default {
		draw square(100#m) at: {50, 50} color: #black;
	}
}

species Stage skills: [fipa] {
	float width <- 30#m;
	float height <- 30#m;
	bool eventOn <- false;
	int countdown <- 100 * rnd(1,12,1) update: countdown - 1;
	//Lights, camera, band_fame, band_quality, ambience, audio_quality
	list concertAttributes <- [rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1),rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1)];
	float crowdmass<-0.0;
	list<Guest> guestsIn <- [];
	int red <- 0;
	int green <-0;	
	
	init{///I don't know about this init////////////////////
		float Lights<-concertAttributes[0];
		float camera<-concertAttributes[1];
		float band_fame<-concertAttributes[2];
		float band_quality<-concertAttributes[3];
		float ambience<-concertAttributes[4];
		float audio_quality<-concertAttributes[5];
	}
	
	aspect default {
		if eventOn{
			color <- flip(0.5)? #purple : rgb(red,green,0);
		}else{
			color <-#white;
		}
		
		draw rectangle(width, height) at: location color: color;
		draw "Lights: "+string(concertAttributes[0]) at: location + {-10#m, 0}  color: #aqua font: font('Default', 18, #bold) ;
		draw "camera: "+string(concertAttributes[1]) at: location + {-10#m, 3}  color: #aqua font: font('Default', 18, #bold) ;
		draw "band_fame: "+string(concertAttributes[2]) at: location + {-10#m, 6}  color: #aqua font: font('Default', 18, #bold) ;
		draw "band_quality: "+string(concertAttributes[3]) at: location + {-10#m, 9}  color: #aqua font: font('Default', 18, #bold) ;
		draw "ambience: "+string(concertAttributes[4]) at: location + {-10#m, 12}  color: #aqua font: font('Default', 18, #bold) ;
		draw "audio_quality: "+string(concertAttributes[5]) at: location + {-10#m, 15}  color: #aqua font: font('Default', 18, #bold) ;
	}
	
	
	reflex crowdmassUpdate{
		if empty(guestsIn) {
			crowdmass <- 0.0;
		}else{
			crowdmass <-  length(guestsIn)/(N);
		}
		red <- int((crowdmass > 0.5 ? 1 - 2 * (crowdmass - 0.50) : 1.0) * 255);
		green <- int((crowdmass > 0.5 ? 1.0 : 2 * crowdmass ) * 255);
	}
	
	reflex announceEvent when: !eventOn and countdown = 0 {
		float Lights<-concertAttributes[0];
		float camera<-concertAttributes[1];
		float band_fame<-concertAttributes[2];
		float band_quality<-concertAttributes[3];
		float ambience<-concertAttributes[4];
		float audio_quality<-concertAttributes[5];
		do start_conversation (to: guestsAll, protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', Lights, camera,band_fame,band_quality,ambience,crowdmass,audio_quality,self,self.location]);
		write name + ' starts event';
		eventOn <- true;
		countdown <- int(1000 * rnd(0.7,1.0,0.1));
	}
	reflex listen when: eventOn and (!empty(cfps)){
		float Lights<-concertAttributes[0];
		float camera<-concertAttributes[1];
		float band_fame<-concertAttributes[2];
		float band_quality<-concertAttributes[3];
		float ambience<-concertAttributes[4];
		float audio_quality<-concertAttributes[5];
		message msg <- (cfps at 0);
		list<unknown> c1 <- msg.contents;
		string x1 <- string(c1[0]);
		if(x1 = 'Query' ){
			do start_conversation (to: msg.sender, protocol: 'fipa-propose', performative: 'cfp', contents: ['Start', Lights, camera,band_fame,band_quality,ambience,crowdmass,audio_quality,self,self.location]);
			//write name + ': '+ msg.sender +' asked info';
		}else if(x1 = 'Remove' ){
			//guestsIn >- msg.sender;
			//write name +" removed "+msg.sender;
		}
	}
	
	reflex end_event when: eventOn and countdown = 1{  
		if !empty(guestsIn){
			do start_conversation (to: guestsIn, protocol: 'fipa-propose', performative: 'cfp', contents: ['End']);	
		}
		eventOn <- false;
		guestsIn <-[];
		countdown <- 500;
	}	
}

species Guest skills: [moving , fipa]{
	
	point targetPoint <- nil;
	list attributeLikes <- [rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1),rnd(0.0,1.0,0.1), rnd(0.0,1.0,0.1)];
	float currentUtil;
	float crowd_pref<-0.0;
	Stage currentStage <- nil;
	bool isIdle <- true;

	init {
		// Place the guest randomly
		guestsAll <+ self;
		currentUtil<-0.0;
		crowd_pref <- flip(0.7)? 0.5:-1.5;
		
	}

	
	reflex beIdle when: currentStage = nil {		
		do wander speed:3.0 ;
	}
	
	
	reflex to_move when: currentStage != nil  {
		targetPoint <- currentStage.location + rnd({-25, -25}, {25, 25});
		if(time mod 100 = 0) and flip(0.5){
					do send_query_message;
					write "Mod for "+name;
		}
		do goto target: targetPoint;
	}
	
	
	action calcUtility(Stage d){
		float total <- 0.0;
			total<-(d.Lights * self.attributeLikes[0] + d.camera * self.attributeLikes[1] + d.band_fame * self.attributeLikes[2] + d.band_quality * self.attributeLikes[3] + d.ambience * self.attributeLikes[4] +d.audio_quality*self.attributeLikes[5]+ d.crowdmass * self.crowd_pref );
		return total;
	}
	
	reflex listen when: (!empty(cfps)){
		message msg <- (cfps at 0);
		list<unknown> c <- msg.contents;
		string x <- string(c[0]);
		if(x = 'Start' )//Event start
		{			
			list<unknown> c3 <- msg.contents;
			float x3 <- float(calcUtility(c3[7]));
			float util <- x3;
			//write " Event from "+ msg.sender;
			if (util > currentUtil){
					write name+": Proposed util: "+ util + "for "+ c3[7]+" is better than "+currentUtil;
					currentUtil <- util;
					if currentStage!=nil{
						do start_conversation (to: [currentStage], protocol: 'fipa-propose', performative: 'cfp', contents: ['Remove']);						
						currentStage.guestsIn >- self;
					}
					do accept_proposal ( message : msg, contents : [] );
					currentStage<- c3[7];
					isIdle <- false;
					currentStage.guestsIn <+self;	
			}else{
					do reject_proposal ( message : msg, contents : [] );
			}
		}else if(c[0] = 'End' ){
					write " Event from "+ msg.sender+" ended";
					currentStage.guestsIn >-self;
					currentStage<-nil;
					targetPoint <- nil;
					isIdle<-true;
					currentUtil <-0.0;
					do send_query_message;
		}
	}

	
	action send_query_message  {
		//write name + ' sends a query message';
		loop d over: Guest_at_stage{
			if d.eventOn{
				do start_conversation (to :: [d], protocol :: 'fipa-propose', performative :: 'cfp', contents :: ['Query']);
				//write name + ' sends a query message to '+ d;
				}
		}
	}
	
	aspect default {
		color <- #blue;
    	draw sphere(1) color:color;
    }	
}


experiment main type:gui{
	output {
		display my_display type:opengl{
			species Stage;
			species Guest;
		}
	}
}
