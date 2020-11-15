/**
* Name: FIPA
* Based on the internal empty template. 
* Author: Fil & Omkar
* Tags: 
*/

model FIPA
species Dutch_Auctioner skills:[fipa]{
	int startPrice <- 100;
	int sellPrice <- startPrice;
	int saleMinimum <- rnd(30,70);
	int downStep <- 10;
	int numberOfItems <-3;
	int money <- 0;
	float startOfSale <- 0.0;
	string itemType <- 'Shoes';
	bool isDone <- false;
	float startNewAuctionTime <- 1.0;
	list participants <- [];
	
	reflex start_Auction  when: (startNewAuctionTime != -1 and time >= startNewAuctionTime  and empty(participants)){
		write "-----------------------------";
		if(isDone){
			write name+": Done selling items, due to lack of reasonable buyers. Made "+money;
		} else {
			//housekeeping for new auction.
			startOfSale <-time;
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
			write name+": Done selling items, sold everything! Made "+money;
		}
		
	}
	
	
	reflex read_informs when: !(empty(informs)){
		message inform <- (informs at 0);
		money <- money + int(list(inform.contents)[0]);
		numberOfItems <- numberOfItems-1;
		write name +": Sold " + itemType +" for "+int(list(inform.contents)[0]) + "!";
		do endAuction(inform);
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
	reflex add_participants when: !(empty(agrees)){
		loop a over: agrees{
			participants <- participants + a.sender;
			list laugh <- a.contents;
		}
		write name+': Starting auction for '+ itemType+' at ' + sellPrice;
		do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [itemType, sellPrice];
	}
	
	
	reflex read_refuse_messages when: !(empty(refuses)){
		//No one would buy
		if length(refuses) = length(participants){
			sellPrice <- sellPrice - downStep;	
			if sellPrice <= saleMinimum{
				write name+": No one wanted to buy my shoes, and I refuse to sell them for "+sellPrice;
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
					write name+": "+r.sender+" says they may buy in future";
					potentialCustomers <- true;	
				}
			}
			if potentialCustomers {
				write name + ": Has potential customers, starting new auction later";
				startNewAuctionTime <- time+auctionWaitTime;
			} else {
				write name + ": No potential customers. Managed to make "+money;
			}
		}
		//Iterating over refusal messages to remove them from the list.
		loop r over: refuses{
			//This is silly. Should have a clean method.
			string trash <-r.contents;
		}
	}
	
	aspect default{
		draw pyramid(2) at: location color:#yellow;
		draw sphere(1) at: {location.x,location.y,1.5} color:#yellow; 
	}
}

species Dutch_Participant skills:[fipa]{
	int buyPrice <- rnd(40,80);
	list items <- [];
	bool inAuction <- false;
	
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
				write name + " joins auction for " + type;
				inAuction <-true;
				do agree message: inform contents:[true];
			}	
		} else {
			// End of auction I was in
			inAuction <- false;
		}
	}
	
	reflex reply_messages when: !empty(cfps) {
		message cfp <- (cfps at 0);
		string type <- list(cfp.contents)[0];
		int sellPrice <- int(list(cfp.contents)[1]);
		if items contains(list(cfp.contents)[0]){
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
	
	reflex reply_finalize_purchase when: !empty(accept_proposals){
		message accept <- (accept_proposals at 0);
		write name+': Yay! I have '+string(list(accept.contents)[0])+' now!';
		items <- items + string(list(accept.contents)[0]);
		inAuction <-false;
		do inform message:accept contents:[buyPrice] ;
	}
	
	reflex handle_rejection when: !empty(reject_proposals){
		// :/ Did not get item I wanted, other proposal accepted before mine.
		message rejection <- reject_proposals at 0;
		string trash <- rejection.contents;
		inAuction <-false;
	}
}

global {
		//Turns cop scenario on/off
	bool copScenario <- true;
	
	//Turns memory challenge on/off
	bool memoryScenario <- true;
	int auctionWaitTime <- 5;
	init {
		create Dutch_Participant number: 20;
		create Dutch_Auctioner number:5;
	}
}

experiment main type: gui{
	output{
		display map type: opengl {
			
		}
	}
}

/* Insert your model definition here */
