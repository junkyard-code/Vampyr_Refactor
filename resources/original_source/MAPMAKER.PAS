Program WorldMapMaker;
{Version 1.0  }
{Draws the world map for Vampyr}
{INSTRUCTIONS for the ignorant fools:
  1) Cursor keys to move around
  2) 'a' - 'v' for icons numbered 0 - 21  (lower case!)
  3) 'z' for no icons (a blank)
  4) SPACE to plot that particular icon on the coordinates designated
  5) CTRL-L to load WORLD.MAP
  6) CTRL-S to save WORLD.MAP
  7) CTRL-F to FILL the whole map with grass
  8) CTRL-Z to exit
 Note: change the directories in the ASSIGN statements before crawling
       to me for help.  BTW, Worldmap.con contains all the icons.  Use
       DRAWMAPI to change them, if you so desire.
                                                Teflon McClain    }

{CHARACTER      ICON NUMBER      MEANING
    a                0           Water (Deep)
    b                1           Water (Shallow)
    c                2           Bridge
    d                3           Forest
    e                4           Bushes
    f                5           Signs
    g                6           Grass
    h                7           Vampyr castle (TOP)
    i                8           Town (LEFT)
    j                9           Town (RIGHT)
    k                10          Castle (LEFT)
    l                11          Ruined castle (LEFT)
    m                12          Mountain
    n                13          Cave
    o                14          Swamp
    p                15          Jungle
    q                16          Boat
    r                17          Castle (RIGHT)
    s                18          Ruined Castle (RIGHT)
    t                19          Vampyr Castle (BOTTOM)
    u                20          Hills
    v                21          Clearing    }

USES
  Graph, Crt;
Var
  GraphDriver, GraphMode : Integer;
  IconPic : Array[0..21] of Pointer;
  Size : Word;
  XLoc, YLoc : Word;
  WorldMap : Array[1..110,1..100] of Byte;
  Ch : Char;
  PicNow : Byte;
  DeadIcon : Pointer;
  CTSize : Word;
  CT : Pointer;

Procedure LoadPics;
Var
  Icon : Array[1..5, 1..2] Of Byte;
  PC : Byte;
  Infile : File;
  X : Integer;
  YLoc, XLoc : Byte;

Begin
  Assign(Infile, 'c:\pascal\vampyr\worldmap.con');
  Reset(Infile,10);
  SetActivePage(3);
  Size := ImageSize(1,1,5,2);
  For X := 0 to 21 Do
    Begin
      Seek(Infile, X);
      BlockRead(Infile, Icon,1);
      For YLoc := 1 to 2 Do
        Begin
          For XLoc := 1 to 5 Do
            Begin
              PC := Icon[XLoc,YLoc];
              PutPixel(XLoc, YLoc,PC);
            End;
        End;
      GetMem(IconPic[X],Size);
      GetImage(1,1,5,2,IconPic[X]^);
      PutImage(1,1,IconPic[X]^,XOrPut);
    End;
  Close(InFile);
  GetMem(DeadIcon,Size);
  GetImage(1,1,5,2,DeadIcon^);
  SetActivePage(0);
End;


Procedure SaveIt;
Var
  OutFile : File;

Begin
{$I-}
  Assign(OutFile,'c:\pascal\vampyr\world.map');
  Reset(OutFile,11000);
  If IOResult <> 0 Then
    ReWrite(OutFile,11000);
{$I+}
  Seek(OutFile,0);
  BlockWrite(OutFile, WorldMap,1);
  Close(OutFile);
End;

Procedure LoadIt;
Var
  InFile : File;
  X,Y : Integer;
  PN : Byte;
Begin
  Assign(Infile,'c:\pascal\vampyr\world.map');
  Reset(Infile,11000);
  Seek(Infile,0);
  BlockRead(InFile,WorldMap,1);
  Close(Infile);
  For Y := 1 to 100 Do
    Begin
      For X := 1 to 110 Do
        Begin
          PN := WorldMap[X,Y];
          If PN <> 255 Then
            PutImage((X-1)*5,(Y-1)*2,IconPic[PN]^,NormalPut);
        End;
    End;
End;

{Main!!!}
Var
  XLocStr,YLocStr,PicNowStr : String[3];

Begin
  GraphDriver := 3;
  GraphMode := 0;
  InitGraph(GraphDriver,GraphMode,'');
  CTSize := ImageSize(600,0,607,199);
  GetMem(CT,CTSize);
  GetImage(600,0,607,199,CT^);
  For YLoc := 1 to 100 Do
    For XLoc := 1 to 110 Do
      WorldMap[XLoc,YLoc] := 255;
  XLoc := 1;
  YLoc := 1;
  PicNow:=255;
  LoadPics;
  SetTextStyle(0,1,1);
  REPEAT
    Ch := ReadKey;
    if ord(ch) in [77,75,72,80] then
      PutImage((XLoc-1)*5,(YLoc-1)*2,IconPic[worldmap[xloc,yloc]]^,NormalPut);
    Case Ord(Ch) of
      77 : If XLoc < 110 Then XLoc := XLoc +1;
      75 : If XLoc > 1 Then XLoc := XLoc -1;
      72 : If YLoc > 1 Then YLoc := YLoc -1;
      80 : If YLoc < 100 Then YLoc := YLoc +1;
      97 : PicNow := 0;
      98 : PicNow := 1;
      99 : PicNow := 2;
      100 : PicNow := 3;
      101 : PicNow := 4;
      102 : PicNow := 5;
      103 : PicNow := 6;
      104 : PicNow := 7;
      105 : PicNow := 8;
      106 : PicNow := 9;
      107 : PicNow := 10;
      108 : PicNow := 11;
      109 : PicNow := 12;
      110 : PicNow := 13;
      111 : PicNow := 14;
      112 : PicNow := 15;
      113 : PicNow := 16;
      114 : PicNow := 17;
      115 : PicNow := 18;
      116 : PicNow := 19;
      117 : PicNow := 20;
      118 : PicNow := 21;
      122 : PicNow := 255;
      32 : Begin
             If PicNow = 255 Then
               PutImage((XLoc-1)*5,(YLoc-1)*2,DeadIcon^,NormalPut)
             Else
               PutImage((XLoc-1)*5,(YLoc-1)*2,IconPic[PicNow]^,NormalPut);
             WorldMap[XLoc,YLoc] := PicNow;
           End;
      12 : LoadIt;
      19 : SaveIt;
       6 : Begin
             For YLoc := 1 to 100 Do
               For XLoc := 1 to 110 Do
               Begin
                 PutImage((XLoc-1)*5,(YLoc-1)*2,IconPic[6]^,NormalPut);
                 WorldMap[XLoc,YLoc] := 6;
               End;
             XLoc := 1;
             YLoc := 1;
           End;
    End;
    PutImage((XLoc-1)*5,(YLoc-1)*2,DeadIcon^,NormalPut);
    Str(XLoc,XLocStr);
    Str(YLoc,YLocStr);
    Str(PicNow,PicNowStr);
    PutImage(592,0,CT^,NormalPut);
    If PicNow = 255 Then
      OutTextXY(600,0,'X: '+XLocStr+'  Y: '+YLocStr+'  Pic: NONE  ')
    Else
      OutTextXY(600,0,'X: '+XLocStr+'  Y: '+YLocStr+'  Pic: '+PicNowStr+'   ');
  Until Ord(Ch) = 26;
  For XLoc := 0 to 21 Do
    FreeMem(IconPic[XLoc],Size);
  FreeMem(DeadIcon,Size);
  FreeMem(CT,CTSize);
  CloseGraph;
End.