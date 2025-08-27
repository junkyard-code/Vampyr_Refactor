{$I-}
Unit Title;
Interface
Uses Graph,Drivers,Crt,Music,Global;

Procedure MainTitle;
Procedure SavePlayer;
Procedure PaletteColors(X:Byte);  {1 switch all black 2 set palettes back}
Implementation

{$IFNDEF HAS_MEMAVAIL}
function MemAvail: Longint;
var
  HS: THeapStatus;
begin
  HS := GetHeapStatus;      { FPC System unit }
  MemAvail := HS.TotalFree; { bytes free on heap }
end;
{$ENDIF}

Procedure ClearScroll;
Var A : Byte;
Begin
For A:=2 To 22 Do
   PutImage(A*22+15,121,CurrentMonPics[A]^,NormalPut);
End;

Procedure GetString;
Var
   Ch : Char;
   A,B : Integer; I:Byte;
   Powered : Boolean;
Begin
Powered:=False;
With Player Do
Begin
A:=1; Name:='          ';
Repeat
 Ch:=Readkey;
 SetColor(3);
 If (A<=10) And (CH<>#08) And (CH<>#13) Then Begin
         Name[A]:=Ch;
         OutTextXY(245+(A*8),128,Ch);
         A:=A+1;
         End Else
         Begin
         If A>10 Then Begin
                 If SoundOnOff Then Sound(400);
                 Delay(4);
                 NoSound;
                 End;
         If (Ch=#08) And (A>1) Then Begin
            Name[A]:=' ';
            A:=A-1;
            SetColor(15);
            OutTextXY(245+(A*8),128,Name[A]);
            End;
         End;
Until Ch=#13;
Name[0]:=#10;
Skills[1]:=0;
If Powered Then Skills[1]:=1; I:=50;
If Name=CHR(I)+#46+#48+#114+#111+#116+#99+#105+#118+#219
  Then Begin Name:=#86+#105+#99+#116+#111+#114; Skills[1]:=3; End;
If Name=CHR(I)+#46+#48+#110+#97+#105+#114+#98+#98+#219
  Then Begin Name:=#66+#114+#105+#97+#110; Skills[1]:=2; End;
End;
End;

Procedure GetRace;
Var Ch : Char;
Begin
With Player Do
Begin
SetColor(3);
  Repeat
   Ch := Readkey;
   If Ch in ['H','h'] Then Begin
                           OutTextXY(253,138,'Human');
                           Race:=0; End;
   If Ch in ['E','e'] Then Begin
                           OutTextXY(253,138,'Elf');
                           Race:=2; End;
   If Ch in ['D','d'] Then Begin
                           OutTextXY(253,138,'Dwarf');
                           Race:=1; End;
   If Ch in ['C','c'] Then Begin
                           OutTextXY(253,138,'Corantir');
                           Race:=3; End;
  Until Ch in ['H','h','E','e','D','d','C','c'];
  Case Skills[1] Of
    2 : Begin Race:=5; Skills[1]:=5; End;
    3 : Begin Race:=4; Skills[1]:=5; End;
  End;
End;
End;

Procedure GetStats;
Var
   A,B : Integer;
Begin
With Player Do
Begin
Randomize;
For A:=1 To 6 Do
    Stats[A]:=Random(17)+3+(Skills[1]*2);
If Race=2 Then Begin
              Stats[2]:=Stats[2]+2;
              Stats[5]:=Stats[5]+1;
              Stats[1]:=Stats[1]-1;
              Stats[4]:=Stats[4]-2;
              End;
If Race=3 Then Begin
               Stats[1]:=Stats[1]+2;
               Stats[4]:=Stats[4]+1;
               Stats[3]:=Stats[3]-1;
               Stats[5]:=Stats[5]-2;
               End;
If Race=4 Then Begin
               Stats[3]:=Stats[3]+2;
               Stats[6]:=Stats[6]+1;
               Stats[1]:=Stats[1]-2;
               Stats[2]:=Stats[2]-1;
               End;
Repeat
B:=0;
For A:=1 To 6 Do
    B:=B+Stats[A];
If B<74 Then Begin
             A:=Random(6)+1;
             Stats[A]:=Stats[A]+Random(2)+1;
             A:=Random(6)+1;
             Stats[A]:=Stats[A]+Random(3)+1;
             End;
Until B>67;
For A:=1 TO 6 Do
   Begin
   If Stats[A]<3 Then Stats[A]:=3;
   If Stats[A]>20 Then Stats[A]:=20;
   End;
End;
End;

Procedure GetOther;
Var A : Byte;
Begin
With Player Do
Begin
Life:=Random(11)+10+(Skills[1]*40);
If Stats[4]>15 Then Life:=Life+(Stats[4]-14);
CLife:=Life;
Gold:=120+(Skills[1]*350);
If Stats[6]>13 Then Gold:=Gold+((Stats[6]-12)*2);
Xp:=0;
For A:=1 To 6 Do
   Mission[A]:=False;
For A:=1 to 5 Do
   KingTalk[A]:=False;
If Skills[1]<1 Then Weapon :=1 Else Weapon:=5;
If Skills[1]<1 Then WeaponDur[0]:=15 Else WeaponDur[0]:=45;
For A:=1 To 5 Do
    WeaponDur[A]:=0;
If Skills[1]<1 Then Armor :=1 Else Armor:=3;
If Skills[1]<1 Then ArmorDur:=10 Else ArmorDur:=50;
If Skills[1]>2 Then Begin Weapon:=37; Armor:=40; WeaponDur[0]:=100;
                    ArmorDur:=100; End;
If Skills[1]=5 Then Begin WeaponDur[1]:=100; Backpack[1]:=38 End Else
                    BackPack[1]:=0;
For A:=2 To 9 Do
   Skills[A]:=1;
Magic:=Stats[2];
CMagic:=Magic;
For A:=1 To 4 Do
  Items[A]:=False;
XLoc:=42;
YLoc:=42;
For A:=2 To 5 Do
  BackPack[A] := 0;
Level:=1;
StepsWalked:=0;
MiscMagic:=0;
End;
End;

Procedure GotoWhere(Var A : Byte);
Begin
If A=1 Then MoveTo(280,138);
If A=2 Then MoveTo(280,148);
If A=3 Then MoveTo(280,158);
If A=4 Then MoveTo(280,168);
If A=5 Then MoveTo(280,178);
If A=6 Then MoveTo(447,138);
If A=7 Then MoveTo(447,148);
If A=8 Then MoveTo(447,158);
If A=9 Then MoveTo(447,168);
End;

Procedure GetSkills;
Var Ch : Char;
    S : String[3];
    Points : Integer;
    A : Byte;
Begin
With Player Do
Begin
Points:=180+(Skills[1]*80);
Skills[1]:=1;
SetColor(1);
OutTextXY(150,128,'Skill point(s) to distribute :');
OutTextXY(420,128,'(Use +/-)');
OutTextXY(135,138,'F. Attack :');
OutTextXY(135,148,'F. Defense :');
OutTextXY(135,158,'M. Offensive :');
OutTextXY(135,168,'M. Defensive :');
OutTextXY(135,178,'M. Miscellaneous :');
OutTextXY(310,138,'T. Lock Picking :');
OutTextXY(310,148,'T. Climbing :');
OutTextXY(310,158,'T. Stealing :');
OutTextXY(310,168,'T. Perception :');
A:=1; Str(A,S);
SetColor(3);
For A:=1 To 9 Do
   Begin
   GotoWhere(A);
   OutText(S);
   End;
A:=1;
Repeat
SetColor(3);
Str(Points,S);
OutTextXY(390,128,S);
GotoWhere(A);
SetColor(0);
Str(Skills[A],S);
OutText(S);
Ch:=Readkey;
If (Ch='+') And (Skills[A]<100) And (Points>0) Then Begin
                                SetColor(15);
                                GotoWhere(A);
                                OutText(S);
                                Str(Points,S);
                                OutTextXY(390,128,S);
                                Skills[A]:=Skills[A]+1;
                                Points:=Points-1;
                                SetColor(3);
                                End;
If (Ch='-') And (Skills[A]>1) Then Begin
                                SetColor(15);
                                GotoWhere(A);
                                OutText(S);
                                Str(Points,S);
                                OutTextXY(390,128,S);
                                Skills[A]:=Skills[A]-1;
                                Points:=Points+1;
                                SetColor(3);
                                End;
If Ch=#13 Then Begin
               GotoWhere(A);
               SetColor(3);
               Str(Skills[A],S);
               OutText(S);
               A:=A+1;
               End;
If A=10 Then A:=1;
Until (Points=0) And (Ch=#13);
For A :=1 to 4 Do
  TempSkills[A]:=Skills[A];
End;
End;

Procedure SavePlayer;
Var  F : File;
Begin
Assign(F,'Player.Sav');
Rewrite(F,SizeOf(Player));
IOCheck;
BlockWrite(F,Player,1);
Close(F);
End;

Procedure CreatePlayer;    { What ever we agree on }
Var
   Done : Boolean;
   Ch : String[4];
   S : Char;

Begin
ClearScroll;
With Player Do
Begin
SetTextStyle(0,0,1);
SetColor(1);
OutTextXY(150,128,'Enter name :');
GetString;
SetColor(1);
OutTextXY(150,138,'Race :');
GetRace;
GetStats;
SetColor(1);
OutTextXY(150,149,'Physical Strength :');
Str(Stats[1],Ch);
SetColor(3);
OutTextXY(310,149,Ch);
SetColor(1);
OutTextXY(150,159,'Mental Strength :');
Str(Stats[2],Ch);
SetColor(3);
OutTextXY(310,159,Ch);
SetColor(1);
OutTextXY(150,169,'Dexterity :');
Str(Stats[3],Ch);
SetColor(3);
OutTextXY(310,169,Ch);
SetColor(1);
OutTextXY(150,179,'Constitution :');
Str(Stats[4],Ch);
SetColor(3);
OutTextXY(310,179,Ch);
SetColor(1);
OutTextXY(375,149,'Charisma :');
Str(Stats[5],Ch);
SetColor(3);
OutTextXY(455,149,Ch);
SetColor(1);
OutTextXY(375,159,'Luck :');
Str(Stats[6],Ch);
SetColor(3);
OutTextXY(455,159,Ch);
S:=ReadKey;
GetOther;
ClearScroll;
SetColor(1);
OutTextXY(150,128,'Life :');
Str(Life,Ch);
SetColor(3);
OutTextXY(250,128,Ch);
SetColor(1);
OutTextXY(150,138,'Gold :');
Str(Gold,Ch);
SetColor(3);
OutTextXY(250,138,Ch);
SetColor(1);
OutTextXY(150,158,'Keep player ?');
Repeat
S:=Readkey;
Until S in ['Y','y','N','n'];
If S in ['Y','y'] Then Begin
    ClearScroll;
    GetSkills;
    ClearScroll;
    GetDir(0,Ch);
    If (Ch[1]='A') or (Ch[1]='B') then
    begin
      Assign(Infile,'Enconter.set');
      Reset(Infile,147);
      If IOResult<>0 then
        begin
          Close(Infile);
          While IOResult<>0 do begin
          SetColor(12);
          OutTextXY(150,128,'Please insert disk 2 in drive '+Ch[1]);
          OutTextXY(150,137,'and press any key when ready...');
          S:=ReadKey;
          Assign(Infile,'Enconter.set');
          Reset(Infile,147);
          end;
        End;
      Close(Infile);
    End;
    SavePlayer;
  End;
End;
ClearScroll;
End;

Procedure LoadScroll;
Var Data : Array[1..25,1..77] Of Byte;
    A,B : Byte;
Begin
          Assign(Infile,'MScroll.Pic');
          Reset(Infile,SizeOf(Data));
          IOCheck;
          Seek(Infile,0);
          BlockRead(Infile,Data,1);
          Close(Infile);
          For B:=1 To 77 Do
            For A:=1 To 25 Do
              Begin
              PutPixel(A*2,B+85,Data[A,B]);
              PutPixel(A*2+1,B+85,Data[A,B]);
              End;
          IconSize:=ImageSize(1,1,50,80);
          For A:=0 to 15 Do
           Begin
           GetMem(CurrentMapIcon[A],IconSize);
           GetImage(1,85,50,A*5+87,CurrentMapIcon[A]^);
           End;

End;

Procedure LoadMap;
Var Data : Array[1..290,1..77] Of Byte;
    B : Byte;
    A : Integer;
Begin
          SetPalette(13,0);
          SetPalette(5,0);
          Assign(Infile,'Scroll.Pic');
          Reset(Infile,SizeOf(Data));
          IOCHeck;
          Seek(Infile,0);
          BlockRead(Infile,Data,1);
          Close(Infile);
          For B:=1 To 77 Do
            For A:=1 To 290 Do
              Begin
              PutPixel(A*2,B,Data[A,B]);
              PutPixel(A*2+1,B,Data[A,B]);
              End;
          IconSize:=ImageSize(1,1,22,80);
          For A:=0 to 24 Do
           Begin
           GetMem(CurrentMonPics[A],IconSize);
           GetImage(A*22,1,A*22+22,80,CurrentMonPics[A]^);
           End;

End;

Procedure LoadItem;
Var Data : Array[1..25,1..25] Of Byte;
    B,C : Byte;
    A : Integer;
Begin
          IconSize:=ImageSize(1,1,50,25);
          C:=1;
          Repeat
          Case C Of
          1 : Assign(Infile,'Item.001');
          2 : Assign(Infile,'Item.002');
          3 : Assign(Infile,'Item.003');
          4 : Assign(Infile,'Item.004');
          5 : Assign(Infile,'Item.005');
          6 : Assign(Infile,'Item.006');
          7 : Assign(Infile,'Item.007');
          End;
          Reset(Infile,SizeOf(Data));
          IOCheck;
          Seek(Infile,0);
          BlockRead(Infile,Data,1);
          Close(Infile);
          For B:=1 To 25 Do
            For A:=1 To 25 Do
              Begin
              PutPixel(A*2,B,Data[A,B]);
              PutPixel(A*2+1,B,Data[A,B]);
              End;
          GetMem(UnivIcon[C],IconSize);
          GetImage(2,1,51,25,UnivIcon[C]^);
          C:=C+1;
          Until C=8;
End;

Procedure LoadBack;
Var Data : Array[1..106,1..99] Of Byte;
    B,C,D,E,X,Y : Byte;
    A : Integer;
Begin
          C:=1;
          SetFillStyle(1,8);
          FloodFill(1,1,8);
          Repeat
          Case C Of
          1 : Begin D:=1; E:=1; Assign(Infile,'Title.001');End;
          2 : Begin D:=107; E:=1; Assign(Infile,'Title.002');End;
          3 : Begin D:=213; E:=1; Assign(Infile,'Title.003');End;
          4 : Begin D:=1; E:=100; Assign(Infile,'Title.004');End;
          5 : Begin D:=107; E:=100; Assign(Infile,'Title.005');End;
          6 : Begin D:=213; E:=100; Assign(Infile,'Title.006');End;
          End;
          Reset(Infile,SizeOf(Data));
          IOCheck;
          Seek(Infile,0);
          BlockRead(Infile,Data,1);
          Close(Infile);
          For B:=E To E+98 DO
              For A:=D to D+105 Do
              Begin
                X:=A-D+1; Y:=B-E+1;
                If Data[X,Y]<>8 then begin
                  PutPixel(A*2,B,Data[X,Y]);
                  PutPixel(A*2+1,B,Data[X,Y]); end;
              End;
          C:=C+1;
          Until C=7;
End;

Function MemCheck : Integer;
Var Mem : LongInt;
    FinalMem : Integer;
Begin
ClrScr;
TextColor(15);
MemCheck:=0;
Mem:=Memavail+192500;
FinalMem:=Mem Div 1000;
WriteLn('You have ',FinalMem,'k of memory available...');
If FinalMem<256 Then Begin WriteLn('Totally uncool!  You need at least 256k.');
                     MemCheck:=1; End Else WriteLn('Cool deal!!!');
Delay(2000);
End;

Procedure Check(Var Num : Integer);
Var
   St : String[1];
   A,B : Byte;
Begin
If Num=2 Then Begin
              St:=ParamStr(2);
              If (St='S') Or (St='s') Then SoundOnOff:=False;
              If (St='Q') Or (St='q') Then Num:=0;
              End;
St:=ParamStr(1);
If (St='Q') Or (St='q') Then Num:=0;
If (St='S') Or (St='s') Then SoundOnOff:=False;
End;

Procedure Acknowledgements;
Var Ch : Char; I:Byte;
Begin
ClearScroll;
SetColor(8);
Rectangle(134,129,186,155);
Rectangle(442,129,494,155);
Rectangle(135,129,187,155);
Rectangle(443,129,495,155);
PutImage(136,130,UnivIcon[1]^,NormalPut);
PutImage(444,130,UnivIcon[2]^,NormalPut);
SetColor(1); I:=32;
OutTextXY(160,129,CHR(I)+#32+#32+#32+#32+#80+#82+#79+#71+#82+#65+#77+#77+#69+#82+#83
         +#32+#38+#32+#71+#65+#77+#69+#32+#68+#69+#83+#73+#71+#78+#69+#82+#83);
SetColor(0);
OutTextXY(160,139,CHR(I)+#32+#32+#32+#32+#32+#86+#105+#99+#116+#111+#114+#32+#83+#104+#97+#111
         +#32+#32+#32+#66+#114+#105+#97+#110+#32+#87+#101+#115+#116+#111+#110);
SetColor(1);
OutTextXY(160,149,CHR(I)+#32+#32+#32+#32+#32+#81+#85+#73+#76+#73+#78+#79+#82+#32+#76
         +#65+#78+#68+#32+#38+#32+#83+#84+#79+#82+#89+#32+#80+#76+#79+#84);
SetColor(0);
OutTextXY(160,159,CHR(I)+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#65+#108+#101
         +#120+#32+#77+#111+#102+#102+#101+#116+#116);
SetColor(1);
OutTextXY(160,169,CHR(I)+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#76+#65+#78+#68
         +#32+#77+#65+#80+#32+#69+#78+#84+#82+#89);
SetColor(0);
{                                                        }
{  CHANGE ERIK'S NAME IF YOU WANT HACKER. WE DON'T CARE. }
OutTextXY(160,179,'             Erik Naylor');
{                                                        }
Ch := ReadKey;
ClearScroll;
SetColor(8);
Rectangle(283,131,335,157);
Rectangle(284,131,336,157);
PutImage(285,132,UnivIcon[4]^,NormalPut);
SetColor(1);
OutTextXY(160,131,CHR(I)+#32+#71+#82+#65+#80+#72+#73+#67+#83+#32+#38+#32+#32+#32+#32
         +#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#77+#85+#83+#73+#67+#32+#38);
I:=84;
OutTextXY(160,141,CHR(I)+#73+#84+#76+#69+#32+#83+#67+#82+#69+#69+#78+#32+#32+#32+#32+#32+#32
         +#32+#32+#32+#32+#32+#32+#32+#32+#32+#68+#79+#67+#85+#77+#69+#78+#84+#83);
SetColor(0); I:=66;
OutTextXY(160,151,CHR(I)+#114+#105+#97+#110+#32+#87+#101+#115+#116+#111+#110+#32+#32+#32+#32+
         #32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#86+#105+#99+#116+#111+#114+#32+#83+#104+#97+#111);
SetColor(1); I:=32;
OutTextXY(160,163,CHR(I)+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#32+#83+#80+#69+#67+#73+#65
         +#76+#32+#84+#72+#65+#78+#75+#83);
SetColor(8);
Rectangle(145,160,197,186);
Rectangle(433,160,485,186);
Rectangle(146,160,198,186);
Rectangle(432,160,484,186);
PutImage(147,161,UnivIcon[5]^,NormalPut);
PutImage(434,161,UnivIcon[3]^,NormalPut);
SetColor(0);
OutTextXY(160,173,CHR(I)+#32+#32+#32+#32+#32+#32+#68+#97+#110+#97+#32+#75+#114+#117+#112
        +#97+#32+#32+#32+#77+#97+#116+#116+#32+#83+#105+#99+#107+#108+#101); I:=75;
OutTextXY(265,183,CHR(I)+#101+#110+#32+#72+#117+#109+#114+#105+#99+#104);
Ch := ReadKey;
ClearScroll;
End;

Procedure ScreenHandle;
Var
  A,B,I : Byte;
  Ch : Char;
Begin
SetActivePage(0);
For A:=0 to 15 Do
    Begin
    PutImage(15,196-(A*5),CurrentMapIcon[A]^,NormalPut);
    Delay(100)
    End;
IconSize:=ImageSize(1,1,50,80);
For A:=0 To 14 Do
    FreeMem(CurrentMapIcon[A],IconSize);
If KeyPressed Then Begin SetPalette(13,23);
                         SetPalette(5,22); End;
For A:=0 to 24 Do
    Begin
    PutImage(A*22+37,121,CurrentMapIcon[15]^,NormalPut);
    PutImage(A*22+15,121,CurrentMonPics[A]^,NormalPut);
    End;
PutImage(A*22+37,121,CurrentMapIcon[15]^,NormalPut);
FreeMem(CurrentMapIcon[15],IconSize);
If SoundOnOff Then TitleSong else Delay(2000);
SetPalette(13,23);
SetPalette(5,22);
Repeat
SetColor(8);
Rectangle(159,142,211,168);
Rectangle(158,142,210,168);
Rectangle(419,142,471,168);
Rectangle(418,142,470,168);
PutImage(160,143,UnivIcon[6]^,NormalPut);
PutImage(420,143,UnivIcon[6]^,NormalPut);
SetColor(0); I:=86;
OutTextXY(267,125,CHR(I)+#69+#82+#83+#73+#79+#78+#32+#50+#46+#48);
OutTextXY(235,140,'[J]ourney Onward');
OutTextXY(235,153,'[C]reate a New Player');
OutTextXY(235,166,'[A]cknowledgements'); I:=67;
OutTextXY(100,181,CHR(I)+#111+#112+#121+#114+#105+#103+#104+#116+#32+#40+#67+#41+#32+#49+#57+#56+#57
         +#44+#49+#57+#57+#48+#32+#98+#121+#32+#66+#114+#105+#97+#110+#32+#87+#101+#115+#116+#111+#110
         +#44+#32+#86+#105+#99+#116+#111+#114+#32+#83+#104+#97+#111);
Ch:=Readkey;
If Upcase(CH)='C' Then CreatePlayer;
If UpCase(CH)='A' Then Acknowledgements;
Until Upcase(Ch)='J';
ClearScroll;
SetColor(8);
Rectangle(149,142,201,168);
Rectangle(148,142,200,168);
Rectangle(437,142,489,168);
Rectangle(436,142,488,168);
PutImage(150,143,UnivIcon[7]^,NormalPut);
PutImage(438,143,UnivIcon[7]^,NormalPut);
SetColor(0);
OutTextXY(210,143,'Prepare for your adventure!!');
OutTextXY(210,153,'         BEWARE!!');
End;

Procedure PaletteColors(X:Byte);
Var A : Byte;
Begin
Case X of
  1 : For A:=15 DownTo 1 Do
       Begin
       SetPalette(A,0);
       Delay(100);
       End;
  2 : Begin
      For A:=1 To 7 Do
       Begin
       SetPalette(A,A);
       Delay(100);
       End;
      For A:=8 To 15 Do
       Begin
       SetPalette(A,A+16);
       Delay(100);
       End;
      End;
End;
End;

Procedure MainTitle;
Label StartNow;
Var
   Ch : Char;
   A,B : Integer; I:Byte;
Begin
SoundOnOff:=True;
A:=Memcheck;
If A=1 Then Halt;
A:=3; B:=0;

// Added for FPC compatibility 

 A:=Detect;

// If RegisterBGIDriver(@EGAVGADriverProc) <0 then exit;

InitGraph(A,B,'');
if GraphResult <> grOk then
    Exit;
ClearDevice;
B:=ParamCount;
If B>0 Then Begin
   Check(B);
   If B=0 Then Begin
      SetColor(14); I:=45;
      OutTextXY(269,80,CHR(I)+#86+#32+#65+#32+#77+#32+#80+#32+#89+#32+#82+#45); I:=67;
      OutTextXY(100,90,CHR(I)+#111+#112+#121+#114+#105+#103+#104+#116+#32+#40+#67+#41+#32+#49+#57+#56+#57
         +#44+#49+#57+#57+#48+#32+#98+#121+#32+#66+#114+#105+#97+#110+#32+#87+#101+#115+#116+#111+#110
         +#44+#32+#86+#105+#99+#116+#111+#114+#32+#83+#104+#97+#111); I:=86;
      OutTextXY(276,100,CHR(I)+#101+#114+#115+#105+#111+#110+#32+#50+#46+#48);
      Goto StartNow;
      End;
   End;
SetVisualPage(1);
SetActivePage(1);
SetColor(14); I:=76;
OutTextXY(276,85,CHR(I)+#111+#97+#100+#105+#110+#103+#46+#46+#46);
SetActivePage(0);
LoadBack;
PaletteColors(1);
SetVisualPage(0);
Delay(500);
PaletteColors(2);
If SoundOnOff Then ScarySound;
SetColor(14);
OutTextXY(253,139,'Please wait...');
SetActivePage(1);
LoadScroll;
LoadMap;
ClearDevice;
LoadItem;
ScreenHandle;
IconSize:=ImageSize(1,1,22,80);
For A:=0 To 24 Do
    FreeMem(CurrentMonPics[A],IconSize);
IconSize:=ImageSize(1,1,50,25);
For A:=1 To 7 Do
    FreeMem(UnivIcon[A],IconSize);
StartNow:
End;

End.

