{                                                            }
{  VAMPYR :  Talisman of Invocation             Version 2.0  }
{  Copyright (C) 1989, 1990 by Brian Weston and Victor Shao  }
{                                                            }

{$mode tp}
{$H-}
{$PACKRECORDS 1}

USES
  Music, Crt, Graph,Global, Title,Display,Vcombat,Monster,InitVam,Shop;

Function SuspicionCheck:Boolean;
Var
  Roll : Byte;
Begin
  Roll := Random(100)+1;
  If Roll <= SuspicionLevel Then SuspicionCheck := False
    Else SuspicionCheck := True;
End;

Function CalPickLock:Boolean;
Var
  Chance : Real;
  Roll : Byte;
  DexBonus, LuckBonus : ShortInt;
Begin
  If SuspicionCheck Then
    Begin
      DexBonus := 0;
      LuckBonus := 0;
      If Player.Stats[3] > 11 Then DexBonus := (Player.Stats[3]-11)*2;
      If Player.Stats[3] < 6 Then DexBonus := (Player.Stats[3] -6)*2;
      If Player.Stats[6] > 10 Then LuckBonus := Player.Stats[6]-10;
      If Player.Stats[6] < 5 Then LuckBonus := Player.Stats[6]-5;
      Chance := (Player.Skills[6] / 1.5)+DexBonus+LuckBonus;
      Roll := Random(100)+1;
      If Roll <= Chance Then
        Begin
          If SoundOnOff then CongratsSound;
          WriteMessage('Success!');
          CalPickLock := True;
        End;
      If Roll > Chance Then
        Begin
          If SuspicionLevel < 100 Then
                     SuspicionLevel := SuspicionLevel+4;
          WriteMessage('Failure.  Pretty sad.');
          CalPickLock:=False;
        End;
    End
  Else
    Begin
      If SoundOnOff then SirenSound;
      WriteMessage('Someone spotted you in your evil act!  Better run!');
      CalPickLock := False;
      StartChasing;
    End;
End;

Procedure ToPickLock;
Var
  LittleX, LittleY, A : Byte;
  Direction : Char;
Begin
  LittleX := TempXloc;
  LittleY := TempYLoc;
  WriteMessage('Pick lock.  Which direction?');
  Direction := Readkey;
  If Direction = #0 Then Direction := ReadKey;
  Case Ord(Direction) of
  77 : LittleX := LittleX+1;
  75 : LittleX := LittleX-1;
  80 : LittleY := LittleY+1;
  72 : LittleY := LittleY-1;
  Else WriteMessage('Consult your DOS manual about the use of cursor keys.')
  End;
  Case CurrentMapType of
  2 : Begin
        Case CurrentMap^[LittleX,LittleY] Of
        14 : WriteMessage('It''s not locked, fool!');
        25 : If CalPickLock Then Begin
           CurrentMap^[LittleX,LittleY] := 14;
           DisplayMap(TempXloc,TempYloc); End;
        Else WriteMessage('No doors there!')
        End;
      End;
  4 : Begin
        Case CurrentMap^[LittleX,LittleY] Of
        16 : WriteMessage('It''s not locked, fool!');
        17 : If CalPickLock Then Begin CurrentMap^[LittleX,LittleY] := 16;
             DisplayMap(TempXloc,TempYloc); End;
        Else WriteMessage('No doors there!')
        End;
      End;
  Else WriteMessage('Whatever you''re unlocking, it''s opened.')
  End;
End;

Procedure ToCastSpells;
Var
  Roll,A : Byte;
  SpellNum : Char;
  MstrBonus : ShortInt;
  Chance : Real;
Begin
  WriteMessage('Misc. magic spells:');
  WriteMessage('1) Wizard Eye  2) Mystical Boost  3) Heroism');
  WriteMessage('4) Cure Light Wounds  5) Cure Critical Wounds');
  If CurrentMapType=3 then WriteMessage('6) Exit To Land');
  WriteMessage('Cast which one? (0 to abort) ');
  SpellNum:=ReadKey; If SpellNum=#0 then SpellNum:=ReadKey;
  If SpellNum='0' then begin WriteMessage('Ok...'); exit; End;
  Case SpellNum of
  '1' : A:=7;
  '2' : A:=12;
  '3' : A:=10;   {Heroism. 10. Right???}
  '4' : A:=3;
  '5' : A:=6;
  '6' : If CurrentMapType<>3 then Begin
          WriteMessage('Not around here.');
          Exit; end
        Else A:=8;
  else Begin
  WriteMessage('If you are trying to crash this game, it''s not working.');
  Exit;
  end
  end;
  If (A>Player.Cmagic) then
    begin
      WriteMessage('Not enough Magic.');
      Exit;
    End;
  Player.Cmagic:=Player.Cmagic-A;
  MstrBonus:=0;
  If Player.Stats[2]>10 then MstrBonus:=(Player.Stats[2]-10)*2;
  If Player.Stats[2]<5 then MstrBonus:=(Player.Stats[2]-5)*2;
  Chance:=(Player.Skills[5]/1.1)+MstrBonus;
  Roll:=Random(100)+1;
  If Roll <= Chance then
    Begin
      CancelMagic;
      ChangeStats(2);
      Case SpellNum of
      '1' : Begin WriteMessage('Wizard Eye is now active.');
              Player.MiscMagic:=1; For Roll:=1 to 7 Do
              For A:=1 TO 7 Do BooMap[Roll,A]:=True;
              End;
      '2' : Begin WriteMessage('Mystical Boost is now active.');
              Player.MiscMagic:=2;
              Roll:=Random(5)+11;
              If (Player.Skills[3]+Roll) <=100 Then
                Player.Skills[3]:=Player.Skills[3]+Roll
              Else Player.Skills[3]:=100;
            End;
      '3' : Begin WriteMessage('Heroism is now active.');
              Player.MiscMagic:=3;
              Roll:=Random(5)+11;
              If (Player.Skills[1]+Roll) <=100 Then
                Player.Skills[1]:=Player.Skills[1]+Roll
              Else Player.Skills[1]:=100;
            End;
      '4' : Begin
              Roll:=Random(11)+10;   {10 to 20???}
              If (Player.Clife+Roll)<= Player.Life then
                Player.Clife:=Player.Clife+Roll
              Else Player.Clife:=Player.Life;
              WriteMessage('You feel better.');
              ChangeStats(1);
            End;
      '5' : Begin
              Roll:=Random(16)+25; {25 to 40???}
              If (Player.Clife+Roll) <= Player.Life then
                Player.Clife:=Player.Clife+Roll
              Else Player.Clife:=Player.Life;
              WriteMessage('You feel better.');
              ChangeStats(1);
            End;
      '6' : Begin
              WriteMessage('Exiting the dungeon...'); PaletteColors(1);
              LoadNewMapType(1);
              If Player.MiscMagic<>1 then BlockIt(Player.Xloc,Player.Yloc);
              DisplayLand(Player.Xloc,Player.Yloc);  PaletteColors(2);
            End;
      End;
    SetPalette(0,22);
    If SoundOnOff Then Begin MagicSound; MagicSound2; MagicSound3; End
                  Else Delay(40);
    SetPalette(0,0);
    ChangeStats(2);
    If CurrentMapType<>1 Then DisplayMap(TempXloc,TempYLoc)
              Else DisplayLand(Player.Xloc,Player.Yloc);
    End
  Else Begin
       WriteMessage('Your spell failed miserably.');
       ChangeStats(1); End;
End;

Function CalClimbWall(WhichOne:Byte) : Boolean;
Var
  Roll, StrBonus : ShortInt;
  Chance : Real;
Begin
  StrBonus := 0;
  If Player.Stats[1] > 10 then StrBonus := (Player.Stats[1]-10)*2;
  If Player.Stats[1] < 5 then StrBonus := (Player.Stats[1]-5)*2;
  Chance := (Player.Skills[7]/1.3)+StrBonus;
  If WhichOne=1 then Chance:=Chance+40;
  Roll := Random(100)+1;
  If Roll <= Chance Then
    Begin
      If SoundOnOff Then CongratsSound;
      CalClimbWall:=True;
    End
  Else
    Begin
      If SoundOnOff Then CrunchSound;
      WriteMessage('Ouch!  That hurts!  You blew it!');
      Player.Clife:=Player.Clife-(Random(4)+1);
      Roll:=1; ChangeStats(Roll);
      CalClimbWall := False;
    End;
End;

Procedure ToClimbWall;
Var
  LittleX, LittleY : Byte;
  Direction : Char;
Begin
  If CurrentMapType = 1 then
    Begin
      WriteMessage('What are you climbing?!?');
      Exit;
    End;
  If (CurrentMapType = 3) And (((Player.Xloc = 45) AND (Player.Yloc=4))
    OR ((Player.Xloc=105) AND (Player.Yloc=10))) Then
    Begin
      WriteMessage('What are you climbing?!?');
      Exit;
    End;
  If ((CurrentMapType = 2) And ((Player.Xloc in [42,43]) AND (Player.Yloc=41))
  AND (FloorLevel <> 1)) OR ((CurrentMapType =3) AND ((Player.Xloc = 98) AND
  (Player.Yloc in [93,94])) AND (FloorLevel <> 1))
    Then Begin
      WriteMessage('Do that at the top of the castle.');
      Exit;
    End;
  LittleX := TempXloc;
  LittleY := TempYLoc;
  WriteMessage('Climb city wall or fence.  Which direction?');
  Direction := Readkey;
  If Direction = #0 Then Direction := ReadKey;
  Case Ord(Direction) of
  77 : LittleX := LittleX+1;
  75 : LittleX := LittleX-1;
  80 : LittleY := LittleY+1;
  72 : LittleY := LittleY-1;
  Else WriteMessage('Consult your DOS manual about the use of cursor keys.')
  End;
  Case CurrentMapType of
  2 : If ((LittleX< 5) or (LittleX > 46) Or (LittleY <5) or (LittleY>46))
      AND (CurrentMap^[LittleX,LittleY] in [10,13,27]) Then
      Begin
        If CalClimbWall(0) Then
          Begin
            WriteMessage('You''re outta there!');
            If Player.MiscMagic<>1 Then BlockIt(LittleX,LittleY);
            DisplayMap(LittleX,LittleY);
            LoadNewMapType(1);
            If Player.MiscMagic<>1 Then BlockIt(Player.Xloc,Player.Yloc);
            DisplayLand(Player.Xloc,Player.Yloc);
          End;
      End
      Else If CurrentMap^[LittleX,LittleY]=27 Then
         Begin
         If CalClimbWall(1) Then
          Begin
            WriteMessage('You made it!');
            If Player.MiscMagic<>1 Then BlockIt(LittleX,LittleY);
            DisplayMap(LittleX,LittleY);
            TempXloc:=LittleX;
            TempYloc:=LittleY;
          End;
      End
      Else WriteMessage('Climb either the outer wall or fences.');
  3 : If ((LittleX<5) or (LittleX>46) or (LittleY<5) or (LittleY>46))
      AND (CurrentMap^[LittleX,LittleY] in [17,23,25]) Then
      Begin
        If CalClimbWall(0) Then
          Begin
            WriteMessage('You''re outta there!');
            If Player.MiscMagic<>1 Then BlockIt(LittleX,LittleY);
            DisplayMap(LittleX,LittleY);
            LoadNewMapType(1);
            If Player.MiscMagic<>1 Then BlockIt(Player.Xloc,Player.Yloc);
            DisplayLand(Player.Xloc,Player.Yloc);
          End;
      End
      Else WriteMessage('Climb the outer wall only.');
  4 : If CurrentMap^[LittleX,LittleY]=13 then
        Begin
          If CalClimbWall(1) then
            Begin
              WriteMessage('You made it!');
              If Player.MiscMagic<>1 then BlockIt(LittleX,LittleY);
              DisplayMap(LittleX,LittleY);
              TempXloc:=LittleX;
              TempYloc:=LittleY;
            End;
        End
      Else
        WriteMessage('This is Heaven, fool.  Can''t climb clouds.');
  End;
End;

Procedure ToKlimb;
Begin    {Klimb}
  If CurrentMapType in [1,4] then
    Begin
      WriteMessage('There isn''t a staircase here now is there?');
      Exit;
    End;
  If CurrentMapType = 2 then
    Begin
      Case CurrentMap^[TempXloc,TempYloc] of
      24 : Begin
             WriteMessage('Going up.');
             FloorLevel := FloorLevel -1;
             LoadNewStuff;
             If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
             DisplayMap(TempXloc,TempYloc);
           End;
      23 : Begin
             WriteMessage('Going down.');
             FloorLevel := FloorLevel +1;
             LoadNewStuff;
             If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
             DisplayMap(TempXloc,TempYloc);
           End;
      Else
        WriteMessage('There isn''t a staircase here now is there?')
      End;
    End;
  If CurrentMapType = 3 then
    Begin
      Case CurrentMap^[TempXloc,TempYloc] of
      13 : Begin
             WriteMessage('Going up.');
             FloorLevel := FloorLevel -1;
             LoadNewStuff;
             If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
             DisplayMap(TempXloc,TempYloc);
           End;
      14 : Begin
             WriteMessage('Going down.');
             FloorLevel := FloorLevel +1;
             LoadNewStuff;
             If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
             DisplayMap(TempXloc,TempYloc);
           End;
      Else
        WriteMessage('There isn''t a staircase here now is there?')
      End;
    End;
End;

Procedure ClearStatsWindow;
Var P : Pointer;
    Size : Word;
Begin
Size:=ImageSize(280,40,625,128);
GetMem(P,Size);
GetImage(280,40,625,128,P^);
PutImage(280,40,P^,XorPut);
FreeMem(P,Size);
End;

Procedure ZstatsCommand;
Var A,B,D : Byte;
    E : ShortInt;
    St : StringType;
    Ch : Char;
    C : String[1];
Begin
ClearStatsWindow;
With Player Do
Begin
SetColor(14);
Str(Skills[1],St);
OutTextXY(280,40,'Fighting attack :'+St);
Str(Skills[2],St);
OutTextXY(280,50,'Fighting defense :'+St);
Str(Skills[3],St);
OutTextXY(280,60,'Magic offensive :'+St);
Str(Skills[4],St);
OutTextXY(280,70,'Magic defensive :'+St);
Str(Skills[5],St);
OutTextXY(280,80,'Magic miscell. :'+St);
Str(Skills[6],St);
OutTextXY(280,90,'Lock picking :'+St);
Str(Skills[7],St);
OutTextXY(280,100,'Climbing :'+St);
Str(Skills[8],St);
OutTextXY(280,110,'Stealing :'+St);
Str(Skills[9],St);
OutTextXY(280,120,'Perception :'+St);
OutTextXY(470,40,'Backpack contains :');
For A:=1 To 5 Do
  Begin
  WeaponInfo(Backpack[A],St,B,D);
  Str(A,C);
  If BackPack[A]=0 Then St:='Nothing';
  OutTextXY(470,50+(A*10),C+'> '+St);
  End;
WriteMessage('Do you want to swap or drop ? [S/D]');
Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
If Ch in ['S','s'] Then Begin
                   WriteMessage('Swap which weapon ?');
                   Repeat
                   Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
                   Until Ch in ['1','2','3','4','5'];
                   If Ch='1' Then B:=1;
                   If Ch='2' Then B:=2;
                   If Ch='3' Then B:=3;
                   If Ch='4' Then B:=4;
                   If Ch='5' Then B:=5;
                   A:=Weapon;
                   E:=WeaponDur[0];
                   WeaponDur[0]:=WeaponDur[B];
                   WeaponDur[B]:=E;
                   Weapon:=BackPack[B];
                   BackPack[B]:=A;
                   WriteMessage('Swapped.');
                   End;
If Ch in ['D','d'] Then Begin
                   WriteMessage('Drop which weapon ?');
                   Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
                   A:=0;
                   Case Ch Of
                    '1' : A:=1;
                    '2' : A:=2;
                    '3' : A:=3;
                    '4' : A:=4;
                    '5' : A:=5;
                   End;
                   If A>0 Then Begin Backpack[A]:=0;
                               WriteMessage('Dropped.'); End;
                   End;
End;
ClearStatsWindow;
ShowPlayerStats;
End;

Procedure ToEnter;
Begin
  If CurrentMapType <> 1 Then
    Begin
      WriteMessage('Enter what?!?');
      Exit;
    End;
  If CurrentMapType = 1 Then
    Begin
      Case LandMap^[Player.Xloc,Player.Yloc] Of
      7,11,19,18,13 : Begin
                        LoadNewMapType(3);
                        OriA:=TempYloc-3;
                        OriB:=TempXloc-3;
                        If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
                        DisplayMap(TempXloc,TempYloc);
                        AnimateMonster(3);
                      End;
      8,9,10,17 : Begin
                    LoadNewMapType(2);
                    OriA:=TempYloc-3;
                    OriB:=TempXloc-3;
                    If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
                    DisplayMap(TempXloc,TempYloc);
                    AnimateMonster(3);
                  End;
      16        : WriteMessage('Hey! Get out of my ship!');
      Else
        WriteMessage('Enter what?!?')
      End;
    End;
End;

Procedure DieScum;
Var Ch : Char;
Begin
  WriteMessage('You proved yourself to be unworthy.');
  Delay(800); Delay(800); Delay(400);
  WriteMessage('DIE!!!!');
  Delay(800);  Delay(800); Delay(400);
  Player.CLife:=0;
  ChangeStats(1);
  PutImage(114,57,UnivIcon[8]^,NormalPut);
  Delay(800); Delay(800);  Delay(400);
  WriteMessage('ARRRRRRRRGGGGGHHHHHHHH!!!!');
  Delay(400);  Delay(400); Delay(400);
  PutImage(114,57,CurrentMapIcon[12]^,NormalPut);
  WriteMessage('Let''s have half a second of silence.');
  If SoundOnOFF Then ReallyDeadSound;
  WriteMessage('Janitor Smith!!!');
  Delay(700); Delay(700); Delay(700); Delay(700);
  WriteMessage('Yes, my most gracious Gods!');
  Delay(200); Delay(200); Delay(200);
  If (((TempXloc-3)=20) AND ((TempYloc-2)=5)) then
    PutImage(6,21,CurrentMapIcon[4]^,NormalPut);
  If ((TempXloc=27) or (TempXloc=25)) and (TempYloc=7) then
    begin
      PutImage(222,57,CurrentMonPics[7]^,NormalPut);  Delay(600);
      PutImage(222,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(222,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(186,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(186,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(186,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(150,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(150,57,CurrentMonPics[20]^,NormalPut);
      WriteMessage('OUCH! I stepped on a nail!!!');
      PutImage(150,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(150,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(150,57,CurrentMapIcon[4]^,NormalPut);
       PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut);
      WriteMessage('I used to be these guys'' A.P. Computer Science teacher.');
      PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(150,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(150,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(150,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(186,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(186,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(186,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(222,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(222,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(222,57,CurrentMapIcon[4]^,NormalPut);
    End
  Else
    Begin
      PutImage(6,57,CurrentMonPics[7]^,NormalPut);  Delay(600);
      PutImage(6,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(6,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(42,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(42,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(42,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(78,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(78,57,CurrentMonPics[20]^,NormalPut);
      WriteMessage('OUCH! I stepped on a nail!!!');
      PutImage(78,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(78,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(78,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut);
      WriteMessage('I used to be these guys'' A.P. Computer Science teacher.');
      PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(114,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(78,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(78,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(78,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(42,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(42,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(42,57,CurrentMapIcon[4]^,NormalPut);
      PutImage(6,57,CurrentMonPics[7]^,NormalPut); Delay(600);
      PutImage(6,57,CurrentMonPics[20]^,NormalPut); Delay(600);
      PutImage(6,57,CurrentMapIcon[4]^,NormalPut);
      End;
  WriteMessage('Next!!!');
  Delay(1000); Delay(700); Delay(700); Delay(400);
  WriteMessage('');
  WriteMessage('It seems that you are really gone this time.');
  WriteMessage('PRESS ANY KEY TO EXIT VAMPYR.');
  Ch := Readkey;
  CloseGraph;
  Halt;
End;

Procedure LetLive;
Begin
  WriteMessage('You have proven yourself to be worthy.');
  Delay(700); Delay(700); Delay(400);
  WriteMessage('We''ll give you another chance.');
  Delay(700); Delay(700); Delay(400);
  LoadNewMapType(1);
  LoadPlayerPic(Player.Race);
  PutImage(114,57,PlayerIcon^,NormalPut);
  If Player.MiscMagic<>1 then Blockit(Player.Xloc,Player.Yloc);
  DisplayLand(Player.Xloc,Player.Yloc);
End;

Function LiveorDie:Byte;
Var Luck,Con,Chr, CTotal:byte;
Begin
  Luck:=0; Con:=0; Chr:=0;
  If Player.Stats[4]>10 then Begin
                   Con:=(Player.Stats[4]-10)+((Player.Stats[4]-10) div 2);
                   WriteMessage('Sturdy little fella...'); End;
  If Player.Stats[5]>10 then Begin
                   Chr:=(Player.Stats[5]-10)+((Player.Stats[5]-10) div 2);
                   WriteMessage('Quite charming...');
                   WriteMessage('Brain says, "Stop looking at him like that, Vic."');
                   WriteMessage('Vic says, "What?!?!?!"');
                   WriteMessage('Brian says, "Just joking around."');
                   End;
  If Player.Stats[6]>10 then Begin
                   Luck:=(Player.Stats[6]-10)+((Player.Stats[6]-10) div 2);
                   WriteMessage('Quite lucky...'); End;
  CTotal:=(Player.Level*8)+Luck+Con+Chr;
  If Player.Items[1] Then Begin CTotal:=CTotal+3;
                          WriteMessage('Got the Blue Rose, OK!'); End;
  If Player.Items[4] Then Begin CTotal:=CTotal+6;
                          WriteMessage('Learned Rust Armor, GOOD!'); End;
  If Player.Items[2] Then Begin CTotal:=CTotal+10;
                          WriteMessage('Met Dalagash, VERY GOOD!'); End;
  LiveOrDie:=CTotal;
  Delay(800);
End;

Procedure JudgeDay;
Var Roll, Modi : Byte;
Var Final : Integer;
Begin
  WriteMessage('Who are you?  Oh, our player!');
  Delay(2000);
  WriteMessage('Hmmmmm... Let''s see... '+Player.Name+'... Ah!  Found ya!');
  Delay(2000);
  WriteMessage('Vic says, "What do you think, Brian?"');
  Delay(2000);
  WriteMessage('Brian says, "Hmmmm... dunno... This is a tough one..."');
  Delay(2000);
  WriteMessage('Brian says, "Let''s check the computer on his progress."');
  Delay(2000);
  WriteMessage('Vic says, "Sounds good."');
  Delay(2000); Delay(2000);
  Modi:=0;
  If Player.Mission[5]=false then Modi:=10;
  If Player.Mission[4]=false then Modi:=25;
  If Player.Mission[3]=false then Modi:=40;
  If Player.Mission[2]=false then Modi:=50;
  If Player.Mission[1]=false then Modi:=70;
  If Player.Mission[1] then WriteMessage('Completed first mission');
  If Player.Mission[2] then WriteMessage('Completed second mission');
  If Player.Mission[3] then WriteMessage('Completed third mission');
  If Player.Mission[4] then WriteMessage('Completed fourth mission');
  If Player.Mission[5] then WriteMessage('Completed fifth mission');
  Final:=LiveorDie-Modi;
  Roll:=Random(100)+1;
  WriteMessage('Well, alright, we''ve made our decision.');
  Delay(1200);
  If Roll<=Final then LetLive else DieScum;
End;

{$I Talk.Pas}

Procedure DetTreasure(Var TreaNum:Byte; Kind:Byte);
{TreaNum is 1 - 3.  if Kind =1 then it's pickpocket item.  No Steel. Div
 total gold by 40%   Kind=2 use CombatMessage}
Var
  Money,Steel, SteelRoll,I:Byte;
  chh : Char;
  Gotten:Boolean;
  MoneyStr:String[3];
  Weap:StringType;
Begin
  Steel:=0;
  If TreaNum=1 Then
    Begin
      Money:=Random(35)+5;
      SteelRoll:= Random(100)+1;
      if SteelRoll<=20 Then Steel:=Random(10)+1;
    End;
  If TreaNum=2 Then
    Begin
      Money:=Random(65)+20;
      SteelRoll:=Random(100)+1;
      If SteelRoll<=30 Then Steel:=Random(10)+11;
    End;
  If TreaNum=3 Then
    Begin
      Money:=Random(130)+50;
      SteelRoll:=Random(100)+1;
      If SteelRoll<=30 then Steel:=Random(10)+21;
    End;
  If Kind=1 then
    Begin
      Money:=(Money Div 5)+(Money Div 5);
      Str(Money,MoneyStr);
      WriteMessage('You stole '+MoneyStr+' gold pieces.');
      If Player.Gold+Money <= 9999 Then Player.Gold:=Player.Gold+Money
      Else Player.Gold:=9999;
      ChangeStats(1);
      Exit;
    End;
  Str(Money,MoneyStr);
  WriteMessage('You looted '+MoneyStr+' gold pieces.');
  If Player.Gold+Money <= 9999 then Player.Gold:=Player.Gold+Money
  Else Player.Gold:=9999;
  ChangeStats(1);
  If Steel <> 0 then Begin
    WeaponInfo(Steel,Weap,Money,I);
    WriteMessage('You found a '+Weap+'.  Take it? [Y/N]');
    Chh:=ReadKey; If Chh=#0 then Chh:=ReadKey;
    If Upcase(Chh) <> 'N' then begin
      If (Player.BackPack[1]>0) and (Player.BackPack[2]>0) and (Player.BackPack
      [3]>0) and (player.BackPack[4]>0) and (Player.BackPack[5]>0) then
        Begin
          WriteMessage('your backpack is full.  Drop an item to make room? [Y/N]');
          Chh:= ReadKey; If Chh=#0 then Chh:=ReadKey;
          If Upcase(Chh) <> 'N' then ZstatsCommand;
        End;
      Gotten:=False;
      For I := 1 to 5 do
        If (Player.BackPack[I]=0) and (Gotten=False) Then
        Begin
          Player.BackPack[I]:=Steel;
          Gotten:=True;
          WriteMessage('You got a '+Weap+'.');
        End;
    End Else WriteMessage('Ok. fine. Your choice.');
  End;
End;

Procedure ToAttack;
Label HoldOn;
Var Chh:Char;
    I,XX,YY,Result : Byte;
Begin
  Result:=255;
  If CurrentMapType=1 then
    begin
      XX:=Player.Xloc;
      YY:=Player.Yloc;
    End
  Else
    Begin
      XX:=TempXloc;
      YY:=TempYloc;
    End;
  WriteMessage('Attack.  Which direction?');
  Chh:=Readkey;
  If Chh = #0 then Chh:=Readkey;
  Case Ord(Chh) of
  75 : XX:=XX-1;
  77 : XX:=XX+1;
  80 : YY:=YY+1;
  72 : YY:=YY-1;
  else begin WriteMessage('The cursor keys, fool.'); exit; end
  End;
  If CurrentMapType in [1,3] then
    Begin
      For I := 1 to 3 do
        If CurrentMonMem[I]<>Nil then
          begin
            If (CurrentMonMem[I]^.X=XX) AND (CurrentMonMem[I]^.Y=YY) then
              begin
                Result:=Combat(CurrentMonMem[I]^.MonsterName,CurrentMonMem[I]^.
                        Status,CurrentMonMem[I]^.NumInGroup);
                If Result =0 then
                  begin
                    If CurrentMapType=1 then LandMap^[CurrentMonMem[I]^
                    .X,CurrentMonMem[I]^.Y]:=CurrentMonMem[I]^.OriPic;
                    If CurrentMapType=3 then CurrentMap^[CurrentMonMem[I]^.
                    X,CurrentMonMem[I]^.Y]:=CurrentMonMem[I]^.OriPic;
                    Dispose(CurrentMonMem[I]);
                    CurrentMonMem[I]:=Nil;
                  End;
              End;
          End;
    End;
  If CurrentMapType in [2,3,4] then
    Begin
      For I := 0 to 24 Do
        If CurrentMonSet[I]<> Nil then
          begin
            If (CurrentMonSet[I]^.X=XX) AND (CurrentMonSet[I]^.Y=YY) then
              begin
                If ((CurrentMapType=4) And (CurrentMonSet[I]^.MonsterName<>2))
                                 Or (CurrentMapType=2) Then StartChasing;
                If ((CurrentMapType=3) And (CurrentMonSet[I]^.MonsterName=11))
                                 And (FloorLevel=1) Then Goto HoldOn;
                If ((CurrentMapType=2) And (CurrentMonSet[I]^.MonsterName=5) And
                       (Player.YLoc=92)) Then Begin
                       Player.Mission[3]:=True;
                       SpecialTalk('A'); End;
                Result:=Combat(CurrentMonSet[I]^.MonsterName,CurrentMonSet[I]^.
                Status,CurrentMonSet[I]^.NumInGroup);
                If ((CurrentMapType=3) And (CurrentMonSet[I]^.MonsterName=11)
                       And (FloorLevel=3) And (Result=0)) Then Begin
                            CurrentMap^[CurrentMonSet[I]^.X,CurrentMonSet[I]^.Y]:=
                            CurrentMonSet[I]^.OriPic;
                            CurrentMonSet[I]^.MonsterName:=12;
                            CurrentMonSet[I]^.Status:=1;
                            CurrentMonSet[I]^.NuminGroup:=1;
                            CurrentMonSet[I]^.Msg1:='HAH!!! You will die!!';
                            CurrentMonSet[I]^.Msg2:='A mortal can''t stop me.';
                            CurrentMonSet[I]^.Y:=CurrentMonSet[I]^.Y-1;
                            CurrentMonSet[I]^.OriPic:=11;
                            Result:=1;
                            WriteMessage('Dalagash, with his last breath, says,');
                            WriteMessage('"You''re too late!!!"');
                            End;
                If Result=0 then
                  begin
                    If (CurrentMapType=4) And (CurrentMonSet[I]^.MonsterName=2)
                       Then Begin
                       WriteMessage('In the distance, you hear voices...');
                       WriteMessage('Brian and Vic say, "HAAAHAAhaaa haaaa!!! Bye Bye, Erik!"');
                       WriteMessage('Brian says, "This player is OK!"');
                       WriteMessage('Vic says, "I know! What guts!"');
                       WriteMessage('Brian and Vic say, "All guards: leave this guy alone!"');
                       WriteMessage('...and the voices stopped.');
                       End;
                    CurrentMap^[CurrentMonSet[I]^.X,CurrentMonSet[I]^.Y]:=
                    CurrentMonSet[I]^.OriPic;
                    Dispose(CurrentMonSet[I]);
                    CurrentMonSet[I]:=Nil;
                  End;
              End;
          End;
    End;
  If Result=255 then WriteMessage('Can''t kill inanimated objects now can we?');
  HoldOn:
  If ((CurrentMapType=3) And (CurrentMonSet[I]^.MonsterName=11))
                                 And (FloorLevel=1) Then SpecialTalk('9');
End;

Function CalPickPock:Boolean;
Var
  DexBonus,ChaBonus,LuckBonus : ShortInt;
  Chance:Real;
  Roll : Byte;
Begin
  DexBonus:=0;
  ChaBonus:=0;
  LuckBonus:=0;
  CalPickPock:=False;
  If Not SuspicionCheck Then
    Begin
      If SoundOnOff then SirenSound;
      WriteMessage('The guy caught on and cried out for the guards!  Better run!');
      SuspicionLevel:=-124;
      StartChasing;
      Exit;
    End;
  If Player.Stats[3]>13 Then DexBonus:=(Player.Stats[3]-13)*2;
  If Player.Stats[3]<7 Then DexBonus:=(Player.Stats[3]-7)*2;
  If Player.Stats[5]>10 Then ChaBonus:=(Player.Stats[5]-10)*2;
  If Player.Stats[5]<6 Then ChaBonus:=(Player.Stats[5]-6)*2;
  If Player.Stats[6]>10 Then LuckBonus:=Player.Stats[6]-10;
  If Player.Stats[6]<5 Then LuckBonus:=Player.Stats[6]-5;
  Chance:=(Player.Skills[8]/1.8)+DexBonus+ChaBonus+LuckBonus;
  Roll:=Random(100)+1;
  If Roll <= Chance Then
    Begin
      If SoundOnOff then CongratsSound;
      WriteMessage('Pretty slick!');
      CalPickPock:=True;
    End
  Else
    Begin
      WriteMessage('Nope.  Not slick enough...');
      If SuspicionLevel < 100 Then SuspicionLevel:=SuspicionLevel+4;
    End;
End;

Procedure ToPickPockets;
Var
  I,LittleX, LittleY:Byte;
  Direction:Char;
  Picked:Boolean;
Begin
  Picked:=false;
  If CurrentMapType in [1,3] then
    Begin
      WriteMessage('Not around here.');
      Exit;
    End;
  LittleX := TempXloc;
  LittleY := TempYLoc;
  WriteMessage('Pick pockets.  Which direction?');
  Direction := Readkey;
  If Direction = #0 Then Direction := ReadKey;
  Case Ord(Direction) of
  77 : LittleX := LittleX+1;
  75 : LittleX := LittleX-1;
  80 : LittleY := LittleY+1;
  72 : LittleY := LittleY-1;
  Else Begin WriteMessage('Consult your DOS manual about the use of cursor keys.');
       Picked:=True; End
  End;
  For I := 0 to 24 Do
    Begin
      If CurrentMonSet[I] <> Nil then
        Begin
          If (CurrentMonSet[I]^.X=LittleX) AND (CurrentMonSet[I]^.Y=LittleY)
          Then Begin
            Picked:=True;
            If CalPickPock Then
              DetTreasure(CurrentMonStats[CurrentMonSet[I]^.MonsterName].
              TreasureType,1);
          End;
        End;
    End;
  If Not Picked then WriteMessage('You must have 1000/20 vision or something...');
End;

Procedure LookGen(Thing:RanMonType);
Var
  Num:String[2];
  D,P : Byte;
  WeaponName,ArmorName : StringType;
Begin
  WriteMessage(CurrentMonStats[Thing.MonsterName].Name);
  Str(Thing.NumInGroup,Num);
  WriteMessage('There are '+Num+' of them altogether.');
  WeaponInfo(CurrentMonStats[Thing.MonsterName].Weapon,WeaponName,D,P);
  ArmorInfo(CurrentMonStats[Thing.MonsterName].Armor,ArmorName,D);
  WriteMessage('Weapon: '+WeaponName);
  WriteMessage('Armor: '+ArmorName);
End;

Procedure LookSet(Thing:SetMonType);
Var
  Num:String[2];
  D,P : Byte;
  WeaponName,ArmorName : StringType;
Begin
  WriteMessage(CurrentMonStats[Thing.MonsterName].Name);
  Str(Thing.NumInGroup,Num);
  WriteMessage('There are '+Num+' of them altogether.');
  WeaponInfo(CurrentMonStats[Thing.MonsterName].Weapon,WeaponName,D,P);
  ArmorInfo(CurrentMonStats[Thing.MonsterName].Armor,ArmorName,D);
  WriteMessage('Weapon: '+WeaponName);
  WriteMessage('Armor: '+ArmorName);
End;

Procedure LookSign(X,Y : Byte);
Type
    SignType = Record
               X,Y : Byte;
               Msg1,Msg2 : String[70];
               End;
Var
   A : Byte;
   Infile : File;
   Sign : SignType;
Begin
  Assign(Infile,'Sign.Dat');
  Reset(Infile,SizeOf(SignType));
  IOCheck;
  A:=0;
  Repeat
  Seek(Infile,SignNum*3+A);
  BlockRead(Infile,Sign,1);
  If (Sign.X=X) And (Sign.Y=Y) Then Begin
                A:=2; WriteMessage('Sign reads :');
                WriteMessage(Sign.Msg1);
                WriteMessage(Sign.Msg2); End;
  A:=A+1;
  Until A=3;
  Close(Infile);
End;

Procedure ToLook;
Var
  LittleX,LittleY:Byte;
  Direction:Char;
  I : Byte;
  Looked : Boolean;
Begin
  Looked:=False;
  If CurrentMapType=1 Then
    Begin
      LittleX:=Player.Xloc;
      LittleY:=Player.Yloc;
    End
  Else
    Begin
      LittleX:=TempXloc;
      LittleY:=TempYloc;
    End;
  WriteMessage('Look.  Which direction?');
  Direction := Readkey;
  If Direction = #0 Then Direction := ReadKey;
  Case Ord(Direction) of
  77 : LittleX := LittleX+1;
  75 : LittleX := LittleX-1;
  80 : LittleY := LittleY+1;
  72 : LittleY := LittleY-1;
  Else Begin WriteMessage('Consult your DOS manual about the use of cursor keys.');
       Looked:=True; End
  End;
if CurrentMapType in [1,3] then
  Begin
    For I := 1 to 3 Do
      If CurrentMonMem[I] <> Nil Then
        Begin
          If (CurrentMonMem[I]^.X=LittleX) AND (CurrentMonMem[I]^.Y=
          LittleY) Then Begin LookGen(CurrentMonMem[I]^); Looked:=True; End;
        End;
  End;
If CurrentMapType in [2,3,4] then
  Begin
    For I := 0 to 24 Do
      If CurrentMonSet[I] <> Nil Then
        Begin
          If (CurrentMonSet[I]^.X=LittleX) AND (CurrentMonSet[I]^.Y=
          LittleY) Then Begin LookSet(CurrentMonSet[I]^); Looked:=True; End;
        End;
  End;
  If Looked = False Then Begin
     If ((CurrentMapType=1) And (LandMap^[LittleX,LittleY]=5)) Or
        ((CurrentMapType<>1) And (CurrentMap^[LittleX,LittleY]=5)) Then Begin
        LookSign(LittleX,LittleY); Looked:=True; End;
     End;
  If Looked = False Then WriteMessage('Huh?  Where?');
End;

Procedure ToGet;
{This procedure is called ONLY if there currentmaptype of 2,3,4.}
Var
  LittleX, LittleY : Byte;
  Direction:char;
Begin
If CurrentMapType=1 Then
  Begin
    WriteMessage('No chests around here.');
    Exit;
  End
Else
  Begin
    LittleX:=TempXloc;
    LittleY:=TempYloc;
  End;
  WriteMessage('Get chest.  Which direction?');
  Direction := Readkey;
  If Direction = #0 Then Direction := ReadKey;
  Case Ord(Direction) of
  77 : LittleX := LittleX+1;
  75 : LittleX := LittleX-1;
  80 : LittleY := LittleY+1;
  72 : LittleY := LittleY-1;
  Else WriteMessage('Consult your DOS manual about the use of cursor keys.')
  End;
  If CurrentMap^[LittleX,LittleY]=7 then
  Begin
    DetTreasure(CTreasure,0);
    Case CurrentMapType of
    2 : CurrentMap^[LittleX,LittleY]:=9;
    3 : CurrentMap^[LittleX,LittleY]:=16;
    4 : CurrentMap^[LittleX,LittleY]:=12;
    End;
    DisplayMap(TempXloc,TempYloc);
  End
  Else WriteMessage('You need a new pair of glasses.');
End;

Procedure ToRest;
Label NoRest;
Var
  Roll, Chance,A : Byte;
  Chh : Char;
  Attacked : Boolean;
Begin
  If CurrentMapType <> 1 then
    Begin
      WriteMessage('Resting is for outdoors only.');
      Exit;
    End;
  WriteMessage('Rest here? [Y/N]');
  Chh:=ReadKey; If Chh=#0 then Chh:=ReadKey;
  If Chh in ['N','n'] then
    Begin
      WriteMessage('Stop bothering me, then.');
      Exit;
    End;
  WriteMessage('Ok... you are dozing off...');
  WriteMessage('Zzzzzzzzz......'); PaletteColors(1);
  Roll:=Random(4)+3;
  For Chance:=1 To Roll Do
    Begin
    GenMonster;
    For A:=1 To 3 DO
       Begin
       Attacked:=False;
       If CurrentMonMem[A]<>Nil Then Attacked:=CombatCheck2(CurrentMonMem[A]);
       If Attacked Then Begin
                        PaletteColors(2);
                        WriteMessage('Suddenly, you''re awaken!!!!');
                        MonsterMovement;
                        DisplayLand(Player.Xloc,Player.YLoc);
                        Goto NoRest; End;
       End;
    MonsterMovement;
    AnimateMonster(3);
    If CurrentMapType<>1 Then DisplayMap(TempXloc, TempYLoc)
                   Else DisplayLand(Player.Xloc,Player.Yloc);
    End;
  Player.CLife:=Player.CLife+(Roll+5)+Random(5);
  If Player.Clife>Player.Life Then Player.CLife:=Player.Life;
  Player.CMagic:=Player.CMagic+(Roll+5)+Random(5);
  If Player.CMagic>Player.Magic Then Player.CMagic:=Player.Magic;
  ChangeStats(2);  PaletteColors(2);
  WriteMessage('You feel better.');
  NoRest:
End;

Procedure PerceptionCheck(Var X,Y:Byte; Var PCheckYes:Boolean);
Var
  XX,YY,Roll,MstrBonus,I,MonNum:ShortInt;
  Chance : Real;
  Dis,Shortdis:Real;
  Direct1,Direct2:String[5];
Begin
  If CurrentMapType=4 then Exit;
  ShortDis:=10000;
  MstrBonus:=0;
  If MstrBonus>12 then MstrBonus:=MstrBonus-12;
  If MstrBonus<6 then MstrBonus:=MstrBonus-6;
  Chance:=(Player.Skills[9]/1.2)+MstrBonus;
  Roll:=Random(100)+1;
  If CurrentMapType=1 Then
    Begin
      If (Roll<=Chance) And (PCheckYes) Then
        Begin
          For I := 1 to 3 Do
            If CurrentMonMem[I]<>Nil then
              Begin
                Dis:=Sqrt(Sqr(X-CurrentMonMem[I]^.X)+Sqr(Y-CurrentMonMem[I]^.Y));
                If Dis < ShortDis Then
                  Begin
                    ShortDis:=Dis;
                    MonNum:=I;
                  End;
              End;
          If (CurrentMonMem[1] <> Nil) Or (CurrentMonMem[2] <> Nil) Or
          (CurrentMonMem[3] <> Nil) Then
            Begin
              YY:=CurrentMonMem[MonNum]^.Y-Y;
              XX:=CurrentMonMem[MonNum]^.X-X;
              Case YY of
              -127..-1 : Direct1:='north';
              0        : Direct1:='';
              1..127   : Direct1:='south';
              End;
              Case XX of
              -127..-1 : Direct2 := 'west';
              0        : Direct2 := '';
              1..127   : Direct2 := 'east';
              End;
             WriteMessage('You heard noises coming from the '+direct1+direct2+'...');
            End;
         End;
      Exit;
    End;
    If Roll<=Chance then
      Begin
        Case CurrentMapType of
        2 : I:=8;
        3 : I:=18;
        End;
        If CurrentMap^[X-1,Y]=I then
          WriteMessage('You noticed a secret door to the left.');
        If CurrentMap^[X,Y-1]=I then
          WriteMessage('You noticed a secret door to the north.');
        If CurrentMap^[X+1,Y]=I then
          WriteMessage('You noticed a secret door to the right.');
        If CurrentMap^[X,Y+1]=I then
          WriteMessage('You noticed a secret door to the south.');
      End;
End;

Procedure MoneyMessage;
Var I:Byte;
Begin
  I:=73;
  WriteMessage(CHR(I)+#102+#32+#121+#111+#117+#32+#102+#105+#110+#100+#32+
  #116+#104+#105+#115+#32+#112+#114+#111+#103+#114+#97+#109+#32+#101+#110+
  #116+#101+#114+#116+#97+#105+#110+#105+#110+#103+#44); I:=112;
  WriteMessage(CHR(I)+#108+#101+#97+#115+#101+#32+#115+#101+#110+#100+#32+
  #121+#111+#117+#114+#32+#111+#114+#100+#101+#114+#115+#32+#111+#114+#32+
  #99+#111+#110+#116+#114+#105+#98+#117+#116+#105+#111+#110+#115+#32+#116+
  #111+#58); I:=86;
  WriteMessage(CHR(I)+#105+#99+#116+#111+#114+#32+#72+#46+#32+#83+#104+#97+#111+#32+#32+#32
  +#32+#32+#32+#32+#32+#32++#32+#32+#66+#114+#105+#97+#110+#32+#74+#46+#32+#87+
  #101+#115+#116+#111+#110); I:=56;
  WriteMessage(CHR(I)+#57+#48+#50+#32+#83+#112+#117+#114+#32+#82+#100+#32+#32+
  #32+#32+#32+#32+#32+#32+#32++#32+#32+#32#32+#54+#57+#52+#49+#32+#67+#111+#116+
  #116+#111+#110+#116+#97+#105+#108+#32+#67+#116); I:=83;
  WriteMessage(CHR(I)+#112+#114+#105+#110+#103+#102+#105+#101+#108+#100+#44+
  #32+#86+#65+#32+#50+#50+#49+#53+#51+#32+#32+#32+#32+#83+#112+#114+#105+#110+
  #103+#102+#105+#101+#108+#100+#44+#32+#86+#65+#32+#50+#50+#49+#53+#51); I:=80;
  WriteMessage('');
  WriteMessage(CHR(I)+#108+#101+#97+#115+#101+#32+#114+#101+#102+#101+#114+
  #32+#116+#111+#32+#86+#65+#77+#80+#89+#82+#46+#68+#79+#67+#32+#102+#111+
  #114+#32+#109+#111+#114+#101+#32+#100+#101+#116+#97+#105+#108+#115+#46);
End;
(*********************************** MAIN *****************************)
Label
  ByeBye;
Var
  Ch,Ch2 : Char;
  B : Byte;
  SpecialKey,PCheckYes : Boolean;
Begin
{  Each time DisplayMap is called, the set encounter procedure has to be
  called, too.  That would display the people onto the screen, and
  set their XY location on CurrentMap to 28.  Player cannot walk on
  28.  Same with random encounter monsters.}
  CheckBreak:=False;
  CheckEOF:=False;
  DirectVideo:=True;
  CheckSnow:=False;
  LineOfMessage:=1;
  MainTitle;
  GetDir(0,Player.Name);
  If (Player.Name[1]='A') or (Player.Name[1]='B') then
    Begin
      Assign(Infile,'Enconter.set');
      Reset(Infile,147);
      If IOResult<>0 then
        begin
          Close(Infile);
          Delay(2000);
          While IOResult<>0 Do Begin
          ClearDevice;
          SetColor(12);
          OutTextXY(0,0,'Please insert disk 2 in drive '+Player.Name[1]);
          OutTextXY(0,9,'and press any key when ready...');
          Ch2:=ReadKey;
          Assign(Infile,'Enconter.set');
          Reset(Infile,147);
          End;
        End;
      Close(Infile);
    End;
  LoadPlayerStats;
  Ch := '~';
  FirstTimeLoad;
  PCheckYes:=True;
  Randomize;
(*  ---------  End of basic initialization --------- *)

  REPEAT                {The main repeat loop}
    If KeyPressed Then
      Begin
        SpecialKey := False;
        Ch := ReadKey;
        If Ch = #0 Then
          Begin
            SpecialKey := True;
            Ch := ReadKey;
          End;
        Case Ord(UpCase(Ch)) Of
        77 : Begin     {M or right cursor}
               If SpecialKey Then Begin
               If CurrentMapType in [1,3] Then GenMonster;
               If Player.CLife>0 Then MonsterMovement;
               If Player.MiscMagic<>0 Then Player.StepsWalked:=Player.
               StepsWalked+1;
               If CurrentMapType = 1 Then
               Begin
                 If (Not CurrentObs[(LandMap^[Player.Xloc+1,Player.Yloc])])
                 Then Begin
                     Player.Xloc:=Player.Xloc+1;
                     OriB:=OriB+1;
                     If Player.MiscMagic<>1 Then BlockIt(Player.Xloc,Player.Yloc);
                     AnimateMonster(3);
                     DisplayLand(Player.Xloc, Player.Yloc);
                     PerceptionCheck(Player.Xloc,Player.Yloc,PCheckYes);
                   End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Blocked!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayLand(Player.Xloc,Player.Yloc);
                   End;
               End
             Else
               Begin
                 If (Not CurrentObs[(CurrentMap^[TempXloc+1,TempYloc])])
                 Then Begin
                   TempXloc:=TempXloc+1;
                   OriB:=OriB+1;
                   If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
                   DisplayMonster(6);
                   DisplayMap(TempXloc, TempYLoc);
                   PerceptionCheck(TempXloc,TempYloc,PCheckYes);
                 End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Watch where you''re going!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayMap(TempXloc,TempYloc);
                   End;
               End;
               End  {SpecialKey}
               Else
                 ToCastSpells;           {CAST}
             End;
        75 : Begin           {K or left cursor}
               If SpecialKey then begin
               If CurrentMapType in [1,3] Then GenMonster;
               If Player.CLife>0 Then MonsterMovement;
               If Player.MiscMagic<>0 Then Player.StepsWalked:=Player.
               StepsWalked+1;
               If CurrentMapType = 1 Then
               Begin
                 If (Not CurrentObs[(LandMap^[Player.Xloc-1,Player.Yloc])])
                 Then Begin
                     Player.Xloc:=Player.Xloc-1;
                     OriB:=OriB-1;
                     If Player.MiscMagic<>1 Then BlockIt(Player.Xloc,Player.Yloc);
                     AnimateMonster(3);
                     DisplayLand(Player.Xloc, Player.Yloc);
                     PerceptionCheck(Player.Xloc,Player.Yloc,PCheckYes);
                   End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Blocked!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayLand(Player.Xloc,Player.Yloc);
                   End;
               End
               Else
               Begin
                 If (Not CurrentObs[(CurrentMap^[TempXloc-1,TempYloc])]) Then
                 Begin
                   TempXloc:=TempXloc-1;
                   OriB:=OriB-1;
                   If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
                   DisplayMonster(4);
                   DisplayMap(TempXloc, TempYLoc);
                   PerceptionCheck(TempXloc,TempYloc,PCheckYes);
                 End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Watch where you''re going!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayMap(TempXloc,TempYloc);
                   End;
               End;
               End   {SpecialKey}
               Else        {K to klimb stairs}
                 ToKlimb;
             End;
        72 : Begin               {H or up cursor}
               If SpecialKey then begin
               If CurrentMapType in [1,3] Then GenMonster;
               If Player.CLife>0 Then MonsterMovement;
               If Player.MiscMagic<>0 then Player.StepsWalked:=Player.
               StepsWalked+1;
               If CurrentMapType = 1 Then
               Begin
                 If (Not CurrentObs[(LandMap^[Player.Xloc,Player.Yloc-1])])
                 Then Begin
                     Player.Yloc:=Player.Yloc-1;
                     OriA:=OriA-1;
                     If Player.MiscMagic <>1 Then BlockIt(Player.Xloc,Player.Yloc);
                     AnimateMonster(3);
                     DisplayLand(Player.Xloc, Player.Yloc);
                     PerceptionCheck(Player.Xloc,Player.Yloc,PCheckYes);
                   End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Blocked!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayLand(Player.Xloc,Player.Yloc);
                   End;
               End
               Else
               Begin
                 If (Not CurrentObs[(CurrentMap^[TempXloc,TempYloc-1])])
                 Then Begin
                   TempYloc:=TempYloc-1;
                   OriA:=OriA-1;
                   If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
                   DisplayMonster(8);
                   DisplayMap(TempXloc, TempYLoc);
                   PerceptionCheck(TempXloc,TempYloc,PCheckYes);
                 End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Watch where you''re going!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayMap(TempXloc,TempYloc);
                   End;
               End;
             End;
             End;
        80 : Begin               {P or down cursor}
               If SpecialKey Then Begin
               If CurrentMapType in [1,3] Then GenMonster;
               If Player.CLife>0 Then MonsterMovement;
               If Player.MiscMagic<>0 then Player.StepsWalked:=Player.
               StepsWalked+1;
               If CurrentMapType = 1 Then
               Begin
                 If (Not CurrentObs[(LandMap^[Player.Xloc,Player.Yloc+1])])
                 Then Begin
                    Player.Yloc:=Player.Yloc+1;
                    OriA:=OriA+1;
                    If Player.MiscMagic<>1 Then Blockit(Player.Xloc,Player.Yloc);
                    AnimateMonster(3);
                    DisplayLand(Player.Xloc, Player.YLoc);
                    PerceptionCheck(Player.Xloc,Player.Yloc,PCheckYes);
                   End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Blocked!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayLand(Player.Xloc,Player.Yloc);
                   End;
               End
               Else
               Begin
                 If (Not CurrentObs[(CurrentMap^[TempXloc,TempYloc+1])])
                 Then Begin
                     TempYloc := TempYLoc+1;
                   If TempYLoc <=47 Then
                   Begin
                     OriA:=OriA+1;
                     If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
                     DisplayMonster(2);
                     DisplayMap(TempXloc, TempYLoc);
                     PerceptionCheck(TempXloc,TempYloc,PCheckYes);
                   End
                   Else
                     Begin
                       LoadNewMapType(1);
                       If Player.MiscMagic<>1 Then BlockIt(Player.Xloc,Player.Yloc);
                       KeyboardFlush;
                       DisplayLand(Player.Xloc,Player.Yloc);
                     End;
                 End
                 Else
                   Begin
                     If SoundOnOff Then PunchSound;
                     WriteMessage('Watch where you''re going!');
                     AnimateMonster(3); KeyboardFlush;
                     DisplayMap(TempXloc,TempYloc);
                   End;
               End;
               End
               Else   {SpecialKey, Pick pockets}
                 ToPickPockets;
             End;
        81 : Begin       {Quit}
               WriteMessage('Are you sure? [Y/N]');
               Ch2 := ReadKey; If Ch2=#0 then Ch2:=ReadKey;
               If UpCase(Ch2) = 'Y' Then Goto ByeBye
               Else WriteMessage('Stop messing around then!');
             End;
        69 : Begin
             ToEnter;       {Enter}
             End;
        83 : Begin       {Save}
               If CurrentMapType <> 1 Then WriteMessage('Only on land.')
               Else Begin
                      WriteMessage('Save the game? [Y/N]');
                      Ch2 := ReadKey; If Ch2=#0 then Ch2:=ReadKey;
                      If UpCase(Ch2) = 'Y' Then
                      Begin
                        SavePlayer;
                        WriteMessage('Saved.');
                      End
                      Else
                        WriteMessage('Not saved.');
                    End;
             End;
        65 : Begin
             ToAttack;     {Attack}
             AnimateMonster(3);
             If Player.CLife>0 Then MonsterMovement;
             If CurrentMapType<>1 Then DisplayMap(TempXloc, TempYLoc)
                Else DisplayLand(Player.Xloc,Player.Yloc);
             End;
        73 : Begin
             WriteMessage('Inspect weapon or armor? [W/A]');
             Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
             If Not (Upcase(Ch) in ['W','A']) then
               WriteMessage('That wasn''t W or A now was it?')
             else begin
             If (Upcase(Ch)='W') Then Begin
               If Player.Weapon=0 then
                 WriteMessage('Nice and big hands you''ve got...')
               else begin
               WriteMessage('The weapon in your hand looks...');
               DurLook(True,Player.Weapon,Player.WeaponDur[0],0); end;
             End;
             If (Upcase(Ch)='A') Then Begin
               If Player.Armor=0 then
                 WriteMessage('You need to have your toenails cut...')
               Else begin
               WriteMessage('The armor you''re wearing looks...');
               DurLook(False,Player.Armor,Player.ArmorDur,0); end;
             End;
             End;
             End;
        85 : Begin
             ToPickLock;
             AnimateMonster(3);
             If Player.CLife>0 Then MonsterMovement;
             If CurrentMapType<>1 Then DisplayMap(TempXloc, TempYLoc)
                Else DisplayLand(Player.Xloc,Player.Yloc);
             End;
        67 : Begin
             ToClimbWall;     {F9 or Climb walls}
             AnimateMonster(3);
             If Player.CLife>0 Then MonsterMovement;
             If CurrentMapType<>1 Then DisplayMap(TempXloc, TempYLoc)
                Else DisplayLand(Player.Xloc,Player.Yloc);
             End;
        13 : Begin
             WriteMessage('Pass.');
             GenMonster;
             If Player.CLife>0 Then MonsterMovement;
             AnimateMonster(3);
             If CurrentMapType<>1 Then DisplayMap(TempXloc, TempYLoc)
                Else DisplayLand(Player.Xloc,Player.Yloc);
             End;
        90 : zstatscommand;
        84 : ToTalk;
        76 : ToLook;   {L for look}
        71 : Begin
             ToGet;    {G for Get Chest}
             AnimateMonster(3);
             If Player.CLife>0 Then MonsterMovement;
             If CurrentMapType<>1 Then DisplayMap(TempXloc, TempYLoc)
                Else DisplayLand(Player.Xloc,Player.Yloc);
             End;
        82 : ToRest;   {R For resting outdoors}
        3  : Begin     {Ctrl-C, clear message window}
              For B := 1 to 7 Do
                PutImage(12,125+(B*9),MessageErase^,NormalPut);
              LineOfMessage := 1;
            End;
        19 : Begin
               SoundOnOff := Not SoundOnOff;    {Ctrl-S, sound off}
               If SoundOnOff = True then WriteMessage('Sound On');
               If SoundOnOff = False then WriteMessage('Sound Off');
             End;
        16 : Begin
               PCheckYes:=Not PCheckYes;
               If PCheckYes then WriteMessage('Perception check On');
               If Not PCheckYes then WriteMessage('Perception check Off');
             End;
        79 : Begin
               WriteMessage('Reload the old saved game? [Y/N]');
               Ch2:=Readkey; If Ch2=#0 then Ch2:=ReadKey;
               If Upcase(Ch2) <> 'Y' then
                 WriteMessage('Oh, ok.')
               else
                 begin
                   LoadPlayerStats;
                   LoadNewMapType(1);
                   LoadPlayerPic(Player.Race);
                   PutImage(114,57,PlayerIcon^,NormalPut);
                   If Player.MiscMagic <>1 then blockit(Player.Xloc,PLayer.Yloc);
                   DisplayLand(Player.Xloc,Player.Yloc);
                   ChangeStats(2);
                 End;
              End;
         9 : MoneyMessage;
        End;     {CASE}
      End;   {KeyPressed}
    If CurrentMapType =1 then
      Begin
        For B := 1 to 3 Do
          If CurrentMonMem[B]<>Nil then Begin
          If (Abs(CurrentMonMem[B]^.X-Player.Xloc)>12) or
          (Abs(CurrentMonMem[B]^.Y-Player.Yloc)>12) then
            begin
              LandMap^[CurrentMonMem[B]^.X,CurrentMonMem[B]^.Y]:=
              CurrentMonMem[B]^.OriPic;
              Dispose(CurrentMonMem[B]);
              CurrentMonMem[B]:=Nil;
            End; End;
      End;
    If CurrentMapType=3 then
      Begin
        For B := 1 to 3 Do
          If CurrentMonMem[B]<>Nil then Begin
          If (Abs(CurrentMonMem[B]^.X-TempXloc)>8) or
          (Abs(CurrentMonMem[B]^.Y-TempYloc)>8) then
            Begin
              CurrentMap^[CurrentMonMem[B]^.X,CurrentMonMem[B]^.Y]:=
              CurrentMonMem[B]^.OriPic;
              Dispose(CurrentMonMem[B]);
              CurrentMonMem[B]:=Nil;
            End; End;
      If CurrentMap^[TempXLoc,TempYLoc]=9 Then Begin
            WriteMessage('Lava!!!');
            Player.Clife:=(Player.Clife)-(Random(7)+10);
            ChangeStats(1);
            End;
      End;
    If (Player.Clife <= 0) And (Player.Race<4)  then
      Begin
        LoadPlayerPic(6);
        PutImage(114,57,PlayerIcon^,NormalPut);
        If SoundOnOff Then RipSound;
        If CurrentMapType=4 then
          Begin
            WriteMessage('Sorry, but if you die in Heaven, you''re dead...'); Delay(1000);
            WriteMessage('...FOR GOOD!'); Delay(1000);
            WriteMessage('PRESS ANY KEY TO EXIT VAMPYR.');
            Ch := Readkey;
            Goto ByeBye;
          End;
        WriteMessage('It seems that you were blown away...');
        LoadNewMapType(4);
        If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
        DisplayMap(TempXloc,TempYLoc);
      End;
    If (Player.Clife <=0) And (Player.Race>3) Then Begin
        WriteMessage('No, Superior Races can''t die.'); Delay(800);
        WriteMessage('Returning full power.'); Delay(800);
        Player.Clife:=Player.Life;
        Player.CMagic:=Player.Magic;
        ChangeStats(1);
        End;
    If Player.StepsWalked>100 then
      Begin
        WriteMessage('Your misc. spell has just ended.');
        CancelMagic;
        ChangeStats(2);
      End;
                      {ANIMATION --- for maps ONLY}
    If CurrentMapType = 1 then
      Begin
        OriA := Player.YLoc-3;
        OriB := Player.XLoc-3;
      End
    Else
      Begin
        OriA := TempYLoc-3;
        OriB := TempXLoc-3;
      End;
    AnimateMap(1);
    If Not KeyPressed Then AnimateMonster(1);
    If Not KeyPressed Then AnimateMap(2);
    If Not KeyPressed Then AnimateMonster(2);
Until Player.Mission[6];  {Main REPEAT loop}
TheEnd;
ByeBye:
  If CurrentMapType = 1 then Dispose(LandMap) Else Dispose(CurrentMap);
  IconSize:=ImageSize(1,1,36,18);
  For B := 0 to 19 Do
    FreeMem(CurrentMapIcon[B],IconSize);
  For B := 0 to 13 Do
    FreeMem(UnivIcon[B],IconSize);
  FreeMem(EmptyIcon,IconSize);
  FreeMem(PlayerIcon,IconSize);
  IconSize := ImageSize(12,1,631,8);
  FreeMem(MessageErase,IconSize);
  IconSize:= ImageSize(12,1,631,54);
  FreeMem(MessageScrollPtr,IconSize);
  CloseGraph;
End.
