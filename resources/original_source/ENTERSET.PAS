Program EnterSetEncounter;
Type
  SetMonType = Record
                 MonsterName : Byte;
                 Status : Byte;
                 NumInGroup : Byte;
                 X,Y : Byte;
                 Msg1, Msg2 : String[70];
               End;
Var
  Infile : File;
  SetMon : SetMonType;
  FileNum : Integer;
  Ch : Byte;

Procedure AddIt;
Begin
{$I-}
  Assign(Infile,'c:\pascal\vampyr\enconter.set');
  reset(Infile, SizeOf(SetMon));
  If IOResult <> 0 Then
    ReWrite(Infile,SizeOf(SetMon));
{$I+}
  Repeat
    Writeln('Enter MONSTERNAME: (255 to exit) ');
    Readln(SetMon.MonsterName);
    If SetMon.MonsterName = 255 Then
      Begin
        Close(Infile);
        Exit;
      End;
    Writeln('Enter STATUS: ');
    Readln(SetMon.Status);
    Writeln('Enter NUMINGROUP: ');
    Readln(SetMon.NumInGroup);
    Writeln('Enter X: ');
    Readln(SetMon.X);
    Writeln('Enter Y: ');
    Readln(SetMon.Y);
    Writeln('Enter MSG1: ');
    Readln(SetMon.Msg1);
    Writeln('Enter MSG2: ');
    Readln(SetMon.Msg2);
    Writeln('Record number? (',FileSize(Infile),') is first empty.');
    Readln(FIleNum);
    Seek(Infile,FileNum);
    BlockWrite(Infile,SetMon,1);
  Until False;
End;

Procedure LoadIt;
Begin
  Assign(Infile,'c:\pascal\vampyr\enconter.set');
  reset(Infile,SizeOf(SetMon));
  Writeln('Enter record number: ');
  readln(FileNum);
  Seek(Infile,FileNum);
  BlockRead(Infile,SetMon,1);
  Writeln;
  With SetMon Do
    Begin
      Writeln(MonsterName);
      Writeln(Status);
      Writeln(NumInGroup);
      Writeln(X);
      Writeln(Y);
      Writeln(Msg1);
      Writeln(Msg2);
    End;
End;

Procedure EditIt;
Var
  I : Byte;
Begin
  LoadIt;
  writeln;
  Writeln('Edit which field? (0-6)');
  Readln(I);
  Writeln('enter new stuff:');
  If I = 0 then Readln(SetMon.MonsterName);
  If I = 1 then readln(SetMon.Status);
  If I = 2 then readln(SetMon.NumInGroup);
  If I = 3 then Readln(SetMon.X);
  If I = 4 then readln(SetMon.Y);
  If I = 5 then Readln(SetMon.Msg1);
  If I = 6 then readln(SetMon.Msg2);
  Seek(Infile,FileNum);
  BlockWrite(Infile,SetMon,1);
  Close(Infile);
End;

Begin
  Repeat
    Writeln;
    Writeln(' (1) to add');
    Writeln(' (2) to look');
    Writeln(' (3) to edit');
    Writeln(' (4) to exit');
    Readln(Ch);
    Case Ch of
    1 : AddIt;
    2 : Begin LoadIt; close(Infile); end;
    3 : EditIt;
    End;
  Until Ch = 4;
End.