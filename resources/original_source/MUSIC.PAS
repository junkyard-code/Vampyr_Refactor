Unit Music;

INTERFACE
  USES Crt;

  Procedure TitleSong;
  Procedure RipSound;
  Procedure ReallyDeadSound;
  Procedure ScarySound;
  Procedure TwZoneSound;
  Procedure CongratsSound;
  Procedure MagicSound;
  Procedure MagicSound2;
  Procedure MagicSound3;
  Procedure CrunchSound;
  Procedure ScrollSound;
  Procedure MissSound;
  Procedure PunchSound;
  Procedure BattleCrySound;
  Procedure BattleCrySound2;
  Procedure SirenSound;

IMPLEMENTATION

PROCEDURE PlayNote(NoteNum:Integer; Duration:Integer;
                    NoSoundFor:Integer);
{Try not to mess around with this procedure.  I have pretty much all
 the notes in tune.  }
Begin
  Case NoteNum of
  1 : Sound(100);
  2 : sound(112);
 29 : Sound(120);
  3 : sound(128);
  4 : sound(134);
 49 : Sound(140);
  5 : sound(151);
  6 : sound(169);
  7 : sound(187);
  8 : sound(200);
  11 : Sound(257);
  12 : Sound(290);
  13 : Sound(328);
  14 : Sound(343);
  15 : Sound(389);        {Used to be 387}
  16 : Sound(438);
  17 : Sound(491);  {475}
  18 : Sound(520);
  21 : Sound(512);
  22 : Sound(574);
  23 : Sound(656);
  24 : Sound(687);
  25 : Sound(774);
  26 : Sound(866);
  27 : Sound(958);
  28 : Sound(1040);
  end;
  Delay(Duration);
  If NoSoundFor <> 0 then
    Begin
      Nosound;
      Delay(NoSoundFor);
    End;
end;

Procedure TitleSong;
Begin
  If Not Keypressed Then PlayNote(3,150,20) Else Exit;
  If Not Keypressed Then PlayNote(3,150,20) Else Exit;
  If Not Keypressed Then PlayNote(3,150,20) Else Exit;
  If Not Keypressed Then PlayNote(1,1200,600) Else Exit;
  If Not Keypressed Then PlayNote(2,150,20) Else Exit;
  If Not Keypressed Then PlayNote(2,150,20) Else Exit;
  If Not Keypressed Then PlayNote(2,150,20) Else Exit;
  Sound(94);
  Delay(1200);
  Nosound;
  Delay(600);
  If Not Keypressed Then PlayNote(3,110,20) Else Exit;
  If Not Keypressed Then PlayNote(3,110,20) Else Exit;
  If Not Keypressed Then PlayNote(3,110,20) Else Exit;
  If Not Keypressed Then PlayNote(1,110,40) Else Exit;
  If Not Keypressed Then PlayNote(4,110,20) Else Exit;
  If Not Keypressed Then PlayNote(4,110,20) Else Exit;
  If Not Keypressed Then PlayNote(4,110,20) Else Exit;
  If Not Keypressed Then PlayNote(3,110,40) Else Exit;
  If Not Keypressed Then PlayNote(15,110,20) Else Exit;
  If Not Keypressed Then PlayNote(15,110,20) Else Exit;
  If Not Keypressed Then PlayNote(15,110,20) Else Exit;
  If Not Keypressed Then PlayNote(13,400,235) Else Exit;
  If Not Keypressed Then PlayNote(3,110,20) Else Exit;
  If Not Keypressed Then PlayNote(3,110,20) Else Exit;
  If Not Keypressed Then PlayNote(3,110,20) Else Exit;
  If Not Keypressed Then PlayNote(1,110,40) Else Exit;
  If Not Keypressed Then PlayNote(4,110,20) Else Exit;
  If Not Keypressed Then PlayNote(4,110,20) Else Exit;
  If Not Keypressed Then PlayNote(4,110,20) Else Exit;
  If Not Keypressed Then PlayNote(3,110,40) Else Exit;
  If Not Keypressed Then PlayNote(16,110,20) Else Exit;
  If Not Keypressed Then PlayNote(16,110,20) Else Exit;
  If Not Keypressed Then PlayNote(16,110,20) Else Exit;
  Sound(370);
  Delay(400);
  Nosound;
  Delay(235);
  If Not Keypressed Then PlayNote(17,125,20) Else Exit;
  If Not Keypressed Then PlayNote(17,125,20) Else Exit;
  If Not Keypressed Then PlayNote(16,125,20) Else Exit;
  If Not Keypressed Then PlayNote(15,250,80) Else Exit;
  If Not Keypressed Then PlayNote(13,125,30) Else Exit;
  Sound(370);
  Delay(150);
  Nosound;
  Delay(40);
  If Not Keypressed Then PlayNote(17,125,20) Else Exit;
  If Not Keypressed Then PlayNote(17,125,20) Else Exit;
  If Not Keypressed Then PlayNote(16,125,20) Else Exit;
  If Not Keypressed Then PlayNote(15,250,80) Else Exit;
  If Not Keypressed Then PlayNote(13,125,30) Else Exit;
  Sound(370);
  Delay(150);
  Nosound;
  Delay(40);
  If Not Keypressed Then PlayNote(17,125,30) Else Exit;
  If Not Keypressed Then PlayNote(17,125,30) Else Exit;
  If Not Keypressed Then PlayNote(16,125,30) Else Exit;
  If Not Keypressed Then PlayNote(15,550,200) Else Exit;
  If Not Keypressed Then PlayNote(13,600,200) Else Exit;
  If Not Keypressed Then PlayNote(17,1200,600) Else Exit;
  If Not Keypressed Then PlayNote(18,180,40) Else Exit;
  If Not Keypressed Then PlayNote(18,180,40) Else Exit;
  If Not Keypressed Then PlayNote(18,180,40) Else Exit;
  If Not Keypressed Then PlayNote(16,1100,1) Else Exit;
End;

Procedure RipSound;
Begin
  PlayNote(1,800,100);
  PlayNote(1,600,100);
  PlayNote(1,300,20);
  PlayNote(1,800,100);
  PlayNote(29,500,100);
  PlayNote(2,300,40);
  PlayNote(2,500,80);
  PlayNote(1,300,40);
  PlayNote(1,500,80);
  Sound(95);
  Delay(300);
  nosound;
  Delay(40);
  PlayNote(1,800,1);
end;

Procedure ReallyDeadSound;
Begin
  PlayNote(11, 600, 100);
  PlayNote(11, 300, 40);
  PlayNote(14, 1400, 450);
  PlayNote(11, 600, 100);
  PlayNote(14, 265, 40);
  PlayNote(16, 1380, 450);
  PlayNote(11, 450, 90);
  PlayNote(14, 225, 60);
  PlayNote(16, 750, 130);
  PlayNote(11, 450, 90);
  PlayNote(14, 225, 60);
  PlayNote(16, 750, 130);
  PlayNote(11, 450, 90);
  PlayNote(14, 225, 60);
  PlayNote(16, 1350, 450);
  PlayNote(14, 600, 100);
  PlayNote(16, 265, 40);
  PlayNote(18, 1380, 450);
  PlayNote(16, 550, 100);
  PlayNote(14, 265, 40);
  PlayNote(11, 1380, 450);
  PlayNote(11, 550, 100);
  PlayNote(11, 265, 40);
  PlayNote(14, 1400, 1);
End;

Procedure ScarySound;
Begin
  If Not KeyPressed Then PlayNote(7,100,12) Else Exit;
  If Not KeyPressed Then PlayNote(6,100,12) Else Exit;
  If Not KeyPressed Then PlayNote(7,900,500) Else Exit;
  If Not KeyPressed Then PlayNote(6,110,12) Else Exit;
  If Not KeyPressed Then PlayNote(5,110,12) Else Exit;
  If Not KeyPressed Then PlayNote(49,110,12) Else Exit;
  If Not KeyPressed Then PlayNote(3,110,12) Else Exit;
  If Not KeyPressed Then PlayNote(29,650,100) Else Exit;
  If Not KeyPressed Then PlayNote(3,1100,900) Else Exit;
  If Not KeyPressed Then PlayNote(7,100,12) Else Exit;
  If Not KeyPressed Then PlayNote(6,100,12) Else Exit;
  If Not KeyPressed Then PlayNote(7,900,500) Else Exit;
  If Not KeyPressed Then PlayNote(49,400,30) Else Exit;
  If Not KeyPressed Then PlayNote(5,400,30) Else Exit;
  If Not KeyPressed Then PlayNote(29,750,120) Else Exit;
  If Not KeyPressed Then PlayNote(3,1100,1) Else Exit;
end;

Procedure TwZoneSound;
Begin
  PlayNote(2,200,10);
  PlayNote(29,200,10);
  PlayNote(2,200,10);
  Sound(89);
  Delay(211);
  Nosound;
  Delay(11);
End;

Procedure CongratsSound;
Begin
  PlayNote(21,120,20);
  PlayNote(23,120,20);
  PlayNote(25,120,20);
  PlayNote(28,200,80);
  PlayNote(25,110,20);
  PlayNote(28,400,1);
End;

Procedure MagicSound;
var
  x,y:Integer;
begin
  for x := 12 downto 1 Do
    begin
      Y:=x*5+20;
      sound(y);
      delay(23);
    end;
  nosound;
End;

Procedure MagicSound2;
var
  x,y:Integer;
begin
  for x := 15 downto 3 Do
    begin
      Y:=x*5+20;
      sound(y);
      delay(33);
    end;
  nosound;
End;

Procedure MagicSound3;
var
  x,y:Integer;
begin
  for x := 20 downto 1 Do
    begin
      Y:=x*5+25;
      sound(y);
      delay(33);
    end;
  nosound;
End;

Procedure CrunchSound;
var
  x:Integer;
begin
  for x := 12 downto 4 Do
    begin
      sound(x*5);
      delay(25);
      sound(125);
      delay(17);
      sound(x*5);
      delay(25);
    end;
  nosound;
End;

Procedure ScrollSound;
begin
  Sound(30);
  Delay(60);
  Sound(20);
  Delay(60);
  nosound;
End;


Procedure PunchSound;
var
  x,y:integer;
Begin
  For x := 5 downto 2 Do
    begin
      Y:=X*27-20;
      sound(y);
      delay(20);
    end;
  nosound;
End;

Procedure MissSound;
var
  x,y,z:integer;
begin
  For x := 1 to 5 Do
    begin
      Y:=X*30+40;
      sound(y);
      delay(15);
    end;
  nosound;
end;

Procedure BattleCrySound;
Begin
  PlayNote(14,130,15);
  PlayNote(14,130,15);
  PlayNote(14,130,15);
  Sound(458);
  Delay(550);
  Nosound;
End;

Procedure BattleCrySound2;
Begin
  PlayNote(11,80,24);
  PlayNote(14,80,24);
  PlayNote(16,150,30);
  PlayNote(11,80,24);
  PlayNote(14,80,24);
  PlayNote(16,150,30);
  PlayNote(11,80,24);
  PlayNote(14,80,24);
  PlayNote(16,220,1);
End;

Procedure SirenSound;
Var
  X, Y, Z:Integer;
Begin
  X:=1;
  Repeat
    For Y := 1 to 25 Do
      Begin
        Z := (Y*10)+500;
        Sound(Z);
        Delay(40);
      End;
    For Y := 24 DownTo 1 Do
      Begin
        Z:=(Y*10)+500;
        Sound(Z);
        Delay(40);
      End;
    X:=X+1;
  Until X = 3;
  NoSound;
End;

END {Implementation}.