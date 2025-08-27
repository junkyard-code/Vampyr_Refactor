Program ShowIcon;
{Print a CON file on screen}

USES
  Graph, Crt;
Var
  GraphDriver, GraphMode : Integer;
  Ch : Char;
  Infile : File;
  InName : String[30];

Procedure ReadIcon;
Var
  Icon : Array[1..18,1..18] of Byte;
  X, Y, PC : Byte;
  Count : Byte;
  XOver, YOver : Integer;
Begin
  ClearDevice;
  XOver:=0;
  YOver:=0;
  Assign(Infile, InName);
  Reset(Infile,324);
  For Count := 0 to (FileSize(Infile)-1) Do
    Begin
      If XOver >= 603 then
        Begin
          YOver := YOver+19;
          Xover:=0;
        End;
      Seek(Infile,Count);
      BlockRead(Infile, Icon, 1);
      For Y := 1 to 18 Do
        Begin
          For X := 1 to 18 Do
            Begin
              PC := Icon[X,Y];
              If PC <> 0 Then
                Begin
                  PutPixel(((X*2-1)+Xover),(Y+YOver),PC);
                  PutPixel(((X*2)+XOver),(Y+YOver),PC);
                End;
            End;
        End;
      Xover := Xover + 37;
  End;
  Close(Infile);
End;

{Main program!!!}
Begin
  InName:='';
  Writeln('Enter file name to read from, including path: ');
  Readln(InName);
  GraphDriver := 3;
  Graphmode := 0;
  InitGraph(GraphDriver,GraphMode,'');
  ReadIcon;
  Ch := ReadKey;
  CloseGraph;
End.