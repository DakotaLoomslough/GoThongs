#define db3$use_cache
#include "got/_core.lsl"

#define log(text) //llOwnerSay(llGetTimestamp()+" "+text)

// Used for "" loading and reporting
integer BFL;
#define BFL_HAS_ASSETS 0x1
#define BFL_HAS_SPAWNS 0x2
#define BFL_SPAWNING_INI 0x4

timerEvent( string id, string data ){

	if( id == "INI" ){
		
		BFL = BFL&~BFL_SPAWNING_INI;
		list d = [BFL&BFL_HAS_ASSETS, BFL&BFL_HAS_SPAWNS];
		raiseEvent(LevelLoaderEvt$defaultStatus, mkarr(d));
		
	}
	
}

default{

    state_entry(){
	
		if(llGetStartParameter() == 2)
			raiseEvent(evt$SCRIPT_INIT, "");
		db3_cache();
		
    }
    
	
	timer(){multiTimer([]);}

    #include "xobj_core/_LM.lsl"
	if(method$isCallback){
	
		if(SENDER_SCRIPT == "got Spawner" && (METHOD == SpawnerMethod$spawnThese || METHOD == SpawnerMethod$spawn)){
		
			//list parse = llJson2List(CB);
			//if(l2s(parse, 0) == "HUD" || l2s(parse, 0) == "CUSTOM"){
			raiseEvent(LevelLoaderEvt$queueFinished, CB);
			//}
			
		}
		return;
		
	}
	

	// Spawn the level, this goes first as it's fucking memory intensive
    if(METHOD == LevelLoaderMethod$load && method$internal){
	
        integer debug = (integer)method_arg(0);
		
		list groups = [method_arg(1)];
		if(llJsonValueType(method_arg(1), []) == JSON_ARRAY)
			groups = llJson2List(method_arg(1));
		
		// Spawning the whole thing if the first group is "" (IE. load live)
		if( l2s(groups, 0) == "" ){
		
			BFL = BFL&~BFL_HAS_ASSETS;
			BFL = BFL&~BFL_HAS_SPAWNS;
			BFL = BFL|BFL_SPAWNING_INI;
			
		}

		
		list out;					// Data to push to spawners
		list data;					// Asset data
		integer spawned;			// Nr spawned
		
        // Spawn from HUD
		list HUD = Level$HUD_TABLES;
		list_shift_each(HUD, table,
		
			log(">> Table "+table);
			// Get spawns from table
			data = llJson2List(db3$get(table, []));
			log(">> Table FETCHED");
			
			// Iterate each spawn
			list_shift_each(data, v,
			
				// Single spawn data
				list val = llJson2List(v);
				
				// Get spawnround
				list l = llList2List(val, 4, 4);
				if( l == [] )
					l = [""];
					
				// See if this should be spawned in one of these groups
				integer pos = llListFindList(groups, l);
				
				// Get the group name
				string group = llList2String(groups, pos);
				
				if(~pos){ 
				
					++spawned;
					log("M "+(str)spawned);
					// Data to send
					string chunk = llList2Json(JSON_ARRAY, [
						llList2String(val, 0), 
						(vector)llList2String(val, 1)+llGetRootPosition(), 
						llList2String(val, 2), 
						llList2String(val, 3), 
						debug, 
						FALSE, 
						group
					]);
					// Reached cap, send
					if(llStringLength(mkarr(out)+chunk)>512){
						// Send out
						Spawner$spawnThese(llGetOwner(), out);
						log("Sending spawner chunk "+mkarr(out));
						out = [];
					}
					
					// Add the chunk
					out+= chunk;
					
				}
			)
		)
		

		// Send any stragglers
		if(out){
			Spawner$spawnThese(llGetOwner(), out);
			log("Sending spawner chunk "+mkarr(out));
		}
		
		// Append a callback so we know if it has finished loading
		out = [llList2Json(JSON_ARRAY, [
			"_CB_", "[\"HUD\","+mkarr(groups)+"]"
		])];
		Spawner$spawnThese(llGetOwner(), out);
		
		
		
		// There was at least 1 spawn
		if( !spawned )
			BFL = BFL|BFL_HAS_SPAWNS;
		

			
		//qd("Spawned "+(str)spawned+" monsters");
        spawned = 0;
		
        // Spawn from the level itself
		out = [];
        
		list CUSTOM = Level$CUSTOM_TABLES;
		list_shift_each(CUSTOM, table,
		
			// Get data from the table
			data = llJson2List(db3$get(table, []));
			log(">> Table "+table);
			
			// Cycle each entry
			list_shift_each(data, v,
			
				// Get info about the spawn
				list val = llJson2List(v);
				
				// Get the group from the spawn
				list l = llList2List(val, 4, 4);
				if( l == [] )
					l = [""];
					
				// Test if group is in the batch that is spawning
				integer pos = llListFindList(groups, l);
				string group = llList2String(groups, pos);
				
				if( ~pos ){
				
					++spawned;
					log("C "+(str)spawned);
					// Add to queue
					string add = llList2Json(JSON_ARRAY, [
						llList2String(val, 0), 
						(vector)llList2String(val,1)+llGetRootPosition(), 
						llList2String(val, 2), 
						llStringTrim(llList2String(val, 3), STRING_TRIM), 
						debug, 
						FALSE, 
						group
					]);
					
					// Send chunks every 1024 or so to prevent stack heaps
					if(llStringLength(mkarr(out))+llStringLength(add) > 512){
						Spawner$spawnThese(LINK_THIS, out);
						log("Sending internal chunk "+mkarr(out));
						out = [];
					}
					out += add;
					
				}
				
			)
		)
		
		if( out ){
			Spawner$spawnThese(LINK_THIS, out);
			log("Sending internal chunk "+mkarr(out));
		}
		
		out = [llList2Json(JSON_ARRAY, [
			"_CB_", "[\"CUSTOM\","+mkarr(groups)+"]"
		])];
		Spawner$spawnThese(LINK_THIS, out);

		// assets are needed
		if( spawned )
			BFL = BFL|BFL_HAS_ASSETS;

		out = [];
		
		if( BFL&BFL_SPAWNING_INI )
			multiTimer(["INI", "", 3, FALSE]);	// 3 sec grace period after initial load for any other items to arrive
		
    }
	
	
    
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
    
    
}

