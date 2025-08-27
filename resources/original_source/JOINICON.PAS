Program JoinIconFile;
{Joins the icons in several icon files into one}

Var
  Infile : File;
  Outfile : File;
  InName, OutName : String[30];
  RecNumIn : Integer;
  RecNumOut : Integer;
  Icon : Array[1..18, 1..18] of Byte;
  IoCode : Byte;

Procedure Again;
Begin
REPEAT
  Writeln;
  Writeln('                           AGAIN           ');
  Writeln('Enter record number:  (-1 to exit) ');
  Readln(RecNumIn);
  If RecNumIn = -1 then Exit;
  Seek(Infile,RecNumIn);
  BlockRead(Infile,Icon,1);
  RecNumOut := FileSize(Outfile);
  Writeln('Enter record number to write: (',RecNumOut,') is first empty.');
  Readln(RecNumOut);
  Seek(Outfile,RecNumOut);
  BlockWrite(Outfile,Icon,1);
UNTIL FALSE;
End;

Begin
  Inname:='';
  OutName:='';
  Writeln('Enter file to read from, including path: ');
  Readln(Inname);
  Assign(Infile, Inname);
  Reset(Infile, 324);
  Writeln('Enter the record number: ');
  Readln(RecNumIn);
  Seek(Infile, RecNumIn);
  BlockRead(Infile,Icon,1);
  Writeln('Enter file to write to, including path: ');
  Readln(OutName);
{$I-}
  Assign(Outfile, OutName);
  Reset(Outfile, 324);
  IoCode := IOResult;
  If IoCode <> 0 Then
  Rewrite(Outfile,324);
{$I+}
  RecNumOut := FileSize(Outfile);
 Writeln('Record number to write to, ',RecNumOut,' is the first empty one.');
  Readln(RecNumOut);
  Seek(Outfile, RecNumOut);
  BlockWrite(Outfile,Icon,1);
  Again;
  Close(Infile);
  Close(Outfile);
End.

