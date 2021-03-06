#ifndef _Trap
#define _Trap

#define TrapMethod$forceSit 1		// (key)victim, (float)duration[, (key)prim, (int)flags] - Will automatically send the forceSit quickrape to a player and sit them onto any "SEAT" named prim in the linkset. Prim can be a non key value instead of SEAT
	#define Trap$fsFlags$strip 0x1
	#define Trap$fsFlags$attackable 0x2	// Allows the victim to be attackable
	#define Trap$fsFlags$noAnims 0x4	// Do not animate
	
#define TrapMethod$end 2			// void - Force end
#define TrapMethod$useQTE 3			// (int)numTaps - Use a quicktime event. 0 numTaps disables
#define TrapMethod$anim 4			// (str)anim, (bool)start - Start or stop an animation on the victim

#define TrapEvent$triggered 1
#define TrapEvent$seated 2
#define TrapEvent$unseated 3
#define TrapEvent$qteButton 4		// (bool)correct - A QTE button has been pushed
#define TrapEvent$reset 5			// Trap has come off cooldown


#define Trap$useQTE(numTaps) runMethod((str)LINK_THIS, "got Trap", TrapMethod$useQTE, [numTaps], TNN)
#define Trap$forceSit(victim, duration, prim, flags) runMethod((string)LINK_THIS, "got Trap", TrapMethod$forceSit, (list)(victim)+(duration)+(prim)+(flags), TNN)
#define Trap$end(targ) runMethod((str)targ, "got Trap", TrapMethod$end, [], TNN)
#define Trap$startAnim(targ, anim) runMethod((str)targ, "got Trap", TrapMethod$anim, [anim, TRUE], TNN)
#define Trap$stopAnim(targ, anim) runMethod((str)targ, "got Trap", TrapMethod$anim, [anim, FALSE], TNN)

#endif
