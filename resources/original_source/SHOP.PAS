{$I-}
Unit Shop;
Interface
Uses Crt,Graph,Music,Global,Title,Display,Initvam,Vcombat;
Procedure Shops(MonSet : SetMonTypePtr);
Procedure BoatTrip(Rec : Byte);
Procedure TheEnd;

Implementation

Procedure BoatTrip(Rec : Byte);
Var A,X,Y:Byte;
    Data : Array[1..25] Of Byte;
    LandSited : Boolean;
Begin
CancelMagic;
WriteMessage('Full sail ahead...');
Case Rec Of
  0  : Begin Player.XLoc:=15; Player.YLoc:=58; X:=19; Y:=84; End;
  2  : Begin Player.XLoc:=19; Player.YLoc:=85; X:=16; Y:=58; End;
  4  : Begin Player.XLoc:=42; Player.YLoc:=81; X:=56; Y:=91; End;
  5  : Begin Player.XLoc:=55; Player.YLoc:=91; X:=16; Y:=58; End;
  8  : Begin Player.XLoc:=55; Player.YLoc:=91; X:=46; Y:=44; End;
 11  : Begin Player.XLoc:=88; Player.YLoc:=59; X:=46; Y:=44; End;
 17  : Begin Player.XLoc:=88; Player.YLoc:=59; X:=88; Y:=93; End;
End;
PutImage(114,57,CurrentMapIcon[9]^,NormalPut);
BlockIt(Player.XLoc,Player.YLoc);
DisplayLand(Player.Xloc,Player.YLoc);
Assign(Infile,'Boat.Dat');
Reset(Infile,SizeOf(Data));
IOCheck;
LandSited:=False;
Repeat
Seek(Infile,Rec);
BlockRead(Infile,Data,1);
For A:=1 TO 25 Do
 Begin
 If A<20 Then If (Data[A+6]=0) And (LandSited=False) Then Begin
                               WriteMessage('Port ahead, captain!');
                               LandSited:=True;
                               End;
 If Data[A]>0 Then Begin
       Case Data[A] Of
         1 : Player.YLoc:=Player.YLoc-1;
         2 : Player.XLoc:=Player.XLoc+1;
         3 : Player.XLoc:=Player.XLoc-1;
         4 : Player.YLoc:=PLayer.YLoc+1;
       End;
       BlockIt(Player.XLoc,Player.YLoc);
       DisplayLand(Player.XLoc,Player.YLoc);
       End;
   End;
If Data[25]>0 Then Rec:=Rec+1;
Until Data[25]=0;
WriteMessage('There you go, sir.');
Close(Infile);
LandMap^[Player.XLoc,Player.YLoc]:=16;
Player.XLoc:=X; Player.YLoc:=Y;
PutImage(114,57,PlayerIcon^,NormalPut);
BlockIt(Player.XLoc,Player.YLoc);
DisplayLand(Player.XLoc,Player.YLoc);
End;

Procedure Sleeping;
Var A,B : Byte;
    BB : Boolean;
Begin
A:=1; B:=Random(3)+3;
OriA := TempYLoc-3;
OriB := TempXLoc-3;
If Player.MiscMagic<>1 Then BlockIt(TempXloc,TempYloc);
DisplayMonster(4);
DisplayMap(TempXloc, TempYLoc);
WriteMessage('Zzzzzz...'); PaletteColors(1);
Repeat
If Player.Clife<Player.Life Then Begin Player.Clife:=Player.Clife+8+Random(6);
If Player.CLife>Player.Life then Player.CLife:=Player.Life; end;
If Player.CMagic<Player.Magic Then Begin Player.CMagic:=Player.CMagic+8+Random(3);
If Player.CMagic>Player.Magic then Player.CMagic:=Player.Magic; end;
A:=A+1;
AnimateMap(1);
AnimateMonster(1);
AnimateMap(2);
AnimateMonster(2); delay(100);
Until A>=B; PaletteColors(2);
WriteMessage('Boy, do you feel better!');
If Player.MiscMagic<>0 Then
  Begin
    WriteMessage('Your misc. spell wore out while you slept.');
    CancelMagic;
  End;
ChangeStats(2);
End;

Procedure Where(X : Byte);
Begin
Case X Of
 0 : Moveto(520,40);
 1 : Moveto(397,60);
 2 : Moveto(397,70);
 3 : Moveto(397,80);
 4 : Moveto(397,90);
 5 : Moveto(397,100);
 6 : Moveto(602,60);
 7 : Moveto(602,70);
 8 : Moveto(602,80);
 9 : Moveto(602,90);
End;
End;

Procedure AddSkills( Which : BooleanType);
Var A,B,C,Points : Byte;
    S : String[5];
    Max : Array[1..9] Of Byte;
    Ch : Char;
Begin
With Player Do
Begin
For A:=1 To 9 Do
 Max[A]:=Skills[A];
For B:=1 To 9 Do
If Which[B]=True Then Begin Where(B);
   Str(Skills[B],S); OutText(S); End;
If Race>4 Then Points:=60 Else Points:=45;
A:=0;
For B:=1 To 9 Do
   If Which[B] Then A:=A+(100-Player.Skills[B]);
If ((A<45) And (Race<5)) Then Points:=A;
If ((A<60) And (Race>4)) Then Points:=A;
A:=1;
Repeat
  Str(Points,S);
  Where(0);
  OutText(S);
  Where(A);
  Str(Skills[A],S);
  SetColor(15);
  OutText(S);
  SetColor(14);
  Ch:=Readkey;
  If (Ch='+') And (Skills[a]<100) And ( points>0) Then Begin
                                       SetColor(0);
                                       Where(A);
                                       OutText(S);
                                       Str(Points,S);
                                       Where(0);
                                       OutText(S);
                                       Skills[A]:=Skills[A]+1;
                       If A in [1,2,3,4] then TempSkills[A]:=TempSkills[A]+1;
                                       Points:=Points-1;
                                       SetColor(14);
                                       End;
  If (Ch='-') And (Skills[A]>Max[A]) Then Begin
                                       SetColor(0);
                                       Where(A);
                                       OutText(S);
                                       Str(Points,S);
                                       Where(0);
                                       OutText(S);
                                       Skills[A]:=Skills[A]-1;
                       If A in [1,2,3,4] then TempSkills[A]:=TempSkills[A]-1;
                                       Points:=Points+1;
                                       SetColor(14);
                                       End;
  If Ch=#13 Then Begin
                 Where(A);
                 Str(Skills[A],S);
                 SetColor(14);
                 OutText(S);
                 Repeat
                 A:=A+1;
                 If A=10 Then A:=1;
                 Until Which[A]=True;
                 End;
  Until (Points=0) And (Ch=#13);
End;
End;

Procedure AddStats;
Var A : Byte;
    Done:Boolean;
Begin
If ((Player.stats[1]=20) and (Player.stats[2]=20) and (Player.stats[3]=20)
and (Player.stats[4]=20) and (Player.stats[5]=20) and (Player.stats[6]=20))
then exit;
Done:=False;
Repeat
A:=Random(6)+1;
If Player.Stats[A]<20 Then Begin
                      Player.Stats[A]:=Player.Stats[A]+1;
                      Case A of
                       1 : WriteMessage('Physical Strength Raised.');
                       2 : WriteMessage('Mental Strength Raised.');
                       3 : WriteMessage('Dexterity Raised.');
                       4 : WriteMessage('Constitution Raised.');
                       5 : WriteMessage('Charisma Raised.');
                       6 : WriteMessage('Luck Raised.');
                      End;
                      Done:=True;
                      End;
Until Done;
End;

Procedure Training(MonSet : SetMonTypePtr);
Var Exp,D : Integer;
    Ch : Char;
    S : String[5];
    Which : BooleanType;
    A,B,C,Points : Byte;
    P : Pointer;
    Size : Word;
    DD : Real;
Begin
With Player Do
Begin
Case Level Of
  1 : Exp:=300;
  2 : Exp:=900;
  3 : Exp:=1800;
  4 : Exp:=2900;
  5 : Exp:=4200;
  6 : Exp:=5600;
  7 : Exp:=7200;
  8 : Exp:=9000;
  9 : Exp:=11000;
 10 : Exp:=13500;
 11 : Exp:=16500;         {HUH?????  What's 0 again?  Well, change this.}
 12 : Exp:=20000;         {Maybe use LongInt for Exp.  Stretch out the}
 13 : Exp:=24000;         {numbers a bit...}
 14 : Exp:=28000;
 Else Exp:=0;
 End;
If (Exp>0) And (Xp>=Exp) Then Begin
   For A:=1 to 9 Do
     Which[A]:=False;
   S:=MonSet^.Msg1[5];
   Val(S,A,D);
   For B:=0 TO (A-1) Do
    Begin
    S:=MonSet^.Msg1[(B*2)+7];
    Val(S,C,D);
    Which[C]:=True;
    End;
   Size:=ImageSize(280,40,610,116);
   GetMem(P,Size);
   GetImage(280,40,610,116,p^);
   PutImage(280,40,p^,XorPut);
   FreeMem(P,Size);
   SetColor(14);
   OutTextXY(280,40,'Skill points to distribute :');
   OutTextXY(280,60,'F. Attack    :');
   OutTextXY(280,70,'F. Defense   :');
   OutTextXY(280,80,'M. Offensive :');
   OutTextXY(280,90,'M. Defensive :');
   OutTextXY(280,100,'M. Miscell. :');
   OutTextXY(460,60,'T. Lock Picking :');
   OutTextXY(460,70,'T. Climbing     :');
   OutTextXY(460,80,'T. Stealing     :');
   OutTextXY(460,90,'T. Perception   :');
   For B:=1 to 9 Do
    If Which[B]=True Then Begin Where(B);
                          OutText('Yes'); End Else Begin
                          Where(B); OutText('No'); End;
   WriteMessage('I can train you in these areas...');
   D:=(Exp Div (Level+8));
   DD:=D-D*((Player.Stats[5]-10)/100);
   D:=Round(DD);
   Str(D,S);
   WriteMessage('for only '+S+' gold pieces. Ok?');
   Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
   If Gold<D Then Begin
             If Ch in ['Y','y'] Then Begin
                   WriteMessage('Maybe another time when you have the gold.');
                   Ch:='N';
                   End;
             End;
   If Ch in ['Y','y'] Then Begin
         Gold:=Gold-D;
         SetColor(0);
         For B:=1 to 9 Do
         If Which[B]=True Then Begin Where(B);
         OutText('Yes'); End Else Begin
         Where(B); OutText('No'); End;
         SetColor(14);
         AddSkills(Which);
         If ((Stats[4]-10) div 2)>0 then
         A:=Random(4)+5+((Stats[4]-10) Div 2)
         else A:=Random(4)+5;
         Life:=Life+A; Clife:=Clife+A;
         B:=0; if Player.Stats[2]>13 then B:=((Stats[2]-13) div 2);
         A:=Random(3)+2;
         Magic:=Magic+A+B;
         CMagic:=CMagic+A+B;
         Level:=Level+1;
         B:=Level*3+(Stats[4]-10);
         C:=Random(100)+1;
         If C<=B Then AddStats;
         WriteMessage(MonSet^.Msg2);
   End;
   Size:=ImageSize(280,40,626,109);
   GetMem(P,Size);
   GetImage(280,40,626,109,P^);
   PutImage(280,40,P^,XorPut);
   FreeMem(P,Size);
   ShowPlayerStats;
   End Else Begin Str(Exp,S);
       WriteMessage('You need '+S+' Ex. points to reach the next level.'); End;
If Exp=0 Then WriteMessage('You''re too powerful already.');
If ((Mission[1]=True) And (Mission[2]=True) And (Mission[3]=True) And
   (Mission[4]=True) And (Mission[5]=True) And (Exp=0)) Then
   WriteMessage('Go kick the Vampyr''s butt and get it over with.');
End;
End;

Procedure Shops(MonSet : SetMonTypePtr);
  { Merchants selling good and buying }
Var A,B,D,E,F : Byte;
    H : ShortInt;
    C,G : Integer;
    Ch : Char;
    St : StringType;
    S1,S2 : String[4]; GetOut,Talked:Boolean;
    Z : Real;
Begin
GetOut:=False; Talked:=False;
If (SuspicionLevel>=0) Or ((Player.Mission[1]) And (Player.Mission[2]) And
   (Player.KingTalk[3]=False)) Then Begin
If (MonSet^.Msg1[1]='P') And (MonSet^.Msg1[2]='U') Then Begin Talked:=True;
   WriteMessage('Good day, sir.  What would you like?');
   WriteMessage('');
   WriteMessage('1> Ale');
   WriteMessage('2> Bread');
   WriteMessage('3> Beer');
   WriteMessage('4> Mutton');
   WriteMessage('5> Wine');
   WriteMessage('6> Round of drinks');
   Ch := Readkey; If Ch=#0 then Ch:=ReadKey;
   If Player.Gold<=0 then WriteMessage('You''ve got no cash!  Get out!')
   Else Begin
     If (Ch in ['1','2','3','4','5','6']) Then begin
   If (Ch in ['1','2','3']) Then Player.Gold:=Player.Gold-1;
   If Ch ='4' then Player.Gold:=Player.Gold-4;
   If Ch='5' then Player.Gold:=Player.Gold-5;
   If Ch ='6' Then Player.Gold:=Player.Gold-10;
      A:=1; ChangeStats(A);
   If (Ch in['1','2','3','4','5']) then
     WriteMessage('<Belch!>  Not bad!');
      If Ch=MonSet^.Msg1[5] Then WriteMessage(MonSet^.Msg2);     {Huh? }
      If Ch='6' Then Begin Player.Items[3]:=True;
      WriteMessage('"You are an okay guy..."'); End;
   End
      Else WriteMessage('Consult your DOS manual about the number keys.');
   End;
   End;
If (MonSet^.Msg1[1]='I') And (MonSet^.Msg1[2]='N') Then Begin Talked:=True;
   WriteMessage(MonSet^.Msg2);
   Val(MonSet^.Msg1[5],A,C);
   If Player.Gold>= A Then Begin
      Str(A,S1);
      WriteMessage('A night of rest will cost you '+S1+' gold pieces. Pay? [Y/N]');
      Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
      If Upcase(Ch) <> 'Y' then
        Begin
          WriteMessage('Get outta here, then!');
          Exit;
        End;
      Player.Gold:=Player.Gold-A;
      ChangeStats(1);
      Val(MonSet^.Msg1[7]+MonSet^.Msg1[8],A,C);
      TempXloc := A;
      Val(MonSet^.Msg1[10]+MonSet^.Msg1[11],A,C);
      TempYloc := A;
      St:=MonSet^.Msg1[13]+MonSet^.Msg1[14];
      Val(St,A,C);
      St:=MonSet^.Msg1[16]+MonSet^.Msg1[17];
      Val(St,B,C);
      CurrentMap^[A,B]:=14;
      Sleeping;
      End
   Else WriteMessage('No gold, no nap.');
   End;
If (MonSet^.Msg1[1]='W') And (MonSet^.Msg1[2]='P') Then Begin Talked:=True;
   WriteMessage('Good day, Sir.  Would you like to (B)uy or (S)ell?');
   Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
   If Ch in ['B','b'] Then Begin
      St:=MonSet^.Msg1[5]+MonSet^.Msg1[6];
      Val(St,A,C);
      For B:=0 TO (A-1) Do
      Begin
      S1:=MonSet^.Msg1[(B*3+8)]+MonSet^.Msg1[(B*3+9)];
      Val(S1,D,C);
      WeaponInfo(D,St,E,F);
      WeaponPrice(D,C);
      Str(C,S2);
      S1:=Chr(B+65);
      WriteMessage(S1+'> '+St+'   '+S2+' gold pieces.');
      End;
      WriteMessage('Which item do you prefer?');
      A:=0;
      Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
      Case UpCase(Ch) of
       'A' : A:=1;
       'B' : A:=2;
       'C' : A:=3;
       'D' : A:=4;
       'E' : A:=5;
       'F' : A:=6;
       'G' : A:=7;
       'H' : A:=8;
       'I' : A:=9;
       'J' : A:=10;
       'K' : A:=11;
       'L' : A:=12;
       'M' : A:=13;
       'N' : A:=14;
       'O' : A:=15;
       Else WriteMessage('Get outta here, scum!')
      End;
      St:=MonSet^.Msg1[5]+MonSet^.Msg1[6];
      Val(St,B,C);
      If (A>0) and (A<=B) then Begin
         St:=MonSet^.Msg1[((A-1)*3+8)]+MonSet^.Msg1[((A-1)*3)+9];
         Val(St,D,C);
         WeaponPrice(D,C);
         If Player.Gold<C Then
         WriteMessage('You don''t have enough gold to buy that.') Else
         Begin
           B:=1;
           Repeat
             If Player.BackPack[B]=0 then GetOut:=True;
             B:=B+1;
           Until (B=6) or (GetOut=True);
         If GetOut Then Begin
            Player.Gold:=Player.Gold-C;
            ChangeStats(1);
            Player.Backpack[B-1]:=D;
            WeaponDurMake(D,Player.WeaponDur[B-1]);
            WriteMessage(MonSet^.Msg2);
            End Else WriteMessage('You don''t have any room.');
         End;
         End;
      End;
   If Ch in ['S','s'] Then Begin
      For A:=1 To 5 Do
       Begin
       Str(A,S1);
       WeaponInfo(Player.Backpack[A],St,B,D);
       If Player.BackPack[A]=0 THen St:='Nothing';
       WriteMessage(S1+'> '+St);
       End;
      Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
      Case Ch of
       '1' : A:=1;
       '2' : A:=2;
       '3' : A:=3;
       '4' : A:=4;
       '5' : A:=5;
       else A:=0
      End;
      If (A<>0) AND (Player.BackPack[A]<>0) Then Begin
         WeaponPrice(Player.Backpack[A],C);
         WeaponDurMake(Player.Backpack[A],H);
         Z:=C+(C*((Player.WeaponDur[A] Div 2)-(H Div 4))/100);
         If Z<0 Then Z:=0;
         C:=Round(Z);
         C:=C Div 2;
         Str(C,St);
         WriteMessage('I''ll give you '+St+' gold pieces for it, Ok?');
         Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
         If Ch in ['Y','y'] Then Begin
                  Player.Backpack[A]:=0;
                  Player.WeaponDur[A]:=0;
                  Player.Gold:=Player.Gold+C;
                  ChangeStats(1);
                  WriteMessage('It has better be a good weapon.');
                  End
         Else WriteMessage('<Why you greedy little...>');
         End
      Else WriteMessage('Like I keep telling ya, LEARN TO USE THE NUMBER KEYS!');
      End;
      End;
If (MonSet^.Msg1[1]='A') And (MonSet^.Msg1[2]='R') Then Begin Talked:=True;
   WriteMessage('Good day, Sir. Would you like to (B)uy or (S)ell?');
   Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
   If Ch in ['B','b'] Then Begin
      If Player.Armor<>0 then
        Begin
          WriteMessage('You are stilling wearing armor.  Sell it first? [Y/N]');
          Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
          If Upcase(Ch)<>'N' then begin WriteMessage('Pay attention next time, huh?'); exit; end
          else WriteMessage('Ok... your choice...');
        End;
      St:=MonSet^.Msg1[5]+MonSet^.Msg1[6];
      Val(St,A,C);
      For B:=0 TO (A-1) Do
      Begin
      S1:=MonSet^.Msg1[(B*3+8)]+MonSet^.Msg1[(B*3+9)];
      Val(S1,D,C);
      ArmorInfo(D,St,E);
      ArmorPrice(D,C);
      Str(C,S2);
      S1:=Chr(B+65);
      WriteMessage(S1+'> '+St+'   '+S2+' gold pieces.');
      End;
      WriteMessage('Which item do you prefer?');
      A:=0;
      Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
      Case UpCase(Ch) of
       'A' : A:=1;
       'B' : A:=2;
       'C' : A:=3;
       'D' : A:=4;
       'E' : A:=5;
       'F' : A:=6;
       'G' : A:=7;
       'H' : A:=8;
       'I' : A:=9;
       'J' : A:=10;
       'K' : A:=11;
       'L' : A:=12;
       'M' : A:=13;
       'N' : A:=14;
       'O' : A:=15;
       Else WriteMessage('Get outta here, scum!')
      End;
      St:=MonSet^.Msg1[5]+MonSet^.Msg1[6];
      Val(St,B,C);
      If (A>0) and (A<=B) then Begin
         St:=MonSet^.Msg1[((A-1)*3+8)]+MonSet^.Msg1[((A-1)*3)+9];
         Val(St,D,C);
         ArmorPrice(D,C);
         If Player.Gold<C Then
         WriteMessage('You don''t have enough gold to buy that.') Else
            Begin
            Player.Gold:=Player.Gold-C;
            Player.Armor:=D;
            ArmorDurMake(D,Player.ArmorDur);
            ChangeStats(2);
            WriteMessage(MonSet^.Msg2);
            End;
      End;
      End;
   If Ch in ['S','s'] Then Begin
         If Player.Armor>0 Then Begin
         ArmorPrice(Player.Armor,C);
         ArmorDurMake(Player.Armor,H);
         Z:=C+(C*((Player.ArmorDur Div 2)-(H Div 4))/100);
         If Z<0 Then Z:=0;
         C:=Round(Z);
         C:=(C Div 2)+Random(3)-1;
         Str(C,St);
         WriteMessage('I''ll give you '+St+' gold pieces for your armor, Ok?');
         Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
         If Ch in ['Y','y'] Then Begin
                  Player.Armor:=0;
                  Player.ArmorDur:=0;
                  Player.Gold:=Player.Gold+C;
                  ChangeStats(2);
                  WriteMessage('It has better be a good suit of armor.');
                  End
         Else WriteMessage('<Why you greedy little...>');
         End Else WriteMessage('Oh, you''re selling your body. That''s nice.');
         End;
      End;
If (MonSet^.Msg1[1]='T') And (MonSet^.Msg1[2]='N') Then Begin Talked:=True;
   WriteMessage('Welcome to the transport.');
   WriteMessage('The trip will take you to '+MonSet^.Msg2+'.');
   S1:=MonSet^.Msg1[13]+MonSet^.Msg1[14]+MonSet^.Msg1[15]+MonSet^.Msg1[16];
   Val(S1,C,G);
   WriteMessage('It will only cost you '+S1+' gold pieces. Ok?');
   Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
   If Ch in ['Y','y'] Then Begin
      If Player.Gold>=C Then Begin
         Player.Gold:=Player.Gold-C;
         S1:=MonSet^.Msg1[5]+MonSet^.Msg1[6];
         Val(S1,C,G);
         ChangeStats(1);
         CurrentMapType:=1;
         LoadNewMapType(1);
         BoatTrip(C);
      End Else WriteMessage('Sorry. No gold, no trip.');
   End else WriteMessage('Go drown in a sea.');
End;
If (MonSet^.Msg1[1]='T') And (MonSet^.Msg1[2]='R') Then Begin Talked:=True;
    Training(MonSet);
    End;
If Not Talked Then Begin Talked:=True;
   WriteMessage(MonSet^.Msg1);
   WriteMessage(MonSet^.Msg1);
   End;
End Else WriteMessage('GUARDS! Over here!');
End;

Procedure TheEnd;
Var A,B : Byte;
Begin
DisposeCurrentMonMem;
TempXLoc := 22;
TempYLoc := 9;
If CurrentMap=Nil then New(CurrentMap);
WriteMessage('At the same time, the castle starts rumbling...');
WriteMessage('The whole place is coming down!!!');
WriteMessage('Retracing your steps, you managed to scramble');
WriteMessage('out of the castle just in time.');
Assign(Infile,'TheEnd.Map');
Reset(Infile,2500);
IOCheck;
Seek(Infile,0);
BlockRead(Infile,CurrentMap^,1);
Close(Infile);
Assign(Infile,'TheEnd.con');
Reset(Infile,324);
LoadCurrentIcons;
Assign(Infile,'Endmon.con');
Reset(Infile,324);
LoadCurrentMonPics;
For A:=0 To 19 Do
  CurrentDisObs[A]:=False;
CurrentDisObs[0]:=True;
CurrentDisObs[5]:=True;
CurrentDisObs[11]:=True;
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
Delay(1000);
PutImage(114,21,CurrentMapIcon[12]^,NormalPut);
PutImage(114,39,CurrentMapIcon[13]^,NormalPut);
Delay(1000);
PutImage(114,21,CurrentMapIcon[14]^,NormalPut);
PutImage(114,39,CurrentMapIcon[15]^,NormalPut);
Delay(1000);
PutImage(114,21,CurrentMapIcon[16]^,NormalPut);
PutImage(114,39,CurrentMapIcon[17]^,NormalPut);
Delay(1000);
PutImage(114,21,CurrentMapIcon[18]^,NormalPut);
PutImage(114,39,CurrentMapIcon[19]^,NormalPut);
Delay(1000);
If SoundOnOff then CrunchSound;
WriteMessage('<CRRRRUUUUUNNNNNCCCCCCHHHHHH>');
WriteMessage('All that''s left is a huge stack of rubble.');
Delay(2000);
For A:=1 To 7 Do
 For B:=1 To 7 Do
   BooMap[A,B]:=False;
DisplayMap(TempXLoc,TempYLoc);
WriteMessage('You seem to be stuck on this island.  With nothing to do,');
WriteMessage('you look around Calatiki.  A dramatic change seems to be');
WriteMessage('taking place.  There are no more monsters running around');
WriteMessage('trying to kill everything in sight.  The vibrant birds');
WriteMessage('sing a song of peace under a bright blue sky.  Two serene');
WriteMessage('days passed before you spotted a ship over the horizon.');
WriteMessage('It''s heading for the island!');
Delay(9000);
WriteMessage('Aboard the ship, the captain tells you that he was sent');
WriteMessage('by His Majesty to bring you back to the castle.');
Delay(4000);
WriteMessage('In the castle, you are given a very shiny suit of armor and a');
WriteMessage('beautiful sword.  Afterwards, you are escorted to the throne room.');
LoadPlayerPic(Player.Race+11);
Delay(4000);
PutImage(114,57,PlayerIcon^,NormalPut);
TempXLoc:=8;
TempYLoc:=7;
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,21,CurrentMonPics[0]^,NormalPut);
PutImage(42,39,CurrentMonPics[1]^,NormalPut);
PutImage(42,57,CurrentMonPics[1]^,NormalPut);
PutImage(42,75,CurrentMonPics[1]^,NormalPut);
PutImage(42,93,CurrentMonPics[1]^,NormalPut);
PutImage(42,111,CurrentMonPics[1]^,NormalPut);
PutImage(186,39,CurrentMonPics[1]^,NormalPut);
PutImage(186,57,CurrentMonPics[1]^,NormalPut);
PutImage(186,75,CurrentMonPics[1]^,NormalPut);
PutImage(186,93,CurrentMonPics[1]^,NormalPut);
PutImage(186,111,CurrentMonPics[1]^,NormalPut);
WriteMessage(Player.Name+', you have proven yourself to be a strong');
WriteMessage('and courageous soul.  The whole world of Quilinor owes');
WriteMessage('you a debt of gratitude.  To repay you for your service,');
WriteMessage('I now pronounce you to be my castellan.'); Delay(2000);
WriteMessage('<Gasps, ooooo''s and ahhhh''s fill the hall>');
Delay(6000);
WriteMessage('<And then, a deafening round of applause>');
Delay(3000); If SoundOnOff then CrunchSound;
PutImage(78,75,UnivIcon[10]^,NormalPut);
PutImage(150,75,UnivIcon[10]^,NormalPut);
Delay(2000);
PutImage(78,75,CurrentMonPics[4]^,NormalPut);
PutImage(150,75,CurrentMonPics[5]^,NormalPut);
WriteMessage('Hey, dudes!  Starting the party without us?  C''mon, Tevin,');
WriteMessage('you know better than that!'); Delay(2000);
WriteMessage('Tevin: "Arrrrrr... sorry, my lords... I don''t know what to say..."');
Delay(1000);
WriteMessage('Ohhh, doesn''t matter.  By the way, congrats, '+Player.Name);
WriteMessage('Thanks for getting rid of Vampyr for us!  It would had been');
WriteMessage('such a pain to get out of Heaven and zoom down to Calatiki ourselves...');
WriteMessage('Anyway... we''re off to our vacation!  Bye!');
Delay(11000);
For A:=1 To 7 Do
 For B:=1 To 7 Do
   BooMap[A,B]:=False;
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,EmptyIcon^,NormalPut);
WriteMessage('Somewhere on a big island...');
TempXLoc:=31;
TempYLoc:=8;
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(42,39,CurrentMonPics[10]^,NormalPut);
PutImage(78,75,CurrentMonPics[11]^,NormalPut);
PutImage(186,39,CurrentMonPics[9]^,NormalPut);
TempXLoc:=TempXLoc+1; Delay(1000);
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(6,39,CurrentMonPics[10]^,NormalPut);
PutImage(42,75,CurrentMonPics[11]^,NormalPut);
PutImage(150,39,CurrentMonPics[9]^,NormalPut);
PutImage(222,75,CurrentMonPics[12]^,NormalPut);
TempXLoc:=TempXLoc+1; Delay(1000);
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(6,75,CurrentMonPics[11]^,NormalPut);
PutImage(114,39,CurrentMonPics[9]^,NormalPut);
PutImage(186,75,CurrentMonPics[12]^,NormalPut);
TempXLoc:=TempXLoc+1; Delay(1000);
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(78,39,CurrentMonPics[9]^,NormalPut);
PutImage(150,75,CurrentMonPics[12]^,NormalPut);
PutImage(222,57,CurrentMonPics[7]^,NormalPut);
PutImage(222,39,CurrentMonPics[8]^,NormalPut);
TempXLoc:=TempXLoc+1; Delay(1000);
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(42,39,CurrentMonPics[9]^,NormalPut);
PutImage(114,75,CurrentMonPics[12]^,NormalPut);
PutImage(186,57,CurrentMonPics[7]^,NormalPut);
PutImage(186,39,CurrentMonPics[8]^,NormalPut);
TempXLoc:=TempXLoc+1; Delay(1000);
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(6,39,CurrentMonPics[9]^,NormalPut);
PutImage(78,75,CurrentMonPics[12]^,NormalPut);
PutImage(150,57,CurrentMonPics[7]^,NormalPut);
PutImage(222,57,CurrentMonPics[6]^,NormalPut);
PutImage(150,39,CurrentMonPics[8]^,NormalPut);
PutImage(222,39,CurrentMonPics[8]^,NormalPut);
TempXLoc:=TempXLoc+1; Delay(1000);
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(42,75,CurrentMonPics[12]^,NormalPut);
PutImage(114,57,CurrentMonPics[7]^,NormalPut);
PutImage(186,57,CurrentMonPics[6]^,NormalPut);
PutImage(114,39,CurrentMonPics[8]^,NormalPut);
PutImage(186,39,CurrentMonPics[8]^,NormalPut);
TempXLoc:=TempXLoc+1; Delay(1000);
BlockIt(TempXLoc,TempYLoc);
DisplayMap(TempXLoc,TempYLoc);
PutImage(114,57,CurrentMapIcon[8]^,NormalPut);
PutImage(78,57,CurrentMonPics[7]^,NormalPut);
PutImage(150,57,CurrentMonPics[6]^,NormalPut);
PutImage(78,39,CurrentMonPics[8]^,NormalPut);
PutImage(150,39,CurrentMonPics[8]^,NormalPut);
PutImage(222,57,CurrentMonPics[9]^,NormalPut);
WriteMessage('Vic: "Ahhhhhh!!!  This is the life, isn''t it?"');
Delay(3000);
PutImage(78,39,CurrentMonPics[21]^,NormalPut);
PutImage(150,39,CurrentMonPics[21]^,NormalPut);
WriteMessage('Brian: "Yeah, sure is!"');
Delay(3000);
PutImage(78,39,CurrentMonPics[8]^,NormalPut);
PutImage(150,39,CurrentMonPics[8]^,NormalPut);  Delay(500);
PutImage(78,39,CurrentMonPics[21]^,NormalPut);
PutImage(150,39,CurrentMonPics[21]^,NormalPut);
WriteMessage('Vic: "Zzzzzzzzz..."');
WriteMessage('Brian: "Zzzzzzzzz..."');
Delay(3000);
PutImage(78,39,CurrentMonPics[8]^,NormalPut);
PutImage(150,39,CurrentMonPics[8]^,NormalPut);
Delay(3000);
PutImage(78,57,CurrentMonPics[20]^,NormalPut);
PutImage(150,57,CurrentMonPics[19]^,NormalPut);
WriteMessage('Brian: "Vic, I think it''s time to get out of the sun."');
Delay(500);
WriteMessage('Vic: "Damn!  I knew I should''ve used a #15!!!"');
Delay(2500);
WriteMessage('');
WriteMessage('                             THE END');
WriteMessage('Hope you enjoyed playing this game.  Bye!!!');
Player.XLoc:=43; Player.YLoc:=42; Player.Mission[6]:=False; SavePlayer;
Repeat
Until KeyPressed;
End;

End.