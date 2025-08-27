Program TownMapMaker;
{Version 1.0  }
{Draws all the towns for Vampyr}
{INSTRUCTIONS for the ignorant fools:
  1) Cursor keys to move around
  2) 'a' - '-' for icons numbered 0 - 27  (lower case!)
  3) '*' for no icons (a blank)
  4) SPACE to plot that particular icon on the coordinates designated
  5) CTRL-L to load castle.map
  6) CTRL-S to save castle.map
  7) CTRL-F to FILL the whole map with tile floor
  8) CTRL-Z to exit
 Note: change the directories in the ASSIGN statements before crawling
       to me for help.  BTW, TownMap.con contains all the icons.  Use
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
    h                7           Chest
    i                8           Brickwall (sec.)
    j                9           Brickfloor
    k                10           brickwall
    l                11          tilefloor
    m                12          window
    n                13          stonewall
    o                14          door
    p                15          PUB
    q                16          ARM
    r                17          WPN
    s                18          TRN
    t                19          TNP
    u                20          INN
    v                21          Counter
    w                22          pillar
    x                23          stair (D)
    y                24          star (U)
    z                25          locked door
    \                26          boat
    -                27          fence  }

USES
  Graph, Crt;
Var
  GraphDriver, GraphMode : Integer;
  IconPic : Array[0..27] of Pointer;
  Size : Word;
  XLoc, YLoc : Word;
  TownMap : Array[1..50,1..50] of Byte;
  Ch : Char;
  PicNow : Byte;
  DeadIcon : Pointer;
  CTSize : Word;
  CT : Pointer;

Procedure LoadPics;
Var
  Icon : Array[1..12, 1..4] Of Byte;
  PC : Byte;
  Infile : File;
  X : Integer;
  YLoc, XLoc : Byte;

Begin
  Assign(Infile, 'TownMap.con');
  Reset(Infile,48);
  SetActivePage(3);
  Size := ImageSize(1,1,12,4);
  For X := 0 to 27 Do
    Begin
      Seek(Infile, X);
      BlockRead(Infile, Icon,1);
      For YLoc := 1 to 4 Do
        Begin
          For XLoc := 1 to 12 Do
            Begin
              PC := Icon[XLoc,YLoc];
              PutPixel(XLoc, YLoc,PC);
            End;
        End;
      GetMem(IconPic[X],Size);
      GetImage(1,1,12,4,IconPic[X]^);
      PutImage(1,1,IconPic[X]^,XOrPut);
    End;
  Close(InFile);
  GetMem(DeadIcon,Size);
  GetImage(1,1,12,4,DeadIcon^);
  SetActivePage(0);
End;


Procedure SaveIt;
Var
  OutFile : File;
  RecNum : Byte;
Begin
{$I-}
  Assign(OutFile,'Theend.map');
  Reset(OutFile,2500);
  If IOResult <> 0 Then
    ReWrite(OutFile,2500);
{$I+}
  PutImage(616,0,CT^,NormalPut);
  OutTextXY(624,0,'Enter record number:   ');
  GotoXY(78,1);
  Readln(RecNum);
  Seek(OutFile,RecNum);
  BlockWrite(OutFile, TownMap,1);
  Close(OutFile);
End;

Procedure LoadIt;
Var
  InFile : File;
  X,Y : Integer;
  PN : Byte;
  RecNum : Byte;
Begin
  Assign(Infile,'TheEnd.map');
  Reset(Infile,2500);
  PutImage(616,0,CT^,NormalPut);
  OutTextXY(624, 0, 'Enter record number:   ');
  GotoXY(78,1);
  Readln(RecNum);
  Seek(Infile,RecNum);
  BlockRead(InFile,TownMap,1);
  Close(Infile);
  For Y := 1 to 50 Do
    Begin
      For X := 1 to 50 Do
        Begin
          PN := TownMap[X,Y];
          If PN <> 255 Then
            PutImage((X-1)*12,(Y-1)*4,IconPic[PN]^,NormalPut);
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
  CTSize := ImageSize(620,0,627,199);
  GetMem(CT,CTSize);
  GetImage(620,0,627,199,CT^);
  For YLoc := 1 to 50 Do
    For XLoc := 1 to 50 Do
      TownMap[XLoc,YLoc] := 255;
  XLoc := 1;
  YLoc := 1;
  PicNow:=255;
  LoadPics;
  SetTextStyle(0,1,1);
  REPEAT
    Ch := ReadKey;
    if ord(ch) in [77,75,72,80] then
      PutImage((XLoc-1)*12,(YLoc-1)*4,IconPic[TownMap[xloc,yloc]]^,NormalPut);
    Case Ord(Ch) of
      77 : If XLoc < 50 Then XLoc := XLoc +1;
      75 : If XLoc > 1 Then XLoc := XLoc -1;
      72 : If YLoc > 1 Then YLoc := YLoc -1;
      80 : If YLoc < 50 Then YLoc := YLoc +1;
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
      119 : PicNow := 22;
      120 : PicNow := 23;
      121 : PicNow := 24;
      122 : PicNow := 25;
      45 : PicNow := 27;
      92 : PicNow := 26;
      42 : PicNow := 255;
      32 : Begin
             If PicNow = 255 Then
               PutImage((XLoc-1)*12,(YLoc-1)*4,DeadIcon^,NormalPut)
             Else
               PutImage((XLoc-1)*12,(YLoc-1)*4,IconPic[PicNow]^,NormalPut);
             TownMap[XLoc,YLoc] := PicNow;
           End;
      12 : LoadIt;
      19 : SaveIt;
       6 : Begin
             For YLoc := 1 to 50 Do
               For XLoc := 1 to 50 Do
               Begin
                 PutImage((XLoc-1)*12,(YLoc-1)*4,IconPic[9]^,NormalPut);
                 TownMap[XLoc,YLoc] := 9;
               End;
             XLoc := 1;
             YLoc := 1;
           End;
    End;
    PutImage((XLoc-1)*12,(YLoc-1)*4,DeadIcon^,NormalPut);
    Str(XLoc,XLocStr);
    Str(YLoc,YLocStr);
    Str(PicNow,PicNowStr);
    PutImage(616,0,CT^,NormalPut);
    If PicNow = 255 Then
      OutTextXY(624,0,'X: '+XLocStr+'  Y: '+YLocStr+'  Pic: NONE  ')
    Else
      OutTextXY(624,0,'X: '+XLocStr+'  Y: '+YLocStr+'  Pic: '+PicNowStr+'   ');
  Until Ord(Ch) = 26;
  For XLoc := 0 to 27 Do
    FreeMem(IconPic[XLoc],Size);
  FreeMem(DeadIcon,Size);
  FreeMem(CT,CTSize);
  CloseGraph;
End.