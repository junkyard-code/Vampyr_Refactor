Program Animate;
{Animation for icons}

USES
  Graph, Crt;

Var
  Infile : File;
  X,Y : Byte;
  InName : String[30];
  Rec1, Rec2, Rec3, Rec4, PC : Byte;
  GraphDriver, GraphMode : Integer;
  Icon : Array[1..18, 1..18] Of Byte;
  Size:Word;
  P1,P2,P3,P4 : Pointer;

Procedure ReadIn;
Begin
  BlockRead(Infile,Icon,1);
  For Y := 1 to 18 Do
    Begin
      For X := 1 to 18 Do
        Begin
          PC := Icon[X,Y];
          If PC <> 0 Then
            Begin
              PutPixel(X*2-1,Y,PC);
              PutPixel(X*2,Y,PC);
            End;
        End;
    End;
End;

Begin
  GraphDriver := 3;
  GraphMode := 0;
  InName :='';
  Writeln('Enter the filename, including the path: ');
  Readln(InName);
  Assign(Infile,InName);
  Reset(Infile,324);
  Writeln('Enter record number for the first picture: ');
  Readln(Rec1);
  Writeln('Enter record number for the second picture: ');
  Readln(Rec2);
  Writeln('Enter record number for the first picture2: ');
  Readln(Rec3);
  Writeln('Enter record number for the second picture2: ');
  Readln(Rec4);
  InitGraph(GraphDriver, GraphMode, '');
  Size := ImageSize(1,1,36,18);
  Seek(Infile,Rec1);
  SetActivePage(3);
  ReadIn;
  GetMem(P1,Size);
  GetImage(1,1,36,18,P1^);
  PutImage(1,1,P1^,XorPut);
  Seek(Infile,Rec2);
  ReadIn;
  GetMem(P2,Size);
  GetImage(1,1,36,18,P2^);
  PutImage(1,1,P2^,XorPut);
  Seek(Infile,Rec3);
  ReadIn;
  GetMem(P3,Size);
  GetImage(1,1,36,18,P3^);
  PutImage(1,1,P3^,XorPut);
  Seek(Infile,Rec4);
  ReadIn;
  Close(Infile);
  GetMem(P4,Size);
  GetImage(1,1,36,18,P4^);
  PutImage(1,1,P4^,XorPut);
  SetActivePage(0);
  REPEAT
    PutImage(284,91,P1^,NormalPut);
    PutImage(320,91,P3^,NormalPut);
    Delay(500);
    PutImage(284,91,P2^,NormalPut);
    PutImage(320,91,P4^,NormalPut);
    Delay(500);
  Until KeyPressed;
  FreeMem(P1,Size);
  FreeMem(P2,Size);
  FreeMem(P3,Size);
  FreeMem(P4,Size);
  CloseGraph;
End.