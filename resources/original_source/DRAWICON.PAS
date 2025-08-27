Program DrawPixel;
{Instructions:
   1) Cursor keys to move around.
   2) a, b, c, d... and so on to SELECT colors 0 - 15   *lower case*
   3) SPACE to actually plot on screen
   4) Ctrl - S to save
   5) Ctrl - L to load
   6) Ctrl - Z to exit

IMPORTANT NOTE: Enter RETURN at the filename prompt will default to the
                value previously entered                 }

USES
  Crt, Graph;

VAR
  GraphDriver, GraphMode : Integer;
  Ch : Char;
  Draw : Boolean;
  XLoc, YLoc : Integer;
  ColorNow : Integer;
  XLocStr : String[3];
  YLocStr : String[3];
  ColorStr : String[3];
  ClearW : Pointer;
  Size : Word;
  OutName, OutName1, InName, InName1 : String[30];
Procedure DrawBorder;
Begin
  ClearDevice;
  SetLineStyle(SolidLn, 0, NormWidth);
  SetColor(15);
  Rectangle(311, 90, 348, 109);
End;

Procedure ClearText;
Begin
  PutImage(1,192,ClearW^,NormalPut);
End;

Procedure LoadIcon;
Var
  Infile:File;
  Icon : Array[1..18,1..18] of Byte;
  X, Y, PC : Byte;
  RecordNum : Integer;
Begin
  InName1:=InName;
  ClearText;
  OutTextXY(110, 184,'Enter file name, including path: ');
  GotoXY(50,24);
  Readln(InName);
  If InName = '' Then InName:=InName1;
  PutImage(1,184,ClearW^,NormalPut);
  Assign(Infile, InName);
  Reset(Infile,324);
  OutTextXY(220,192,'Record number? ');
  GotoXY(45,25);
  Readln(RecordNum);
  DrawBorder;
  Seek(Infile,RecordNum);
  BlockRead(Infile, Icon, 1);
  Close(Infile);
  For Y := 1 to 18 Do
    Begin
      For X := 1 to 18 Do
        Begin
          PC := Icon[X,Y];
          If PC <> 0 Then Begin
            PutPixel((X*2)+310,(Y+90),PC);
            PutPixel((X*2)+311,(Y+90),PC);
            END;
        End;
    End;
End;

Procedure SaveIcon;
Var
  Infile : File;
  Icon : Array[1..18, 1..18] of Byte;
  X, Y : Byte;
  PC : Byte;
  IOCode : Integer;
  OutNum : Byte;
  OutNumStr : String[3];
Begin
  OutName1 := OutName;
  ClearText;
  OutTextXY(110,184,'Enter name, including path: ');
  GotoXY(48,24);
  Readln(OutName);
  If OutName = '' Then OutName := OutName1;
  PutImage(1,184,ClearW^,NormalPut);
{$I-}
  Assign(Infile, OutName);
  Reset(Infile,324);
  IOCode := IOResult;
  If IOCode <> 0 Then
    Rewrite(Infile,324);
{$I+}
  OutNum:=FileSize(Infile);
  Str(OutNum, OutNumStr);
  OutTextXY(150,184,'Enter record number, '+OutNumStr+' is first empty: ');
  GotoXY(65,24);
  Readln(OutNum);
  PutImage(1,184,ClearW^,NormalPut);
  For X := 1 to 18 Do
    For Y := 1 to 18 Do
      Icon[X,Y] := 0;
  For Y := 1 to 18 Do
    Begin
      For X := 1 to 18 Do
        Begin
          PC := GetPixel(310+(X*2),90+Y);
          Icon[X,Y] := PC;
        End;
    End;
  Seek(Infile, OutNum);
  BlockWrite(Infile,Icon,1);
  Close(Infile);
End;

{               MAIN !!!       }
Begin
  Draw:=False;
  XLoc := 1;
  YLoc := 1;
  OutName:='';
  OutName1 := '';
  InName := '';
  InName1 := '';
  ColorNow := 0;
  GraphDriver := 3;
  GraphMode := 0;
  InitGraph(GraphDriver, GraphMode,'');
  Size:=ImageSize(1,192,GetMaxX,GetMaxY);
  GetMem(ClearW,Size);
  GetImage(1,192,GetMaxX,GetMaxY,ClearW^);
  DrawBorder;
  REPEAT
    Ch := ReadKey;
    Case Ord(Ch) Of
    80 : Begin
           If YLoc = 18 Then
             Begin
               ClearText;
               OutTextXY(220,192,'Out of range!');
             End
           Else
             YLoc := YLoc +1;
         End;
    72 : Begin
           If YLoc = 1 Then
             Begin
               ClearText;
               OutTextXY(220,192,'Out of range!');
             End
           Else
             YLoc := YLoc -1;
         End;
    77 : Begin
           If XLoc = 18 Then
             Begin
               ClearText;
               OutTextXY(220,192,'Out of range!');
             End
           Else
             XLoc := XLoc +1;
         End;
    75 : Begin
           If XLoc = 1 Then
             Begin
               ClearText;
               OutTextXY(220,192,'Out of range!');
             End
           Else
             XLoc := XLoc -1;
         End;
    12 : LoadIcon;
    97 : ColorNow := 0;
    98 : ColorNow := 1;
    99 : ColorNow := 2;
    100 : ColorNow := 3;
    101 : ColorNow := 4;
    102 : ColorNow := 5;
    103 : ColorNow := 6;
    104 : ColorNow := 7;
    105 : ColorNow := 8;
    106 : ColorNow := 9;
    107 : ColorNow := 10;
    108 : ColorNow := 11;
    109 : ColorNow := 12;
    110 : ColorNow := 13;
    111 : ColorNow := 14;
    112 : ColorNow := 15;
    59  : If Draw=False Then Draw:=True Else Draw:=False;
    60  : Begin
          For XLoc:=1 to 18 do
           For YLoc:=1 to 18 do
              Begin
              Putpixel((Xloc*2)+310,90+Yloc,0);
              Putpixel((Xloc*2)+311,90+Yloc,0);
              End;
         XLoc:=1; YLoc:=1;
         End;
    19 : SaveIcon;
  End;
  If (CH=' ') OR (Draw=True) THEN BEGIN
    PutPixel(310+(XLoc*2),90+YLoc,ColorNow);
    PutPixel(311+(XLoc*2),90+YLoc,ColorNow);
    END;
  Str(XLoc, XLocStr);
  Str(YLoc, YLocStr);
  Str(ColorNow,ColorStr);
  ClearText;
  OutTextXY(220,192,'X : '+XLocStr+ '  Y : '+YLocStr+ '  Color : '+ColorStr);
  Until Ord(Ch) = 26;
  FreeMem(ClearW,Size);
  CloseGraph;
End.

