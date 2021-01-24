# pokemonGen3AutoRNG

This lua script can allow you to automatically RNG any pokemon in a gen 3 pokemon game.

Note that only method 1 Pokemon, static encounters, have been tested.

Steps to use the script:
1. Download a VBA-RR emulator.

2. Get the emulator working with your ROM and savegame.

3. Place the lua script in the lua folder / directory where lua scripts are stored in your version.

4. Use RNGReporter to find the pokemon you want to get. Note that this was built for RNGReporter 10.3.4. This may be incompatible with other versions based on how columns are ordered and output.
- You will need PKHex to view data about your save file if you want to get shiny pokemon and dont have any yet.
- You will need to know the seed of the current RNG instance in the game. Unless you are somehow emulating a battery, Pokemon Emerald will have a seed of 0, Sapphire/Ruby will be 5A0, and FireRed/LeafGreen will generate one after "start" is pressed on the title screen. For FR/LG, the seed can be found in the bottom left corner of the screen when the LUA script is running. Note that for FR/LG this seed will change if you "turn off" the system. However, it will stay the same if you save that save state. Consequentially, it may be benefitial to reset the game and check every seed you encounter to look for good/early frame pokemon in these seeds, making savestates of ones you think are good.
  
5. Export only that pokemon's entry as a text file, naming it "target.txt". Place it in the same directory as the lua script.

6. Export the pokemon with surrounding entries as well. Make sure to leave a lot of extra room depending on the frame number of the target pokemon. The higher the frame number, the more room. For numbers < 100,000, leave +/- 10,000 entries. For numbers between 100,000 and 1,000,000, leave +/- 100,000 entries. For sufficiently large frame numbers, consider using +/- 2,000,000 entries. Name the file "1.txt", "h2.txt", or "h4.txt" depending on the method, and place it in the lua directory.

7. Start the game, and get to the moment right before the keypress that will trigger an encounter / trigger the pokemon to be generated. Edit the top of the lua script.
- isPartyPkmn: true if the pokemon will be in your party (gift pokemon like starter, beldum, and magikarp), false if wild encounter.
- partyIndex: If status == 1, the location in the party where the pokemon will appear. Can be 1-6.
- method: 1 if method 1 pokemon. Any other number otherwise. Make sure that your method's txt file is the only one in the directory!
- button: 0 if "A" is to be pressed to trigger the encounter. For other integers, "Up" will be used.

8. Pause the game from the emulator and create your own manual savestate (just incase something goes wrong :) ).

9. Run the lua script and unpause the emulator. You can make the game speed as fast as possible.

10. Wait until the game pauses, showing the pokemon. The script will calculate the estimated time until the desired frame is reached.

11. Make a savestate and catch that Pokemon!

How it works: 
The script will progress until the desired frame. Meanwhile it is periodically making save states. The frequency of the save states depend on how large the desired frame is, and increases as it draws nearer. Once the desired frame is reached, the script inputs the trigger button to encounter the pokemon. Then, the stats of the pokemon are searched in the method text file to find the pokemon that was found. If the pokemon was not the desired one, the frame error is calculated (difference between frame of actual pokemon and desired pokemon) and a new target frame is created. The latest savestate before this frame is then loaded. This process repeats until the desired pokemon is achieved. Note that 0-3 reloads are expected. Once the desired pokemon is reached, the game will pause and the pokemon's stats will be displayed.

Troubleshooting:
- Re-read the above steps carefully. Look up manual RNG manipulation guides if you are confused about the overall process.
- Make sure that you are only one keypress away from encountering the pokemon. Sometimes this is calculated while talking to someone.
- Note that the frame error tends to increase as the current frame increases, and as the game clock increases. This may cause a very early frame to be unobtainable. You can try to fix this issue by changing the game clock in PKHex.
- The script will change the encoding of the text files so that they are compatible with lua. This was achieved by running powershell commands in the background. This may not work on your computer.

TODO:
- Optimize savesatates algorithm
  . Memory efficiency (Less saves)
  . Time efficiency (Frequency of saves)
- Test method 2 and 4 encounters
