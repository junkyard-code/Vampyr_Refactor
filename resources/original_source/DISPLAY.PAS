Unit Display;
Interface
Uses Global, Music, Graph, Crt;
Procedure DisplayBlock;
Procedure AnimateMonster(JobNum : Byte);
Procedure DisplayMap(VAR X,Y:Byte);
Procedure DisplayLand(Var X,Y : Byte);
Procedure AnimateMap(JobNum : Byte);
Procedure Blockit(Var X,Y: Byte);
Procedure DisplayMonster(Direct:Byte);
Implementation
Procedure DisplayBlock;
Var A : Byte;
    S : Array[3..5,3..5] Of Boolean;

Begin
For A:=1 To 7 Do                                 { 3th loop }
  Begin
  If BooMap[A,1]=False Then BooMap[A,1]:=True;
  If BooMap[A,7]=False Then BooMap[A,7]:=True;
  If BooMap[1,A]=False Then BooMap[1,A]:=True;
  If BooMap[7,A]=False Then BooMap[7,A]:=True;
  End;
For A:=3 To 5 Do                                { 1st loop }
  Begin
  S[A,3]:=BooMap[A,3];
  S[A,4]:=BooMap[A,4];
  S[A,5]:=BooMap[A,5];
  BooMap[A,3]:=True;
  BooMap[A,4]:=True;
  BooMap[A,5]:=True;
  End;
If S[3,3]=False Then Begin
                     BooMap[2,2]:=False;
                     BooMap[3,2]:=False;
                     BooMap[2,3]:=False;
                     End;
If S[4,3]=False Then BooMap[4,2]:=False;
If S[5,3]=False Then Begin
                     BooMap[6,2]:=False;
                     BooMap[5,2]:=False;
                     BooMap[6,3]:=False;
                     End;
If S[5,4]=False Then BooMap[6,4]:=False;
If S[5,5]=False Then Begin
                     BooMap[6,6]:=False;
                     BooMap[6,5]:=False;
                     BooMap[5,6]:=False;
                     End;
If S[4,5]=False Then BooMap[4,6]:=False;
If S[3,5]=False Then Begin
                     BooMap[2,6]:=False;
                     BooMap[2,5]:=False;
                     BooMap[3,6]:=False;
                     End;
If S[3,4]=False Then BooMap[2,4]:=False;
If BooMap[2,2]=False Then Begin                  { 2nd loop }
                          BooMap[1,2]:=False;
                          BooMap[1,1]:=False;
                          BooMap[2,1]:=False;
                          If S[3,3]=True Then BooMap[2,2]:=True;
                          End;
If BooMap[3,2]=False Then Begin
                          BooMap[2,1]:=False;
                          BooMap[3,1]:=False;
                          If S[3,3]=True Then BooMap[3,2]:=True;
                          End;
If BooMap[4,2]=False Then Begin
                          BooMap[4,1]:=False;
                          BooMap[3,1]:=False;
                          BooMap[5,1]:=False;
                          If S[4,3]=True Then BooMap[4,2]:=True;
                          End;
If BooMap[5,2]=False Then Begin
                          BooMap[5,1]:=False;
                          BooMap[6,1]:=False;
                          If S[5,3]=True Then BooMap[5,2]:=True;
                          End;
If BooMap[6,2]=False Then Begin
                          BooMap[6,1]:=False;
                          BooMap[7,1]:=False;
                          BooMap[7,2]:=False;
                          If S[5,3]=True Then BooMap[6,2]:=True;
                          End;
If BooMap[6,3]=False Then Begin
                          BooMap[7,2]:=False;
                          BooMap[7,3]:=False;
                          If S[5,3]=True Then BooMap[6,3]:=True;
                          End;
If BooMap[6,4]=False Then Begin
                          BooMap[7,4]:=False;
                          BooMap[7,3]:=False;
                          BooMap[7,5]:=False;
                          If S[5,4]=True Then BooMap[6,4]:=True;
                          End;
If BooMap[6,5]=False Then Begin
                          BooMap[7,5]:=False;
                          BooMap[7,6]:=False;
                          If S[5,5]=True Then BooMap[6,5]:=True;
                          End;
If BooMap[6,6]=False Then Begin
                          BooMap[7,6]:=False;
                          BooMap[7,7]:=False;
                          BooMap[6,7]:=False;
                          If S[5,5]=True Then BooMap[6,6]:=True;
                          End;
If BooMap[5,6]=False Then Begin
                          BooMap[5,7]:=False;
                          BooMap[6,7]:=False;
                          If S[5,5]=True Then BooMap[5,6]:=True;
                          End;
If BooMap[4,6]=False Then Begin
                          BooMap[4,7]:=False;
                          BooMap[3,7]:=False;
                          BooMap[5,7]:=False;
                          If S[4,5]=True Then BooMap[4,6]:=True;
                          End;
If BooMap[3,6]=False Then Begin
                          BooMap[3,7]:=False;
                          BooMap[2,7]:=False;
                          If S[3,5]=True Then BooMap[3,6]:=True;
                          End;
If BooMap[2,6]=False Then Begin
                          BooMap[1,6]:=False;
                          BooMap[1,7]:=False;
                          BooMap[2,7]:=False;
                          If S[3,5]=True Then BooMap[2,6]:=True;
                          End;
If BooMap[2,5]=False Then Begin
                          BooMap[1,5]:=False;
                          BooMap[1,6]:=False;
                          If S[3,5]=True Then BooMap[2,5]:=True;
                          End;
If BooMap[2,4]=False Then Begin
                          BooMap[1,4]:=False;
                          BooMap[1,3]:=False;
                          BooMap[1,5]:=False;
                          If S[3,4]=True Then BooMap[2,4]:=True;
                          End;
If BooMap[2,3]=False Then Begin
                          BooMap[1,3]:=False;
                          BooMap[1,2]:=False;
                          If S[3,3]=True Then BooMap[2,3]:=True;
                          End;
End;

Procedure AnimateMonster(JobNum : Byte);
Var
  X : Byte;
Begin
If CurrentMapType = 1 then
             Begin
             OriA := Player.YLoc-3;
             OriB := Player.XLoc-3;
             End
             Else
             Begin
             OriA := TempYLoc-3;
             OriB := TempXLoc-3;
             End;
If CurrentMapType in [1,3] Then
  Begin
    For X := 1 to 3 Do
      If (CurrentMonMem[X] <> Nil) Then
        Begin
          If ((CurrentMonMem[X]^.X in [OriB..OriB+6]) AND
             (CurrentMonMem[X]^.Y in [OriA..OriA+6])) AND
          (BooMap[CurrentMonMem[X]^.X-OriB+1,CurrentMonMem[X]^.Y-OriA+1]=True)
              Then Begin
                 If JobNum =3 then JobNum:=2 else Delay(170);
                 Case JobNum of
                 1 : PutImage((CurrentMonMem[X]^.X-OriB)*36+6,
                     (CurrentMonMem[X]^.Y-OriA)*18+3,CurrentMonPics[(
                     CurrentMonMem[X]^.MonsterName)+13]^,NormalPut);
                 2 : PutImage((CurrentMonMem[X]^.X-OriB)*36+6,
                     (CurrentMonMem[X]^.Y-OriA)*18+3,CurrentMonPics[(
                     CurrentMonMem[X]^.MonsterName)]^,NormalPut);
                 End;
               End;
        End;
  End;
If CurrentMapType in [2,3,4] Then
  Begin
    For X := 0 to 24 Do
      If (CurrentMonSet[X] <> Nil) Then
        Begin
          If ((CurrentMonSet[X]^.X in [OriB..OriB+6]) AND
             (CurrentMonSet[X]^.Y in [OriA..OriA+6])) AND
          (BooMap[CurrentMonSet[X]^.X-OriB+1,CurrentMonSet[X]^.Y-OriA+1]=True)
              Then Begin
                 If JobNum=3 then JobNum:=2 else Delay(170);
                 Case JobNum of
                 1 : PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                     (CurrentMonSet[X]^.Y-OriA)*18+3,CurrentMonPics[(
                     CurrentMonSet[X]^.MonsterName)+13]^,NormalPut);
                 2 : PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                     (CurrentMonSet[X]^.Y-OriA)*18+3,CurrentMonPics[(
                     CurrentMonSet[X]^.MonsterName)]^,NormalPut);
                 End;
              End;
        End;
  End;
End;

Procedure DisplayMap(VAR X,Y:Byte);
{Input: A map under the variable CurrentMap.  A changed CurrentDisObs}
Var
  XCount, YCount : Byte;
  OriX, OriY : Byte;
Begin
  OriX := X-3;
  OriY := Y-3;
  For YCount := (Y-3) to (Y+3) Do
    For XCount := (X-3) to (X+3) Do
      If ((XCount <> X) or (YCount <> Y)) Then
      Case CurrentMap^[XCount,YCount] of
      0..7 : If (BooMap[XCount-OriX+1,YCount-OriY+1] = True)
             Then PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
             UnivIcon[(CurrentMap^[XCount,YCount])]^,NormalPut)
             Else PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
             EmptyIcon^,NormalPut);
      8..27 : If (BooMap[XCount-OriX+1,YCount-OriY+1] = True)
              Then PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
              CurrentMapIcon[(CurrentMap^[XCount,YCount])-8]^,NormalPut)
              Else PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
              EmptyIcon^,NormalPut);
      28    : If (BooMap[XCount-OriX+1,YCount-OriY+1] = False) Then
              PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,EmptyIcon^,
              NormalPut);
      End;
End;

Procedure DisplayLand(Var X,Y : Byte);
{Input: A map under the variable LandMap.  A changed CurrentDisObs}
Var
  XCount, YCount : Byte;
  OriX, OriY : Byte;
Begin
  OriX := X-3;
  OriY := Y-3;
  For YCount := (Y-3) to (Y+3) Do
    For XCount := (X-3) to (X+3) Do
      If ((XCount <> X) or (YCount <> Y)) Then
      Case LandMap^[XCount,YCount] of
      0..6 : If (BooMap[XCount-OriX+1,YCount-OriY+1] = True)
             Then PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
             UnivIcon[(LandMap^[XCount,YCount])]^,NormalPut)
             Else PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
             EmptyIcon^,NormalPut);
      7..21 : If (BooMap[XCount-OriX+1,YCount-OriY+1] = True)
              Then PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
              CurrentMapIcon[(LandMap^[XCount,YCount])-7]^,NormalPut)
              Else PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
              EmptyIcon^,NormalPut);
         28 : If (BooMap[XCount-OriX+1,YCount-OriY+1] = False) then
              PutImage((XCount-OriX)*36+6,(YCount-OriY)*18+3,
              EmptyIcon^,NormalPut);
      End;
End;

Procedure AnimateMap(JobNum : Byte);
Var
A,B : Byte;
Begin
  Case CurrentMapType Of
    1 : Begin
          For A := (Player.YLoc-3) to (Player.YLoc+3) Do
            For B := (Player.XLoc-3) to (Player.XLoc+3) Do
              If ((A <> Player.YLoc) or (B <> Player.Xloc)) AND
              (BooMap[B-OriB+1,A-OriA+1] = True) Then
                Begin
                  Case JobNum of
                  1 : Begin
                       If LandMap^[B,A] in [0,1] Then
                       PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                       [(LandMap^[B,A]+12)]^,NormalPut);
                       If LandMap^[B,A] in [7,8,9,10,11] Then
                       PutImage((B-OriB)*36+6,(A-OriA)*18+3,CurrentMapIcon
                       [(LandMap^[B,A]+8)]^,NormalPut);
                      End;
                  2 : Begin
                       If LandMap^[B,A] in [0,1] Then
                       PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                       [(LandMap^[B,A])]^,NormalPut);
                       If LandMap^[B,A] in [7,8,9,10,11] Then
                       PutImage((B-OriB)*36+6,(A-OriA)*18+3,CurrentMapIcon
                       [(LandMap^[B,A]-7)]^,NormalPut);
                      End;
                  End;
                End;
        End;
  4   : Begin
        For A := (TempYloc-3) to (TempYLoc+3) Do
          For B := (TempXLoc-3) to (TempXLoc+3) Do
            If ((A <> TempYLoc) or (B <> TempXloc)) AND
            (BooMap[B-OriB+1,A-OriA+1] = True) Then
              Begin
                Case JobNum of
                1 : Begin
                     If CurrentMap^[B,A] in [0,1] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                     [(CurrentMap^[B,A]+12)]^,NormalPut);
                     If CurrentMap^[B,A] = 8 Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,CurrentMapIcon
                     [19]^,NormalPut);
                    End;
                2 : Begin
                     If CurrentMap^[B,A] in [0,1] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                     [(CurrentMap^[B,A])]^,NormalPut);
                     If CurrentMap^[B,A] = 8 Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,CurrentMapIcon
                     [0]^,NormalPut);
                    End;
                End;
            End;
       End;
  2   : Begin
        For A := (TempYloc-3) to (TempYLoc+3) Do
          For B := (TempXLoc-3) to (TempXLoc+3) Do
            If ((A <> TempYLoc) or (B <> TempXloc)) AND
            (BooMap[B-OriB+1,A-OriA+1] = True) Then
              Begin
                Case JobNum of
                1 :  If CurrentMap^[B,A] in [0,1] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                     [(CurrentMap^[B,A]+12)]^,NormalPut);
                2 :  If CurrentMap^[B,A] in [0,1] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                     [(CurrentMap^[B,A])]^,NormalPut);
                End;
              End;
        End;
  3 : Begin
        For A := (TempYloc-3) to (TempYLoc+3) Do
          For B := (TempXLoc-3) to (TempXLoc+3) Do
            If ((A <> TempYLoc) or (B <> TempXloc)) AND
            (BooMap[B-OriB+1,A-OriA+1] = True) Then
              Begin
                Case JobNum of
                1 : Begin
                     If CurrentMap^[B,A] in [0,1] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                     [(CurrentMap^[B,A]+12)]^,NormalPut);
                     If CurrentMap^[B,A] in [8,9] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,CurrentMapIcon
                     [(CurrentMap^[B,A]+10)]^,NormalPut);
                    End;
                2 : Begin
                     If CurrentMap^[B,A] in [0,1] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,UnivIcon
                     [(CurrentMap^[B,A])]^,NormalPut);
                     If CurrentMap^[B,A] in [8,9] Then
                     PutImage((B-OriB)*36+6,(A-OriA)*18+3,CurrentMapIcon
                     [(CurrentMap^[B,A]-8)]^,NormalPut);
                    End;
                End;
              End;
      End;
  End;   {CASE}
End;      {Procedure}

Procedure Blockit(Var X,Y: Byte);
Var XCount,YCount : Byte;
Begin
Case CurrentMapType of
2,3,4 : Begin
      For YCount := (Y-3) to (Y+3) Do
        For XCount := (X-3) to (X+3) Do
          Begin
              If CurrentDisObs[(CurrentMap^[XCount,YCount])] = True Then
                BooMap[XCount-(X-3)+1,YCount-(Y-3)+1] := False
              Else BooMap[XCount-(X-3)+1,YCount-(Y-3)+1] := True;
          End;
    End;
1 : Begin
          For YCount := (Y-3) to (Y+3) Do
            For XCount := (X-3) to (X+3) Do
              Begin
                IF CurrentDisObs[(LandMap^[XCount,YCount])] = True Then
                  BooMap[XCount-(X-3)+1,YCount-(Y-3)+1] := False
                Else BooMap[XCount-(X-3)+1,YCount-(Y-3)+1]:=True;
              End;
    End;
End;
  DisplayBlock;
End;

Procedure DisplayMonster(Direct:Byte);
Var X :Byte;
Begin
  If CurrentMapType in [2,4,3] Then
    Begin
      For X := 0 to 24 Do
        If (CurrentMonSet[X] <> Nil) Then
          Begin
            If ((CurrentMonSet[X]^.X in [OriB..OriB+6]) AND
               (CurrentMonSet[X]^.Y in [OriA..OriA+6])) AND
            (BooMap[CurrentMonSet[X]^.X-OriB+1,CurrentMonSet[X]^.Y-OriA+1]=True)
                Then Begin
                  PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                  (CurrentMonSet[X]^.Y-OriA)*18+3,CurrentMonPics[(
                  CurrentMonSet[X]^.MonsterName)]^,NormalPut);
                  Case Direct of
                  2 : If (CurrentMonSet[X]^.Y-OriA<6) AND (CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y+1] <> 28) Then
                      Begin
                      If (CurrentMap^[CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y+1] >=8) Then
                      PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                      (CurrentMonSet[X]^.Y-OriA+1)*18+3,CurrentMapIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y+1])-8]^,NormalPut) Else
                      PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                      (CurrentMonSet[X]^.Y-OriA+1)*18+3,UnivIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y+1])]^,NormalPut);
                      end;
                  8 : If (CurrentMonSet[X]^.Y-OriA>0) AND (CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y-1] <> 28) Then
                      Begin
                      If (CurrentMap^[CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y-1] >=8) Then
                      PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                      (CurrentMonSet[X]^.Y-OriA-1)*18+3,CurrentMapIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y-1])-8]^,NormalPut) Else
                      PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                      (CurrentMonSet[X]^.Y-OriA-1)*18+3,UnivIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y-1])]^,NormalPut);
                      End;
                  4 : If (CurrentMonSet[X]^.X-OriB>0) AND (CurrentMap^
                      [CurrentMonSet[X]^.X-1,CurrentMonSet[X]^.Y] <> 28) Then
                      Begin
                      If (CurrentMap^[CurrentMonSet[X]^.X-1,CurrentMonSet[X]^.Y] >=8) Then
                      PutImage((CurrentMonSet[X]^.X-OriB-1)*36+6,
                      (CurrentMonSet[X]^.Y-OriA)*18+3,CurrentMapIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X-1,CurrentMonSet[X]^.Y])-8]^,NormalPut) Else
                      PutImage((CurrentMonSet[X]^.X-OriB-1)*36+6,
                      (CurrentMonSet[X]^.Y-OriA)*18+3,UnivIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X-1,CurrentMonSet[X]^.Y])]^,NormalPut);
                      End;
                  6 : If (CurrentMonSet[X]^.X-OriB<6) And (CurrentMap^
                      [CurrentMonSet[X]^.X+1,CurrentMonSet[X]^.Y] <> 28) Then
                      Begin
                      If (CurrentMap^[CurrentMonSet[X]^.X+1,CurrentMonSet[X]^.Y] >= 8) Then
                      PutImage((CurrentMonSet[X]^.X-OriB+1)*36+6,
                      (CurrentMonSet[X]^.Y-OriA)*18+3,CurrentMapIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X+1,CurrentMonSet[X]^.Y])-8]^,NormalPut) Else
                      PutImage((CurrentMonSet[X]^.X-OriB+1)*36+6,
                      (CurrentMonSet[X]^.Y-OriA)*18+3,UnivIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X+1,CurrentMonSet[X]^.Y])]^,NormalPut);
                      End;
                  Else If ((CurrentMonSet[X]^.X-OriB<6) AND (CurrentMonSet[X]^.X-OriB>0)
                      And (CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y] <> 28)) Or
                      ((CurrentMonSet[X]^.Y-OriA<6) AND (CurrentMonSet[X]^.Y-OriA>0)
                      And (CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y] <> 28)) Then
                      Begin
                      If (CurrentMap^[CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y] >= 8) Then
                      PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                      (CurrentMonSet[X]^.Y-OriA)*18+3,CurrentMapIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y])-8]^,NormalPut) Else
                      PutImage((CurrentMonSet[X]^.X-OriB)*36+6,
                      (CurrentMonSet[X]^.Y-OriA)*18+3,UnivIcon[(CurrentMap^
                      [CurrentMonSet[X]^.X,CurrentMonSet[X]^.Y])]^,NormalPut);
                      End;
                  End;
              End;
          End;
    End;
  If CurrentMapType=3 then
    Begin
      For X := 1 to 3 Do
      If (CurrentMonMem[X] <> Nil) Then
        Begin
          If ((CurrentMonMem[X]^.X in [OriB..OriB+6]) AND
             (CurrentMonMem[X]^.Y in [OriA..OriA+6])) AND
          (BooMap[CurrentMonMem[X]^.X-OriB+1,CurrentMonMem[X]^.Y-OriA+1]=True)
              Then PutImage((CurrentMonMem[X]^.X-OriB)*36+6,
                   (CurrentMonMem[X]^.Y-OriA)*18+3,CurrentMonPics[(
                   CurrentMonMem[X]^.MonsterName)]^,NormalPut);
        End;
    End;
End;
End.