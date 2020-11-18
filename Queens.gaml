/**
* Name: Queens
* Based on the internal empty template. 
* Author: fil
* Tags: 
*/


model Queens

/* Insert your model definition here */

// nxn board, with n queens
// grid based approach from predator / prey

species Queen skills: [fipa]{
	//check all positions.
	//if none valid, say to "previous" queen, please move.
	board_cell cell <- one_of(board_cell);
	list previousCells <- [];
	Queen parent <- nil;
	
	init {
		location <- cell.location;
		//if invalid location, ask parent to move
		
	}
	
	
	aspect base {
    	draw circle(3) color: #blue;
    }
    
    reflex goToNextValidCell when: !empty(requests){
    	message req <- requests at 0;
    	previousCells<- previousCells + cell;
    		
    }
    
    bool locationIsValid{
    	if !empty(Queen where(each.cell.grid_x = cell.grid_x)){
    		
    	}
    	return false;
    }
    
}

grid board_cell width: N height: N neighbors: 8 {
	
}
   
global {
	int N <- 4;
    init {
    	create Queen with: (cell: board_cell grid_at {0, 0});
    	loop i from: 1 to: N {
    		board_cell thing <- one_of(board_cell where(each.grid_x = i));
    		create Queen with: (cell: thing, parent: (Queen at (i-1)));	
    	}
    	
    }
}

experiment MyExperiment type: gui {
    output {
        display MyDisplay type: opengl {
            grid board_cell lines: #black;
            species Queen aspect:base;
        }
    }
}
