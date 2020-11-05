/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Omkar
* Tags: 
*/


model HAgent
global{
	
	init{
		create Guests number:50
		{
			
		}
		create IC number:1 
		{
			location<-{50,50,0};
		}
		create Shops number:5
		{
			
		}
		create DieAgentDie number:3
		{
			
		}
	}
}

species guard skills:[moving]{
	point guard_pose<-nil;
	reflex beIdle when: guard_pose=nil
	{
		do wander;
	}
	//reflex moveToTarget when:die_pose = nil
	//{
		
	//}
}

species DieAgentDie skills:[moving]{
	point die_pose<-nil;
	reflex beIdle when: die_pose !=nil
	{
		do wander;
	}
    reflex being_killed
     {
        do debug("I will disappear from the simulation");
        do die;
    }
    aspect {
		draw pyramid(2) at: location color:#black;
		draw sphere(1) at: {location.x,location.y,1.5} color:#black;
	}
}




species Guests skills:[moving]{
	rgb myColor<-#red;
	point targetPoint<-nil;
	point IC_pos<-{50,50,0};
	reflex beIdle when: targetPoint =nil	
	{
		do wander;
	}
	reflex changeColor{
		myColor<-flip(0.4)? #red: #blue;
		
		
	}
	reflex moveToTarget when: targetPoint = nil
	{
		do goto target:targetPoint;
	}
	reflex enterStore when: location distance_to(IC_pos)<10
	{
		write "Doing something";
		do	goto target:IC_pos;
	} 
	reflex logBlueColor when: myColor=#blue{
		write self.name+"Hi........";
	}
	aspect {
		draw pyramid(2) at: location color:#yellow;
		draw sphere(1) at: {location.x,location.y,1.5} color:#yellow;
	}
	reflex update{
		ask IC{
			write self.name;	
			
		}
	}
}



species IC{
	
	
	aspect {
		draw cube(8) at: location color:#blue; 
		draw pyramid(8) at: {50,50,8} color:#blue;
		
	}
}





species Shops{
	
	rgb myColor<-#red;
	
	
	aspect {
		draw pyramid(4) at: location color:myColor;
	}
}








experiment main type: gui{
	output{
		display map type: opengl{
			species Guests;
			species IC;
			species Shops;
			species DieAgentDie;
		}
	}
}






/* Insert your model definition here */

