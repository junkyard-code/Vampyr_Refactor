Program BoatMaker;
Type
  SetMonType = Array[1..25] Of Byte;
Var
  St : String[2];
  A : Byte;
  Infile : File;
  SetMon : SetMonType;
  FileNum : Integer;
  Ch : Byte;

Procedure AddIt;
Begin
{$I-}
  Assign(Infile,'c:\pascal\vampyr\Boat.Dat');
  reset(Infile, SizeOf(SetMon));
  If IOResult <> 0 Then
    ReWrite(Infile,SizeOf(SetMon));
{$I+}
    For A:=1 To 25 Do
    Begin
    Str(A,St);
    Write(St+' ');
    Readln(SetMon[A]);
    End;
    Writeln('Record number? (',FileSize(Infile),') is first empty.');
    Readln(FIleNum);
    Seek(Infile,FileNum);
    BlockWrite(Infile,SetMon,1);
End;

Procedure LoadIt;
Begin
  Assign(Infile,'c:\pascal\vampyr\Boat.dat');
  reset(Infile,SizeOf(SetMon));
  Writeln('Enter record number: ');
  readln(FileNum);
  Seek(Infile,FileNum);
  BlockRead(Infile,SetMon,1);
  Writeln;
  For A:=1 To 25 Do
  Begin
  Str(A,St);
   Writeln(St+' ',SetMon[A]);
  End;
End;

Procedure EditIt;
Var
  I : Byte;
Begin
  LoadIt;
  writeln;
  Writeln('Edit which field? (1-25)');
  Readln(I);
  Writeln('enter new stuff:');
  Readln(SetMon[I]);
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