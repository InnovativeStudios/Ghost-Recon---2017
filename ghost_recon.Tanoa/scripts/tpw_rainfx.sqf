/*
TPW RAINFX - rain droplet fx on the ground, player goggles and vehicle windscreens.
Version: 1.11
Author: tpw
Date: 20160611
Requires: CBA A3, tpw_core.sqf
Compatibility: SP

Disclaimer: Feel free to use and modify this code, on the proviso that you post back changes and improvements so that everyone can benefit from them, and acknowledge the original author (tpw) in any derivative works. 

To use: 
1 - Save this script into your mission directory as eg tpw_rainfx.sqf
2 - Call it with 0 = [] execvm "tpw_rainfx.sqf"; 

THIS SCRIPT WON'T RUN ON DEDICATED SERVERS
*/

if (isDedicated) exitWith {};
WaitUntil {!isNull FindDisplay 46};

//VARIABLES
tpw_rain_version = "1.11";

// SHOULD RAIN FX FUNCTIONS RUN?	
tpw_rain_fnc_check =
	{
	private ["_pos","_highpos"];
	while {true} do
		{
		// Raining	
		if (rain > 0.1) then
			{
			_pos = eyepos player;
			_highpos = [_pos select 0,_pos select 1,(_pos select 2) + 10];
			
			// Run rain fx function if not undercover or underwater
			if (!(lineintersects [_pos,_highpos]) && !(underwater player)) then 
				{
				[] spawn tpw_rain_fnc_ground; 
				[] spawn tpw_rain_fnc_raindrops; 
				};
			};	
		sleep 1;	
		};
	};
	
// RAIN DROPS ON VEHICLE WINDOWS AND PLAYER GOGGLES
tpw_rain_fnc_raindrops =
	{
	private ["_int","_rainemitter","_showdrops","_lt","_sz","_dst"];
	if (cameraview == "internal") then 
		{
		_showdrops = false;
		// Player on foot and wearing goggles
		if (vehicle player == player && {goggles player !=""}) then
			{
			_int = 0.01 / rain; // more drops if heavier rain
			_lt = 0.05; // droplet lifetime
			_sz = 0.3; // drop size
			_dst = 2; // max spawn distance
			_showdrops = true;
			} else
			{
			// Player in car (not tank, boat, heli etc).
			if (vehicle player iskindof "car_f") then
				{
				_int = 0.0001 / rain; 
				_sz = rain * 0.1; // heavier rain = bigger drops 
				_dst = 5;
				if (speed player  > 10) then 
					{
					_int = _int / (speed player / 10); // more drops if moving
					};
				_lt = 0.05;
				_showdrops = true;
				};
			};
		if (_showdrops) then
			{
			_rainemitter = "#particlesource" createVehicleLocal getpos player;
			_rainemitter setParticleCircle [0.0, [0, 0, 0]];
			_rainemitter setParticleRandom [0, [_dst,_dst,_dst], [0, 0, 0], 0, 0.01, [0, 0, 0, 0.1], 0, 0];
			_rainemitter setParticleParams 
			[["\A3\data_f\ParticleEffects\Universal\Refract",1,0,1],
			"",
			"Billboard", 1,_lt, [0,0,0], [0,0,0], 1, 1000, 0.000, 1.7,[_sz],[[1,1,1,1]],[0,1], 0.2, 1.2, "", "", vehicle player];
			_rainemitter setDropInterval _int;    
			_rainemitter attachto [vehicle player,[0,0,0]];
			sleep 1;
			deletevehicle _rainemitter;
			};	
		};
	};
	
// RAIN DROPS ON GROUND
tpw_rain_fnc_ground =
	{
	private ["_int","_rainemitter","_drop","_lt","_sz","_dst"];
	if (vehicle player == player && {cameraview == "internal"}) then 
		{
		_int = 0.001 / rain; // more drops if heavier rain
		_lt = 0.05; // droplet lifetime
		_sz = 0.03; // drop size
		_dst = 5; // max spawn distance

		_rainemitter = "#particlesource" createVehicleLocal getpos player;
		_rainemitter setParticleCircle [0.0, [0, 0, 0]];
		_rainemitter setParticleRandom [0, [_dst,_dst,0.001], [0, 0, 0], 0, 0.01, [0, 0, 0, 0.1], 0, 0];
		_rainemitter setParticleParams 
		[["\A3\data_f\ParticleEffects\Universal\Refract",1,0,1],
		"",
		"Billboard", 1,_lt, [0,0,0], [0,0,0], 1, 1000, 0.000, 1.7,[_sz],[[1,1,1,1]],[0,1], 0.2, 1.2, "", "", vehicle player];
		_rainemitter setDropInterval _int;    
		_rainemitter attachto [vehicle player,[0,0,0]];
		sleep 1;
		deletevehicle _rainemitter;
		};	
	};	
		
// RUN IT	
[] spawn tpw_rain_fnc_check;

while {true} do
	{
	// dummy loop so script doesn't terminate
	sleep 10;
	};