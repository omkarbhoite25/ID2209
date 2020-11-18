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
	board_cell cell <- nil;
	list previousCells <- [];
	Queen parent <- nil;
	bool informNext <- false;
	
	//When you ask your parent to move, empty your previousCells list.
	init {
		if cell != nil {
			location <- cell.location;
		}
	}
	
	reflex start when: informNext{
		do informMyChild;
		informNext <- false;
	}
	
	action informMyChild{
		write name + " informing next";
		int column <- cell.grid_x+1;
		if (column <N){
			write name + " asking" + column + "to place itself...";
			ask Queen at (column){
				do placeYourself(column);
			}
		}
		write name + " Done infroming next";
	}
	
	aspect base {
    	draw circle(3) color: #blue;
    }
    
    bool goToNextValidCell{
    	if(length(previousCells) <N-1){ // Ah, that's why.
    		do addToPrevious(cell);
    		cell <- board_cell grid_at {cell.grid_x,cell.grid_y+1};
    		location <- cell.location;
    		write name + " is now on "+cell.grid_x+","+cell.grid_y;
    		return true;
    	} else {
    		write name+": No valid locations left..";
    		return false;
    	}

    }
    action addToPrevious(board_cell toAdd){
    	if !(previousCells contains toAdd){
    		previousCells <- previousCells + toAdd;
    	}
    }
    
    action placeYourself(int startX){
    	cell <- board_cell grid_at {startX, 0};
    	location <- cell.location;
    	write name + " Placing itself at "+cell.grid_x+","+cell.grid_y;
    	loop while:!locationIsValid(){
    		if !goToNextValidCell(){
    			write name+" asking parent to move";
    			int column <- cell.grid_x-1;
    			cell <- nil;
    			location <- {0,0};
    			previousCells <- [];
    			ask Queen at (column){
    				do addToPrevious(cell);
					do placeYourself(column);
				}
    			return;
    		}
    	}
    	do informMyChild;
    }
    
    bool locationIsValid{
    	//Checks rows.
    	if previousCells contains cell{
    		write name + " Has previously been to "+cell;
    		return false;
    	}
    	if length(Queen where(each.cell!=nil and each.cell.grid_y = cell.grid_y)) >1{
    		write name + " found other queen on row";
    		return false;
    	}
    	//Check diagonal up.
    	int x <- cell.grid_x -1;
    	int y <- cell.grid_y -1;
    	
    	loop while: (x !=-1) and (y!=-1){
    		board_cell cellToCheck <-board_cell grid_at {x, y};
    		if !empty(Queen where(each.cell = cellToCheck)){
    			write name + " found other queen on upper diagonal";
    			return false;
    		}
    		x <- x-1;
    		y <- y-1;
    	}
    	
    	//Check diagonal down.
    	x <- cell.grid_x -1;
    	y <- cell.grid_y +1;
    	
    	loop while: (x !=-1) and (y<N){
    		board_cell cellToCheck <-board_cell grid_at {x, y};
    		if !empty(Queen where(each.cell = cellToCheck)){
    			write name + " found other queen on lower diagonal";
    			return false;
    		}
    		x <- x-1;
    		y <- y+1;
    	}
    	write name + " found no conflicting queens";
    	return true;
    }
    
}

grid board_cell width: N height: N neighbors: 8 {}
   
global {
	int N <- 8;
	Queen topQueen <- nil;
    init {
    	create Queen with: (cell: board_cell grid_at {0, 0}, informNext:true);
    	create Queen number: N-1 with: (location: {0,0});
    	topQueen <- Queen at 0;
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
