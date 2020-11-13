/**
* Name: FIPA
* Based on the internal empty template. 
* Author: Omkar Bhoite
* Tags: 
*/


model FIPA
global{
	float targetPoint<-nil;
	point I_location<-nil;
	point II_location<-nil;
	list bidder<-[];
	float startprice;
	float baseprice;
	float buyprice;
	
	init{
		create Auctioncenter number:1{
			location<-{25,25};
		}
		create Auctioner_1 number:1{
			startprice<-1000;
			baseprice<-500;
			location<-{20,20};
			
		}
		create Participant number:3{
			buyprice<-449;
		}
		create Auctioner_2 number:1{
			startprice<-1000;
			baseprice<-500;
			location<-{20,30};
		}
			bidder <- Participant;
		}
		
	}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
species Auctioncenter {
	aspect default{
		draw square(20) color:#aqua ;
	}
}
	
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
species Auctioner_2 skills:[fipa]{
	float price<-300;
	bool SOA_1;
	reflex start_auction  when: SOA_1= true{
		write 'Starting the auction-1';
		do start_conversation with: [to :: bidder, protocol::'fipa-contract-net',performative::'inform',contents::['Selling for price:'+price]];		
	}
	
	reflex call_for_proposals{
		write 'Calling';
		do start_conversation with: [to :: bidder, protocol::'fipa-contract-net',performative::'cfp',contents::['Sell for price:']];
		
	}
	reflex read_proposals when: !(empty(proposes)){
		loop p over: proposes{
			write 'Reading';
			if buyprice>=baseprice{
				do accept_proposal with:[message::p,contents::['Deal']];
			}
			else{
				do reject_proposal with:[message::p,contents::['No Deal']];				
			}
			
			
		}
	}
	
	aspect default{
		draw pyramid(2) at: location color:#green;
		draw sphere(1) at: {location.x,location.y,1.5} color:#green; 
	}
}




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species Auctioner_1 skills:[fipa]{
	float price;
	bool SOA;
	reflex start_auction  when: SOA= true{
		write 'Starting Auction';
		do start_conversation with: [to :: bidder, protocol::'fipa-contract-net',performative::'inform',contents::['Starting the auction']];	
	}
	
	reflex call_for_proposals{
		write 'Calling';
		do start_conversation with: [to :: bidder, protocol::'fipa-contract-net',performative::'cfp',contents::['Sell for price:']];
		
	}
	reflex read_proposals when: !(empty(proposes)){
		loop p over: proposes{
			write 'Reading';
			if buyprice>=baseprice{
				do accept_proposal with:[message::p,contents::['Deal']];
			}
			else{
				do reject_proposal with:[message::p,contents::['No Deal']];
				buyprice<-buyprice+10;				
			}
			
			
		}
	}
	
	aspect default{
		draw pyramid(2) at: location color:#yellow;
		draw sphere(1) at: {location.x,location.y,1.5} color:#yellow; 
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

species Participant skills:[fipa,moving]{
	reflex read_inform_message when: !(empty(informs)){
		loop i over: informs {
			write self.name + ': Information recieved for the auction : ' + string(i.contents);
		}
	}
	reflex read_cfp_message when: (!empty(cfps)){
		loop c over: cfps{
			do propose with:[message::c,contents::['Got the proposal']];
		}
	}
	reflex proposal_accepted when: !(empty(accept_proposals)){
		loop ap over: accept_proposals {
			write self.name + ': Acceptance recieved: ' + string(ap.contents);
			write self.name + ': OK.';
			do end_conversation with: [message :: ap, contents :: ['OK.']];
		}
	}
	reflex proposal_rejected when: !(empty(reject_proposals)) {
		loop rp over: reject_proposals {
			write self.name + ': Rejection recieved: ' + string(rp.contents);
			write self.name + ': OK.';
			do end_conversation with: [message :: rp, contents :: ['OK.']];
		}
	}
		
		//do agree with: (message:cfpFromInitiator, contents:['I will']);
		//write 'inform the initiator of the failure ';
		//do failure (message:cfpFromInitiator, contents: ['The bed is broken']);
	
	aspect default{
		draw pyramid(2) at: location color:#blue;
		draw sphere(1) at: {location.x,location.y,1.5} color:#blue;
	}
	reflex moveToTarget  when:(empty(accept_proposals))  
	{
		ask Auctioner_1{
		I_location<-location;
	}
		ask Auctioner_2{
		II_location<-location;
	}	
		do goto target:{II_location.x+3,II_location.y+2,II_location.z} speed:10.0;
		do goto target:{I_location.x+3,I_location.y+2,I_location.z} speed:10.0;
	}
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
experiment main type: gui{
	output{
		display map type: opengl{
			species Auctioner_1;
			species Participant;
			species Auctioner_2;
			species Auctioncenter;
			
		}
	}
}

/* Insert your model definition here */

