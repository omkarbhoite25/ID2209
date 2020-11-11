/**
* Name: FIPA
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/


model FIPA
global{
	float targetPoint<-nil;
	point I_location<-nil;
	list bidder<-[];
	
	init{
		create Initiator number:1{
			
		}
		create Participant number:10{
			
		}
			bidder <- Participant;
		}
		
	}

/////////////////////////////////////////////////////////////////////////////

species Initiator skills:[fipa]{
	float price;
	bool SOA;
	reflex start_auction  when: SOA= true{
		write 'Starting Auction';
		do start_conversation with: [to :: bidder, protocol::'fipa-contract-net',performative::'inform',contents::['Sell for price:']];		
	}
	
	reflex call_for_proposals{
		write 'Calling';
		do start_conversation with: [to :: bidder, protocol::'fipa-contract-net',performative::'cfp',contents::['Sell for price:']];
		
	}
	reflex read_proposals when: !(empty(proposes)){
		loop p over: proposes{
			write 'Reading';
			do accept_proposal with:[message::p,contents::['Deal']];
			do reject_proposal with:[message::p,contents::['No Deal']];
			
		}
	}
	
	aspect default{
		draw pyramid(2) at: location color:#yellow;
		draw sphere(1) at: {location.x,location.y,1.5} color:#yellow; 
	}
}

//////////////////////////////////////////////////////////////////////////////////////

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
	reflex proposal_accepted when: !(empty(accept_proposals)) {
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
	reflex moveToTarget  when: (empty(informs)) 
	{
		ask Initiator{
		I_location<-location;
	}		
		do goto target:{I_location.x+3,I_location.y+2,I_location.z} speed:1.0;
	}
}


/////////////////////////////////////////////////////////////////////////////////////////////
experiment main type: gui{
	output{
		display map type: opengl{
			species Initiator;
			species Participant;
			
		}
	}
}

/* Insert your model definition here */

