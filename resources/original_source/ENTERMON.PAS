Program EnterMonster;
{Enter names and stats of monster.}
{Status: 0 - Ambush
         1 - Attack
         2 - Run
         3 - Steal
         4 - Stand
         5 - Wander
 TreasureType: 1 - sucky treasure
               2 - ok treasure
               3 - awesome treasure
 SpecialAttack: 0 - None
                1 - Fireball
                               }

Type
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
                  TreasureType : Byte;
                  SpecialAttack : Byte;
                End;

Var
  Infile : File;
  Fname : string[30];
  Monster:MonsterType;
  FileNum : String[3];
  X, Menu : Byte;

Procedure SaveIt;
Begin
  Writeln('Enter file name w/ path: ');
  Readln(Fname);
{$I-}
  Assign(Infile, Fname);
  Reset(Infile,SizeOf(Monster));
  If IOResult <> 0 Then
    ReWrite(Infile, SizeOf(Monster));
{$I+}
  REPEAT
    Writeln('Enter NAME: (0 to exit) ');
    Readln(Monster.Name);
    If Monster.Name = '0' then
    Begin
      Close(Infile);
      exit;
    End;
    Writeln('Enter HITPTS: ');
    Readln(Monster.HitPts);
    Writeln('Enter XPVAL: ');
    Readln(Monster.XPVal);
    Writeln('Enter OFFENSIVE:');
    Readln(Monster.Offensive);
    Writeln('Enter DEFENSIVE:');
    Readln(Monster.Defensive);
    Writeln('Enter WEAPON: ');
    Readln(Monster.Weapon);
    Writeln('Enter ARMOR: ');
    Readln(Monster.Armor);
    Writeln('Enter MAXNUMINGROUP: ');
    Readln(Monster.MaxNumInGroup);
    Writeln('Enter MAGICRES: ');
    Readln(Monster.MagicRes);
    WRITELN('Enter TREASURETYPE: ');
    Readln(Monster.TreasureType);
    Writeln('Enter SPECIALATTACK:');
    Readln(Monster.SpecialAttack);
    Str(FileSize(Infile), FileNum);
    Writeln('Save as what record? ('+FileNum+') is the first empty');
    Readln(X);
    Seek(Infile,X);
    BlockWrite(Infile,Monster,1);
  Until False;
End;

Procedure LoadIt;
Begin
  Writeln('Enter file name w/ path: ');
  Readln(Fname);
  Assign(Infile, Fname);
  Reset(Infile,SizeOf(monster));
  Writeln('Record number? ');
  Readln(X);
  Seek(Infile,X);
  BlockRead(Infile, Monster,1);
  Close(Infile);
  With Monster Do
    Begin
      Writeln('Name: ',Name);
      Writeln('HitPts: ',HitPts);
      Writeln('XPVal: ',XPVal);
      Writeln('Offensive: ',Offensive);
      Writeln('Defensive: ',Defensive);
      Writeln('Weapon: ',Weapon);
      Writeln('Armor: ',Armor);
      Writeln('MaxNumInGroup: ',MaxNumInGroup);
      Writeln('MagicRes: ',MagicRes);
      Writeln('TreasureType: ',TreasureType);
      Writeln('SpecialAttack: ',SpecialAttack);
    End;
End;

Begin
  REPEAT
    Writeln;
    Writeln(' (1) to add new monsters');
    Writeln(' (2) to look at monsters');
    Writeln(' (3) to exit');
    Writeln;
    Readln(Menu);
    Case Menu of
    1 : SaveIt;
    2 : LoadIt;
    End;
  Until Menu = 3;
End.


