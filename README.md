# Dead's PvP Script Suite

## Downloads
Simply right-click on the links below and select "Save Link As..." to download the configuration files:
 - [DeadGunner_Min.conf](https://raw.githubusercontent.com/Deadrank/DeadRank-DU/main/DeadGunner_min.conf) (Use these)
 - [DeadRemote_Min.conf](https://raw.githubusercontent.com/Deadrank/DeadRank-DU/main/DeadRemote_min.conf) (Use these)
 - 
 - [DeadGunner.conf](https://raw.githubusercontent.com/Deadrank/DeadRank-DU/main/DeadGunner.conf) (works but deprecated)
 - [DeadRemote.conf](https://raw.githubusercontent.com/Deadrank/DeadRank-DU/main/DeadRemote.conf) (works but deprecated)

## Installation
1) Download the .conf file(s) you would like to use
2) Place them in your `custom` folder in the DU game path (defaults to here on installation: `C:\ProgramData\Dual Universe\Game\data\lua\autoconf\custom`
3) Update custom scripts in-game or log in if the game is not running
4) Run the custom script autoconfiguration on the correct device (gunner chair or remote)
   
## 5.0.1 Bug fixes/Updates
 - Important note: I will no longer be updating the DeadRemote.conf and DeadGunner.conf any updates from here forward will very likely be only to the -min versions of the script. I am deprecating the originals, just because they are to laggy and I would rather move forward on the -min versions that have better performance.
 - Fixed an issue where the shield resistance would be 100% set on Thermic if your shield profile was on "auto" and you had not taken any resent damage.
 - Fixed an issue where the resistances and shield stress were not accurately reflecting thier appropriate values
 - Fixed the DPS and Damage stat indicators. These numbers should now reflect an avg DPS and avg incoming damage over a short period (Lua export parameter: dmgAvgDuration)
 - Changed: Controller requires manual link to databank. This needed to happen to make it so the controller didn't try to link to all databanks on the ship
 - Added shield resistance reset cooldown timer
 - Added dynamic transponder codes via imported file (added back in from the main version using the `transponder.lua` file)
 - Added (but in testing)
   - `hvt.lua` - If this file is found in your custom folder, it will read the contents and add any of the ship ID's to your primary radar widget (if enabled). Format of the file is as follows:<br>
   ```
      return {
        [1] = '123456',
        [2] = '234567',
        [3] = '345678',
      }
    ```
   - `scouting.lua` - If this file is found in your custom folder, it will read the contents and use any custom ship names that match the ship IDs in the file and display those in the radar widget instead of their actual name:<br>
   ```
      return {
        ['123456'] = 'Johns Hauler',
        ['234567'] = 'Sweet Corvette',
      }
    ```
   - Lua Parameter `slave`: this sets the gunner chair up as a slave seat and it will connect to all databanks on the ship. When a non-slave seat selects a primary target in the lua channel (i.e. `123`), that selection is picked up by the slave seat and added to the primaries radar widget automatically
  
## 5.0.0 New release
 - Created new minimal version of HUD focused on performance (less screen lag), but has less features/info
 - Fixed issues with certain characters in ship names causing regex errors when parsing data
 - Known issues: DPS stats are not working, Shield resist information not accurately updating, possibly other small bugs. I do not currently play the game, so won't be updating the script soon. However, I did use the new minimal version in several fights before leaving the game and everything required for PvP functionally worked and it is safe to use.
## 4.2.5 Updates
 - Auto enable dampening when auto-pilot is enabled
## 4.2.4 Updates
 - Minor improvements (default HUD refresh rate lowered. Requires DB variable change)
 - Set the default option to show weapon widgets rather than hide them
 - Fixed a bug where all weapons were getting their own widgets
## 4.2.3 Updates
 - Minor updates/bug fixes
 - Added estimation of enemy shield resistance settings (lua print out on weapon hit).
## 4.2.2 Updates
 - Fixed a bug where shield resist profile would continually reset even if profile wasn't changed
## 4.2.1 Updates
 - Added new lua comand for manually setting shield resists `sp <profile name>` can now be used in lua chat to set predefined shield profiles.
 Default profiles are:
   - `auto` = Matches incoming damage
   - `cannon` = 50/50 split between `kn` and `th` damage types
   - `railgun` = 50/50 split between `am` and `em` damage types
   - `missile` = 50/50 split between `kn` and `am` damage types
   - `laser` = 50/50 split between `em` and `th` damage types
   - `am` = 100% resist of `am` damage type
   - `em` = 100% resist of `em` damage type
   - `th` = 100% resist of `th` damage type
   - `kn` = 100% resist of `kn` damage type
 - Custom profiles can be added to unit.start (eventually will add a lua file import for this) and should be formatted as follows
    `resistProfiles['custom'] = {['am']=<am resist>, ['em']=<em resist>, ['kn']=<kn resist>, ['th']=<th resist>}`
    Each resist should be the percent of shield resistance set to that damage type. Total resists should add up to 1 (i.e. .1, .1, .4, .4).

## Previous Updates
 - Updated all scripts to compensate for functions that now return true booleans instead of "1" or "0" as was done prior to DU 1.4.
 - Fixed an issue that could cause the radar widget to malfunction
 - Added Lua Parameter for screen refresh rate on the remote and adjusted the default rate (hopefully increase FPS)
 - Added option to disable adjustor dampening (`alt-d`)
 - Added tracking mode (alt-5) that changes the way the script handles position tags entered into lua chat (tracking mode or autopilot)
 - Primary Target Radar:
   1) A new radar widget is now shown by default (can be disabled via lua parameter `targetRadar`)
   2) Add ships to primary radar using `a###` command in lua chat (`a` then the 3 digit ship code)
   3) Remove ships from the primary radar using `d###` command in lua chat (`d` then the 3 digit ship code)
   4) Clear the primary radar completely using `d0` command in lua chat
   5) The extra radar widget can be removed or added from the screen with either `primary radar off` or `primary radar on`
 - Trajectory Estimator:
   1) Target a construct (identification not required)
   2) Aim at the construct (diamond on the center of the screen)
   3) Hit the `space bar` to mark it's current position
   4) Repeat steps (2) and (3) again
   5) Destination is set 20su along the calculated trajectory, estimated travel indicator is started, estimated target speed is printed to lua chat
 - Damage Chart: Chart showing your Outgoing DPS vs Incoming DPS. Chart shows totals, not DPS against a specific target and is avg'd into 10 second chunks
 - Revamped default color scheme to be a little more immersive
 - `alt`+`shift`+`4` now sets your auto-pilot destination to your home base location (if you have one set/saved to the databank)

## DeadGunner.conf (Gunner Seat Script)
The gunner seat will control and/or read data from:
 - Weapons (manual link)
 - Radar (manual link)
 - Databank (auto link if present, optional) (links to all databanks on the construct, but only writes to one)

Any items listed above as manual link, must be linked *before* running  the autoconfiguration

### Hotkeys
 - `Alt`+`shift`+`2`: Changes the gunner seat AR Mode. Toggles through the following:
   - 'All' = Shows all gunner related AR points
   - 'FLEET' = Shows only fleet related AR points
   - 'ABANDONDED' = Shows only abandoned cores
 - `Alt`+`7`: Changes radar filtering mode. Toggles through the following options:
   - 'All' = Default mode that shows everything 
   - 'enemy' = Show only ships that do not have matching transponder tags or have a matching friendly ship ID
   - 'identified' = show only ships you have identified
   - 'friendly' = show only ships that have matching transponder tags or have a matching friendly ship ID
   - 'primary' = show ONLY your primary target in radar widget (see lua commands for how to choose a "primary" target)
 - `Alt`+`8`: Start/Stop shield vent manually

### Lua Commands
#### Transponder
 - `code <transponder tag>`: Adds the transponder tag specified to your transponder (auto-toggles the transponder off and then on to ensure it is active as well)
 - `delcode <transponder tag>`: Removes the transponder tag specified from your transponder
 - `show codes`: Displays the active transponder codes in the transponder widget on-screen for 5 seconds
 - `agc <any whole number>`: Changes the code seed value of the automatically generated transponder codes (if enabled)

#### Targeting
 - `<3 digit target number>`: Enter the 3 digit number of your desired target to set it as your "primary"  (can be used with radar widget filter for quicker targeting).
 - `0`: Entering "0" will clear the current active primary target
 - `setFC`: Will set the currently highlighted ship as the fleet FC for AR (REQUIRES matching transponder code)
 - `setSL`: Will set the currently highlighted ship as the squad leader for AR (REQUIRES matching transponder code)
 - `show <core size>`: Makes the selected core size visible again in the radar widget (core sizes need to be uppercase)
 - `hide <core size>`: Filters out the selected core size from the radar widget (core sizes need to be in uppercase)
 - `clear abnd`: Clears the closest abandanded construct AR marker

#### Other
 - `print db`: Prints out all key value pairs of string values in the databank (if connected)
 - `clear db`: Clears all key value pairs stored in the databank
 - `coreid`: Prints your ships core ID
 - `clear damage`: Clears damage from the current chair against the current target
 - `clear all damage`: Clears all damage from the current chair against all targets
 - `? <string>`: Search the databank for values that contain the `<string>`
 - `/G <key> <value>`: Searches for the `<key>` in the databank and if found, sets it to `<value>`

### Key Lua Parameters
 - `useDB`:  If a databank is connected, use any parameters stored in it over what is entered in the lua parameters. If you want to change parameter values, you need to ensure this is unchecked (Default = enabled)
 - `validatePilot`: If enabled, will ensure that the player using the seat matches the ID entered into the lua code. To enable this, first ensure that you know your playerID, then edit the lua inside of "unit start" and replace the following with your player ID (Default = disabled):<br>
![image](https://user-images.githubusercontent.com/17240745/179420665-07efca53-1c95-441f-b40d-0a7231b8823c.png)<br>
 - `autoVent`: Whether or not to automatically start venting when shield is destroyed (Default = enabled)
 - `toggleBrakes`: If enabled, brakes will be toggled on and off by the brake key. If this is disabled, the brake key will only feather the brakes. They can still be locked in this mode by using `ctrl`+`space`
 - `homeBaseLocation`: Location of home base. If a position tag is present, the HUD will turn off your shield when you get close (default=emtpy)
 - `homeBaseDistance`: Distance in km from home base to turn off shield (default=5)
 

### Weapons
Weapons are controllable from 3rd persion view using the weapon widgets. With the widget, you can start firing, stop firing and reload the weapons. I the lower left of the screen the HUD displays the hit chance of each weapon linked.<br>
![Weapon Data](https://user-images.githubusercontent.com/17240745/202014932-a74d8b79-b4bd-45ff-9753-da28c5a9cac8.png)

### Radar
The radar widget has various filter modes for easier identification and targeting. The different modes are described in the hotkey section under Alt+7. On top of the filtering, the radar widget also displays a unique identifyer (last 3 digits of the `construct id`). If the target has matching transponder tags, the unique identifer is instead replaced with the owner of the construct (player name for player owned constructs or Organization tag for org owned constructs). Additionally, the radar widget also puts any identified constructs at the top of the list regardless of their distance from your position.

Target data of currently selected construct appears in the center of the screen. This data will display whether the construct is identified or not. I the selected construct is friendly, a warning will also appear.
Unidentified friendly:<br>
![Friendly](https://user-images.githubusercontent.com/17240745/202023287-a206ce41-fdc9-4197-a08b-354fc28c00de.png)
<br>
If the selected target is abandoned (i.e. cored) a warning will pop up indicating that it is cored)<br>
![image](https://user-images.githubusercontent.com/17240745/202024098-a2e9e93b-50a9-4a8f-a6b4-36d4385e3fca.png)


Any identified ships (when not selected) will have ship card with info appear on the left side of the screen above the weapon information. The identification cards display various information about the identified targets. An example can be seen below:<br>
![IDCard](https://user-images.githubusercontent.com/17240745/202023528-570f331e-f770-4eda-894b-34d042f35a35.png)

Additional data is gathered from the radar to help determine engagement actions. In the upper left corner, you will be able to see your radars identification range, how many ships have you identified and how many ships are actively shooting at you. Example seen below:
![Radar Data](https://user-images.githubusercontent.com/17240745/179417814-99cb9291-6334-43b4-aa09-0d10dfe3355e.png)

The bottom middle information box also includes how many friendly and enemy *dynamic* constructs are currently on radar.
![image](https://user-images.githubusercontent.com/17240745/185774152-bbe26a39-79e0-4efa-8420-4730b987e8f9.png)

Finally, the radar provides script overload protection. If there are two many constructs on radar at once, the script will disable the specialized radar functionality (i.e. unique code in the radar widget) and the radar widget will display targets like it would in a vanilla controller.

### Shield
If there is a shield on the construct it will be auto-linked when the configuration is run. If enabled (which it is by default), the gunner script will auto-vent the shield as soon as it reaches 0% health. If the sheild is venting and the CCS reaching less than 10%, the script will cancel the rest of the vent in order to try and save the ship from being destroyed by CCS depletion.<br>
![Shield/CCS](https://user-images.githubusercontent.com/17240745/185774141-83fc1bc6-3d75-4e0a-92e4-18c50a074ceb.png)


The shield will also automatically set resistance levels to match the incoming damage (assuming the resistence timer isn't on a cooldown).
![Resist data](https://user-images.githubusercontent.com/17240745/185774123-dc4e5d9a-d149-451b-86cb-e09e27ce05ef.png)


### Transponder
If there is a transponder on the construct it will be auto-linked when the configuration script is run. If enabled (which it is not by default), the script will automatically generate a time based transponder tag. These auto-generated tags will start with the first three characters of `AGC` to indicate that they are "auto generated codes". These auto-generated codes will rotate every 1000 seconds. If this feature is enabled, the gunner seat will require you to enter a whole number when it first starts up. This number is your unique seed for the auto-code generation. Anyone else using this HUD that enters the same number will always have the same auto-generated code as you and therefor be seen as having matching transponder tags. This allows fleets to have matching transponder tags without the risk of their tag being comprimised even if the enemy gets a hold of their transponder.<br>
![Transponder](https://user-images.githubusercontent.com/17240745/185774367-649fcc29-fe1a-4b8e-bac7-ea495836e151.png)
<br>
Further, the HUD provides the ability to enter manual codes if needed without actually opening the transponder interface directly (see lua commands section).

## DeadRemote.conf (Remote Controller Script)

### Hotkeys
 - `Alt`+`1`: Overlays the screen with quick help tips
 - `Alt`+`2`: Rotates through various Augmented Reality (AR) modes including:
   - ALL: Shows all AR points available (within range)
   - PLANETS: ONLY show planets (moons are excluded by default, but can be enabled in lua parameters)
   - TEMPORARY: Only show temporary points (ones entered using the `addwaypoint` lua command
   - FROM_FILE: Only show AR points that were read from the `AR_Waypoints.lua` file (more info in the *Additional Files* section)
   - NONE: No AR points shown (excludes auto-pilot destination)
 - `Alt`+`3`: Clears all engine tag filtering so that the throttle controls all engines again
 - `Alt`+`Shift`+`3`: Rotates through a list of predefined engine tags to control. List includes (`military`,`maneuver` and `freight`)
 - `Alt`+`4`: Starts auto-pilot towards the current auto-pilot destination *Auto-pilot feature is currently a work in progress, use with caution and only for in space travel`
 - `Alt`+`5`: Toggles tracking mode on and off. Tracking mode enabled means that position tags will be used to calculate trajectories rather than for autopiloting.
 - `Alt`+`6`: Sets current waypoint destination and auto-pilot destination to the center of the nearest safe zone (does not automatically engage auto-pilot however)
 - `Alt`+`9`: Toggles engine control mode between throttle and cruise

### Lua Commands
 - `disable <engine tag>`: Removes the entered engine tag from the currently controlled engine tag list
 - `enable <engine tag>`: Adds the entered engine tag to the currently controlled engine tag list
 - `warp <::pos{}>`: Prints out the best warp pipe to the destination from the current position. Printout includes how far from the pipe the position is
 - `warpFrom <::pos{start position}> <::pos{destination position>`: Prints out the best warp pipe to the destination from the entered position. Printout includes how far from the pipe the position is.
 - `addWaypoint <::pos{}> [name]`: Adds the entered postion to the temporary AR point list. Optionally include the name to display on that waypoint. If no name is entered, then the tag is labeled with "Temp_0"
 - `delWaypoint <name>`: Removes the selected waypoint from the temprary AR point list
 - `<::pos{auto-pilot destination}>`: Enter a position tag by itself to set the auto-pilot destination. The auto-pilot destination also adds a permenant AR point that is shown on the screen.

### Features
#### Travel Indicators
The remote HUD includes several travel indicators to help you pilot the ship. These include a forward direction indicator (light grey), a prograde indicator (direction of travel green) and a retrograde indicator (opposite of travel direction red). See below for examples:<br>
![Travel Indicators](https://user-images.githubusercontent.com/17240745/179416679-dd1ad825-5851-49a5-a82a-bf90dfce824a.png)

#### Augmented Reality
The HUD allows you to view positions in space even when they are not rendered into the game. The further the position tag is from your current location, the smaller the indicator. The AR modes only display locations within 500 SU of your current location.<br>
![AR Example](https://user-images.githubusercontent.com/17240745/179419499-5da15447-409a-4325-a92b-f11224a8d10e.png)

By default the HUD includes all planets as AR reference points, but addtional ones may be added through lua commands or added to a lua file in the custom folder (see additional files section for details)

Your current AR mode can be seen in the upper left of the HUD:<br>
![image](https://user-images.githubusercontent.com/17240745/179419569-2f1f74a9-9b70-42e7-af2e-6b8032fb77a4.png)

#### Engine Control
The remote HUD allows you to control only specific engines with your throttle. By default when the remote is started, you control all engines pointed along the forward axis. When controlling specific engine tags, the current state of non-controlled engines is saved. Example:
If there are 2 engines on the construct with the tag of "freight" and 2 with the tag of "military". Setting the throttle to 100% while controlling "ALL" engines will initially set all the engines to 100% throttle. If you then add the "military" tag to the engine control (either through lua commands or hotkeys) and then set the throttle to 0%, your engines with the "military" tag will turn off, while the "freight" tagged engines will continue at 100% throttle.
Engine tags must be set on each engine individually. Engines without custom tags will always be ignored whenever an engine tag is enabled. Your current engine tag filtereing can be seen in the upper left of the HUD. Any combination of engine tags may be used at a time:<br>
![image](https://user-images.githubusercontent.com/17240745/179419804-30083b43-96b2-4a8b-a3ef-9aebd62200e2.png)

#### Other features
The HUD also includes many other smaller features including:
 - Nearest Planet
 - Nearest Pipe
 - Safe Zone Distance
 - Construct Flight statistics (Brake distance, max speed, max acceleration, max brake, etc)


## Additional Files
This remote HUD can take advantage of additional files locally put in the `lua/autoconf/custom` folder. The advantage of using these custom files is that none of the data is stored on the controller itself. So sensative information can't be retrieved from the controller or databank even if the ship is captured. The two files the remote uses are the following.

### DeadRemote_CustomFileIndex.lua
This file is used to list out all custom waypoint files you will use with DeadRemote. Each file can have a custom display name which is shown when cycling between the various AR Modes. The format of the file is the following:
```
return {
	{DisplayName = "Default File",FilePath = 'autoconf/custom/AR_Waypoints'},
	{DisplayName = "Asteroids: Near SafeZone",FilePath = 'autoconf/custom/waypoints/Asteroids_NearSafeZone'},
	{DisplayName = "Asteroids: Near Jago",FilePath = 'autoconf/custom/waypoints/Asteroids_NearJago'},
	{DisplayName = "Asteroids: Near Teoma",FilePath = 'autoconf/custom/waypoints/Asteroids_NearTeoma'},
	{DisplayName = "Personal Waypoints",FilePath = 'autoconf/custom/waypoints/Personal_Waypoints'}
}
```
### AR_Waypoints.lua
This file is used to load AR points into your HUD that you use on a regular basis so they do not have to be re-entered every time the remote starts. The format of the file is the following:
```
return {
  Example_Waypoint1 = '::pos{0,0,1,2,3}',
  Example_Waypoint2 = '::pos{0,0,9,8,7}'
}
```
Any number of waypoints can be added to this list. Ensure that each entry (except the last one) ends in a `,` (comma).

### beacons.lua
This file is used to load any additional warp points that you would like into the HUD. This is useful if you have access to other warp beacons. The warp pipe calculations will include any beacons that are loaded from this file.
Format of the file is the following:
```
return {
  Beacon1 = '::pos{0,0,1,2,3}',
  Beacon2 = '::pos{0,0,9,8,7}'
}
```
Any number of beacons can be added to this list. Ensure that each entry (except the last one) ends in a `,` (comma).

### transponder.lua
This file can be used to house the initial seed for generating random transponder codes. If the file is present and properly formatted, the gunner chair will pick up the code stored in the file and use it to generate the random codes. If you have the same code seed as another ship, your "random" codes will always be matching. The codes change every 2 minutes by default and have an overlap time of 5 seconds (to help prevent lag issues).<br>
```return 123456```

## PB-Periscope.json (Periscope script for board)
This script is simply copied an pasted to the desired programming board. No linking necessary.

## PB-Transponder.json (Transponder script for board)
This script can suppliment the transponder code in the gunner seat (i.e. if you are running a non-PvP ship). The code works the same as that mentioned above for AGC, just link the transponder to the board and paste the config in it.

### Audio Files for Radar contact are put at the location below (contact.mp3, targetleft.mp3):
..\Documents\NQ\DualUniverse\audio
