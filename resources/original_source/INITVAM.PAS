{$mode tp}
{$H-}
{$PACKRECORDS 1}
{$I-}

Unit InitVam;
Interface
Uses Music,Graph,Crt,Global,Display,Monster,Vcombat;
Procedure LoadPlayerStats;
Procedure LoadCurrentIcons;
Procedure LoadCurrentMonPics;
Procedure LoadCurrentMonStats;
Procedure LoadPlayerPic(X : Byte);
Procedure DisposeCurrentMonMem;
Procedure DisposeCurrentMonSet;
Procedure LoadSetMon(StartAt,EndAt : Word);
Procedure LoadNewMapType(JobNum:Byte);
Procedure LoadNewStuff;
Procedure DrawMainBorder;
Procedure FirstTimeLoad;

Implementation

Procedure LoadPlayerStats;
Begin
  Assign(Infile,'player.sav');
  Reset(Infile,SizeOf(Player));
  If IOResult=$02 then
    begin
      ClearDevice;
      SetColor(12);
      OutTextXY(0,0,'PLAYER.SAV not found!');
      OutTextXY(0,9,'CREATE a character first!');
      Delay(2400);
      CloseGraph;
      Halt;
    end else IOCheck;
  BlockRead(Infile,Player,1);
  Close(Infile);
End;

Procedure LoadCurrentIcons;
Var
  B,A : Byte;
Begin
  IOCheck;
  SetActivePage(3);
  For IconNum := 0 to 19 Do
    Begin
      Seek(Infile, IconNum);
      BlockRead(Infile, Icon, 1);
      For A := 1 to 18 Do
        For B := 1 to 18 Do
          If Icon[B,A] <> 0 Then
            Begin
              PutPixel(B*2-1,A,Icon[B,A]);
              PutPixel(B*2,A,Icon[B,A]);
            End;
      GetImage(1,1,36,18,CurrentMapIcon[IconNum]^);
      PutImage(1,1,CurrentMapIcon[IconNum]^,XorPut);
    End;
Close(Infile);
SetActivePage(0);
End;

Procedure LoadCurrentMonPics;
Var
  B,A : Byte;
Begin
  IOCheck;
  SetActivePage(3);
  For IconNum := 0 to 25 Do
    Begin
      Seek(Infile, IconNum);
      BlockRead(Infile, Icon, 1);
      For A := 1 to 18 Do
        For B := 1 to 18 Do
          If Icon[B,A] <> 0 Then
            Begin
              PutPixel(B*2-1,A,Icon[B,A]);
              PutPixel(B*2,A,Icon[B,A]);
            End;
      GetImage(1,1,36,18,CurrentMonPics[IconNum]^);
      PutImage(1,1,CurrentMonPics[IconNum]^,XorPut);
    End;
Close(Infile);
SetActivePage(0);
End;

Procedure LoadCurrentMonStats;
Var I : Byte;
Begin
  IOCheck;
  For I := 0 to 12 Do
    Begin
      Seek(Infile,I);
      BlockRead(Infile,CurrentMonStats[I],1);
    End;
Close(Infile);
End;

Procedure LoadPlayerPic(X : Byte);
Var
  B,A : Byte;
Begin
  SetActivePage(3);
  Assign(Infile,'player.con');
  Reset(infile,324);
  IOCheck;
  Seek(Infile, X);
  BlockRead(Infile, Icon, 1);
  For A := 1 to 18 Do
    For B := 1 to 18 Do
      If Icon[B,A] <> 0 Then
        Begin
          PutPixel(B*2-1,A,Icon[B,A]);
          PutPixel(B*2,A,Icon[B,A]);
        End;
  GetImage(1,1,36,18,PlayerIcon^);
  PutImage(1,1,PlayerIcon^,XorPut);
  Close(Infile);
  SetActivePage(0);
End;

Procedure DisposeCurrentMonMem;
Var X : Byte;
Begin
  For X := 1 to 3 do
    If CurrentMonMem[X] <> Nil Then
      Begin
        Dispose(CurrentMonMem[X]);
        CurrentMonMem[X]:=Nil;
      End;
End;

Procedure DisposeCurrentMonSet;
Var X : Byte;
Begin
  For X := 0 to 24 Do
    If CurrentMonSet[X] <> Nil Then
      Begin
        Dispose(CurrentMonSet[X]);
        CurrentMonSet[X]:=Nil;
      End;
End;

Procedure LoadSetMon(StartAt, EndAt : Word);
Var
  I : Integer;
Begin
  Assign(Infile,'enconter.set');
  Reset(Infile,147);
  IOCheck;
  For I := StartAt to EndAt Do
    Begin
      New(CurrentMonSet[I-StartAt]);
      Seek(Infile,I);
      BlockRead(Infile,CurrentMonSet[I-StartAt]^,1);
      CurrentMonSet[I-StartAt]^.OriPic := CurrentMap^[(CurrentMonSet[I-StartAt]
      ^.X),(CurrentMonSet[I-StartAt]^.Y)];
      CurrentMap^[(CurrentMonSet[I-StartAt]^.X),(CurrentMonSet[I-StartAt]^.Y)]
      := 28;
    End;
  Close(Infile);
End;

Procedure LoadNewMapType(JobNum:Byte);
Var
  X : Byte;
Begin
For X := 7 to 27 Do
  Begin
    CurrentObs[X] := False;
    CurrentDisObs[X] := False;
  End;
Case JobNum of
1 : Begin
      SignNum:=0;
      Ctreasure:=1;
      Player.Items[3]:=False;
      WriteMessage('Returning to Quilinor...');
      DisposeCurrentMonMem;
      DisposeCurrentMonSet;
      If CurrentMap<>Nil then Dispose(CurrentMap);
      CurrentMap:=Nil;
      If LandMap=Nil then New(LandMap);
      Assign(Infile, 'world.map');
      Reset(Infile,11000);
      IOCheck;
      Seek(Infile,0);
      BlockRead(Infile, LandMap^, 1);
      Close(Infile);
      Assign(Infile, 'land.con');
      Reset(Infile, 324);
      LoadCurrentIcons;
      CurrentObs[12] := True;
      CurrentDisObs[12] := True;
      CurrentDisObs[13] := True;
      CurrentDisObs[15] := True;
      Assign(Infile,'landmon.con');
      Reset(Infile,324);
      LoadCurrentMonPics;
      Assign(Infile,'landmon.dat');
      Reset(Infile,SizeOf(MonsterType));
      LoadCurrentMonStats;
    End;  { 1 }
2 : Begin
      DisposeCurrentMonMem;
      Dispose(LandMap);
      LandMap:=Nil;
      New(CurrentMap);
      If ((Player.Xloc in [42,43]) AND (Player.Yloc = 41)) Then
        Begin
          SignNum:=9;
          WriteMessage('Entering castle...');
          Assign(Infile,'castle.map');
          Reset(Infile,2500);
          IOCheck;
          Seek(Infile,2);
          BlockRead(Infile,CurrentMap^,1);
          Close(Infile);
          LoadSetMon(200,224);
          Ctreasure:=2;
        End
      Else
        Begin
          Ctreasure:=1;
          Assign(Infile,'town.map');
          Reset(Infile,2500);
          IOCheck;
          If ((Player.Xloc in [45,46]) AND (Player.Yloc=43)) Then
          Begin
            SignNum:=1;
            WriteMessage('Entering the town of Balinar...');
            Seek(Infile,0);
            BlockRead(Infile,CurrentMap^,1);
            Close(Infile);
            LoadSetMon(0,24);
          End;
          If ((Player.Xloc in [15,16]) AND (Player.Yloc=57)) Then
          Begin
            SignNum:=2;
            WriteMessage('Entering the town of Rendyr...');
            Seek(Infile,1);
            BlockRead(Infile,CurrentMap^,1);
            Close(Infile);
            LoadSetMon(25,49);
          End;
          If ((Player.Xloc in [86,87]) AND (Player.Yloc=59)) Then
          Begin
            SignNum:=3;
            WriteMessage('Entering the town of Maninox...');
            Seek(Infile,2);
            BlockRead(Infile,CurrentMap^,1);
            Close(Infile);
            LoadSetMon(50,74);
          End;
          If ((Player.Xloc in [20,21]) AND (Player.Yloc=85)) Then
          Begin
            SignNum:=4;
            WriteMessage('Entering the town of Zachul...');
            Seek(Infile,3);
            BlockRead(Infile,CurrentMap^,1);
            Close(Infile);
            LoadSetMon(75,99);
          End;
          If ((Player.Xloc in [40,41]) AND (Player.Yloc=81)) Then
          Begin
            SignNum:=5;
            WriteMessage('Entering the town of Trocines...');
            Seek(Infile,4);
            BlockRead(Infile,CurrentMap^,1);
            Close(Infile);
            LoadSetMon(100,124);
          End;
          If ((Player.Xloc in [56,57]) AND (Player.Yloc=92)) Then
          Begin
            SignNum:=6;
            WriteMessage('Entering the town of Myron...');
            Seek(Infile,5);
            BlockRead(Infile,CurrentMap^,1);
            Close(Infile);
            If ((Player.Mission[1]=true) and (Player.mission[2]=true) and
            (Player.mission[3]=false)) then LoadSetMon(280,297) else
            LoadSetMon(125,149);
          End;
        End;
      Assign(Infile,'town.con');
      Reset(Infile,324);
      LoadCurrentIcons;
      CurrentObs[7] := True;
      CurrentObs[10] := True;
      CurrentObs[12] := True;
      CurrentObs[13] := True;
      CurrentObs[15] := True;
      CurrentObs[16] := True;
      CurrentObs[17] := True;
      CurrentObs[18] := True;
      CurrentObs[19] := True;
      CurrentObs[20] := True;
      CurrentObs[21] := True;
      CurrentObs[22] := True;
      CurrentObs[25] := True;
      CurrentObs[26] := True;
      CurrentObs[27] := True;
      CurrentDisObs[8] := True;
      CurrentDisObs[10] := True;
      CurrentDisObs[13] := True;
      CurrentDisObs[14] := True;
      CurrentDisObs[25] := True;
      Assign(Infile,'townmon.con');
      Reset(Infile,324);
      LoadCurrentMonPics;
      Assign(Infile,'townmon.dat');
      Reset(Infile, SizeOf(MonsterType));
      LoadCurrentMonStats;
      TempXLoc := 25;
      TempYLoc := 46;
      SuspicionLevel := 0;
      FloorLevel := 3;
    End;
3 : Begin
      DisposeCurrentMonMem;
      Dispose(LandMap);
      LandMap := Nil;
      New(CurrentMap);
      If ((Player.Xloc = 45) AND (Player.Yloc = 4)) OR
      ((Player.Xloc = 105) AND (Player.Yloc = 10)) Then
      Begin
        WriteMessage('Entering dungeon...');
        Assign(Infile,'dungeon.map');
        Reset(Infile,2500);
        IOCheck;
        SignNum:=11;
        FloorLevel := 1;
        Ctreasure:=1;
        If ((Player.Xloc = 45) AND (Player.Yloc =4)) Then Seek(Infile,0)
          Else Begin Seek(Infile,3); Ctreasure:=2; End;
      End;
      If ((Player.Xloc = 98) AND (Player.Yloc in [93,94])) Then
        Begin
          WriteMessage('Entering Vampyr''s Castle...');
          FloorLevel := 2;
          SignNum:=13;
          Ctreasure:=3;
          Assign(Infile,'vcastle.map');
          Reset(Infile,2500);
          IOCheck;
          Seek(Infile,1);
          TwzoneSound;
          Twzonesound;
        End;
      If ((Player.Xloc in [60,61]) AND (Player.Yloc = 58)) Then
        Begin
          WriteMessage('Entering ruin...');
          Ctreasure:=2;
          Assign(Infile,'ruin.map');
          Reset(Infile,2500);
          IOCheck;
          Seek(Infile,0);
        End;
      If ((Player.Xloc in [21,22]) AND (Player.Yloc = 18)) Then
        Begin
          WriteMessage('Entering ruin...');
          Ctreasure:=2;
          Assign(Infile,'ruin.map');
          Reset(Infile,2500);
          IOCheck;
          Seek(Infile,1);
        End;
      BlockRead(Infile, CurrentMap^,1);
      Close(Infile);
      If ((Player.Xloc = 98) AND (Player.Yloc in [93,94])) AND
        (Player.Items[2]=True) then
          begin
            CurrentMap^[25,12]:=16;
            CurrentMap^[26,12]:=16;
          end;
      Assign(Infile,'dungeon.con');
      Reset(Infile,324);
      LoadCurrentIcons;
      CurrentObs[7] := True;
      CurrentObs[8] := True;
      CurrentObs[10] := True;
      CurrentObs[11] := True;
      CurrentObs[12] := True;
      CurrentObs[17] := True;
      CurrentObs[20] := True;
      CurrentObs[22] := True;
      CurrentObs[23] := True;
      CurrentObs[24] := True;
      CurrentObs[25] := True;
      CurrentDisObs[17] := True;
      CurrentDisObs[18] := True;
      CurrentDisObs[21] := True;
      CurrentDisObs[23] := True;
      CurrentDisObs[24] := True;
      CurrentDisObs[25] := True;
      If ((Player.Xloc in [60,61]) AND (Player.Yloc = 58)) OR
      ((Player.Xloc in [21,22]) AND (Player.Yloc = 18)) OR
      ((Player.Xloc = 98) AND (Player.Yloc in [93,94])) Then
        Begin
          Assign(Infile,'ruinmon.con');
          Reset(Infile,324);
          LoadCurrentMonPics;
          Assign(Infile,'ruinmon.dat');
          Reset(Infile,SizeOf(MonsterType));
          LoadCurrentMonstats;
          If ((Player.Xloc in [60,61]) AND (Player.Yloc = 58)) then
            LoadSetMon(255,264);
          If ((Player.Xloc in [21,22]) AND (Player.Yloc = 18)) Then
            LoadSetMon(250,254);
          If ((Player.Xloc = 98) and (Player.Yloc in [93,94])) then
            LoadSetMon(274,276);
        End
      Else
        Begin
          Assign(Infile,'dungmon.con');
          Reset(Infile,324);
          LoadCurrentMonPics;
          Assign(Infile,'dungmon.dat');
          Reset(Infile,SizeOf(MonsterType));
          LoadCurrentMonStats;
          If (Player.Xloc=45) and (Player.Yloc=4) then
            LoadSetMon(265,266);
        End;
      {Load set encounter}
      TempXloc:=26;
      TempYLoc:=46;
      SuspicionLevel := 0;
    End;
4 : Begin
      SignNum:=10;
      Ctreasure:=3;
      DisposeCurrentMonSet;
      DisposeCurrentMonMem;
      If LandMap <> Nil Then
      Begin
        Dispose(LandMap);
        LandMap:=Nil;
        New(CurrentMap);
      End;
      Assign(Infile,'after.map');
      Reset(Infile,2500);
      IOCheck;
      Seek(Infile,0);
      BlockRead(Infile,CurrentMap^,1);
      Close(Infile);
      WriteMessage('But wait...');
      Assign(Infile,'after.con');
      Reset(Infile,324);
      LoadCurrentIcons;
      WriteMessage('Is the game over already?');
      CurrentObs[7] := True;
      CurrentObs[8] := True;
      CurrentObs[10] := True;
      CurrentObs[11] := True;
      CurrentObs[13] := True;
      CurrentObs[14] := True;
      CurrentObs[15] := True;
      CurrentObs[17] := True;
      CurrentObs[18] := True;
      CurrentObs[19] := True;
      CurrentObs[21] := True;
      CurrentObs[22] := True;
      CurrentObs[23] := True;
      CurrentObs[24] := True;
      CurrentObs[25] := True;
      CurrentObs[26] := True;
      CurrentDisObs[10] := True;
      CurrentDisObs[16] := True;
      CurrentDisObs[17] := True;
      CurrentDisObs[21] := True;
      Assign(Infile,'lifemon.con');
      Reset(Infile,324);
      LoadCurrentMonPics;
      LoadPlayerPic(Player.Race+7);
      Player.Clife:=Player.Life;
      WriteMessage('No it''s not!  You''ve arrived at... Heaven.');
      ChangeStats(1);
      Assign(Infile,'lifemon.dat');
      Reset(Infile,SizeOf(MonsterType));
      LoadCurrentMonStats;
      LoadSetMon(225,249);
      TempXloc := 25;
      TempYloc := 46;
      PutImage(114,57,PlayerIcon^,NormalPut);
      SuspicionLevel:=0;
    End;
End;   {CASE}
CurrentMapType:=JobNum;
End;

Procedure LoadNewStuff;
Var A : Byte;
    B : Boolean;
{For going up or down dungeons and stuff.  Loads new SetEncounter and
 the new map and for all the signs.  Reset ran encounters}
Begin
  DisposeCurrentMonMem;
  If ((Player.Xloc in [42,43]) And (Player.Yloc = 41)) Then
    Begin
      B:=False;
      For A:=0 TO 24 DO
        If (CurrentMonSet[A]^.Status=1) And (CurrentMonSet[A]^.MonsterName=2)
            Then B:=True;
      Assign(Infile,'castle.map');
      Reset(Infile,2500);
      IOCheck;
      Seek(Infile,FloorLevel-1);
      SignNum:=FloorLevel+6;
      BlockRead(Infile,CurrentMap^,1);
      Close(Infile);
      LoadSetMon(125+(FloorLevel*25),149+(FloorLevel*25));
      If B Then StartChasing;
    End;
  If ((Player.Xloc = 98) And (Player.Yloc in [93,94])) Then
    Begin
      Assign(Infile,'vcastle.map');
      Reset(Infile,2500);
      IOCheck;
      Seek(Infile,FloorLevel-1);
      BlockRead(Infile,CurrentMap^,1);
      Close(Infile);
      SignNum:=FloorLevel+11;
      If (FloorLevel=2) and (Player.Items[2]=true) then
        begin
          CurrentMap^[25,12]:=16;
          CurrentMap^[26,12]:=16;
        End;
      if (FloorLevel=1) and (Player.Items[2]=true) then
        LoadSetMon(271,272) else     {273 is dalagash}
      LoadSetMon(268+(FloorLevel*3),270+(FloorLevel*3));
    End;
  If ((Player.Xloc = 45) And (Player.Yloc = 4)) Then
    Begin
      Assign(Infile,'dungeon.map');
      Reset(Infile,2500);
      IOCheck;
      Seek(Infile,FloorLevel-1);
      BlockRead(Infile,CurrentMap^,1);
      Close(Infile);
      LoadSetMon(263+(FloorLevel*2),264+(FloorLevel*2));
    End;
  If ((Player.Xloc = 105) and (Player.Yloc = 10)) Then
    Begin
      Assign(Infile,'dungeon.map');
      Reset(Infile,2500);
      IOCheck;
      Seek(Infile,FloorLevel+2);
      BlockRead(Infile,CurrentMap^,1);
      Close(Infile);
      {LoadSetMon...}
    End;
End;

Procedure DrawMainBorder;
Var A,B,C : Byte;
    Data : Array[1..145,1..25] Of Byte;
Begin
  SetActivePage(0);
  SetVisualPage(3);
  ClearDevice;
  SetColor(4);
  Rectangle(0,0,639,199);
  Rectangle(1,0,638,199);
  Rectangle(4,2,635,197);
  Rectangle(5,2,634,197);
  Rectangle(258,3,263,128);
  Rectangle(259,3,262,128);
  Rectangle(6,129,633,131);
  SetColor(12);
  Rectangle(2,1,637,198);
  Rectangle(3,1,636,198);
  Rectangle(260,2,261,129);
  Line(4,130,635,130);
  Assign(Infile,'Vampyr.001');
  Reset(Infile,SizeOf(Data));
  Seek(Infile,0);
  BlockRead(Infile,Data,1);
  Close(Infile);
  For A:=1 To 145 Do
  For B:=1 To 25 Do
      Begin
         PutPixel((A*2-1)+300,B+4,Data[A,B]);
         PutPixel((A*2)+300,B+4,Data[A,B]);
      End;
  SetActivePage(0);
  SetVisualPage(0);
End;

Procedure FirstTimeLoad;
Var
  A,B:Byte;
Begin
  SetActivePage(3);
  IconSize := ImageSize(12,1,631,8);
  GetMem(MessageErase,IconSize);
  GetImage(12,1,631,8,MessageErase^);
  IconSize:= ImageSize(12,1,631,54);
  GetMem(MessageScrollPtr,IconSize);
  IconSize := ImageSize(1,1,36,18);
  GetMem(EmptyIcon,IconSize);
  GetImage(1,1,36,18,EmptyIcon^);
  Assign(Infile, 'univ.con');
  Reset(Infile, 324);
  IOCheck;
  For IconNum := 0 to 14 Do
    Begin
      Seek(Infile, IconNum);
      BlockRead(Infile, Icon, 1);
      For A := 1 to 18 Do
        For B := 1 to 18 Do
          If Icon[B,A] <> 0 Then
            Begin
              PutPixel(B*2-1,A,Icon[B,A]);
              PutPixel(B*2,A,Icon[B,A]);
            End;
      GetMem(UnivIcon[IconNum], IconSize);
      GetImage(1,1,36,18,UnivIcon[IconNum]^);
      PutImage(1,1,UnivIcon[IconNum]^,XorPut);
    End;
  Close(Infile);
  CurrentDisObs[0] := False;
  CurrentDisObs[1] := False;
  CurrentDisObs[2] := False;
  CurrentDisObs[3] := True;
  CurrentDisObs[4] := False;
  CurrentDisObs[5] := False;
  CurrentDisObs[6] := False;
  CurrentDisObs[28] := False;
  CurrentObs[0] := True;
  CurrentObs[1] := True;
  CurrentObs[2] := False;
  CurrentObs[3] := False;
  CurrentObs[4] := False;
  CurrentObs[5] := True;
  CurrentObs[6] := False;
  CurrentObs[28] := True;
  CurrentMap:=Nil;
  New(LandMap);
  Assign(Infile, 'world.map');
  Reset(Infile,11000);
  IOCheck;
  Seek(Infile,0);
  BlockRead(Infile, LandMap^, 1);
  Close(Infile);
  Assign(Infile, 'land.con');
  Reset(Infile, 324);
  IOCheck;
  For IconNum := 0 to 19 Do
    Begin
      Seek(Infile, IconNum);
      BlockRead(Infile, Icon, 1);
      For A := 1 to 18 Do
        For B := 1 to 18 Do
          If Icon[B,A] <> 0 Then
            Begin
              PutPixel(B*2-1,A,Icon[B,A]);
              PutPixel(B*2,A,Icon[B,A]);
            End;
      GetMem(CurrentMapIcon[IconNum], IconSize);
      GetImage(1,1,36,18,CurrentMapIcon[IconNum]^);
      PutImage(1,1,CurrentMapIcon[IconNum]^,XorPut);
    End;
  Close(Infile);
  CurrentMapType := 1;
  For B := 7 to 27 Do
  Begin
    CurrentObs[B] := False;
    CurrentDisObs[B] := False;
  End;
  CurrentObs[12] := True;
  CurrentDisObs[12] := True;
  CurrentDisObs[13] := True;
  CurrentDisObs[15] := True;
  Assign(Infile,'landmon.con');
  Reset(Infile,324);
  IOCheck;
  For IconNum := 0 to 25 Do
    Begin
      Seek(Infile, IconNum);
      BlockRead(Infile, Icon, 1);
      For A := 1 to 18 Do
        For B := 1 to 18 Do
          If Icon[B,A] <> 0 Then
            Begin
              PutPixel(B*2-1,A,Icon[B,A]);
              PutPixel(B*2,A,Icon[B,A]);
            End;
      GetMem(CurrentMonPics[IconNum],IconSize);
      GetImage(1,1,36,18,CurrentMonPics[IconNum]^);
      PutImage(1,1,CurrentMonPics[IconNum]^,XorPut);
    End;
  Close(Infile);
  Assign(Infile,'landmon.dat');
  Reset(Infile,SizeOf(MonsterType));
  IOCheck;
  For A := 0 to 12 Do
    Begin
      Seek(Infile,A);
      BlockRead(Infile,CurrentMonStats[A],1);
    End;
  Close(Infile);
  For A := 1 to 3 Do
    CurrentMonMem[A] := Nil;
  For A := 0 to 24 Do
    CurrentMonSet[A] := Nil;
  Assign(Infile, 'player.con');
  Reset(Infile, 324);
  IOCheck;
  Seek(Infile, Player.Race);
  BlockRead(Infile, Icon, 1);
  Close(Infile);
  For A := 1 to 18 Do
    For B := 1 to 18 Do
      If Icon[B,A] <> 0 Then
        Begin
          PutPixel(B*2-1,A,Icon[B,A]);
          PutPixel(B*2,A,Icon[B,A]);
        End;
  GetMem(PlayerIcon, IconSize);
  GetImage(1,1,36,18,PlayerIcon^);
  PutImage(1,1,PlayerIcon^,XorPut);
  DrawMainBorder;
  SetPalette(5,5);
  SetPalette(13,21);
  PutImage(114,57,PlayerIcon^,NormalPut);
  BlockIt(Player.Xloc,Player.Yloc);
  DisplayLand(Player.Xloc, Player.Yloc);
  SignNum:=0;
  ShowPlayerStats;
End;


End.