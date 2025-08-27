Procedure SpecialTalk(Msg : Char);
Var A,B : Byte;
    Ch : Char;
    SS : String[4];
    Gift : Integer;
Begin
Case Msg Of
 '1' : Begin
       WriteMessage('Hello!  I''m the King''s wizard.');
       WriteMessage('I have created a new spell. Its called...');
       WriteMessage('Rust. For many months, I have done research');
       WriteMessage('on the Rust Monsters and Slimes.');
       WriteMessage('I was able to create this great spell.');
       WriteMessage('It can rust all your enemies'' metal armors.');
       WriteMessage('However, it requires a lot of Magic.');
       WriteMessage('I''ll teach it to you for 500 gold pieces. Ok?');
       WriteMessage('');
       Repeat
       Ch:=Readkey; If Ch=#0 then Ch:=ReadKey;
       Until Upcase(Ch) in ['Y','N'];
       If (Upcase(CH)='Y') And (Player.Gold<500) Then
                           WriteMessage('Sorry, sir, but you need 200 gold.');
       If (Upcase(CH)='Y') And (Player.Gold>=500) Then Begin
                         WriteMessage('Thank you! Here you go, sir!');
                         SetPalette(0,22);
                         If SoundOnOff Then Begin MagicSound; MagicSound2;
                            MagicSound3; End Else Delay(40);
                         SetPalette(0,0);
                         Player.Gold:=Player.Gold-500;
                         ChangeStats(2);
                         Player.Items[4]:=True;
                         WriteMessage('Use this spell wisely.');
                         End;
       End;
 '2' : Begin
       For A := 1 to 5 do
         If (Player.Mission[A]=true) and (Player.KingTalk[A]=false) then
           begin
             Player.KingTalk[A]:=True;
             WriteMessage('Good! You have completed your mission!');
             If A=1 then begin
               WriteMessage('The writing on this parchment is coded.');
               WriteMessage('I''ll have someone decipher it.');
             End;
             If A=2 then begin
               WriteMessage('This Dalagash''s mad plan will destroy Quilinor!');
               Writemessage('He mustn''t succeed!');
             End;
             If A=3 then begin
               WriteMessage('The people of Myron thank you for all you''ve done!  While');
               WriteMessage('you were away at Myron, the parchment was decoded. It mentions');
               WriteMessage('something about a talisman that is being kept by a dragon in a');
               WriteMessage('dungeon up north. Dalagash wanted my clerics to go retrieve');
               WriteMessage('it. Apparently, without it, Dalagash could not invoke Vampyr.');
             End;
             If A=4 then begin
               WriteMessage('Without the Talisman of Invocation, Dalagash''s plan will');
               WriteMessage('fail! However, we must make certain that it does.');
             End;
             If A=5 then begin
               WriteMessage('While you were away, Dalagash''s minions came to the');
               WriteMessage('castle and stole the talisman!');
             end;
             WriteMessage('Your reward for completing your mission is:');
             Case A of
             1 : Gift:=300;
             2 : Gift:=500;
             3 : Gift:=800;
             4 : Gift:=1200;
             5 : Gift:=1600;
             end;
             Str((Gift-100),SS);
             WriteMessage(SS+' gold pieces.');
             If (Player.Gold+(Gift-100))<9999 then Player.Gold:=Player.Gold+(Gift-100)
             else Player.Gold:=9999;
             Str(Gift,SS);
             Writemessage(SS+' XPs.');
             Player.XP:=Player.XP+Gift;
             ChangeStats(2);
           End;
       A:=0;
       If Not Player.Mission[1] Then Begin
           WriteMessage('Welcome, adventurer!');
           WriteMessage('I need you to preform a duty for me.');
           WriteMessage('Some of my clerics went to the forest in the northwest');
           WriteMessage('to investigate a gathering of monsters. However, they');
           WriteMessage('never came back. Go seek them. Bring back evidence');
           WriteMessage('of their whereabouts. You will be rewarded.');
           A:=1;
         End;
       If (Not Player.Mission[2]) And (A=0) Then Begin
           A:=1;
           WriteMessage('You mentioned someone named Dalagash. He seems to be');
           WriteMessage('the one who enslaved my clerics. Go find out who he is.');
         End;
       If (Not Player.Mission[3]) And (A=0) Then Begin
           A:=1;
           WriteMessage('The town of Myron was invaded by a band of evil clerics.');
           WriteMessage('Go kill their leader, and stop this invasion.');
         End;
       If (Not Player.Mission[4]) And (A=0) Then Begin
           A:=1;
           WriteMessage('Go to the dragon''s lair up north and bring back the talisman.');
         End;
       If (Not Player.Mission[5]) And (A=0) Then Begin
           A:=1;
           WriteMessage('A great sage has been missing ever since this Dalagash');
           WriteMessage('appeared. Go look for him. He might have the knowledge');
           WriteMessage('that could stop Dalagash once and for all.');
         End;
       If (Player.KingTalk[5]) Then
          WriteMessage('Go to Vampyr''s Castle and stop Dalagash!!');
       End;
 '3': JudgeDay;
 '4' : Begin
         If Player.Items[1] then
           begin
             WriteMessage('Sorry. One blue rose per customer.');
             exit;
           end;
         WriteMessage(CurrentMonSet[2]^.Msg2);
         WriteMessage('I''ll sell it to you for 500 gold pieces. Deal? [Y/N]');
         Repeat
           Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
         Until Upcase(Ch) in ['Y','N'];
         If Upcase(Ch) = 'Y' then
           Begin
             If Player.Gold<500 then
               begin
                 WriteMessage('Maybe some other day when you have the cash.');
                 Exit;
               End;
             Player.Gold:=Player.Gold-500;
             WriteMessage('Wise choice. It will save your life one day.');
             Player.Items[1]:=True;
             ChangeStats(2);
           End
         Else
           WriteMessage('Ok, fine. You''ll regret it.');
       End;
 '5' : Begin
         WriteMessage(CurrentMonSet[16]^.Msg2);
         If ((Player.Mission[1]=true) and (Player.Mission[2]=true) and
         (Player.Mission[3]=true) and (Player.mission[4]=true) and
         (Player.Mission[5]=true)) Then
           Begin
             WriteMessage('I offer to take you to the castle where The Evil resides.');
             WriteMessage('However, it''s a long and treacherous journey.');
             WriteMessage('I must ask for 2000 gold pieces in payment. Agreed?');
             Repeat
             Ch:=ReadKey; If Ch=#0 then Ch:=ReadKey;
             Until Upcase(ch) in ['Y','N'];
             If Upcase(ch) = 'Y' then
               begin
                 If Player.Gold<2000 then
                   Begin
                     WriteMessage('When you have the money, I''ll take you there.');
                     exit;
                   end;
                 Player.Gold:=Player.Gold-2000;
                 ChangeStats(1);
                 WriteMessage('Well, let''s go...');
                 LoadNewMapType(1);
                 BoatTrip(17);
                 DisplayLand(Player.Xloc,Player.Yloc);
               End
             Else
               WriteMessage('Ok, maybe some other day, then.');
           End
         Else
           begin
             WriteMessage('I would only take the hardiest of all to Calatiki.');
             WriteMessage('You are still too weak.');
           End;
       End;
  '6' : Begin
          WriteMessage(CurrentMonSet[22]^.Msg2);
          Player.Mission[2]:=True;
          WriteMessage('You inquire about Dalagash.  I have a tale for you.');
          WriteMessage('Dalagash is a powerful magic user.  Not too long ago,');
          WriteMessage('He discovered the location of the tomb of Vampyr.  He');
          WriteMessage('has also learned the reason why the Summoning failed.');
          WriteMessage('With those knowledges, he will try to resurrect Vampyr.');
          WriteMessage('If he succeeds, Vampyr would again enslave the entire');
          WriteMessage('Quilinor like he has done before.  You must stop');
          WriteMessage('Dalagash to insure the safety of Quilinor.');
          WriteMessage('Run along now, before the guards catch you.');
       End;
  '7' : Begin
          WriteMessage(CurrentMonSet[4]^.Msg2);
          Player.Mission[1]:=True;
          Writemessage('< While he talked, you noticed a parchment on his desk. >');
          WriteMessage('< With your amazing thieving ability, you quickly snatched it. >');
          WriteMessage('... are you doing here? Well, just tell that ol... Hey! Give that back!');
          CurrentMonSet[4]^.Status:=1;
          CurrentMonSet[0]^.Status:=1;
          CurrentMonSet[1]^.Status:=1;
          CurrentMonSet[2]^.Status:=1;
        End;
  '8' : Begin
          Player.Mission[5]:=True;
          WriteMessage('I am a sage with great magical power. I have been alive ever');
          WriteMessage('since Vampyr''s first appearance in Quilinor. My magic has');
          WriteMessage('prolonged my life over the years. Anyway, I was captured not');
          WriteMessage('too long ago by Dalagash, who thought my knowledge was dangerous');
          WriteMessage('to the success of his plan. Now that you have found me, let me');
          WriteMessage('give you some infomation I discovered that are vital to stopping');
          WriteMessage('                ---<ANY KEY TO CONTINUE>---');
          Ch:=ReadKey;
          WriteMessage('this madness. 1) Vampyr''s castle is on the island of Calatiki.');
          WriteMessage('2) You must seek Dalagash first. He has the Keystone. Without');
          WriteMessage('it, you cannot enter the catabomb that contains Vampyr''s tomb.');
          WriteMessage('Anyway, Dalagash should be there already. Who knows, he might');
          WriteMessage('even has set up a laboratory to prepare himself for the invocation.');
          WriteMessage('Well, thanks again for rescuing me. Good luck, for Quilinor''s sake!');
          CurrentMonSet[4]^.Status:=5;
        End;
  '9' : Begin
          Player.Items[2]:=True;
          WriteMessage(CurrentMonSet[2]^.Msg2);
          CurrentMap^[CurrentMonSet[2]^.X,CurrentMonSet[2]^.Y]:=
          CurrentMonSet[2]^.OriPic;
          Dispose(CurrentMonSet[2]);
          CurrentMonSet[2]:=Nil;
          If Player.MiscMagic<>1 then BlockIt(TempXloc,TempYloc);
          DisplayMap(TempXloc,TempYloc);
        End;
  'A' : Begin
          WriteMessage(CurrentMonSet[0]^.Msg2);
          CurrentMonSet[0]^.Status:=1;
          For B:=0 to 24 do
            Begin
              If CurrentMonSet[B]^.MonsterName=6 then
                CurrentMonSet[B]^.Status:=1;
            End;
        End;
 End;
End;

Procedure ToTalk;
Var
  I,A : Byte;
  LittleX,LittleY : Byte;
  Direction : Char;
  Tell1,Tell2 : Boolean;
  Talked : Boolean;
Begin
  Talked:=False;
  Tell1 := False; Tell2 := False;
  If CurrentMapType <> 1 Then
   Begin
     LittleX := TempXloc;
     LittleY := TempYLoc;
     WriteMessage('Talk.  Which direction?');
     Direction := Readkey;
     If Direction = #0 Then Direction := ReadKey;
     Case Ord(Direction) of
     77 : LittleX := LittleX+1;
     75 : LittleX := LittleX-1;
     80 : LittleY := LittleY+1;
     72 : LittleY := LittleY-1;
     Else Begin WriteMessage('Consult your DOS manual about the use of cursor keys.');
          Talked:=True; End
     End;
     If ((CurrentMapType=2) AND (CurrentMap^[LittleX,LittleY] In [21,12])) or
     ((CurrentMapType=4) AND (CurrentMap^[LittleX,LittleY] in [22,19])) Then
        Case Ord(Direction) of
        77 : LittleX := LittleX+1;
        75 : LittleX := LittleX-1;
        80 : LittleY := LittleY+1;
        72 : LittleY := LittleY-1;
        End;
     For I := 0 to 24 Do
       Begin
         If CurrentMonSet[I] <> Nil Then
           Begin
             If (CurrentMonSet[I]^.X=LittleX) AND (CurrentMonSet[I]^.Y=LittleY)
             Then Begin
               Talked := True;
               A:=Random(5)+1;
               If A>2 Then Tell1:=True;
               If A<3 Then Begin Tell1:=True; Tell2:=True; End;
               If (CurrentMonSet[I]^.Msg1[1]='S') And (CurrentMonSet[I]^.Msg1[2]='P')
                  And (CurrentMonSet[I]^.Msg1[3]='L') And (CurrentMonSet[I]^.Msg1[4]=' ')
                  Then Begin SpecialTalk(CurrentMonSet[I]^.Msg1[5]); Tell1:=False;
                  Tell2:=False End Else Begin
               If CurrentMonStats[CurrentMonSet[I]^.MonsterName].Name=
                  'Merchant' Then Begin Shops(CurrentMonSet[I]); Tell1:=False;
                  Tell2:=False; Exit; End;
               If CurrentMonStats[CurrentMonSet[I]^.MonsterName].Name='Bard'
                  Then Begin Tell1:=True; Tell2:=True; End;
               If CurrentMonStats[CurrentMonSet[I]^.MonsterName].Name='Drunk'
                  Then Begin
                  If Player.Items[3]=True Then
                    Begin Tell1:=False; Tell2:=True; End
                    Else Begin Tell1:=True; Tell2:=False; End;
                  End;
               End;
               If Tell1=True Then WriteMessage(CurrentMonSet[I]^.Msg1);
               If Tell2=True Then WriteMessage(CurrentMonSet[I]^.Msg2);
             End;
           End;
       End;
     If (Talked=false) and (CurrentMapType=3) then
       begin
         for I := 1 to 3 do
           Begin
             If (CurrentMonMem[I]^.X=LittleX) AND (CurrentMonMem[I]^.Y=LittleY) then
               Begin
                 Talked:=True;
                 WriteMessage('The monster doesn''t want to talk. He wants to eat.');
               End;
           End;
       End;
     If Talked=False then
       WriteMessage('Talking to yourself again.  Tsk tsk tsk.');
  End Else WriteMessage('No one wants to talk to you.');
End;

