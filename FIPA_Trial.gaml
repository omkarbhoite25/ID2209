/**
* Name: FIPA
* Based on the internal empty template. 
* Author: Fil & Omkar
* Tags: 
*/

model FIPA
species Initiator skills:[fipa]{
	int startPrice <- 100;
	int sellPrice <- startPrice;
	int saleMinimum <- rnd(30,50);
	int downStep <- 10;
	int numberOfItems <-3;
	int money <- 0;
	float startOfSale <- 0.0;
	string itemType <- 'Shoes';
	bool isDone <- false;
	
	reflex send_request  when: (time =1){
		startOfSale <-time;
		write 'Selling shoes at ' + sellPrice;
		do start_conversation to: list(Participant) protocol: 'fipa-contract-net' performative: 'cfp' contents: [itemType, sellPrice];
	}
	
	reflex read_agree_messages when: !(empty(proposes)){
		int bestPrice <- 0;
		message bestMessage <- nil;
		loop a over: proposes {
			write 'Potential buyer: ' + string(a.sender)+ " for " + string(a.contents);
			int suggestedPrice <- int(list(a.contents)[0]);
			if suggestedPrice > bestPrice {
				bestPrice <- suggestedPrice;
				bestMessage <- a;
			}
		}
		if bestMessage != nil{
			money <- money + bestPrice;
			do accept_proposal message: bestMessage contents:[itemType];
		} else {
			write "error getting best price of buyers";
		}
	}
	
	
	//Might not care about refused messages at all
	reflex read_refuse_messages when: !(empty(refuses)){
		//No one would buy
		if length(refuses) = length(Participant){
			sellPrice <- sellPrice - downStep;	
			write name+": No buyers for my shoes :(... Now selling shoes at "+sellPrice;
			do start_conversation to: list(Participant) protocol: 'fipa-contract-net' performative: 'cfp' contents: [itemType, sellPrice];
		}
		//Remove refusal messages
		loop r over: refuses{
			string laugh <-r.contents;
		}
	}
	
	aspect default{
		draw pyramid(2) at: location color:#yellow;
		draw sphere(1) at: {location.x,location.y,1.5} color:#yellow; 
	}
}

species Participant skills:[fipa,moving]{
	int buyPrice <- rnd(1,80);
	//int fomoCost <- rnd(0,10);
	bool hasShoes <- false;
	
	reflex reply_messages when: !empty(cfps) {
		message cfp <- (cfps at 0);
		string type <- list(cfp.contents)[0];
		int sellPrice <- int(list(cfp.contents)[1]);
		if list(cfp.contents)[0] = 'Shoes'{
			if hasShoes {
				//Message and will buy at lower price
				do refuse message: cfp contents: ['I already have shoes', false];
			} else if sellPrice > buyPrice{
				//Message and will not buy more shoes
				do refuse message: cfp contents: ['Those shoes are too expensive', true];
			} else {
				//Message that will buy shoes at this price.
				do propose message: cfp contents:[buyPrice];
			}
		}
	}
	
	reflex getShoes when: !empty(accept_proposals){
		message accept <- (accept_proposals at 0);
		write name+': Yay! I have '+string(list(accept.contents)[0])+' now!';
		do inform message:accept contents:[] ;
		hasShoes <- true;
	}
}

global {
	init {
		create Participant number: 10;
		create Initiator number:1;
	}
}

experiment main type: gui{
	output{
	}
}

/* Insert your model definition here */
