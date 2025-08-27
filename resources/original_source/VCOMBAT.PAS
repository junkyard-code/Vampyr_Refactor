{$mode tp}
{$H-}
{$PACKRECORDS 1}

Unit VCombat;
Interface
Uses Music, Global, Graph, Crt, Display;
Procedure WeaponInfo(N : Byte; Var Name : StringType; Var Damage : Byte;
                     Var Plus : Byte);
Procedure ArmorInfo(N : Byte; Var Name : StringType; Var Defense : Byte);
Procedure WeaponPrice(N : Byte; Var Price : Integer);
Procedure ArmorPrice(N : Byte; Var Price : Integer);
Function Combat(Var Name,Stats,Num : Byte) : Byte;
Function CombatCheck(Var Mon : SetMonTypePtr): Boolean;
Function CombatCheck2(Var Mon : RanMonTypePtr): Boolean;
Function CombatCheck3(Var Mon : RanMonTypePtr): Boolean;
Procedure CancelMagic;
Procedure ShowPlayerStats;
Procedure ChangeStats(JobNum:Byte);
Procedure PutStats(JobNum:Byte);
Implementation
Procedure PutStats(JobNum : Byte);
Var St,S2 : StringType;
    A,B : Byte;
Begin
SetColor(3);
With Player Do
Begin
If JobNum=2 Then Begin
                 OutTextXY(342,40,Name);
                 Case Race Of
                  0 : St:='Human';
                  1 : St:='Dwarf';
                  2 : St:='Elf';
                  3 : St:='Corintir';
                4,5 : St:='Superior';
                  End;
                  OutTextXY(342,50,St);
                  WeaponInfo(Weapon,St,A,B);
                  OutTextXY(342,100,St);
                  ArmorInfo(Armor,St,A);
                  OutTextXY(342,110,St);
                  For A:=1 To 6 Do
                   Begin
                   Str(Stats[A],St);
                   OutTextXY(587,40+(A*10),St);
                   End;
                  Str(Level,S2);
                  OutTextXY(587,40,S2);
                  SetColor(15);
                  Case MiscMagic Of
                    1 : OutTextXY(470,110,'Wizard Eye');
                    2 : OutTextXY(470,110,'Mystical Boost');
                    3 : OutTextXY(470,110,'Heroism');
                    4 : OutTextXY(470,110,'Spell Protection');
                    5 : OutTextXY(470,110,'Shield');
                    6 : OutTextXY(470,110,'Iron Skin');
                  End;
                  SetColor(3);
                  If Items[1]=True Then
                    Begin SetColor(9); OutTextXY(470,120,'Blue Rose');
                    SetColor(3); End;
                  End;
If CLife<11 Then SetColor(14);
If CLife<6 Then SetColor(12);
Str(CLife,St);
Str(Life,S2);
OutTextXY(342,60,St+'/'+S2);
SetColor(3);
Str(CMagic,St);
Str(Magic,S2);
OutTextXY(342,70,St+'/'+S2);
Str(XP,St);
OutTextXY(342,80,St);
Str(Gold,St);
OutTextXY(342,90,St);
End;
End;

Procedure ChangeStats(JobNum : Byte);  { Displays Current Stats }
Var
   P : Pointer;
Begin
Case JobNum Of
  1 : Begin
      IconSize:=ImageSize(342,60,462,96);
      GetMem(P,IconSize);
      GetImage(342,60,462,96,P^);
      PutImage(342,60,P^,XorPut);
      FreeMem(P,IconSize);
      End;
  2 : Begin
      IconSize:=ImageSize(342,40,462,116);
      GetMem(P,IconSize);
      GetImage(342,40,462,116,P^);
      PutImage(342,40,P^,XorPut);
      FreeMem(P,IconSize);
      IconSize:=ImageSize(586,40,610,126);
      GetMem(P,IconSize);
      GetImage(586,40,610,126,P^);
      PutImage(586,40,P^,XorPut);
      FreeMem(P,IconSize);
      IconSize:=ImageSize(470,110,610,120);
      GetMem(P,IconSize);
      GetImage(470,110,610,120,P^);
      PutImage(470,110,P^,XorPut);
      FreeMem(P,IconSize);
      End;
    End;
PutStats(JobNum);
End;

Procedure ShowPlayerStats;   { First time call for display stats }
Begin
SetTextStyle(0,0,1);
SetColor(8);
OutTextXY(280,40,'Name  :');
OutTextXY(280,50,'Race  :');
OutTextXY(280,60,'Life  :');
OutTextXY(280,70,'Magic :');
OutTextXY(280,80,'X.P.  :');
OutTextXY(280,90,'Gold  :');
OutTextXY(280,100,'Weapon:');
OutTextXY(280,110,'Armor :');
OutTextXY(470,50,'Phy. Strength:');
OutTextXY(470,60,'Men. Strength:');
OutTextXY(470,70,'Dexterity    :');
OutTextXY(470,80,'Constitution :');
OutTextXY(470,90,'Charisma     :');
OutTextXY(470,100,'Luck         :');
OutTextXY(470,40,'Level        :');
PutStats(2);
End;

Procedure WeaponInfo(N : Byte; Var Name : StringType; Var Damage : Byte;
                     Var Plus : Byte);
Var Ch : String[1];
Begin
Plus:=0;
If (N>10) And (N<21) Then Begin
                     Plus:=1; N:=N Mod 10;
                     End;
If (N>20) And (N<31) Then Begin
                     Plus:=2; N:=N Mod 10;
                     End;
If (N>30) And (N<41) Then Begin
                     Plus:=3; N:=N Mod 10;
                     End;
Case N Of
   1 : Begin Name:='Dagger';
             Damage:=Random(3)+2; End;    { 2-4 }
   2 : Begin Name:='Staff';
             Damage:=Random(4)+1; End;    { 1-4 }
   3 : Begin Name:='Mace';
             Damage:=Random(5)+2; End;    { 2-6 }
   4 : Begin Name:='Morn. Star';
             Damage:=Random(6)+3; End;    { 3-8 }
   5 : Begin Name:='Axe';
             Damage:=Random(6)+2; End;    { 2-7 }
   6 : Begin Name:='Long Sword';
             Damage:=Random(9)+2; End;    { 2-10 }
   7 : Begin Name:='2H Sword';
             Damage:=Random(13)+3; End;   { 3-15 }
   8 : Begin Name:='Long Bow';
             Damage:=Random(7)+1; End;    { 1-7 }
   9 : Begin Name:='Sling';
             Damage:=Random(5)+1; End;    { 1-5 }
0,10 : Begin
       If (N=0) And (Plus=0) Then Begin
                 Name:='Hands';
                 Damage:=Random(2)+1;
                 End Else Begin
                 Name:='Club';
                 Damage:=Random(6)+1;     { 1-6 }
                 End;
       End;
  41 : Begin Name:='Slime';
             Damage:=Random(2)+1; End;
  42 : Begin Name:='Bite';
             Damage:=Random(3)+1; End;
  43 : Begin Name:='Big Bite';
             Damage:=Random(6)+2; End;
  44 : Begin Name:='Giant Bite';
             Damage:=Random(8)+3; End;
  45 : Begin Name:='Fist';
             Damage:=Random(3)+1; End;
  46 : Begin Name:='Big Fist';
             Damage:=Random(5)+2; End;
  47 : Begin Name:='Giant Fist';
             Damage:=Random(11)+5; End;
  48 : Begin Name:='Claws';
             Damage:=Random(3)+2; End;
  49 : Begin Name:='Big Claws';
             Damage:=Random(7)+2; End;
  50 : Begin Name:='Giant Claws';
             Damage:=Random(13)+3; End;
  51 : Begin Name:='Vampire Touch';
             Damage:=Random(10)+3; End;
  52 : Begin Name:='Vampyr Touch';
             Damage:=Random(16)+5; End;
  53 : Begin Name:='Big Broom';
             Damage:=Random(21)+100; End;
  End;
If Plus>0 Then Begin
               Str(Plus,Ch);
               Name:=Concat(Name,' +',Ch);
               Damage:=Damage+(Plus*2)+1;
               If Player.Stats[1]>17 Then Damage:=Damage+(17-Player.Stats[1]);
               End;
End;

Procedure ArmorInfo(N : Byte; Var Name : StringType; Var Defense : Byte);
Var Ch : String[1];
    Plus : Byte;
Begin
Plus:=0;
If (N>10) And (N<21) Then Begin
                     Plus:=1; N:=N Mod 10;
                     End;
If (N>20) And (N<31) Then Begin
                     Plus:=2; N:=N Mod 10;
                     End;
If (N>30) And (N<41) Then Begin
                     Plus:=3; N:=N Mod 10;
                     End;
Case N Of
  1 : Begin Name:='Cloth';
            Defense:=3; End;
  2 : Begin Name:='Padded';
            Defense:=6; End;
  3 : Begin Name:='Leather';
            Defense:=10; End;
  4 : Begin Name:='Studded';
            Defense:=13; End;
  5 : Begin Name:='Ring Mail';
            Defense:=17; End;
  6 : Begin Name:='Scale M.';
            Defense:=20; End;
  7 : Begin Name:='Chain M.';
            Defense:=25; End;
  8 : Begin Name:='Splint M.';
            Defense:=30; End;
  9 : Begin Name:='Plate M.';
            Defense:=33; End;
0,10 : Begin
      If (N=0) And (Plus=0) Then Begin
         Name:='Nude';
         Defense:=0; End Else Begin
         Name:='Full Plate';
         Defense:=35; End;
       End;
  41 : Begin Name:='Bones';
       Defense:=10; End;
  42 : Begin Name:='Thick Skin';
       Defense:=13; End;
  43 : Begin Name:='Transparency';
       Defense:=30; End;
  44 : Begin Name:='Fur';
       Defense:=6; End;
  45 : Begin Name:='Thick Fur';
       Defense:=15; End;
  46 : Begin Name:='Scales';
       Defense:=27; End;
  47 : Begin Name:='Magic Robe';
       Defense:=25; End;
  48 : Begin Name:='Hard Bark';
       Defense:=23; End;
  49 : Begin Name:='Slime Coating';
       Defense:=5; End;
   End;
If Plus>0 Then Defense:=Defense+(Plus*4);
If Plus>0 Then Begin Str(Plus,Ch); Name:=Concat(Name,' +',Ch); End;
End;

Procedure WeaponPrice(N : Byte; Var Price : Integer);
Var Plus : Byte;
    A : Real;
Begin
Price:=0;
Plus:=0;
If (N>10) And (N<21) Then Begin Plus:=1; N:=N Mod 10;
                     End;
If (N>20) And (N<31) Then Begin Plus:=2; N:=N Mod 10;
                     End;
If (N>30) And (N<41) Then Begin Plus:=3; N:=N Mod 10;
                     End;
Case N Of
   1 : Price:=10;
   2 : Price:=5;
   3 : Price:=25;
   4 : Price:=45;
   5 : Price:=30;
   6 : Price:=55;
   7 : Price:=75;
   8 : Price:=40;
   9 : Price:=25;
0,10 : Price:=20;
  End;
Case Plus Of
  1 : Price:=Price+150;
  2 : Price:=Price+300;
  3 : Price:=Price+500;
End;
A:=Price+(Price*((Player.Stats[5]-10)/100));
Price:=Round(A);
End;

Procedure ArmorPrice(N : Byte; Var Price : Integer);
Var Plus : Byte;
    A : Real;
Begin
Plus:=0; Price:=0;
If (N>10) And (N<21) Then Begin
                     Plus:=1; N:=N Mod 10;
                     End;
If (N>20) And (N<31) Then Begin
                     Plus:=2; N:=N Mod 10;
                     End;
If (N>30) And (N<41) Then Begin
                     Plus:=3; N:=N Mod 10;
                     End;
Case N Of
  1 : Price:=5;
  2 : Price:=15;
  3 : Price:=25;
  4 : Price:=40;
  5 : Price:=60;
  6 : Price:=75;
  7 : Price:=100;
  8 : Price:=150;
  9 : Price:=200;
0,10 : Price:=300;
   End;
Case Plus Of
  1 : Price:=Price+200;
  2 : Price:=Price+500;
  3 : Price:=Price+1000;
End;
A:=Price+(Price*((Player.Stats[5]-10)/100));
Price:=Round(A);
End;

Procedure CombatStats;
{show player stats}
Var St : StringType;
    A,B : Byte;
Begin
With Player Do
Begin
  SetColor(0);
  OutTextXY(480,40,'      ');
  OutTextXY(480,50,'           ');
  OutTextXY(480,60,'      ');
  OutTextXY(480,80,'             ');
  OutTextXY(480,90,'             ');
  OutTextXY(470,110,'                ');
  SetColor(15);
  OutTextXY(480,30,Name);
  If Clife<11 Then SetColor(14);
  If Clife<6 Then SetColor(4);
  Str(CLife,St);
  OutTextXY(480,40,ST);
  SetColor(15);
  Str(XP,St);
  OutTextXY(480,50,ST);
  Str(CMagic,St);
  OutTextXY(480,60,ST);
  WeaponInfo(Weapon,St,A,B);
  OutTextXY(480,80,St);
  ArmorInfo(Armor,St,A);
  OutTextXY(480,90,St);
  Case MiscMagic Of
         1  : OutTextXY(470,110,'Wizard Eye');
         2  : OutTextXY(470,110,'Magical Boost');
         3  : OutTextXY(470,110,'Heroism');
         4  : OutTextXY(470,110,'Spell Protection');
         5  : OutTextXY(470,110,'Shield');
         6  : OutTextXY(470,110,'Iron Skin');
         7  : OutTextXY(470,110,'Confusion');
         8  : OutTextXY(470,110,'Time Delay');
         End;
End;
End;

Procedure DrawBattleField;
VAR
  X,Y : Byte;
Begin
SetActivePage(1);
ClearDevice;
SetColor(1);
Rectangle(0,0,639,199);
Rectangle(1,0,638,199);
Rectangle(4,2,635,197);
Rectangle(5,2,634,197);
Line(4,14,635,14);
Line(4,16,635,16);
Line(402,16,402,197);
Line(403,16,403,197);
Line(406,16,406,197);
Line(407,16,407,197);
Line(407,120,634,120);
Line(407,122,634,122);
SetColor(7);
OutTextXY(415,30,'Name  :');
OutTextXY(415,40,'Life  :');
OutTextXY(415,50,'XP.   :');
OutTextXY(415,60,'Magic :');
OutTextXY(415,80,'Weapon:');
OutTextXY(415,90,'Armor :');
SetColor(9);
Rectangle(2,1,637,198);
Rectangle(3,1,636,198);
Line(4,15,635,15);
Line(404,16,404,197);
Line(405,16,405,197);
Line(406,121,635,121);
SetFillStyle(1,7);
FloodFill(10,5,1);
SetColor(12);
OutTextXY(276,5,'C O M B A T');
SetColor(1);
Case CurrentMapType of
1,4 : For Y := 0 to 9 Do
        For X := 0 to 10 Do
          PutImage(X*36+6,Y*18+17,UnivIcon[6]^,NormalPut);
2 : For Y := 0 to 9 Do
      For X := 0 to 10 Do
        PutImage(X*36+6,Y*18+17,CurrentMapIcon[1]^,NormalPut);
3 : For Y := 0 to 9 Do
      For X := 0 to 10 Do
        PutImage(X*36+6,Y*18+17,CurrentMapIcon[8]^,NormalPut);
End;
{Put up all the stats}
SetVisualPage(1);
End;

Function CombatCheck(Var Mon : SetMonTypePtr): Boolean;
Var A,B : ShortInt;
Begin
CombatCheck:=False;
A:=-1; B:=-1;
Repeat
  If (Mon^.X=TempXloc+A) And (Mon^.Y=TempYloc+B) Then Begin
      CombatCheck:=True;
      B:=2; A:=-1; End;
  A:=A+1;
  If A=2 Then Begin A:=-1; B:=B+1; End;
Until B=2;
End;

Function CombatCheck2(Var Mon : RanMonTypePtr): Boolean;
Var A,B : ShortInt;
Begin
CombatCheck2:=False;
A:=-1; B:=-1;
Repeat
  If (Mon^.X=Player.Xloc+A) And (Mon^.Y=Player.Yloc+B) Then Begin
      If (Mon^.MonsterName=3) then
        begin
          WriteMessage('A thief tried to pick your pocket...');
          A:=Random(100)+1;
          If A <= (20-(Player.Stats[3] div 2)) then
            begin
              A:=Random(Player.Gold div 10)+1;
              Player.Gold:=Player.Gold-A;
              ChangeStats(1);
            End;
          Mon^.Status:=2;
        end
      Else
      CombatCheck2:=True;
      B:=2; A:=-1; End;
  A:=A+1;
  If A=2 Then Begin A:=-1; B:=B+1; End;
Until B=2;
End;

Function CombatCheck3(Var Mon : RanMonTypePtr): Boolean;
Var A,B : ShortInt;
Begin
CombatCheck3:=False;
A:=-1; B:=-1;
Repeat
  If (Mon^.X=TempXloc+A) And (Mon^.Y=TempYloc+B) Then Begin
      CombatCheck3:=True;
      B:=2; A:=-1; End;
  A:=A+1;
  If A=2 Then Begin A:=-1; B:=B+1; End;
Until B=2;
End;

Procedure CombatDisplay(N,X1,Y1,X2,Y2 : Byte);
{Display background icon then monster icon }
Begin
Case CurrentMapType Of   { Put Background icon on screen }
1,4 : PutImage(X1*36+6,Y1*18+17,UnivIcon[6]^,NormalPut);
2 :   PutImage(X1*36+6,Y1*18+17,CurrentMapIcon[1]^,NormalPut);
3 :   PutImage(X1*36+6,Y1*18+17,CurrentMapIcon[8]^,NormalPut);
End;
If (X2>-1) And (X2<11) And (Y2>-1) And (Y2<10) And (N<100) Then
{If the monster is on the screen and n<100 then put monster on screen }
         PutImage(X2*36+6,Y2*18+17,CurrentMonPics[N]^,NormalPut);
If (N=100) and (X2>-1) and (X2<11) and (Y2>-1) and (Y2<10)
  Then PutImage(X2*36+6,Y2*18+17,PlayerIcon^,NormalPut);
{If n=100 then put player on screen}
End;

Procedure CombatAnimate1(Var Mon: CombatMon);
{ Puts second step animation on screen.}
Begin
    If Mon.Hp>0 then
    PutImage(Mon.X*36+6,Mon.Y*18+17,CurrentMonPics[Mon.Name+13]^,NormalPut);
End;

Procedure CombatAnimate2(Var Mon:CombatMon);
Begin
    If Mon.Hp>0 Then
    PutImage(Mon.X*36+6,Mon.Y*18+17,CurrentMonPics[Mon.Name]^,NormalPut);
End;

Procedure ComTreasure(TT,Weap,Armor,Number:Byte);
Var
  Names:StringType;
  Money : Byte;
  C : Char;
  Nothing:Integer;
  A : ShortInt;
Begin
Money:=0;
  Case TT of
  1 : Money:=Random(35)+5;
  2 : Money:=Random(65)+20;
  3 : Money:=Random(130)+50;
  5 : Begin
      CombatMessage('The Vampyr turns to gaseous',6);
      CombatMessage('form and returns to his',6);
      CombatMessage('tomb, defeated.',6);
      Player.Mission[6]:=True;
      End;
  6 : Begin
      CombatMessage('You discovered a talisman!',6);
      Player.Mission[4]:=True;
      Money:=Random(130)+50;
      End;
  End;
  SetColor(10);
  Str(Money,Names);
  If Money>0 Then CombatMessage('You found '+Names+' gold pieces.',6);
  If (Player.Gold+Money)<9999 then Player.Gold:=Player.Gold+Money
  Else Player.Gold:=9999;
    If (Armor<=40) And (Armor>0) then
      begin
        ArmorInfo(Armor,Names,TT);
        ArmorDurMake(Armor,A);
        A:=Random(A Div 2)+10;
        CombatMessage('You found several suits of',6);
        CombatMessage(Names+'. They''re in...',6);
        DurLook(False,Armor,A,1);
        CombatMessage('condition. Put one on?',6);
        REPEAT C:=ReadKey; Until Upcase(C) in ['Y','N'];
        If UpCase(C)='Y' then
          begin
            CombatMessage('You dropped your old armor',6);
            CombatMessage('and put on the new one.',6);
            CombatMessage('Nice fit!',6);
            Player.Armor:=Armor;
            Player.ArmorDur:=A;
            CombatStats;
          End
        Else
          CombatMessage('Ok, fine.',6);
        CombatMessage('',6);
      End;
    If (Weap<=40) And (Weap<>0) then
      Begin
        Str(Number,Names);
        CombatMessage('You found '+Names,6);
        WeaponInfo(Weap,Names,Money,TT);
        WeaponDurMake(Weap,A);
        A:=Random(A Div 2)+10;
        CombatMessage(Names+'(s). They are in...',6);
        DurLook(True,Weap,A,1);
        CombatMessage('condition. Take some?',6);
        REPEAT C := Readkey; Until Upcase(C) in ['Y','N'];
        If Upcase(C)='Y' then
          begin
            TT:=0;
            For Money:= 1 to 5 do
              If Player.BackPack[Money]=0 then TT:=TT+1;
            If TT=0 then Begin
              CombatMessage('Your backpack is full. Sorry!',6); {Might change}
              Exit; End;
            Str(TT,Names);
            CombatMessage('Your backpack has '+Names,6);
            CombatMessage('slots open.',6);
            CombatMessage('Take how many?',6);
            C := ReadKey; If C=#0 then C:=ReadKey;
            If Not (C in ['2','3','4','5']) then C:='1';
            Val(C,TT,Nothing);
            If TT>Number then
              Begin CombatMessage('There aren''t that many!',6);
                    Str(Number,Names);
                    CombatMessage('You get '+Names+', and that''s it.',6);
                    TT:=Number; End;
            Money:=0;
            For Nothing := 1 to 5 Do
              If (Player.BackPack[Nothing]=0) AND (Money<TT) then
              Begin Player.BackPack[Nothing]:=Weap; Player.WeaponDur[Nothing]:=A;
                    Money:=Money+1; End;
            CombatMessage('You''ve got it.',6);
          end
        Else
          CombatMessage('Ok, fine.',6);
        CombatMessage('',6);
      End;
Delay(500);
End;

Procedure BiteHim;
Begin
If ((Random(100))<80) Then Begin
                        CombatMessage('Vampyr bit you...',2);
                        CombatMessage('You died instantly!!!',2);
                        Player.CLife:=0;
                        CombatStats;
                        End Else Begin
                        CombatMessage('Vampyr tried to',2);
                        CombatMessage('bite you but missed!',2);
                        End;
End;


Procedure MonAttack(N : Byte);
{Ahhh the monsters attack n is the monsters name.}
Var A,C,B : Byte;
    DexBon : ShortInt;
    Hit : Real;
    Name2 : StringType;
Begin
If ((CurrentMapType=3) and (N=12) And ((Player.Xloc=98) and (Player.Yloc
in [93,94])) And ((Random(100))<41)) Then Begin
  If Player.Items[1] Then Begin
    CombatMessage('Vampyr tried to bite',2);
    CombatMessage('you but the sight of',2);
    CombatMessage('the blue rose stopped',2);
    CombatMessage('him.',2); End Else BiteHim;
End
else begin
CombatMessage(CurrentMonStats[N].Name,5);
CombatMessage('armed with',2);
ArmorInfo(Player.Armor,Name2,C);
WeaponInfo(CurrentMonStats[N].Weapon,Name2,A,B);
CombatMessage(Name2+' attacking...',2);
DexBon:=0;
If Player.Stats[3]>12 then DexBon:=((Player.Stats[3]-12)*2);
If Player.Stats[3]<6 then DexBon:=((Player.Stats[3]-6)*2);
Hit:=(CurrentMonStats[N].Offensive*1.6)-((Player.Skills[2])/7)-C-DexBon+(B*3);
C:=Random(100)+1;
If C<=Hit Then Begin
  Str(A,Name2);
  CombatMessage('Hits for '+Name2+' pts of damage!',2);
  If Player.ArmorDur>0 Then ArmorDurCheck(A);
  If CurrentMonStats[N].SpecialAttack=3 Then Begin
     B:=Random(100)+1;
     If (B<31) And (Player.Armor in [5..10,15..20,25..30,35..40]) Then Begin
             CombatMessage('Your armor starts rusting...',2);
             Player.Armor:=0;
             CombatMessage('...and falls apart!!!',2);
             CombatStats;
             End;
      End;
  CombatMessage('',2);
  If SoundOnOff Then PunchSound;
  If Player.Clife<A then Player.Clife:=0 else
  Player.Clife:=Player.Clife-A;
  CombatStats;
End Else Begin
  CombatMessage('Missed...',2);
  CombatMessage('',2);
  If SoundOnOff Then MissSound;
End;
End;
End;

Procedure PlayerAttack(Var Mon : CombatMon; Armor : Byte);
{Player attack, mon = the monster that is being attacked }
Var A,C,B : Byte;
    StrBon,DexBon : ShortInt;
    Hit : Real;
    Name : StringType;
Begin
CombatMessage(Player.Name,4);       { Same as monattack above }
CombatMessage('armed with',1);
ArmorInfo(Armor,Name,C);
WeaponInfo(Player.Weapon,Name,A,B);
CombatMessage(Name+' attacking...',1);
StrBon:=0;
DexBon:=0;
If Player.Stats[1]>10 then StrBon:=((Player.Stats[1]-10)*2);
If Player.Stats[1]<6 then StrBon:=((Player.Stats[1]-6)*2);
If Player.Stats[3]>12 then DexBon:=Player.Stats[3]-12;
If Player.Stats[3]<4 then DexBon:=Player.Stats[3]-4;
Hit:=(Player.Skills[1]*1.5)+StrBon+DexBon+(B*3)
     -CurrentMonStats[Mon.Name].Defensive-C;
C:=Random(100)+1;
If C<=Hit Then Begin
  Str(A,Name);
  CombatMessage('Hits for '+Name+' pts of damage!',1);
  CombatMessage('',1);
  If SoundOnOff Then PunchSound;
  If Mon.Hp<A then Mon.Hp:=0 Else Mon.Hp:=Mon.Hp-A;
  If Player.WeaponDur[0]>0 Then Begin
                    DurCheck(CurrentMonStats[Mon.Name].Defensive);
                    CombatStats; End;
  End Else Begin
    CombatMessage('Missed...',1);
    CombatMessage('',1);
    If SoundOnOff Then MissSound;
End;
End;

Function RunAway(Var Com:Byte) : Boolean;
Var
  Ch : Char;
Begin
   RunAway:=False;
   CombatMessage('Do you want to run from',1);
   CombatMessage('the battle? [Y/N]',1);
   CombatMessage('',1);
   Repeat
   CH:=Readkey; If Ch=#0 then Ch:=ReadKey;
   Until Ch in ['Y','y','N','n'];
   If Ch in['Y','y'] Then begin RunAway:=True; Com:=2; End;
End;

Function MissleWeapon(Dir,X,Y : Byte; Mon : CombatMonType;
                            A,B : Byte; T :Byte): Byte;
Var C,M : Byte;
Begin
M:=10;
Repeat
Case Dir Of
 1 : If Y>0 Then Y:=Y-1 Else Y:=200;
 2 : Y:=Y+1;
 3 : If X>0 Then X:=X-1 Else X:=200;
 4 : X:=X+1;
End;
If (T<>5) And (X<11) And (Y<10) And (X>=0) And (Y>=0) Then
       PutImage(X*36+6,Y*18+17,UnivIcon[7+T]^,NormalPut);
If (T=5) And (X<11) And (Y<10) And (X>=0) And (Y>=0) Then
       PutImage(X*36+6,Y*18+17,UnivIcon[14]^,NormalPut);
Delay(160);
C:=0;
Repeat
C:=C+1;
If (Mon[C].X=X) And (Mon[C].Y=Y) Then C:=C+10;
Until C>7;
If (X=A) And (Y=B) Then Begin C:=0; M:=0; End;
If (C>10) And (X<11) And (Y<10) And (X>=0) And (Y>=0) Then M:=C-10 Else
If (X<11) and (Y<10) and (X>=0) and (Y>=0) then Begin
        Case CurrentMapType Of   { Put Background icon on screen }
          1,4 : PutImage(X*36+6,Y*18+17,UnivIcon[6]^,NormalPut);
          2 :   PutImage(X*36+6,Y*18+17,CurrentMapIcon[1]^,NormalPut);
          3 :   PutImage(X*36+6,Y*18+17,CurrentMapIcon[8]^,NormalPut);
        End; End;
If (X<0) Or (Y<0) Or (X>10) Or (Y>9) Then M:=9;
Until M<10;
MissleWeapon:=M;
End;

Procedure FireBall(Var Hp : Integer; T : Byte; DamageDiv : Byte);
Var B : Byte;
    C : String[2];
Begin
Case T Of
 0 : Begin
     B:=(Random(7)+6) Div DamageDiv;   {Magic Missles does 6-12 damage }
     If (Hp>=B) Then Hp:=Hp-B Else Hp:=0;
     CombatMessage('Magic Missiles hits doing...',3);
     Str(B,C);
     CombatMessage(C+' points of damage!!!',3);
     End;
 1 : Begin
     B:=(Random(10)+24) Div DamageDiv;  { Fireball does 24-33 damage }
     If (Hp>=B) Then Hp:=Hp-B Else Hp:=0;
     CombatMessage('Fireball hits doing...',3);
     Str(B,C);
     CombatMessage(C+' points of damage!!!',3);
     End;
 2 : Begin
     B:=(Random(11)+14) Div DamageDiv;   { Lighting does 14-24 damage }
     If (Hp>=B) Then Hp:=Hp-B Else Hp:=0;
     CombatMessage('Lightning hits doing...',3);
     Str(B,C);
     CombatMessage(C+' points of damage!!!',3);
     End;
 3 : Begin
     B:=(Random(4)+4) Div DamageDiv;  { Burning hands does 4-7 damage }
     If (Hp>=B) Then Hp:=Hp-B Else Hp:=0;
     CombatMessage('Burning hands burned for...',3);
     Str(B,C);
     CombatMessage(C+' points of damage!!!',3);
     End;
End;
CombatMessage('',3);
End;

Procedure CancelMagic;
Begin
  Player.StepsWalked:=0;
  Case Player.MiscMagic Of
     2 : Player.Skills[3]:=Player.TempSkills[3];
     3 : Player.Skills[1]:=Player.TempSkills[1];
     4 : Player.Skills[4]:=Player.TempSkills[4];
   5,6 : Player.Skills[2]:=Player.TempSkills[2];
     7 : Begin
         CombatMessage('Confusion wore off...',3);
         CombatMessage('',3);
         End;
     8 : Begin
         CombatMessage('Time continues...',3);
         CombatMessage('',3);
         End;
  End;
  Player.MiscMagic:=0;
End;

Procedure MonDie;
begin
  CombatMessage('Monster dies!!!',3);
end;

Procedure CombatMagic(X,Y : Byte; Var Mon : CombatMonType; Var Stats : Byte;
                     Var Armor : Byte);
Var Ch : Char;
    A,B,C : Byte;
    D : Integer;
    E: Real;
Begin
CombatMessage('Spells:',3);
CombatMessage('(A) Magic Missiles',3);
CombatMessage('(B) Fireball',3);
CombatMessage('(C) Lightning',3);
CombatMessage('(D) Burning Hands',3);
CombatMessage('(E) Enemy Disintegration',3);
CombatMessage('(F) Spell Protection',3);
CombatMessage('<ANY KEY> TO CONTINUE...',2);
Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
CombatMessage('(G) Shield',3);
CombatMessage('(H) Confusion',3);
CombatMessage('(I) Time Delay',3);
CombatMessage('(J) Iron Skin',3);
CombatMessage('(K) Scare',3);
If Player.Items[4] Then CombatMessage('(L) Rust Armor',3)
else CombatMessage('',3);
CombatMessage('Which one?',3);
Ch:=ReadKey; If Ch=#0 then begin Ch:=ReadKey; Ch:='X'; end;
A:=0;
Case Upcase(Ch) Of
  'A' : A:=6;                          {  <---            }
  'B' : A:=12;                         {  HERE Magic Pts. }
  'C' : A:=13;                         {  <---            }
  'D' : A:=3;
  'E' : A:=16;
  'F' : A:=4;
  'G' : A:=6;
  'H' : A:=8;
  'I' : A:=15;
  'J' : A:=10;
  'K' : A:=3;
  'L' : If Player.Items[4] Then A:=20;
End;
If (Not (Upcase(Ch) In ['A'..'L'])) Then CH:='X';
If (A>0) And (Player.CMagic<A) Then Begin Ch:='W';
                               CombatMessage('Not enough Magic.',3); End;
If (A>0) And (Player.CMagic>=A) Then Player.CMagic:=Player.CMagic-A;
If Upcase(CH)='Z' Then CH:='Y';
If (Upcase(CH)='L') And (Not Player.Items[4]) Then CH:='X';
If UpCase(Ch) In ['F'..'K'] Then Begin
                         E:=(Player.Skills[4]*1.4)+50-
                            (CurrentMonStats[Mon[1].Name].Offensive);
                         If E<(Random(100)+1) Then CH:='Z';
                         End;
If UpCase(Ch) In ['A'..'L'] Then Begin
                            SetPalette(0,22);
                            If SoundOnOff Then Begin MagicSound; MagicSound2;
                            MagicSound3; End
                            Else Delay(40);
                            SetPalette(0,0);
                            If (Player.MiscMagic=7) And (Stats in [21,22])
                                                 Then Stats:=Stats-20;
                            If (Player.MiscMagic=7) And (Stats in [31,32])
                                                 Then Stats:=Stats-30;
                            If (Player.MiscMagic=7) And (Stats in [41,42])
                                                 Then Stats:=Stats-40;
                            CancelMagic;
                            End;
Case Upcase(Ch) Of
 'A','B': Begin
            Player.MiscMagic:=0;
               Case UpCase(Ch) Of
                'A' : A:=5;
                'B' : A:=1;
               End;
               CombatMessage('Which direction?',3);
               B:=0;
               Ch:=Readkey;
               If CH=#0 Then CH:=Readkey Else Ch:='Z';
               Case Ord(Upcase(Ch)) Of
                 75 : B:=MissleWeapon(3,X,Y,Mon,X,Y,A);
                 77 : B:=MissleWeapon(4,X,Y,Mon,X,Y,A);
                 72 : B:=MissleWeapon(1,X,Y,Mon,X,Y,A);
                 80 : B:=MissleWeapon(2,X,Y,Mon,X,Y,A);
                 90 : CombatMessage('Cursor keys only!',3);
               End;
               If B=0 Then CombatMessage('Missed...',3);
               If (B>0) And (B<9) Then Begin
                        If ((Player.Skills[3]*1.2+50)-CurrentMonStats[Mon[B].Name]
                           .MagicRes)>=Random(100)+1 Then Begin
                            Case A Of
                              5 : A:= 0;
                              1 : A:= 1;
                            End;
                            D:=Mon[B].Hp;
                            FireBall(D,A,1);
                            Mon[B].HP:=D;
                            If Mon[B].Hp<1 Then Begin CombatDisplay(Mon[B].Name,
                                           Mon[B].X,Mon[B].Y,200,200);
                                           MonDie;
                                           CombatMessage('',3);
                                           Player.Xp:=Player.Xp+
                                           CurrentMonStats[Mon[B].Name].XpVal;
                                           CombatStats;
                                           End Else
                                           CombatDisplay(Mon[B].Name,Mon[B].X,
                                           Mon[B].Y,Mon[B].X,Mon[B].Y);

                            End Else Begin
                            CombatMessage('Monster resisted..',3);
                            Case A Of
                              5 : A:= 0;
                              1 : A:= 1;
                            End;
                            D:=Mon[B].Hp;
                            FireBall(D,A,4);
                            Mon[B].HP:=D;
                            If Mon[B].Hp<1 Then Begin CombatDisplay(Mon[B].Name,
                                           Mon[B].X,Mon[B].Y,200,200);
                                           MonDie;
                                           CombatMessage('',3);
                                           Player.Xp:=Player.Xp+
                                           CurrentMonStats[Mon[B].Name].XpVal;
                                           CombatStats;
                                           End Else
                                           CombatDisplay(Mon[B].Name,Mon[B].X,
                                           Mon[B].Y,Mon[B].X,Mon[B].Y);
                            End;
                         End;
               End;
 'C' : Begin
       Player.MiscMagic:=0;
       CombatMessage('Which direction?',3);
       Ch:=Readkey;
       A:=X; C:=Y; B:=0;
       If Ch=#0 Then CH:=Readkey Else Ch:='Z';
       Repeat
       Case Ord(Upcase(Ch)) Of
            75 : B:=MissleWeapon(3,A,C,Mon,X,Y,3);
            77 : B:=MissleWeapon(4,A,C,Mon,X,Y,3);
            72 : B:=MissleWeapon(1,A,C,Mon,X,Y,3);
            80 : B:=MissleWeapon(2,A,C,Mon,X,Y,3);
            90 : CombatMessage('Cursor keys only!',3);
       End;
       If B=0 Then CombatMessage('Missed...',3);
       If (B>0) And (B<9) Then Begin
                A:=Mon[B].X; C:=Mon[B].Y;
                If ((Player.Skills[3]*1.2+50)-CurrentMonStats[Mon[B].Name].MagicRes)
                   >=(Random(100)+1) Then Begin
                            D:=Mon[B].Hp;
                            FireBall(D,2,1);
                            Mon[B].Hp:=D;
                            If Mon[B].Hp<1 Then Begin
                                 CombatDisplay(Mon[B].Name,
                                 Mon[B].X,Mon[B].Y,200,200);
                                 MonDie;
                                 CombatMessage('',3);
                                 Player.Xp:=Player.Xp+
                                 CurrentMonStats[Mon[B].Name].XpVal;
                                 CombatStats;
                                 End Else
                                 CombatDisplay(Mon[B].Name,Mon[B].X,
                                 Mon[B].Y,Mon[B].X,Mon[B].Y);
                            End Else Begin
                            CombatMessage('Monster Resisted..',3);
                            D:=Mon[B].Hp;
                            FireBall(D,2,4);
                            Mon[B].Hp:=D;
                            If Mon[B].Hp<1 Then Begin
                                 CombatDisplay(Mon[B].Name,
                                 Mon[B].X,Mon[B].Y,200,200);
                                 MonDie;
                                 CombatMessage('',3);
                                 Player.Xp:=Player.Xp+
                                 CurrentMonStats[Mon[B].Name].XpVal; CombatStats; End
                                 Else
                                 CombatDisplay(Mon[B].Name,Mon[B].X,
                                 Mon[B].Y,Mon[B].X,Mon[B].Y);
                            End;
                    End;
       Until (B=9) Or (B=0);
       End;
 'D' : Begin
       Player.MiscMagic:=0;
       CombatMessage('Which direction?',3);
       CH:=Readkey;
       A:=X; B:=Y;
       If Ch=#0 Then CH:=Readkey Else Ch:='Z';
       Case Ord(Upcase(Ch)) Of
         75 : A:=A-1;
         77 : A:=A+1;
         72 : B:=B-1;
         80 : B:=B+1;
         90 : CombatMessage('Cursor keys only!',3);
       End;
       For C:=1 To 8 Do
         If (Mon[C].X=A) And (Mon[C].Y=B) Then Begin
                   If ((Player.Skills[3]*1.2+50)-CurrentMonStats[Mon[B].Name]
                   .MagicRes)>=(Random(100)+1) Then Begin
                             D:=Mon[C].Hp;
                             FireBall(D,3,1);
                             Mon[C].Hp:=D;
                             If Mon[C].Hp<1 Then Begin
                                   CombatDisplay(Mon[C].Name,
                                   Mon[C].X,Mon[C].Y,200,200);
                                   MonDie;
                                   CombatMessage('',3);
                                   Player.Xp:=Player.Xp+
                                 CurrentMonStats[Mon[C].Name].XpVal; CombatStats; End;
                   End Else Begin
                       CombatMessage('Monster resisted...',3);
                       D:=Mon[C].Hp;
                       FireBall(D,3,4);
                       Mon[C].Hp:=D;
                       If Mon[C].Hp<1 Then Begin
                       CombatDisplay(Mon[C].Name,
                       Mon[C].X,Mon[C].Y,200,200);
                       MonDie;
                       CombatMessage('',3);
                       Player.Xp:=Player.Xp+
                       CurrentMonStats[Mon[C].Name].XpVal; CombatStats; End;
                       End;
                   End;
       End;
 'E' : Begin
       Player.MiscMagic:=0;
       CombatMessage('Enemy Disintegration',3);
       CombatMessage('',3);
       C:=98+(Player.Level*2);
       A:=1; B:=0;
       Repeat
       If (Mon[A].Hp<=C) And (Mon[A].Hp>0) Then Begin
                   If ((Player.Skills[3]*1.2+50)-CurrentMonStats[Mon[A].Name]
                   .MagicRes)>=(Random(100)+1) Then Begin
                          C:=C-Mon[A].Hp;
                          Mon[A].Hp:=0;
                          CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,200,200);
                          Mon[A].X:=200; Mon[A].Y:=200;
                          If SoundOnOff Then PunchSound;
                          MonDie;
                          CombatMessage('',3); B:=B+1;
                          Player.Xp:=(Player.Xp+(CurrentMonStats
                          [Mon[A].Name].XpVal Div 2)); CombatStats;
                          End Else CombatMessage('Monster resisted...',3);
                          End;
       A:=A+1;
       Until (A=9) Or (C<1);
       If B=0 Then Begin CombatMessage('Failed...',3);
                         MissSound; End;
       CombatMessage('',3);
       End;
 'F' : Begin
       Player.MiscMagic:=4;
       A:=Random(5)+11;
       If (Player.Skills[4]+A) <=100 Then
       Player.Skills[4]:=Player.Skills[4]+A
       Else Player.Skills[4]:=100;
       Player.StepsWalked:=20;
       CombatMessage('Spell protection',3);
       CombatMessage('has been cast.',3);
       CombatMessage('',3);
       End;
 'G' : Begin
       Player.MiscMagic:=5;
       A:=Random(5)+11;
       If (Player.Skills[2]+A) <=100 Then
       Player.Skills[2]:=Player.Skills[2]+A
       Else Player.Skills[2]:=100;
       Player.StepsWalked:=20;
       CombatMessage('Shield has been cast.',3);
       CombatMessage('',3);
       End;
 'H' : Begin
       Player.MiscMagic:=7;
       CombatMessage('Confusion has been cast.',3);
       CombatMessage('',3);
       Player.StepsWalked:=85;
       End;
 'I' : Begin
       Player.MiscMagic:=8;
       CombatMessage('Time Delay has been cast.',3);
       CombatMessage('',3);
       Player.StepsWalked:=92;
       End;
 'J' : Begin
        Player.MiscMagic:=6;
       A:=Random(6)+30;
       If (Player.Skills[2]+A) <=100 Then
       Player.Skills[2]:=Player.Skills[2]+A
       Else Player.Skills[2]:=100;
       CombatMessage('Iron Skin has been cast.',3);
       CombatMessage('',3);
       Player.StepsWalked:=60;
       End;
 'K' : Begin
       CombatMessage('Scare has been cast.',3);
       B:=0;
       For A:=1 To 8 Do
         B:=B+Mon[A].Hp;
       If (Player.CLife/1.5)>=B Then Begin
                               Stats:=2;
                               CombatMessage('Monsters are scared!!',3);
                               End Else Begin
                               CombatMessage('Failed...',3);
                               MissSound;
                               End;
       CombatMessage('',3);
       End;
 'L' : Begin
       If (Armor in [5..10,15..20,25..30,35..40])
          Then Begin
               Armor:=0;
               CombatMessage('Monsters'' Armors are gone.',3);
          End Else begin CombatMessage('Monsters are not wearing',3);
                         CombatMessage('metal armors.',3); End;
       End;
 'X' : CombatMessage('Please use the correct keys.',3);
 'Z' : Begin CombatMessage('Your concentration is broken',3);
             CombatMessage('by the monsters'' movements.',3); End;
  End;
CombatStats;
CombatMessage('',3);
End;

Procedure CombatSwap;
Var Ch : Char;
    A,B,C : Byte;
    S1 : StringType;
    S2 : String[1];
Begin
CombatMessage('Backpack contains:',1);
For A:=1 To 5 Do
  Begin
  WeaponInfo(Player.BackPack[A],S1,B,C);
  Str(A,S2);
  If Player.BackPack[A]=0 Then S1:='Nothing';
  CombatMessage(S2+'> '+S1,1);
  End;
CombatMessage('Swap with what?',1);
CH:=Readkey; If Ch=#0 then Ch:=ReadKey;
Case Ch Of
  '1' : Begin
        A:=Player.Weapon;
        Player.Weapon:=Player.BackPack[1];
        Player.BackPack[1]:=A;
        A:=Player.WeaponDur[0];
        Player.WeaponDur[0]:=Player.WeaponDur[1];
        Player.WeaponDur[1]:=A;
        End;
  '2' : Begin
        A:=Player.Weapon;
        Player.Weapon:=Player.BackPack[2];
        Player.BackPack[2]:=A;
        A:=Player.WeaponDur[0];
        Player.WeaponDur[0]:=Player.WeaponDur[2];
        Player.WeaponDur[2]:=A;
        End;
  '3' : Begin
        A:=Player.Weapon;
        Player.Weapon:=Player.BackPack[3];
        Player.BackPack[3]:=A;
        A:=Player.WeaponDur[0];
        Player.WeaponDur[0]:=Player.WeaponDur[3];
        Player.WeaponDur[3]:=A;
        End;
  '4' : Begin
        A:=Player.Weapon;
        Player.Weapon:=Player.BackPack[4];
        Player.BackPack[4]:=A;
        A:=Player.WeaponDur[0];
        Player.WeaponDur[0]:=Player.WeaponDur[4];
        Player.WeaponDur[4]:=A;
        End;
  '5' : Begin
        A:=Player.Weapon;
        Player.Weapon:=Player.BackPack[5];
        Player.BackPack[5]:=A;
        A:=Player.WeaponDur[0];
        Player.WeaponDur[0]:=Player.WeaponDur[5];
        Player.WeaponDur[5]:=A;
        End;
End;
If Ch in ['1','2','3','4','5'] Then CombatMessage('Swapped.',1);
CombatMessage('',1);
CombatStats;
End;

Function Combat(Var Name,Stats,Num : Byte) : Byte;
{ The Main combat function }           {0 -- Player won}
Label Again, GetOut;                   {1 -- Player lost}
Var Ch : Char;                         {2 -- Player ran}
    Mon : CombatMonType;               {3 -- Monster ran}
    X,Y : Byte;
    Armor,A,B,C,Com,Num2 : Byte;
    InWay, Done : Boolean;
Begin
Num2:=Num;
If Not (Stats In [1,2]) Then Stats:=1;
MLine:=1;                      { Beginning of setup  }
Done:=False; Armor:=CurrentMonStats[Name].Armor;
If Player.Clife> 15 then WriteMessage('Combat!!!') Else
WriteMessage('Uh-oh... looks like you are in trouble...');
DrawBattleField;
CombatStats;
For A:=1 To 8 Do
 Mon[A].Hp:=0;
For A:=1 To Num Do
 Begin
 Mon[A].Hp:=CurrentMonStats[Name].Hitpts;
 Mon[A].Name:=Name;
 Case A Of
  1 : Begin Mon[A].X:=5; Mon[A].Y:=4; End;
  2 : Begin Mon[A].X:=4; Mon[A].Y:=3; End;
  3 : Begin Mon[A].X:=6; Mon[A].Y:=3; End;
  4 : Begin Mon[A].X:=3; Mon[A].Y:=2; End;
  5 : Begin Mon[A].X:=5; Mon[A].Y:=2; End;
  6 : Begin Mon[A].X:=7; Mon[A].Y:=2; End;
  7 : Begin Mon[A].X:=4; Mon[A].Y:=1; End;
  8 : Begin Mon[A].X:=6; Mon[A].Y:=1; End;
 End;
 CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y);
 End;
X:=5; Y:=7;
CombatDisplay(100,X,Y,X,Y);
Com:=10; KeyboardFlush;
A:=Random(2);
If (A=1) and SoundOnOff then BattleCrySound;
If (A=0) and SoundOnOff then BattleCrySound2;
Repeat           { main loop }
Again:
  Repeat
    For B := 1 to 8 Do
      begin
        If Player.MiscMagic<>8 Then CombatAnimate1(Mon[B]);
        Delay(60);
        If Player.MiscMagic<>8 Then CombatAnimate2(Mon[B]);
        Delay(5);
      End;
  Until KeyPressed;
Ch:=Readkey;              {player input }
If Ch=#0 Then CH:=Readkey;  {special key }
Case Ord(Upcase(Ch)) Of
  77 : Begin
         If (X+1)>10 then
           Begin
           If RunAway(Com) then Goto GetOut;
           End
         Else Begin
     Inway:=True;
     A:=0;
     For B:=1 To Num Do   { checks to see if monsters are in the way }
     If (Mon[B].Y=Y) And (Mon[B].X=X+1)
     And (Mon[B].Hp>0) Then A:=B;
     If A=0 Then Begin   {if not then move }
                CombatDisplay(100,X,Y,X+1,Y);
                X:=X+1;
                End;
     If (A>0) And (Player.Weapon In [8,9,18,19,28,29,38,39]) Then
              CombatMessage('You must FIRE that weapon!!',1);
     If (A>0) And (Not (Player.Weapon In [8,9,18,19,28,29,38,39])) Then Begin
            PlayerAttack(Mon[A],Armor);
            If Mon[A].Hp<1 Then begin MonDie;
              CombatMessage('',1); CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,
              200,200); Player.Xp:=Player.Xp+CurrentMonStats[Mon[A].Name].XpVal;
              Mon[A].X:=200; Mon[A].Y:=200; CombatStats End;
            End;   End;
     End;
  75 : Begin    {same as above }
         If (X-1)<0 then
           begin
             If RunAway(Com) then Goto GetOut;
           End
         Else Begin
     A:=0;
     For B:=1 To Num Do
     If (Mon[B].Y=Y) And (Mon[B].X=X-1)
     And (Mon[B].Hp>0) Then A:=B;
     If A=0 Then Begin
                CombatDisplay(100,X,Y,X-1,Y);
                X:=X-1;
                End;
      If (A>0) And (Player.Weapon In [8,9,18,19,28,29,38,39]) Then
              CombatMessage('You must FIRE that weapon!!',1);
      If (A>0) And (Not (Player.Weapon In [8,9,18,19,28,29,38,39])) Then Begin
            PlayerAttack(Mon[A],Armor);
            If Mon[A].Hp<1 Then begin MonDie;
              CombatMessage('',1); CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,
              200,200); Player.Xp:=Player.Xp+CurrentMonStats[Mon[A].Name].XpVal;
              Mon[A].X:=200; Mon[A].Y:=200; CombatStats End;
            End;   End;
     End;
  72 : Begin
         If (Y-1)<0 then
           Begin
             If RunAway(Com) then Goto GetOut;
           End
         Else Begin
     A:=0;
     For B:=1 To Num Do
     If (Mon[B].Y=Y-1) And (Mon[B].X=X)
     And (Mon[B].Hp>0) Then A:=B;
     If A=0 Then Begin
                CombatDisplay(100,X,Y,X,Y-1);
                Y:=Y-1;
                End;
     If (A>0) And (Player.Weapon In [8,9,18,19,28,29,38,39]) Then
              CombatMessage('You must FIRE that weapon!!',1);
     If (A>0) And (Not (Player.Weapon In [8,9,18,19,28,29,38,39])) Then Begin
            PlayerAttack(Mon[A],Armor);
            If Mon[A].Hp<1 Then begin MonDie;
              CombatMessage('',1); CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,
              200,200); Player.Xp:=Player.Xp+CurrentMonStats[Mon[A].Name].XpVal;
              Mon[A].X:=200; Mon[A].Y:=200; CombatStats End;
            End;   End;
     End;
  80 : Begin
         If (Y+1)>9 then
           Begin
             If RunAway(Com) then Goto GetOut;
           End
         Else Begin
     A:=0;
     For B:=1 To Num Do
     If (Mon[B].Y=Y+1) And (Mon[B].X=X)
     And (Mon[B].Hp>0) Then A:=B;
     If A=0 Then Begin
                CombatDisplay(100,X,Y,X,Y+1);
                Y:=Y+1;
                End;
     If (A>0) And (Player.Weapon In [8,9,18,19,28,29,38,39]) Then
              CombatMessage('You must FIRE that weapon!!',1);
     If (A>0) And (Not (Player.Weapon In [8,9,18,19,28,29,38,39])) Then Begin
            PlayerAttack(Mon[A],Armor);
            If Mon[A].Hp<1 Then Begin MonDie;
              CombatMessage('',1); CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,
              200,200); Player.Xp:=Player.Xp+CurrentMonStats[Mon[A].Name].XpVal;
              Mon[A].X:=200; Mon[A].Y:=200; CombatStats End;
            End;   End;
     End;
  3 : Begin
        GetImage(412,126,633,188,MessageScrollPtr^);
        PutImage(412,126,MessageScrollPtr^,XorPut);
        MLine:=1;
        Goto Again;
      End;
  13 : Begin CombatMessage('Pass.',1); CombatMessage('',1); End;
  70 : If (Player.Weapon In [8,9,18,19,28,29,38,39]) Then Begin
          If (Player.Weapon in [8,18,28,38]) Then B:=2 Else B:=4;
          CombatMessage('Which direction ?',1);
          Ch:=Readkey;
          If Ch=#0 Then Ch:=Readkey Else Ch:='Z';
          Case Ord(UpCase(Ch)) Of
            75 : A:=MissleWeapon(3,X,Y,Mon,X,Y,B);
            77 : A:=MissleWeapon(4,X,Y,Mon,X,Y,B);
            72 : A:=MissleWeapon(1,X,Y,Mon,X,Y,B);
            80 : A:=MissleWeapon(2,X,Y,Mon,X,Y,B);
            90 : CombatMessage('Cursor keys only.',1);
          End;
          If (A>0) And (A<9) Then Begin PlayerAttack(Mon[A],Armor);
                                  If Mon[A].Hp<1 Then Begin
                                  CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,
                                                200,200);
                                               Mon[A].X:=200; Mon[A].Y:=200;
                                               MonDie;
                                               CombatMessage('',1);
                                               Player.Xp:=Player.Xp+
                                               CurrentMonStats[Mon[A].Name].XpVal;
                                               CombatStats;
                                               End;
                                  CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,
                                                Mon[A].X,Mon[A].Y);
                                  End;
          If (A=9) Then CombatMessage ('Missed...',1);
          End else CombatMessage('Use a missile weapon!',1);
  67 : CombatMagic(X,Y,Mon,Stats,Armor);
  83 : CombatSwap;
     Else Goto Again
End;
For A:=1 To Num Do
  If (Mon[A].Hp>0) And (Player.MiscMagic<>8) And ((Mon[A].X<10) Or
     (Mon[A].Y<9)) Then Begin
               Done:=False;
               If Stats in [2,21,22] Then Begin
                     If Mon[A].X>X Then Begin
                       Inway:=True;
                       For B:=1 To Num Do
                        If (Mon[B].X=Mon[A].X+1) And (Mon[B].Y=Mon[A].Y)
                           And (Mon[B].Hp>0) Then InWay:=False;
                        If (Inway) And (Mon[A].X=10) Then Begin
                               CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,200,200);
                               Mon[A].X:=200; Mon[A].Y:=200; Inway:=False; End;
                        If (Inway) Then Begin CombatDisplay(Mon[A].Name,
                             Mon[A].X,Mon[A].Y,Mon[A].X+1,Mon[A].Y);
                             Mon[A].X:=Mon[A].X+1; Done:=True; End;
                        If (Mon[A].X>10) Or (Mon[A].Y>9) Then Begin
                           Mon[A].X:=200; Mon[A].Y:=200; CombatDisplay
                           (Mon[A].Name,Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y); End;
                        End;
                    If (Mon[A].X<X) And (Not Done) Then Begin
                       Inway:=True;
                       For B:=1 To Num Do
                        If (Mon[B].X=Mon[A].X-1) And (Mon[B].Y=Mon[A].Y)
                           And (Mon[B].Hp>0) Then InWay:=False;
                        If (Inway) And (Mon[A].X=0) Then Begin
                              CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,200,200);
                              Mon[A].X:=200; Mon[A].Y:=200; Inway:=False; End;
                        If (Inway) Then Begin CombatDisplay(Mon[A].Name,
                             Mon[A].X,Mon[A].Y,Mon[A].X-1,Mon[A].Y);
                             Mon[A].X:=Mon[A].X-1; Done:=True; End;
                        If (Mon[A].X>10) Or (Mon[A].Y>9) Then Begin
                           Mon[A].X:=200; Mon[A].Y:=200; CombatDisplay
                           (Mon[A].Name,Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y); End;
                        End;
                    If (Mon[A].Y>Y) And (Not Done) Then Begin
                       Inway:=True;
                       For B:=1 To Num Do
                        If (Mon[B].Y=Mon[A].Y+1) And (Mon[B].X=Mon[A].X)
                           And (Mon[B].Hp>0) Then InWay:=False;
                        If (Inway) And (Mon[A].Y=9) Then Begin
                               CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,200,200);
                               Mon[A].X:=200; Mon[A].Y:=200; Inway:=False; End;
                        If (Inway) Then Begin CombatDisplay(Mon[A].Name,
                             Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y+1);
                             Mon[A].Y:=Mon[A].Y+1; Done:=True; End;
                        If (Mon[A].X>10) Or (Mon[A].Y>9) Then Begin
                           Mon[A].X:=200; Mon[A].Y:=200; CombatDisplay
                           (Mon[A].Name,Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y); End;
                        End;
                    If (Mon[A].Y<Y) And (Not Done) Then Begin
                       Inway:=True;
                       For B:=1 To Num Do
                        If (Mon[B].Y=Mon[A].Y-1) And (Mon[B].X=Mon[A].X)
                           And (Mon[B].Hp>0) Then InWay:=False;
                       If (Inway) And (Mon[A].Y=0) Then Begin
                               CombatDisplay(Mon[A].Name,Mon[A].X,Mon[A].Y,200,200);
                               Mon[A].X:=200; Mon[A].Y:=200; Inway:=False; End;
                        If (Inway) Then Begin CombatDisplay(Mon[A].Name,
                             Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y-1);
                             Mon[A].Y:=Mon[A].Y-1; Done:=True; End;
                        If (Mon[A].X>10) Or (Mon[A].Y>9) Then Begin
                           Mon[A].X:=200; Mon[A].Y:=200; CombatDisplay
                           (Mon[A].Name,Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y); End;
                        End;
                 End;
           If Stats in [1,31,32] Then Begin
               If CurrentMonStats[Mon[A].Name].SpecialAttack in [1,2] Then Begin
                 B:=Random(100)+1;
                 If (B<33) And ((X=Mon[A].X) Or (Y=Mon[A].Y)) Then Done:=True;
                 If (Done) Then Begin
                          If CurrentMonStats[Mon[A].Name].SpecialAttack=1 Then
                             C:=5 Else C:=1;
                          If X<Mon[A].X Then
                              B:=MissleWeapon(3,Mon[A].X,Mon[A].Y,Mon,X,Y,C);
                          If X>Mon[A].X Then
                              B:=MissleWeapon(4,Mon[A].X,Mon[A].Y,Mon,X,Y,C);
                          If Y<Mon[A].Y Then
                              B:=MissleWeapon(1,Mon[A].X,Mon[A].Y,Mon,X,Y,C);
                          If Y>Mon[A].Y Then
                              B:=MissleWeapon(2,Mon[A].X,Mon[A].Y,Mon,X,Y,C);
                          CombatDisplay(100,X,Y,X,Y);
                          If (B=0) Then Begin
                             B:=Player.Skills[4]-CurrentMonStats[Mon[A].Name].Offensive+10;
                             If B>=Random(100)+1 Then Begin
                             FireBall(Player.Clife,CurrentMonStats[Mon[A].Name].
                                     SpecialAttack-1,1);
                             CombatStats; CombatDisplay(100,X,Y,X,Y); End Else
                             Begin
                             If CurrentMonStats[Mon[A].Name].SpecialAttack=2
                              Then CombatMessage('You resisted the fireball!',3)
                              Else
                              Begin CombatMessage('You resisted the magic',3);
                                    CombatMessage('missiles!',3); end;
                              FireBall(Player.Clife,CurrentMonStats[Mon[A].Name].
                                     SpecialAttack-1,4);
                             CombatStats; CombatDisplay(100,X,Y,X,Y); End;
                             End;
                         End;
                    End;
                    If ((CurrentMonStats[Mon[A].Name].Weapon in
                       [8,9,18,19,28,29,38,39]) And (Not Done))
                       And ((Random(100)+1)<55) And (Mon[A].X=X) And (Mon[A].Y=Y)
                       Then Begin Done:=True;
                       If (CurrentMonStats[Mon[A].Name].Weapon in [8,18,28,38]) Then
                          B:=2 Else B:=4;
                       If X<Mon[A].X Then
                              C:=MissleWeapon(3,Mon[A].X,Mon[A].Y,Mon,X,Y,B);
                       If X>Mon[A].X Then
                              C:=MissleWeapon(4,Mon[A].X,Mon[A].Y,Mon,X,Y,B);
                       If Y<Mon[A].Y Then
                              C:=MissleWeapon(1,Mon[A].X,Mon[A].Y,Mon,X,Y,B);
                       If Y>Mon[A].Y Then
                              C:=MissleWeapon(2,Mon[A].X,Mon[A].Y,Mon,X,Y,B);
                       If C=9 Then CombatMessage('Missed...',2);
                       If C=0 Then Begin
                              MonAttack(Mon[A].Name);
                              CombatStats;
                              CombatDisplay(100,X,Y,X,Y);
                              End;
                       End;
                    If (Mon[A].Y<Y) And (Not Done) Then Begin
                       Inway:=True;
                       For B:=1 To Num Do
                        If (Mon[B].Y=Mon[A].Y+1) And (Mon[B].X=Mon[A].X)
                           And (Mon[B].Hp>0) Then InWay:=False;
                        If (Inway) And ((Y<>Mon[A].Y+1) or (X<>Mon[A].X))
                             Then Begin CombatDisplay(Mon[A].Name,
                             Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y+1);
                             Mon[A].Y:=Mon[A].Y+1; Done:=True; End;
                        If (Inway) And ((Y=Mon[A].Y+1) And (X=Mon[A].X))
                            and (Not Done)
                            Then Begin MonAttack(Mon[A].Name); Done:=True;
                             End;
                        End;
                    If (Mon[A].Y>Y) And (Not Done) Then Begin
                       Inway:=True;
                       For B:=1 To Num Do
                        If (Mon[B].Y=Mon[A].Y-1) And (Mon[B].X=Mon[A].X)
                           And (Mon[B].Hp>0) Then InWay:=False;
                        If (Inway) And ((Y<>Mon[A].Y-1) or (X<>Mon[A].X))
                             Then Begin CombatDisplay(Mon[A].Name,
                             Mon[A].X,Mon[A].Y,Mon[A].X,Mon[A].Y-1);
                             Mon[A].Y:=Mon[A].Y-1; Done:=True; End;
                        If (Inway) And ((Y=Mon[A].Y-1) And (X=Mon[A].X))
                           And (Not Done)
                           Then Begin MonAttack(Mon[A].Name); Done:=True;
                             End;
                        End;
                   If (Mon[A].X<X) And (Not Done) Then Begin
                      Inway:=True;
                      For B:=1 To Num Do
                       If (Mon[B].X=Mon[A].X+1) And (Mon[B].Y=Mon[A].Y)
                          And (Mon[B].Hp>0) Then InWay:=False;
                       If (Inway) And ((X<>Mon[A].X+1) or (Y<>Mon[A].Y))
                           Then Begin CombatDisplay(Mon[A].Name,
                           Mon[A].X,Mon[A].Y,Mon[A].X+1,Mon[A].Y);
                           Mon[A].X:=Mon[A].X+1; Done:=True; End;
                       If (Inway) And ((X=Mon[A].X+1) And (Y=Mon[A].Y))
                          And (Not Done)
                          Then Begin MonAttack(Mon[A].Name); Done:=True;
                           End;
                    End;
                    If (Mon[A].X>X) And (Not Done) Then Begin
                       Inway:=True;
                       For B:=1 To Num Do
                        If (Mon[B].X=Mon[A].X-1) And (Mon[B].Y=Mon[A].Y)
                           And (Mon[B].Hp>0) Then InWay:=False;
                        If (Inway) And ((X<>Mon[A].X-1) or (Y<>Mon[A].Y))
                             Then Begin CombatDisplay(Mon[A].Name,
                             Mon[A].X,Mon[A].Y,Mon[A].X-1,Mon[A].Y);
                             Mon[A].X:=Mon[A].X-1; Done:=True; End;
                        If (Inway) And ((X=Mon[A].X-1) And (Y=Mon[A].Y))
                            And (Not Done)
                            Then Begin MonAttack(Mon[A].Name); Done:=True;
                             End;
                        End;
                     End; End;
If (CurrentMonStats[Mon[1].Name].Name='The Vampyr') And ((Random(100)+1<16))
     And (Mon[2].Hp<1) And (Mon[3].Hp<1) And (Mon[4].Hp<1)
     Then Begin                   { 15% Vampyr raise evil clerics }
                A:=Random(3)+1;   { raise 1-3 evil clerics }
                CombatMessage('Vampyr summons',2);
                CombatMessage('evil clerics...',2);
                Num:=Num+A;
                For B:=1 To A Do
                 Begin
                  Mon[B+1].Name:=6;
                  Mon[B+1].Hp:=CurrentMonStats[6].HitPts;
                  Mon[B+1].Y:=0;
                 End;
                A:=2;
                For B:=1 TO 7 Do
                  If (Mon[1].X<>B) Or (Mon[1].Y<>1) And (X<>B) Or (Y<>1)
                  Then Begin Mon[A].X:=B; A:=A+1; End;
                End;

If CurrentMonStats[Mon[1].Name].SpecialAttack=4 Then Begin
                    For A:=1 To Num Do   { 65% monster can regenerate 1-2 hp}
                        If (CurrentMonStats[Mon[A].Name].SpecialAttack=4) And
                           ((Random(100)+1)<66) And (Mon[A].Hp>0) And (Mon[A].Hp
                           <CurrentMonStats[Mon[A].Name].HitPts) Then Begin
                           Mon[A].Hp:=Mon[A].Hp+Random(2)+1; End;
                    End;
If Player.MiscMagic=7 Then Begin
                      If (Player.MiscMagic=7) And (Stats in [21,22])
                                                 Then Stats:=Stats-20;
                      If (Player.MiscMagic=7) And (Stats in [31,32])
                                                 Then Stats:=Stats-30;
                      If (Player.MiscMagic=7) And (Stats in [41,42])
                                                 Then Stats:=Stats-40;
                      A:=Random(100)+1;
                      If (A>0) And (A<41) Then Stats:=Stats+20;
                      If (A>40) And (A<51) Then Stats:=Stats+40;
                      If (A>50) Then Stats:=Stats+30;
                      End;
Player.StepsWalked:=Player.StepsWalked+1;
If Player.StepsWalked>100 Then Begin
                               If (Player.MiscMagic=7) And (Stats in [21,22])
                                                 Then Stats:=Stats-20;
                               If (Player.MiscMagic=7) And (Stats in [31,32])
                                                 Then Stats:=Stats-30;
                               If (Player.MiscMagic=7) And (Stats in [41,42])
                                                 Then Stats:=Stats-40;
                               CancelMagic;
                               CombatStats;
                               End;
B:=0;
For A:=1 To Num Do
  Begin
  If (Mon[A].Hp<1) And (Stats<>2) Then B:=B+1;
  If (Stats in [2,21,22]) And ((Mon[A].X>10) Or (Mon[A].Y>9)) Then
    B:=B+1;
  End;
If (B=Num) Then Begin Com:=0;
                      CombatMessage('',1);
                      CombatMessage('Victory!!!!',1);
                      CombatMessage('',1);
                      If SoundOnOff Then CongratsSound;
                End;
If (B=Num) And (Stats in [2,21,22]) Then Com:=3;
If Player.Clife<1 Then Begin
                       Com:=1;
                       CombatMessage('',2);
                       CombatMessage('Battle Lost...',2);
                       CombatMessage('',2);
                       End;
Until Com<10;
GetOut:
KeyboardFlush;
B:=0;
If Player.MiscMagic In [7,8] Then CancelMagic;
For A := 1 to 8 Do
  If Mon[A].Hp>0 then B:=B+1;
Num:=B;
If ((CurrentMapType=3) and (Mon[1].name=12) And (Player.Xloc=98) and (Player.Yloc
in [93,94])) Then Num:=1;
If ((CurrentMapType=3) and (Mon[1].name=12) and (Mon[1].hp<=0) And
(Player.Xloc=98) and (Player.Yloc in [93,94])) Then begin Num:=0; com:=0; end;
If (Com=3) and (Num=0) then Com:=0;
If Com=3 then Stats:=2;
If Com=0 Then ComTreasure(CurrentMonStats[Mon[1].Name].TreasureType,
              CurrentMonStats[Mon[1].Name].Weapon,Armor,Num2);
Delay(500);
SetVisualPage(0);
SetActivePage(0);
ChangeStats(2);
Combat:=Com;
End;
End.