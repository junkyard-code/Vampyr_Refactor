Vampyr – The Talisman of Invocation
Refactored Classic & Enhanced Editions

Version: 1.0.0
Build Date: 2026-01-30

Original Game: Version 2.0 (1989–1990)
Author: Brian Weston

Copyright © 1989–1990 Brian Weston and Victor Shao
Copyright © 2026 Brian Weston
All rights reserved.

Executables:
- vampyr_classic.exe
- vampyr_enhanced.exe

Saved games are written to the same folder as the executable and may be overwritten.
See the docs/ folder for game documentation and hints

This archive contains a faithful refactor of the original 1989–1990
game by its original author. See “A Note from the Author” below.

A NOTE FROM THE AUTHOR
It’s been about 35 years since Vic and I released Vampyr the Talisman of Invocation.  This game was originally a final project for my advanced placement computer science class at West Springfield High School during my junior year in 1989.  This prototype demonstrated my ability to code a tile-based world of towns, monsters, and quests.    
As an avid gamer back in the day, I was deeply influenced by role-playing games—especially Ultima—and wanted to build a game of my own using Turbo Pascal.  Graphical game development in the late 1980s came with many constraints: slow processors, no dedicated graphics hardware, tight memory and floppy disks space, and the lack of game development books and information.
Development was a collaborative effort with several high-school friends. Victor Shao made significant contributions, assisting with music, documentation, and general support whenever my attention was consumed by design and programming. The initial version was completed in roughly two months during the summer of 1989 and released in October, followed by a second version released a couple of months later.  The game was distributed through local bulletin board systems.
In the months that followed, I received letters, donations, and reviews from players around the world. Experiencing that response as a teenager was both humbling and unforgettable.
To be frank, Vampyr is not an easy game. Many players over the years chose to modify saved games in order to progress or see the story through to completion. I have always viewed this not as a flaw in the player, but as a sign of genuine engagement—people cared enough about the world and its mysteries to persist.
Testing at the time was limited. Like most high-school seniors, my friends and I had little time for playtesting following the game’s release. The game reflects both the ambition and the limitations of its creation.
Despite all of this, I remain proud of Vampyr and of what I was able to accomplish at that stage in my life.
Now, decades later, after rediscovering old reviews and play-throughs online, I returned to the old source code and refactored Vampyr to run on modern systems. The goal of this work was preservation first: to remain faithful to the original game while making it playable today. All original data files have been retained, and many quirks and oversights were intentionally left intact. An enhanced edition was also created alongside the classic version, offering selective improvements without rewriting the game’s core identity.
I hope you enjoy playing Vampyr—whether for the first time or as a return journey.  Completing this project certainly brought back nostalgic memories.
Sincerely,
Brian Weston

CHANGE LOG
This refactored version of Vampyr: The Talisman of Invocation was based on the version 2.0 of the game released in October of 1989.  Both a classic and an enhanced versions were created in the refactored project.  

V1.0.0 (2026-01-30)
- First public release of the refactored Classic and Enhanced Editions

REFACTORED CHANGES
This refactor was created by the original author and preserves the original game while improving usability and compatibility on modern systems.
- Vampyr is now available in Classic and Enhanced versions (vampyr_classic.exe and vampyr_enhanced.exe).
- The original Vampyr game ran in DOS at 640x200 EGA resolution.  The refactored versions run natively on modern Windows systems at a scaled resolution of 1280×800.
- Original PC-speaker sounds have been converted to WAV audio.
- A bug was fixed where players could become stuck when all skills were capped during point distribution.
- Players are now offered the option to reload a saved game instead of exiting immediately after judgment.
- The [TAB] key no longer displays outdated donation and address information of the programmers; it now shows player command references, including during combat.
- Document and Book of Hints are included in the refactored with some minor adjustments to the maps and slightly improved drawings.

ENHANCED VERSION ADJUSTMENTS
The Enhanced version makes modest adjustments intended to smooth difficulty and presentation while preserving the original design.
- Converted from 16-color EGA to a 256-color VGA palette
- A small number of previously static tiles are now animated (e.g., bridges, ships, castle moat)
- Character creation starting values for life (hit points) increased from 10-20 to 10-40
- Character creation starting values for gold increased from 120 to 200
- Character creation starting magic points are doubled
- Random monster spawning has been slightly reduced
- The gods are somewhat more forgiving in their judgments
- Weapons and armor have double the original duration




