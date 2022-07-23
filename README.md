# Dead's PvP Script Suite

## Downloads
Simply right-click on the links below and select "Save Link As..." to download the configuration files:
 - [DeadGunner.conf](https://raw.githubusercontent.com/Deadrank/DeadRank-DU/main/DeadGunner.conf)
 - [DeadRemote.conf](https://raw.githubusercontent.com/Deadrank/DeadRank-DU/main/DeadRemote.conf)

## Installation
1) Download the .conf file(s) you would like to use
2) Place them in your `custom` folder in the DU game path (defaults to here on installation: `C:\ProgramData\Dual Universe\Game\data\lua\autoconf\custom`
3) Update custom scripts in-game or log in if the game is not running
4) Run the custom script autoconfiguration on the correct device (gunner chair or remote)

## DeadGunner.conf (Gunner Seat Script)
The gunner seat will control and/or read data from:
 - Weapons (manual link)
 - Radar (manual link
 - Transponder (auto link if present)
 - Databank (manually linked, optional)
 - Shield (manually linked, optional)

Any items listed above as manual link, must be linked *before* running  the autoconfiguration

### Hotkeys
 - Alt+7: Changes radar filtering mode. Toggles through the following options:
   - 'All' = Default mode that shows everything 
   - 'enemy' = Show only ships that do not have matching transponder tags or have a matching friendly ship ID
   - 'identified' = show only ships you have identified
   - 'friendly' = show only ships that have matching transponder tags or have a matching friendly ship ID
   - 'primary' = show ONLY your primary target in radar widget (see lua commands for how to choose a "primary" target)
 - Alt+8: Start/Stop shield vent manually

### Lua Commands
 - `code <transponder tag>`: Adds the transponder tag specified to your transponder (auto-toggles the transponder off and then on to ensure it is active as well)
 - `hide codes`: Changes visual display of transponder tags on the HUD to "redacted". This is useful if you are streaming and do not want your tags displayed on-stream
 - `show codes`: Changes the visual display of transponder codes back to their actual values
 - `delcode <transponder tag>`: Removes the transponder tag specified from your transponder
 - `addships`: Adds all ships currently on your radar to a "friendly" ship list so that they will be filtered out of certain radar views even if they do not have matching transponder tags (if a databank is linked, will also store the construct IDs in the databank for future use) *NOTE: this feature is currently not working, will remove this note when fixed*
 - `addshipid <construct id> [owner/name]`: Adds an individual ship to the "friendly" ship list. The ship is tagged will be tagged with the specified owners name (optional).
 - `delshipid <construct id>`: Removes the specified construct ID from the "friendly" ship list
 - `<3 digit target number>`: Enter the 3 digit number of your desired target to set it as your "primary"  (can be used with radar widget filter for quicker targeting).
 - `0`: Entering "0" will clear the current active primary target
 - `agc <any whole number>`: Changes the code seed value of the automatically generated transponder codes (if enabled)
 - `show <core size>`: Makes the selected core size visible again in the radar widget (core sizes need to be uppercase)
 - `hide <core size>`: Filters out the selected core size from the radar widget (core sizes need to be in uppercase)
 - `print db`: Prints out all key value pairs of string values in the databank (if connected)
 - `clear db`: Clears all key value pairs stored in the databank

### Lua Parameters
 - `useDB`:  If a databank is connected, use any parameters stored in it over what is entered in the lua parameters (Default = enabled)
 - `printCombatLog`: Print out weapon hits and misses (including damage dealt) in the lua channel. Useful so so that you do not have to switch between the combat log and lua channel for commands. (Default = enabled)
 - `dangerWarning`: The number of ships that need to start attacking you before a warning is displayed on screen (Default = 4)
 - `validatePilot`: If enabled, will ensure that the player using the seat matches the ID entered into the lua code. To enable this, first ensure that you know your playerID, then edit the lua inside of "unit start" and replace the following with your player ID (Default = disabled):<br>
![image](https://user-images.githubusercontent.com/17240745/179420665-07efca53-1c95-441f-b40d-0a7231b8823c.png)<br>
 - `generateAutoCode`: Whether or not to enable the auto-code generation feature of the transponder (Default = disabled)
 - `autoVent`: Whether or not to automatically start venting when shield is destroyed (Default = enabled)
 - `L_Shield_HP`: Mapped value for Large Constructs shield (used in target shield health estimate) (Default = 11500000)
 - `M_Shield_HP`: Mapped value for Medium Constructs shield (used in target shield health estimate) (Default = 8625000)
 - `S_Shield_HP`: Mapped value for Small Constructs shield (used in target shield health estimate) (Default = 8625000)
 - `XS_Shield_HP`: Mapped value for Small Constructs shield (used in target shield health estimate) (Default = 500000)
 - `max_radar_load`: Radar limit before disabling radar widget customization (to prevent overload) (Default = 250)
 - `bottomHUDLineColorSZ`: HUD Color customizations (Default = 'white')
 - `bottomHUDFillColorSZ`: HUD Color customizations (Default = 'rgba(29, 63, 255, 0.75)')
 - `textColorSZ`: HUD Color customizations (Default = 'white')
 - `bottomHUDLineColorPVP`: HUD Color customizations (Default ='lightgrey')
 - `bottomHUDFillColorPVP`: HUD Color customizations (Default ='rgba(255, 0, 0, 0.75)')
 - `textColorPVP`: HUD Color customizations (Default = 'black')
 - `neutralLineColor`: HUD Color customizations (Default = 'lightgrey')
 - `neutralFontColor`: HUD Color customizations (Default = 'darkgrey')
 - `warning_size`: Size of warning indicators in the upper right

### Weapons
Weapons are controllable from 3rd persion view using the weapon widgets. With the widget, you can start firing, stop firing and reload the weapons. I the lower left of the screen the HUD displays the hit chance of each weapon linked.
![Weapon Data](https://user-images.githubusercontent.com/17240745/179405092-d4cbd4c2-3a78-4096-b091-def94a05f87a.png)

### Radar
The radar widget has various filter modes for easier identification and targeting. The different modes are described in the hotkey section under Alt+7. On top of the filtering, the radar widget also displays a unique identifyer (last 3 digits of the `construct id`). If the target has matching transponder tags, the unique identifer is instead replaced with the owner of the construct (player name for player owned constructs or Organization tag for org owned constructs). Additionally, the radar widget also puts any identified constructs at the top of the list regardless of their distance from your position.

Target data of currently selected construct appears in the center of the screen. This data will display whether the construct is identified or not. I the selected construct is friendly, a warning will also appear.
Unidentified friendly: ![Unidentified Freindly](https://user-images.githubusercontent.com/17240745/179416594-b1db7e8a-3a5f-4cc4-bee6-ce1b6d8a0d57.png)
Identified enemy: ![Identified Enemy](https://user-images.githubusercontent.com/17240745/179416995-7d2dbd94-750b-4c26-b88a-8b4f346abede.png)
If the selected target is abandoned (i.e. cored) a warning will pop up indicating that it is cored)
![image](https://user-images.githubusercontent.com/17240745/179420317-8fdc84a3-2a64-482a-856e-2efb97bd07d0.png)


Any identified ships (when not selected) will have ship card with info appear on the left side of the screen above the weapon information. The identification cards display various information about the identified targets. An example can be seen below:
![Identification Cards](https://user-images.githubusercontent.com/17240745/179417323-9d605353-8755-4ed3-9cb2-3ca1ab00b642.png)

Additional data is gathered from the radar to help determine engagement actions. In the upper left corner, you will be able to see your radars identification range, how many ships have you identified and how many ships are actively shooting at you. Example seen below:
![Radar Data](https://user-images.githubusercontent.com/17240745/179417814-99cb9291-6334-43b4-aa09-0d10dfe3355e.png)

The bottom middle information box also includes how many friendly and enemy *dynamic* constructs are currently on radar.
![image](https://user-images.githubusercontent.com/17240745/179418021-c6132e7f-c5e7-41f9-8457-46a0ad51c013.png)

Finally, the radar provides script overload protection. If there are two many constructs on radar at once, the script will disable the specialized radar functionality (i.e. unique code in the radar widget) and the radar widget will display targets like it would in a vanilla controller.

### Shield
If there is a shield on the construct it will be auto-linked when the configuration is run. If enabled (which it is by default), the gunner script will auto-vent the shield as soon as it reaches 0% health. If the sheild is venting and the CCS reaching less than 10%, the script will cancel the rest of the vent in order to try and save the ship from being destroyed by CCS depletion.

The shield will also automatically set resistance levels to match the incoming damage (assuming the resistence timer isn't on a cooldown).
![Resist data](https://user-images.githubusercontent.com/17240745/179417983-f3f24c88-c03b-464b-b14b-f4f6b5f70712.png)


### Transponder
If there is a transponder on the construct it will be auto-linked when the configuration script is run. If enabled (which it is not by default), the script will automatically generate a time based transponder tag. These auto-generated tags will start with the first three characters of `AGC` to indicate that they are "auto generated codes". These auto-generated codes will rotate every 1000 seconds. If this feature is enabled, the gunner seat will require you to enter a whole number when it first starts up. This number is your unique seed for the auto-code generation. Anyone else using this HUD that enters the same number will always have the same auto-generated code as you and therefor be seen as having matching transponder tags. This allows fleets to have matching transponder tags without the risk of their tag being comprimised even if the enemy gets a hold of their transponder.
![image](https://user-images.githubusercontent.com/17240745/179420260-ffe2b6f6-9cc0-4874-9896-1489a0863306.png)
Further, the HUD provides the ability to enter manual codes if needed without actually opening the transponder interface directly (see lua commands section).

## DeadRemote.conf (Remote Controller Script)

### Hotkeys
 - Alt+1: Overlays the screen with quick help tips
 - Alt+2: Rotates through various Augmented Reality (AR) modes including:
   - ALL: Shows all AR points available (within range)
   - PLANETS: ONLY show planets (moons are excluded by default, but can be enabled in lua parameters)
   - TEMPORARY: Only show temporary points (ones entered using the `addwaypoint` lua command
   - FROM_FILE: Only show AR points that were read from the `AR_Waypoints.lua` file (more info in the *Additional Files* section)
   - NONE: No AR points shown (excludes auto-pilot destination)
 - Alt+3: Clears all engine tag filtering so that the throttle controls all engines again
 - Alt+Shift+3: Rotates through a list of predefined engine tags to control. List includes (`military`,`maneuver` and `freight`)
 - Alt+4: Starts auto-pilot towards the current auto-pilot destination *Auto-pilot feature is currently a work in progress, use with caution and only for in space travel`
 - Alt+5: Enables "auto follow" mode. This mode attempts to match the speed of the selected construct and maintain optimal weapon distance. *This feature does not steer the ship, but only controls throttle operations*
 - Alt+6: Sets current waypoint destination and auto-pilot destination to the center of the nearest safe zone (does not automatically engage auto-pilot however)
 - Alt+9: Toggles engine control mode between throttle and cruise

### Lua Commands
 - `disable <engine tag>`: Removes the entered engine tag from the currently controlled engine tag list
 - `enable <engine tag>`: Adds the entered engine tag to the currently controlled engine tag list
 - `warp <::pos{}>`: Prints out the best warp pipe to the destination from the current position. Printout includes how far from the pipe the position is
 - `warpFrom <::pos{start position}> <::pos{destination position>`: Prints out the best warp pipe to the destination from the entered position. Printout includes how far from the pipe the position is.
 - `addWaypoint <::pos{}> [name]`: Adds the entered postion to the temporary AR point list. Optionally include the name to display on that waypoint. If no name is entered, then the tag is labeled with "Temp_0"
 - `delWaypoint <name>`: Removes the selected waypoint from the temprary AR point list
 - `<::pos{auto-pilot destination}>`: Enter a position tag by itself to set the auto-pilot destination. The auto-pilot destination also adds a permenant AR point that is shown on the screen.

### Lua Parameters
 - `validatePilot`: If enabled, will ensure that the player using the seat matches the ID entered into the lua code. To enable this, first ensure that you know your playerID, then edit the lua inside of "unit start" and replace the following with your player ID (Default = disabled):<br>
 - `useDB`:  If a databank is connected, use any parameters stored in it over what is entered in the lua parameters (Default = enabled)
 - `showRemotePanel`: Show default remote controller widget (Default = disabled)
 - `showDockingPanel`: Show default docking widget (Default = disabled)
 - `showFuelPanel`: Show default fuel widget (Default = disabled)
 - `showHelper`: Always show default helper widget (Default = disabled)
 - `showShieldWidget`: Show default shield widget (Default = disabled)
 - `defaultHoverHeight`: Set default hover engine height (Default = 42)
 - `defautlFollowDistance`: Set default auto-follow distance (overridden when gunner chair has weapons) (Default = 40)
 - `topHUDLineColorSZ`: HUD Color customizations (Default = 'white')
 - `topHUDFillColorSZ`: HUD Color customizations (Default = 'rgba(29, 63, 255, 0.75)')
 - `textColorSZ`: HUD Color customizations (Default = 'white')
 - `topHUDLineColorPVP`: HUD Color customizations (Default = 'lightgrey')
 - `topHUDFillColorPVP`: HUD Color customizations (Default = 'rgba(255, 0, 0, 0.75)')
 - `textColorPVP`: HUD Color customizations (Default = 'black')
 - `fuelTextColor`: HUD Color customizations (Default = 'white')
 - `Direction_Indicator_Size`: HUD Color customizations (Default = 5)
 - `Direction_Indicator_Color`: HUD Color customizations (Default = 'white')
 - `Prograde_Indicator_Size`: HUD Color customizations (Default = 7.5)
 - `Prograde_Indicator_Color`: HUD Color customizations (Default = 'rgb(60, 255, 60)')
 - `AP_Brake_Buffer`: Sets distance from autopilot destination to stop in km (Default = 5000)
 - `AP_Max_Rotation_Factor`: Sets autopilot turn factor (Default = 20)
 - `AR_Mode`: Sets the intial AR mode when entering the remote (Default = 'NONE')
 - `AR_Range`: Sets side of screen offsite for AR points (Default = 3)
 - `AR_Size`: Sets AR Point max size (Default = 15)
 - `AR_Fill`: HUD Color customizations (Default = 'rgb(29, 63, 255)')
 - `AR_Outline`: HUD Color customizations (Default = 'white')
 - `AR_Opacity`: HUD Color customizations (Default = '0.5')
 - `AR_Exclude_Moons`: Exlude moons from AR point sets (Default = enabled)
 - `EngineTagColor`: HUD Color customizations (Default = 'rgb(60, 255, 60)')
 - `initialResistWait` Sets the amount of time in seconds after initial damage before setting resistences (Default = 15)
 - `autoVent`: Enables the auto vent functionality of the shield if linked (Default = enabled)

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


## DU-PeriscopePB.json (Periscope script for board)
This script is simply copied an pasted to the desired programming board. No linking necessary.

### Audio Files for Radar contact are put at the location below (contact.mp3, targetleft.mp3):
..\Documents\NQ\DualUniverse\audio
