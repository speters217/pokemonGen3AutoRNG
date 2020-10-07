# pokemonGen3AutoRNG

This lua script can allow you to automatically RNG any pokemon in a gen 3 pokemon game.

Steps to use the script:
1. Download a VBA-RR emulator.
2. Get the emulator working with your ROM and savegame.
3. Place the lua script in the lua folder / directory where lua scripts are stored in your version.
4. Use RNGReporter to find the pokemon you want to get.
5. Export only that pokemon's entry as a text file, naming it "target.txt". Place it in the same directory as the lua script.
6. Export the pokemon with surrounding entries as well. Make sure to leave a lot of extra room depending on the frame number of the target pokemon. The higher the frame number, the more room. For numbers < 1,000,000, leave +/- 100,000 entries. For sufficiently large frame numbers, consider using +/- 2,000,000 entries. Name the file "1.txt", "h2.txt", or "h4.txt" depending on the method, and place it in the lua directory.
7. Start the game, and get to the moment right before the keypress that will trigger an encounter / trigger the pokemon to be generated. Make sure to edit the top of the lua script for the proper keypress. ("A" or "UP", etc.)
8. Pause the game from the emulator and create your own manual savestate.
9. Run the lua script and unpause the emulator.
10. Enjoy!

TODO:
- Optimize savesatates algorithm
- Test method 4 encounters
