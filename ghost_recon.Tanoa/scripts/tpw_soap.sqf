/* 
TPW soap - Middle Eastern Ambience Pack
Author: tpw, autigergrad 
Date: 20160915
Version: 1.08
Requires: CBA A3, tpw_core.sqf
Compatibility: SP, MP client

Disclaimer: Feel free to use and modify this code, on the proviso that you post back changes and improvements so that everyone can benefit from them, and acknowledge the original author (tpw) in any derivative works.     

To use: 
1 - Save this script into your mission directory as eg tpw_soap.sqf
2 - Call it with 0 = [1,1,1,1,1,0,0,0] execvm "tpw_soap.sqf";  

1 = ambient sounds volume (0-2)
1 = music volume (0-2)
1 = Azan volume (0-2)
1 = house FX volume (0-2)
1 = scream volume (0-2)
0 = number of user music files in @TPW_MODS\music (0-20)
0 = number of user sound files in @TPW_MODS\sounds (0-20)
0 = region (0 = autoselect Greek/Fijian sounds on Greek/Fijian maps (1 = force Greek, 2 = force Mid East, 3 = force Fijian))

THIS SCRIPT WON'T RUN ON DEDICATED SERVERS.
*/

if (isDedicated) exitWith {};
WaitUntil {!isNull FindDisplay 46};
if (count _this < 8) exitwith {hint "TPW soap incorrect/no config, exiting."};

// READ IN CONFIGURATION VALUES
tpw_soap_version = "1.08"; // Version string
tpw_soap_ambientvolume = _this select 0; // Ambient sounds volume
tpw_soap_musicvolume = _this select 1; // Music volume
tpw_soap_azanvolume = _this select 2; // Azan volume
tpw_soap_housefxvolume = _this select 3; // House fx volume
tpw_soap_screamvolume = _this select 4; // Screams volume

tpw_soap_usermusic = _this select 5; // Number of user supplied songs
tpw_soap_usersounds = _this select 6; // Number of user supplied sounds
tpw_soap_region = _this select 7; // 0 = autodetect 1 = Greece, 2 = Mideast 

// OTHER VARS
tpw_soap_active = true; // Global enable/disabled
tpw_soap_radius = 50; // Distance around player to spawn ambience into houses
tpw_soap_attenuation = 100; // Distance over whic sound fades out
tpw_soap_greeksoundlength = [60,48,87,73,61,88,87,65,72,56,72,49,69,64,85,62,76]; // Length (sec) of each ambience clip in the order of the config
tpw_soap_greeksonglength = [69,187,165,149,153,181,240,194,175]; // Length (sec) of each song in the order of the config
tpw_soap_mideastsoundlength = [41,25,80,47,48,65,61,57,61,61,37,81,38,38,45,108,40,52,134,82,32,28,40,81,9,15,81,64,63,59,97,101,90,66,21,52]; // Length (sec) of each ambience clip in the order of the config
tpw_soap_mideastsonglength = [19,180,180,180,180,180,180,276,329,133,120]; // Length (sec) of each song in the order of the config
tpw_soap_fijisoundlength = [60,70,50,50,20,30,25,20,15,25,15,10,35,45,45,55]; // Length (sec) of each ambience clip in the order of the config
tpw_soap_fijisonglength = [220,180,40,120,120,130,150,110,80,180,180]; // Length (sec) of each song in the order of the config
tpw_soap_azanlength = [223,149,128,184,173,159,120,133,120,112];// Length (sec) of each Azan in the config
tpw_soap_songsplaying = 0; // How many songs
tpw_soap_maxsongs = 4; // Maximum simultaneous songs allowed
tpw_soap_soundsplaying = 0; // How many songs
tpw_soap_maxsounds = 12; // Maximum simultaneous sounds allowed
tpw_soap_dead = 0; // initial number of deaths
tpw_soap_nearhouses = []; // initial number of nearby buildings
tpw_soap_volume = 1; // MAster volume

// SUNRISE AND SUNSET
_riseset = [] call BIS_fnc_sunriseSunsetTime;
tpw_soap_sunrise = _riseset select 0;
tpw_soap_sunset = _riseset select 1;

// AUTO DETECT REGION
if (tpw_soap_region == 0) then
	{
	tpw_soap_region = 2;
	if  (tolower worldname in ["altis","stratis"]) then 
		{
		tpw_soap_region = 1;
		};
	if  (tolower worldname in ["tanoa"]) then 
		{
		tpw_soap_region = 3;
		};
	};

// IS PLAYER IN A HOUSE?		
tpw_soap_fnc_indoors = 
	{
	private ["_pos","_highpos","_return"];
	_pos = eyepos player;
	_highpos = [_pos select 0,_pos select 1,(_pos select 2) + 10];
	if (lineintersects [_pos,_highpos]) then
		{
		_return = true;
		}
		else
		{
		_return = false;
		};
	_return	
	};
	
// NEAREST BUILDING
tpw_soap_fnc_nearestbuilding =
	{	
	private ["_return"];

	// Workaround for bizarre building behaviour on Kidal
	if (tolower worldname in ["kidal","tanoa"]) then
		{
		_return = (nearestObject [player, "House"]) distance player; // will also return walls
		} else
		{
		_return = (nearestbuilding player) distance player;
		};
	_return
	};
	
// MAIN LOOP
tpw_soap_fnc_mainloop = 
	{
	
	while {true} do
		{
		// Scan houses only if fewer than maximum sounds are playing 
		if ((tpw_soap_active) && 
		{tpw_soap_soundsplaying < tpw_soap_maxsounds} && 
		{player == vehicle player} && 
		{!([] call tpw_soap_fnc_indoors)}) then
			{
			tpw_soap_nearhouses = [];
			if ([] call tpw_soap_fnc_nearestbuilding < tpw_soap_radius) then
				{
				0 = [] call tpw_soap_fnc_housescan;
				};
			};
		sleep 5.11;
		};
	};
	
// AZAN LOOP
tpw_soap_fnc_azanloop = 
	{
	tpw_soap_azanflag = 0;
	while {true} do
		{
		if ((tpw_soap_active) &&
		{tpw_soap_azanflag == 0} &&
		{(daytime > tpw_soap_sunrise - 1.25 && daytime < tpw_soap_sunrise - 1 ) || 
		(daytime > tpw_soap_sunrise && daytime < tpw_soap_sunrise + 0.25) || 
		(daytime > 11.75 && daytime < 12) || 
		(daytime > 14 && daytime < 14.25) ||
		(daytime > tpw_soap_sunset - 2 && daytime < tpw_soap_sunset - 1.75) || 
		(daytime > tpw_soap_sunset && daytime < tpw_soap_sunset + 0.25)}) then
			{
			0 = [] call tpw_soap_fnc_mosquescan;
			};
		sleep 61.3;
		};
	};
	
// HOUSE SCANNING 
tpw_soap_fnc_housescan =
	{
	private ["_nearhouses","_house","_i"];
	// Region - can be changed on the fly
	if (tpw_soap_region == 1) then
		{
		tpw_soap_sounds = 17;
		tpw_soap_songs = 9;
		tpw_soap_path = "TPW_AMBIENCE\sounds\greek\";
		tpw_soap_soundlength = tpw_soap_greeksoundlength;
		tpw_soap_songlength = tpw_soap_greeksonglength;
		tpw_soap_musicfactor = 1.2; // Slightly louder Greek music
		};
		
	if (tpw_soap_region == 2) then
		{
		tpw_soap_sounds = 36;
		tpw_soap_songs = 11;
		tpw_soap_path = "TPW_AMBIENCE\sounds\mideast\";
		tpw_soap_soundlength = tpw_soap_mideastsoundlength;
		tpw_soap_songlength = tpw_soap_mideastsonglength;
		tpw_soap_musicfactor = 0.8; // Slightly quieter Arabic music
		}; 	

	if (tpw_soap_region == 3) then
		{
		tpw_soap_sounds = 16;
		tpw_soap_songs = 11;
		tpw_soap_path = "TPW_AMBIENCE\sounds\fiji\";
		tpw_soap_soundlength = tpw_soap_fijisoundlength;
		tpw_soap_songlength = tpw_soap_fijisonglength;
		tpw_soap_musicfactor = 2; // Slightly quieter Fijian music
		}; 		
		
	// Adjust volume & chance of spawning based on time of day
	tpw_soap_soundvolmult =  [0.3,0.2,0.1,0.1,0.1,0.5,0.6,0.7,0.8,0.9,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,0.9,0.8,0.6,0.6,0.5,0.3,0.3] select (round daytime);
	tpw_soap_musicvolmult =  [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.5,0.6,0.7,0.8,0.9,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.2,1.1,1,0.8,0.6,0.4,0.0] select (round daytime);

	// Scan for habitable houses 
	_nearhouses = [tpw_soap_radius] call tpw_core_fnc_houses;
	tpw_soap_nearhouses = _nearhouses;
	
	// Loop through nearest houses, find first available
	for "_i" from 0 to (count tpw_soap_nearhouses - 1) do
		{
		_house = tpw_soap_nearhouses select _i;
		
		// Play environmental ambience if not already doing so
		if (
		(_house getvariable ["tpw_soap_ambienceflag",0] == 0) &&
		{_house distance player  > 5} &&
		{random 1 < tpw_soap_soundvolmult} &&
		{tpw_soap_soundsplaying < tpw_soap_maxsounds}
		) then 
			{
			tpw_soap_soundsplaying = tpw_soap_soundsplaying + 1;
			_house setvariable ["tpw_soap_ambienceflag",1,true];
			[_house] call tpw_soap_fnc_ambientsounds; 
			};
		
		// Occasionally play music if not already doing so
		if (
		(_house getvariable ["tpw_soap_musicflag",0] == 0)  && 
		{_house distance player  > 5} &&
		{random 50 < (1 * tpw_soap_musicvolmult)} &&
		{tpw_soap_songsplaying < tpw_soap_maxsongs}
		) then 
			{
			tpw_soap_songsplaying = tpw_soap_songsplaying + 1;
			_house setvariable ["tpw_soap_musicflag",1,true];
			[_house] call tpw_soap_fnc_ambientmusic; 
			};	
		};
	};
	
// MOSQUE SCANNING	
tpw_soap_fnc_mosquescan =
	{
	private ["_nearhouses","_nearmosques","_mosque","_i","_playflag"];
	// Scan for habitable houses - which can include mosques
	
	_nearhouses = [250] call tpw_core_fnc_houses;
	_nearmosques = [];
	
	// Grab nearest mosques - but only want one playing at a given time
	_playflag = 0;
	for "_i" from 0 to (count _nearhouses - 1) do
		{
		_mosque = _nearhouses select _i;
		if (["osque",str typeof _mosque] call BIS_fnc_inString) then 
			{
			_nearmosques set [count _nearmosques,_mosque];
			};
		};
	_nearmosques = [_nearmosques,[],{player distance _x},"ASCEND"] call BIS_fnc_sortBy;
	
	if ((count _nearmosques > 0) && {_mosque getvariable ["tpw_soap_azanflag",0] == 0}) then
		{
		_mosque = _nearmosques select 0;
		[_mosque] call tpw_soap_fnc_azanplay; 
		};
	};	

// PLAY MUSIC FROM HOUSES
tpw_soap_fnc_ambientmusic =
	{
	private ["_house","_sel","_len","_finish","_clip","_pos","_pitch","_atten"];
	_house = _this select 0;
	[_house] spawn	
		{
		sleep random 3;
		_house = _this select 0;
		_pitch = 1;
		_pos = getposasl _house;
		_atten = tpw_soap_attenuation + random tpw_soap_attenuation;
		
		// Music
		_sel = floor (random tpw_soap_songs);
		_clip = format ["%1s%2.ogg",tpw_soap_path,_sel + 1];	
		_len = tpw_soap_songlength select _sel;
			
		// Play user song from @TPW_MODS\music
		if ((tpw_soap_usermusic >0) && {random 10 < 5}) then
			{
			_clip = format ["@TPW_MODS\music\%1.ogg",floor (random tpw_soap_usermusic) + 1];
			_len = 180;
			};
		_finish = diag_ticktime + _len - 5;
		_house setvariable ["tpw_soap_musicflag",_finish,true];
		playsound3d [_clip,_house,false,_pos,(tpw_soap_musicvolume * tpw_soap_volume * tpw_soap_musicvolmult * tpw_soap_musicfactor),_pitch,_atten];
		waituntil
			{
			sleep 5;
			(diag_ticktime > _house getvariable "tpw_soap_musicflag");
			};	
		_house setvariable ["tpw_soap_musicflag",0,true];
		tpw_soap_songsplaying = tpw_soap_songsplaying - 1;
		};
	};	
	
// PLAY ENVIROMENTAL AMBIENCE IN HOUSES
tpw_soap_fnc_ambientsounds =
	{
	private ["_house","_sel","_len","_finish","_clip","_pos","_pitch","_atten"];
	_house = _this select 0;
	[_house] spawn	
		{
		sleep random 3;
		_house = _this select 0;
		_pitch = 0.9 + random 0.2;
		_pos = getposasl _house;
		_atten = tpw_soap_attenuation + random tpw_soap_attenuation;
		
		// Inbuilt SFX
		_sel = floor (random tpw_soap_sounds);
		_clip = format ["%1%2.ogg",tpw_soap_path,_sel + 1];	
		_len = tpw_soap_soundlength select _sel;

		// User SFX
		if ((tpw_soap_usersounds > 0) && {random 10 < 5}) then
			{
			_clip = format ["@TPW_MODS\sounds\%1.ogg",floor (random tpw_soap_usersounds) + 1];
			_len = 30;
			};
		_finish = diag_ticktime + _len - 5;
		_house setvariable ["tpw_soap_ambienceflag",_finish,true];
		playsound3d [_clip,_house,false,_pos,(tpw_soap_ambientvolume * tpw_soap_volume * tpw_soap_soundvolmult),_pitch,_atten];
		waituntil
			{
			sleep 5;
			(diag_ticktime > _house getvariable "tpw_soap_ambienceflag");
			};	
		_house setvariable ["tpw_soap_ambienceflag",0,true];
		tpw_soap_soundsplaying = tpw_soap_soundsplaying - 1;
		};
	};	

// PLAY AZAN IN NEARBY MOSQUE
tpw_soap_fnc_azanplay =
	{
	private ["_mosque","_sel","_len","_finish","_song","_vol","_pos"];
	_mosque = _this select 0;
	if (player distance _mosque > 250) exitwith {};
	[_mosque] spawn	
		{
		_mosque = _this select 0;
		_sel = floor random 10;
		_len = tpw_soap_azanlength select _sel;
		_song = format ["TPW_AZAN\sounds\%1.ogg",(_sel + 1)];
		_finish = diag_ticktime + _len;
		_mosque setvariable ["tpw_soap_azanflag",_finish,true];
		_vol = tpw_soap_azanvolume * 0.5 + random 0.5;
		_pos = getposasl _mosque;
		_pos = [_pos select 0, _pos select 1, (_pos select 2) + 50];
		playsound3d [_song,_mosque,false,_pos,_vol,1,0];
		tpw_soap_azanflag = 1;
		sleep 10;
		// Play prayer in nearest house
		playsound3d ["TPW_AMBIENCE\sounds\mideast\18.ogg",nearestbuilding player];
		waituntil
			{
			sleep 10;
			(diag_ticktime > _mosque getvariable "tpw_soap_azanflag");
			};	
		_mosque setvariable ["tpw_soap_azanflag",0,true];
		tpw_soap_azanflag = 0;
		};
	};		
	
// CREAKING NOISES IN HOUSES
tpw_soap_fnc_housenoise = 
	{
	private ["_sound","_pitch","_vol"];
	while {true} do
		{
		if (([] call tpw_soap_fnc_indoors) && {[] call tpw_soap_fnc_nearestbuilding < 10}) then
			{
			_pitch = 0.8 + random 0.4;
			_vol = (tpw_soap_housefxvolume * windstr * 0.25) + 0.1; // louder creaking in the wind
			_sound = format ["TPW_AMBIENCE\sounds\house\c%1.ogg",(ceil random 7)];
			playsound3d [_sound,player,false,getposasl player,_vol,_pitch,50];
			};
		sleep random 30;	
		};
	};
	
// WIND NOISE IN HOUSES	
tpw_soap_fnc_windnoise = 
	{
	private ["_sound","_pitch","_vol"];
	while {true} do
		{
		if (([] call tpw_soap_fnc_indoors) && {[] call tpw_soap_fnc_nearestbuilding < 10} && {windstr > 0.2}) then
			{
			_pitch = 0.8 + random 0.4;
			_vol = (tpw_soap_housefxvolume * windstr * 0.5) + 0.25;
			_sound = format ["TPW_AMBIENCE\sounds\house\w%1.ogg",(ceil random 9)];
			playsound3d [_sound,player,false,getposasl player,_vol,_pitch,50]; // wind
			sleep random 10;
			_sound = format ["TPW_AMBIENCE\sounds\house\r%1.ogg",(ceil random 6)]; // rattle
			playsound3d [_sound,player,false,getposasl player,_vol * 2,_pitch,50];
			};
		sleep 30 + random 10;	
		};
	};	
	
// MONITOR DEATHS, LOWER MASTER VOLUME FOR A FEW MINUTES AFTER EACH NEW DEATH
tpw_soap_fnc_battle =
	{
	private ["_battletime","_orig_vol"];
	_battletime = 0;
	_orig_vol = tpw_soap_volume;
	while {true} do
		{
		if (count alldeadmen > tpw_soap_dead) then
			{
			tpw_soap_dead = count alldead;
			_battletime = diag_ticktime + (random 120);
			tpw_soap_volume = _orig_vol * 0.5;
			};
		if  (diag_ticktime > _battletime) then
			{
			tpw_soap_volume = _orig_vol;
			};
		sleep 11.53;
		};
	};
	
// SCREAMS / BARKS IF NEARBY GUNFIRE
player addeventhandler ["firednear",{0 = [player] spawn tpw_soap_fnc_scream}];
tpw_soap_bulletcount = 0;
tpw_soap_nextcry = 0;
tpw_soap_fnc_scream =
	{
	private ["_sound","_pitch","_vol","_house","_nearhouses"];
	if ((tpw_soap_active) && {diag_ticktime > tpw_soap_nextcry} && {random 10 < 3}) then 
		{			
		tpw_soap_nextcry = diag_ticktime + random 15;	
		sleep 1 + random 5;
		_nearhouses = [tpw_soap_radius * 0.75] call tpw_core_fnc_houses;
		if ((_nearhouses select 0 distance player  < tpw_soap_radius) && {!([] call tpw_soap_fnc_indoors)}) then
			{
			_house = _nearhouses select floor (random (count _nearhouses));
			_vol = tpw_soap_housefxvolume * 2;
			_pitch = 0.9 + random 0.2;
			if (random 10 < 5) then
				{
				_sound = format ["TPW_AMBIENCE\sounds\fear\%1.ogg",(ceil random 12)]; // screams, babies
				} else
				{
				_sound = format ["TPW_SOUNDS\sounds\dog%1.ogg",ceil (random 20)]; // barks
				};
			playsound3d [_sound,_house,false,getposasl _house,_vol,_pitch,100];	
			};
		};
	};	
	
// RUN IT
[] spawn tpw_soap_fnc_battle;	
[] spawn tpw_soap_fnc_mainloop;
[] spawn tpw_soap_fnc_azanloop;
[] spawn tpw_soap_fnc_housenoise;
[] spawn tpw_soap_fnc_windnoise;

while {true} do
	{
	// dummy loop so script doesn't terminate
	sleep 10;
	};	