module main;
import start;

extern(C) void _d_assert_msg( 
  string msg, 
  string file, 
  uint line 
){}

struct Color
{	
	//static  if(__ctfe){ import std.bitmanip;}
	union{
    int Value=0;
	Color_t T;
	}
	alias T this;
}

struct Color_t {
	import mybitops:bitfields;
	mixin(bitfields!(		
			uint, "R", 8,
			uint, "G", 8,
			uint, "B", 8,
			uint, "A", 8));
}




static void main_loop(){
	
	Color Mycolor;
	
	enum state { one, two, three};
	state mystate=state.one;


	while(true){
		
		Mycolor.Value++;

		
		if(Mycolor.A>0){
			Mycolor.Value=0;
			mystate++;
			
			switch(mystate){
				default: 
				case state.one:
					mystate=state.one;
					RGB_LED(255,0,0); break;
				case state.two:
					RGB_LED(0,255,0); break;
				case state.three:
					RGB_LED(0,0,255); break;
				
			}
		}

	}

}
