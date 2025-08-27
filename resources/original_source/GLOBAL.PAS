{$mode tp}
{$H-}
{$PACKRECORDS 1}

Unit Global;
Interface
  Uses Graph,Crt;
Type
  CombatMon = Record
              X,Y : Byte;
              Hp : Byte;
              Name : Byte;
              End;
  CombatMonType = Array[1..8] Of CombatMon;
  BooMapType = Array[1..7,1..7] of Boolean;
  CurrentMapMap = Array[1..50,1..50] of Byte;
  LandMapMap = Array[1..110,1..100] of Byte;
  BooleanType = Array[1..9] of Boolean;
  MonsterType = Record
                  Name : String[15];
                  HitPts : Integer;
                  XPVal : Word;
                  Offensive : Byte;
                  Defensive : Byte;
                  Weapon : Byte;
                  Armor : Byte;
                  MaxNumInGroup : Byte;
                  MagicRes : Byte;
                  TreasureType : Byte;      {Need work}
                  SpecialAttack : Byte;
                End;
  RanMonType = Record
                   MonsterName : Byte;
                   Status : Byte;
                   NumInGroup : Byte;   {Based on MaxNumInGroup}
                   X,Y : Byte;
                   OriPic : Byte;
               End;          {Treasure is determined in memory once mons}
                              {are killed and based on TreasureType}
  RanMonTypePtr = ^RanMonType;
  SetMonType = Record
                 MonsterName : Byte;
                 Status : Byte;
                 NumInGroup : Byte;
                 X,Y : Byte;
                 Msg1, Msg2 : String[70];
                 OriPic : Byte;
               End;
  SetMonTypePtr = ^SetMonType;
  (*PLAYER*)
  StringType = String[13];  {Weapons, armors}
  SkillType = Array[1..9] Of Byte;
  StatsType = Array[1..6] Of Byte;
  SType = String[10];
  PlayerType = Record
           Name : SType;
           Race : Byte;
           Level : Byte;
           Life, CLife, Gold : Integer;
           XP : LongInt;
           Magic,CMagic : Byte;
           Stats : StatsType;
           TempSkills : Array[1..4] Of Byte;
           Skills : Array[1..9] Of Byte;
           Weapon, Armor : Byte;
           Mission : Array[1..6] Of Boolean;  { 6 = Killed Vampyr }
           KingTalk : Array[1..5] Of Boolean;
           Items : Array[1..4] Of Boolean; { 1 = Rose 2 = Meet Dalagash }
                        { 3= Bought round of drinks 4= Learned Rust Spell }
           XLoc,YLoc : Byte;
           MiscMagic,StepsWalked:Byte;
           BackPack : Array[1..5] of Byte; {contains weapons, 0 for none}
           WeaponDur : Array[0..5] Of ShortInt;
           ArmorDur : ShortInt;
           End;

Var
  SoundOnOff : Boolean;
  CurrentMapType : Byte;
  BooMap : BooMapType;
  CurrentMap : ^CurrentMapMap;
  LandMap : ^LandMapMap;
  CurrentObs, CurrentDisObs : Array[0..28] of Boolean;
  CurrentMapIcon : Array[0..19] of Pointer;
  UnivIcon : Array[0..14] of Pointer;
  EmptyIcon : Pointer;
  Player : PlayerType;
  CurrentMonStats : Array[0..12] of MonsterType;
  CurrentMonPics : Array[0..25] of Pointer;
  CurrentMonMem : Array[1..3] of RanMonTypePtr;
  CurrentMonSet : Array[0..24] of SetMonTypePtr;    {Set encounter}
  TempXloc, TempYloc : Byte;
  Infile : File;
  IconSize : Word;
  Icon : Array[1..18,1..18] of Byte;
  MessageErase : Pointer;
  MessageScrollPtr : Pointer;
  MLine, LineOfMessage : Byte;
  IconNum : Byte;
  PlayerIcon : Pointer;
  FloorLevel : Byte;
  OriA, OriB : Byte;
  SuspicionLevel : ShortInt;    {For guards start chasing ya}
  CTreasure : Byte;   {Treasure type for chests in towns and stuff}
  SignNum : Byte;

 Procedure WriteMessage(Message:String);
 Procedure CombatMessage(S : String; T : Byte);
 Procedure DurCheck(Def : Byte);
 Procedure ArmorDurCheck(Dam : Byte);
 Procedure WeaponDurMake(D : Byte; Var Dur : ShortInt);
 Procedure ArmorDurMake(D : Byte; Var Dur : ShortInt);
 Procedure DurLook(Weap : Boolean; D:Byte ; Dur : ShortInt; Where : Byte);
 Procedure IOCheck;
 Procedure KeyboardFlush;
Implementation

Procedure WriteMessage(Message:String);
Begin
  SetColor(9);
  If LineOfMessage <= 7 Then
    Begin
      OutTextXY(12, 125+(LineOfMessage*9),Message);
      LineOfMessage := LineOfMessage+1;
    End
  Else
    Begin
      GetImage(12,143,631,196, MessageScrollPtr^);
      PutImage(12,134,MessageScrollPtr^,NormalPut);
      PutImage(12,188,MessageErase^,NormalPut);
      OutTextXY(12,188,Message);
    End;
End;

Procedure IOCheck;
Var
  C : Char;
Begin
      Case IOResult of
        0   : Exit;
        $02 : begin SetactivePage(0); ClearDevice; OutTextXY(0,0,'File not found'); end;
        $03 : begin setactivepage(0); cleardevice; OutTextXY(0,0,'Path not found'); end;
        $04 : begin setactivepage(0); cleardevice; OutTextXY(0,0,'File not open'); end;
        $99 : begin setactivepage(0); cleardevice; OutTextXY(0,0,'Unexpected end-of-file'); end;
        $F0 : begin setactivepage(0); cleardevice; OutTextXY(0,0,'Disk write error'); end;
        $F1 : begin setactivepage(0); cleardevice; OutTextXY(0,0,'Directory is full'); end
      Else
        begin setactivepage(0); cleardevice; OutTextXY(0,0,'Unknown I/O error'); end;
      End;
  SetColor(12);
  OutTextXY(0,9,'Press any key to EXIT');
  C := ReadKey;
  CloseGraph;
  Halt;
End;

Procedure CombatMessage(S : String; T : Byte);
Begin
 Case T Of
  1 : SetColor(11);
  2 : SetColor(12);
  3 : SetColor(14);
  4 : SetColor(3);
  5 : SetColor(4);
 End;
 If MLine <= 7 Then
    Begin
    OutTextXY(412,117+(MLine*9),S);
    MLine:=MLine+1;
    End
    Else
    Begin
    GetImage(412,135,633,188,MessageScrollPtr^);
    PutImage(412,126,MessageScrollPtr^,NormalPut);
    GetImage(412,180,633,188,MessageScrollPtr^);
    PutImage(412,180,MessageScrollPtr^,XorPut);
    OutTextXY(412,180,S);
    End;
End;

Procedure DurCheck(Def : Byte);
Label NextPart;
Begin
If (Def>0) And (Def<35) Then Begin
               Player.WeaponDur[0]:=Player.WeaponDur[0]-1;
               Goto NextPart; End;
If Def>34 Then Player.WeaponDur[0]:=Player.WeaponDur[0]-2;
NextPart:
If (Player.WeaponDur[0]<1) AND (Player.Weapon<>0) Then Begin
                         CombatMessage('Your weapon breaks!!!',1);
                         Player.WeaponDur[0]:=0;
                         Player.Weapon:=0;
                         End;
End;

Procedure ArmorDurCheck(Dam : Byte);
Label NextPart;
Begin
If Dam<10 Then Begin
               Player.ArmorDur:=Player.ArmorDur-1;
               Goto NextPart; End;
If Dam<20 Then Begin
               Player.ArmorDur:=Player.ArmorDur-2;
               Goto NextPart; End;
If Dam>19 Then Player.ArmorDur:=Player.ArmorDur-3;
NextPart:
If (Player.ArmorDur<1) and (Player.Armor<>0) Then Begin
                     CombatMessage('Your armor falls apart!!!',1);
                     Player.ArmorDur:=0;
                     Player.Armor:=0;
                     End;
End;

Procedure WeaponDurMake(D : Byte; Var Dur : ShortInt);
Var C : Byte;
Begin
Dur:=0;
If D>10 Then C:=D Mod 10 Else C:=D;
            Case C Of
            1 : Dur:=45;
            2 : Dur:=50;
            3 : Dur:=55;
            4 : Dur:=60;
            5 : Dur:=70;
            6 : Dur:=75;
            7 : Dur:=80;
            8 : Dur:=60;
            9 : Dur:=45;
            0 : Dur:=45;
            End;
If (D>10) Then Dur:=Dur+15;
If (D>20) Then Dur:=Dur+15;
If (D>30) Then Dur:=Dur+17;
End;

Procedure ArmorDurMake(D : Byte; Var Dur : ShortInt);
Var C : Byte;
Begin
If D>10 Then C:=D Mod 10 Else C:=D;
        Case C Of
           1 : Dur:=10;
           2 : Dur:=30;
           3 : Dur:=45;
           4 : Dur:=55;
         5,6 : Dur:=65;
       7,8,9 : Dur:=75;
           0 : Dur:=80;
       End;
If (D>10) Then Dur:=Dur+15;
If (D>20) Then Dur:=Dur+15;
If (D>30) Then Dur:=Dur+17;
End;

Procedure DurLook(Weap : Boolean; D:Byte ; Dur : ShortInt; Where : Byte);
Var S : String[9];
    A : ShortInt;
Begin
If Not Weap Then ArmorDurMake(D,A) Else WeaponDurMake(D,A);
S:='Very Bad';
If ((Dur)>(A Div 6)) Then S:='Poor';          {<16%}
If ((Dur)>(A Div 3)) Then S:='Fair';           {<33%}
If ((Dur)>(A Div 2)) Then S:='Average';         {<50%}
If Dur>(Round(A/1.4)) Then S:='Good';  {<71%}
If Dur>(Round(A/1.2)) Then S:='Excellent!';      {<83%}
If Dur>A Then S:='Super!!!';          {>100%}
If Where=1 Then CombatMessage(S,6)
   Else WriteMessage(S);
End;

Procedure KeyboardFlush;
Var ch:Char;
Begin
  While KeyPressed do
    Ch:=ReadKey;
end;

End.