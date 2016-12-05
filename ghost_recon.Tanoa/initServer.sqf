enableSaving [false, false];

[] spawn {
//	waitUntil {time > 5};
	["Revive Module is Enabled! \n\n When a player is down, revive them by holding 'Space' when prompted to. \n\n When you're incapacitated, you can force respawn by holding 'Space' if you don't want to wait for revive.", "hint", WEST, true] call BIS_fnc_MP;
};

while {true} do {
    waitUntil {time > 5};
    _locationType = ["NameCity", "NameCityCapital", "NameMarine", "NameVillage", "Airport"];
    _nearestCities = nearestLocations [getPos player, _locationType, 1200];
    _nearestCity = [_nearestCities, player] call BIS_fnc_nearestPosition;

    _hour = floor dayTime;
    _minute = floor ((dayTime - _hour) * 60);
    _second = floor (((((dayTime) - (_hour)) * 60) - _minute) * 60);

    if (_minute < 10) then {_minute = format ["0%1", _minute]};
    if (_second < 10) then {_second = format ["0%1", _second]};

    _time = text format ["%1:%2:%3", _hour, _minute, _second];
//    _time = [dayTime] call BIS_fnc_timeToString;

    _month = date select 1;
    _monthToYear = ["JAN", "FEB", "MAR", "APR", "MAY", "JUNE", "JULY", "AUG", "SEP", "OCT", "NOV", "DEC"];
    _day = date select 2;

    if (_day < 10) then {_day = format ["0%1", _day]};

    _date = text format ["%1 %2 %3", _day, _monthToYear select (_month - 1), date select 0];

//    hint format ["%1",_nearestCity];

    if (position player distance _nearestCity < 600) then {
        [text(_nearestCity), str(_time), str(_date)] call BIS_fnc_infoText;
    } else {
//        hint "DEBUG: NO LOCATION NEARBY";
    };
    sleep 300;
};

// The script runs every 5min and will only call BIS_fnc_infoText if the player is 600m or less from a specified location type within the _locationType array.