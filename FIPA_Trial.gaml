/**
* Name: FIPA
* Based on the internal empty template. 
* Author: Fil & Omkar
* Tags: 
*/

model FIPA
species Auctioneer skills:[fipa]{
	string itemType <- 'teapot';
	int money <- 0;
	int startPrice <- 100;
	int numberOfItems <-1;
	int sellPrice <- startPrice;
	list participants <- [];	
	bool isDone <- false;
	float startNewAuctionTime <- 1.0;
	int step <- 5;
		
	aspect default{
		draw pyramid(2) at: location color:#yellow;
		draw sphere(1) at: {location.x,location.y,1.5} color:#yellow; 
		draw string(name+":"+money) at: location +{0,0,5} color:#black; 
	}
	
	action endAuction (message ignore){
		//Tell everyone the auction is over
		loop p over: participants{
			if(ignore = nil or p != ignore.sender){
				do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: [false,itemType];
			}
		}
		participants <- [];
	}
}


species Dutch_Auctioner parent: Auctioneer {
	int saleMinimum <- rnd(30,70);
	reflex add_participants when: !(empty(agrees)){
		loop a over: agrees{
			participants <- participants + a.sender;
			list laugh <- a.contents;
		}
		write name+': Starting auction for '+ itemType+' at ' + sellPrice;
		do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [itemType, sellPrice];
	}
	
	reflex start_Auction  when: (startNewAuctionTime != -1 and time >= startNewAuctionTime  and empty(participants)){
		write "-----------------------------";
		if(numberOfItems <=0){
			write name+": Out of items to sell. Made "+money;
			startNewAuctionTime <- -1.0;
		} else if(isDone){
			write name+": Done selling items, due to lack of reasonable buyers. Made "+money;
			startNewAuctionTime <- -1.0;
		} else {
			//housekeeping for new auction.
			sellPrice <- startPrice;
			write name+': Asking for participants to buy '+ itemType;
			//Asking people to join auction
			do start_conversation to: list(Dutch_Participant) protocol: 'no-protocol' performative: 'inform' contents: [true,itemType];
			startNewAuctionTime <- -1.0; //ongoing Auction
		}
	}
	
	reflex read_proposals when: !(empty(proposes)){
		int bestPrice <- 0;
		message bestMessage <- nil;
		list proposals <- proposes;
		loop a over: proposals {
			int suggestedPrice <- int(list(a.contents)[0]);
			if suggestedPrice > bestPrice {
				bestPrice <- suggestedPrice;
				bestMessage <- a;
			}
		}
		write name+": Offering to " + bestMessage.sender;
		//Send reject and accept messages.
		loop a over: proposals {
			if bestMessage.sender = a.sender {
				do accept_proposal message: bestMessage contents:[itemType];	
			} else {
				do reject_proposal message: a contents:[itemType];
			}
		}
		//Start a new round!
		if numberOfItems != 0 {
			startNewAuctionTime <- time+auctionWaitTime;
		} else {
			isDone <- true;
			write name+": Done selling items, sold everything! Made "+money;
		}
		
	}
	
	reflex read_informs when: !(empty(informs)){
		message inform <- (informs at 0);
		string trash <-inform.contents;
		money <- money + sellPrice;
		numberOfItems <- numberOfItems-1;
		write name +": Sold " + itemType +" for "+sellPrice + "!";
		do endAuction(inform);
	}
	
	reflex read_refuse_messages when: !(empty(refuses)){
		//No one would buy
		if length(refuses) = length(participants){
			sellPrice <- sellPrice - step;	
			if sellPrice <= saleMinimum{
				write name+": No one wanted to buy my "+itemType+", and I refuse to sell for "+sellPrice;
				do endAuction(nil);
				isDone<- true;
				write name+": Done selling items, due to lack of reasonable buyers. Made "+money;
			} else {
				write name+": No buyers this round... New round at "+sellPrice;
				do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [itemType, sellPrice];				
			}
		} else if empty(participants){
			bool potentialCustomers <- false;
			loop r over: refuses{
				if bool(list(r.contents)[0]){
					potentialCustomers <- true;	
				}
			}
			if potentialCustomers {
				write name + ": Has potential customers, starting new auction later";
				startNewAuctionTime <- time+auctionWaitTime;
			} else {
				isDone <- true;
				write name + ": No potential customers. Managed to make "+money;
			}
		}
		//Iterating over refusal messages to remove them from the list.
		loop r over: refuses{
			//This is silly. Should have a clean method.
			string trash <-r.contents;
		}
	}
}

species Participant skills:[fipa]{
	int buyPrice <- rnd(40,80);
	list items <- [];
	bool inAuction <- false;
	aspect default{
		draw pyramid(2) at: location color:#green;
		draw sphere(1) at: {location.x,location.y,1.5} color:#green;
		if items contains("teapot"){
			draw teapot(0.25) at: {location.x,location.y+1,0.5} color:#green;
		} 
		if items contains("soda") {
			draw cylinder(0.25,0.25) at: {location.x-1,location.y+1,0.5} color:#green;
		}
		if items contains("box") {
			draw cube(0.25) at: {location.x-1.5,location.y+1,0.5} color:#green;
		}
	}

}

species Dutch_Participant parent: Participant skills:[fipa]{

	reflex reply_messages when: !empty(cfps) {
		message cfp <- (cfps at 0);
		string type <- list(cfp.contents)[0];
		int sellPrice <- int(list(cfp.contents)[1]);
		if items contains(list(cfp.contents)[0]){
			//Message and will buy at lower price
			do refuse message: cfp contents: ['I already have taht', false];
		} else if sellPrice > buyPrice{
			//Message and will not buy more shoes
			do refuse message: cfp contents: ['Those are too expensive', true];
		} else {
			//Message that will buy shoes at this price.
			do propose message: cfp contents:[buyPrice];
		}
	}
	
	reflex reply_finalize_purchase when: !empty(accept_proposals){
		message accept <- (accept_proposals at 0);
		write name+': Yay! I have '+string(list(accept.contents)[0])+' now!';
		items <- items + string(list(accept.contents)[0]);
		inAuction <-false;
		do inform message:accept contents:[] ;
	}
	
	reflex handle_rejection when: !empty(reject_proposals){
		// :/ Did not get item I wanted, other proposal accepted before mine.
		message rejection <- reject_proposals at 0;
		string trash <- rejection.contents;
		inAuction <-false;
	}
	reflex reply_auction_inform when: !empty(informs){
		message inform <- (informs at 0);		
		bool start <- bool(list(inform.contents)[0]);
		string type <- list(inform.contents)[1];
		if start and inAuction{
			do refuse message:inform contents:[true]; //willing to join auction later
		} else if start {
			if items contains(type){
				do refuse message:inform contents:[false]; //will never join auction
			} else {
				write name + " joins "+ inform.sender + " for " + type;
				inAuction <-true;
				do agree message: inform contents:[true];
			}	
		} else {
			// End of auction I was in
			inAuction <- false;
		}
	}
	

}

species English_Auctioner parent: Auctioneer skills:[fipa]{
	message topBidder <- nil;
	int saleMinimum <- rnd(20,30);
	
	reflex start_Auction  when: (startNewAuctionTime != -1 and time >= startNewAuctionTime  and empty(participants)){
		write "-----------------------------";
		if(isDone){
			write name+": Done selling items, due to lack of reasonable buyers. Made "+money;
			startNewAuctionTime <- -1.0;
		} else {
			//housekeeping for new auction.
			sellPrice <-saleMinimum;
			write name+': Do I hear $'+sellPrice + " for this fantastic "+ itemType+"?";
			//Asking people to join auction
			topBidder <- nil;
			participants <-list(English_Participant);
			do start_conversation to: list(English_Participant) protocol: 'no-protocol' performative: 'inform' contents: [itemType, sellPrice];
			startNewAuctionTime <- -1.0; //ongoing Auction
		}
	}

	reflex handle_agrees when: !empty(agrees){
		participants <- [];
		list bidders <- agrees;
		topBidder <- bidders at 0;
		loop ag over: list(English_Participant){
			//Everyone who is not top Bidder
			if ag != topBidder.sender {
				participants <- participants + ag;
			}
		}
		write name+": "+sellPrice+" from "+topBidder.sender +"...";
		sellPrice <- sellPrice + step;
		write name+': Do I hear $'+sellPrice + " for this fantastic "+ itemType+"?";
		do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: [itemType, sellPrice];
		
		loop a over: agrees{
			string trash <- a.contents;//just to be safe
		}
	}
	
	reflex handle_refusals when: !empty(refuses){
		if(length(refuses) = length(participants) and(topBidder != nil)){
			//everyone said no
			sellPrice <- sellPrice -step;
			write "No? Then sold! to"+ topBidder.sender +" for "+sellPrice;
			money <- money + sellPrice;
			do agree message:topBidder contents:[itemType];
		} //else, who gives a fuck?
		
		loop a over: refuses{
			string trash <- a.contents;//just to be safe
		}
	}

}//end of english auctioneer

species English_Participant  parent: Participant skills:[fipa]{
	reflex reply_Start when: !empty(informs) {
		message inform <- (informs at 0);		
		string type <- list(inform.contents)[0];
		int sellPrice <- int(list(inform.contents)[1]);
		if !(items contains(type)) and (sellPrice <= buyPrice){
			//write name + ": Agrees to "+ inform.sender + "bid for " + type;
			do agree message: inform contents:[];
		} else {
			do refuse message:inform contents:[false];
		}	
	}
	
	reflex handle_agree when: !empty(agrees){
		message agree <- agrees at 0;
		write name+": Amazing. I love my new "+ string(list(agree.contents)[0]);
		items <- items + string(list(agree.contents)[0]);
	}
		
}

species Japanese_Auctioner parent: Auctioneer skills:[fipa]{
	int saleMinimum <- rnd(20,30);
	reflex start_Auction  when: (startNewAuctionTime != -1 and time >= startNewAuctionTime  and empty(participants)){
		write "-----------------------------";
		if(isDone){
			write name+": Done selling items, due to lack of reasonable buyers. Made "+money;
			startNewAuctionTime <- -1.0;
		} else {
			//housekeeping for new auction.
			sellPrice <-saleMinimum;
			write name+': '+itemType+' at $'+sellPrice ;
			//Asking people to join auction
			participants <-list(Japanese_Participant);
			do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: [itemType, sellPrice];
			startNewAuctionTime <- -1.0; //ongoing Auction
		}
	}
	
	reflex handle_refusals when: !empty(refuses){
		loop a over: refuses{
			string trash <- a.contents;//just to be safe
			participants <- participants - a.sender;
		}
		if length(participants) = 0 {
			write name +": Oops... everyone ran from the room";
		}
	}
	
	reflex handle_agrees when: !empty(agrees){
		if length(participants) = 1 {
			write name+": Sold, to " + (participants at 0);
			money <- money + sellPrice;
			do start_conversation to: participants protocol: 'no-protocol' performative: 'agree' contents: [itemType, sellPrice];	
		}  else {
			sellPrice <- sellPrice +step;
			write name+': '+itemType+' at $'+sellPrice ;
			do start_conversation to: participants protocol: 'no-protocol' performative: 'inform' contents: [itemType, sellPrice];
		}
		loop a over: agrees {
			string trash <- a.contents;
		}
	}

}//end of english auctioneer

species Japanese_Participant parent: Participant skills:[fipa]{
	reflex reply_Start when: !empty(informs) {
		message inform <- (informs at 0);		
		string type <- list(inform.contents)[0];
		int sellPrice <- int(list(inform.contents)[1]);
		if (items contains(type)) or (sellPrice > buyPrice){
			write name + ": Runs from room! ";
			do refuse message:inform contents:[];
		} else {
			do agree message:inform contents:[];
		}
	}
	
	reflex handle_agree when: !empty(agrees){
		message agree <- agrees at 0;
		write name+": Amazing. I love my new "+ string(list(agree.contents)[0]);
		items <- items + string(list(agree.contents)[0]);
	}
		
}

global {
	//Scenarios 0,1,2 (0 is basic, 1 is challenge 1, 2 is challenge 2)
	int scenario <- 2; 
	//Time auctioneers need to wait between starting new auctions.
	int auctionWaitTime <- 10;
	init {
		if scenario = 0{
			//Everyone wants tea
			create Dutch_Participant number: 3;
			create Dutch_Auctioner number:1;
		} else if scenario = 1{
			//People want what they don't have.
			create Dutch_Participant number: 3 with: (items:["teapot"]);
			create Dutch_Participant number: 4 with: (items:["soda"]);
			//Auctioneers sell different types of things
			create Dutch_Auctioner number:2 with: (itemType:"teapot");
			create Dutch_Auctioner number:2 with: (itemType:"soda");
		} else if scenario = 2 {
			int a <- rnd(50,60);
			int b <- rnd(50,70);
			int c <- rnd(50,80);
			int minimum <-rnd(30,70);
			write "Starting params a:"+a+", b:"+b+", c:"+c+" --- minimum:"+minimum;
			//People want what they don't have.
			create Dutch_Participant number: 1 with: (buyPrice: a);
			create Dutch_Participant number: 1 with: (buyPrice: b);
			create Dutch_Participant number: 1 with: (buyPrice: c);

			create English_Participant number: 1 with: (buyPrice: a);
			create English_Participant number: 1 with: (buyPrice: b);
			create English_Participant number: 1 with: (buyPrice: c);

			create Japanese_Participant number: 1 with: (buyPrice: a);
			create Japanese_Participant number: 1 with: (buyPrice: b);
			create Japanese_Participant number: 1 with: (buyPrice: c);

			create Dutch_Auctioner number:1 with: (itemType:"teapot", saleMinimum:minimum);
			create English_Auctioner number:1 with: (itemType:"soda", saleMinimum:minimum);
			create Japanese_Auctioner number:1 with: (itemType:"box", saleMinimum:minimum);
		}

	}
}

experiment main type: gui{
	output{
		display map type: opengl {
			//Teapot (teapot), Soda (cylinder), Box (square)
			species Dutch_Auctioner aspect: default; 
			species Dutch_Participant aspect: default;
			species English_Auctioner aspect: default; 
			species English_Participant aspect: default;
			species Japanese_Auctioner aspect: default; 
			species Japanese_Participant aspect: default;
		}
	}
}

/* Insert your model definition here */
