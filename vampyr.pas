program vampyr;
{$mode objfpc}{$H+}

uses
  CRT, SDL2, SysUtils, Math, Classes, uGfx_fb, uAudioSDL, data_loaders, uConTiles, 
  StatusPanel, uMonster, uItems, uShops, uDisplay, fb_viewer;

// In the interface section, add:
// In the implementation section:
var
  ClimbTargetX, ClimbTargetY: Integer;

procedure DoClimbWall_Begin;
begin
  if ActiveKind = mkWorld then
  begin
    WriteMessage('What are you climbing?!?');
    Exit;
  end;

  // Check for special location restrictions
  if (ActiveKind = mkDungeon) and 
     ((Player.XLoc = 44) and (Player.YLoc = 3) or  // Top of castle
      (Player.XLoc = 104) and (Player.YLoc = 9)) then  // Bottom of castle
  begin
    WriteMessage('What are you climbing?!?');
    Exit;
  end;
  writeln(ActiveKind);
  writeln(ActiveLevelIndex);
  // Check if at castle entrance but not top floor
  if ((ActiveKind = mkCastle) and (ReturnWorldX in [41,42]) and (ReturnWorldY = 40) and (ActiveLevelIndex > 0)) or
     ((ActiveKind = mkVCastle) and (ReturnWorldX = 96) and (ReturnWorldY in [91,92]) and (ActiveLevelIndex > 0)) then
  begin
    WriteMessage('Do that at the top of the castle.');
    Exit;
  end;

  PendingAction := paClimb;
  WriteMessage('Climb city wall or fence. Which direction?');
end;

procedure DoClimbWall_Handle(sym: LongInt);
var
  dx, dy: Integer;
  targetTile: Byte;
  canClimb: Boolean;
  strBonus : ShortInt;
  chance : Real;
begin
  // Convert direction key to delta
  case sym of
    SDLK_UP:    begin dx := 0;  dy := -1; end;
    SDLK_DOWN:  begin dx := 0;  dy := 1;  end;
    SDLK_LEFT:  begin dx := -1; dy := 0;  end;
    SDLK_RIGHT: begin dx := 1;  dy := 0;  end;
  else
    WriteMessage('Consult your DOS manual about the use of cursor keys.');
    Exit;
  end;

  ClimbTargetX := Player.XLoc + dx;
  ClimbTargetY := Player.YLoc + dy;
  
  // Check if target tile is climbable
  targetTile := AM_Get(ClimbTargetX, ClimbTargetY);
  canClimb := False;
// Calculate strength bonus
strBonus := 0;
if Player.Stats.PhyStr > 10 then
  strBonus := (Player.Stats.PhyStr - 10) * 2
else if Player.Stats.PhyStr < 5 then
  strBonus := (Player.Stats.PhyStr - 5) * 2;

// Base chance with strength bonus
chance := (Player.Skills[7] / 1.3) + strBonus;


  case ActiveKind of
    mkTown:
    begin
      // Can climb outer walls or specific tiles
      canClimb := ((ClimbTargetX < 4) or (ClimbTargetX > 45) or 
                  (ClimbTargetY < 4) or (ClimbTargetY > 45) and
                  (ActiveLevelIndex = 0) and
                  (targetTile in [10, 13, 27])) or (targetTile = 27); // Climbable tiles
      if targetTile = 27 then  // You'll need to determine this based on tile type
         chance := chance + 40;
    end;
    mkCastle, mkVCastle:
    begin
      // Can climb outer walls or specific tiles
      canClimb := ((ClimbTargetX < 4) or (ClimbTargetX > 45) or 
                  (ClimbTargetY < 4) or (ClimbTargetY > 45)) and
                  (ActiveLevelIndex = 0) and
                  (targetTile in [10, 13, 27]) or (targetTile = 27); // Climbable tiles
      if targetTile = 27 then  // You'll need to determine this based on tile type
           chance := chance + 40;
    end;
    mkAfterLife:
      begin
        WriteMessage('This is Heaven, fool. Can''t climb clouds.');
        Exit;
      end;
  end;

  if not canClimb then
  begin
    WriteMessage('You can''t climb that!');
    Exit;
  end;



  // Attempt to climb
  if Random(100) + 1 <= chance then // Climbing skill
  begin
    // Success
    if ((ClimbTargetX < 4) or (ClimbTargetX > 45) or 
       (ClimbTargetY < 4) or (ClimbTargetY > 45))  then
    begin
      // Exit to world map
      PlayCongratsSound;
      WriteMessage('You''re outta there!');
      if Player.MiscMagic <> 1 then 
        //BlockIt(ClimbTargetX, ClimbTargetY);
        AM_SetActiveToWorld;
        Player.XLoc := ReturnWorldX;
        Player.YLoc := ReturnWorldY;
    end
    else
    begin
      // Move to new position
      WriteMessage('You made it!');
      if Player.MiscMagic <> 1 then 
        //BlockIt(ClimbTargetX, ClimbTargetY);
      Player.XLoc := ClimbTargetX;
      Player.YLoc := ClimbTargetY;  // (((((((((((((((((())))))))))))))))))
    DrawMapView;       // background + animated tiles + SLEEP overlay (center)
    DrawStatusArea;    // fills panel + draws logo each frame
    Status_Draw;
    DrawMessageArea;   // fills panel
    Message_Render;
    Present;
    end;
  end
  else
  begin
    // Climbing failed
    PlayCrunchSound;
    WriteMessage('Ouch! That hurts! You blew it!');
    Player.CLife := Player.CLife - (Random(4) + 1);
    Status_Draw; // Update status display
end;
end;


// ******************************************** IsStairUp ********************************************

function IsStairUp(const tileID: Byte): Boolean;
begin
  case ActiveKind of
    mkTown, mkCastle:
      Result := (tileID = 23);  // Town/Castle up
    mkDungeon, mkRuin, mkVCastle:
      Result := (tileID = 14);  // Dungeon-family up
  else
    Result := False;
  end;
end;

// ******************************************** IsStairDown ********************************************

function IsStairDown(const tileID: Byte): Boolean;
begin
  case ActiveKind of
    mkTown, mkCastle:
      Result := (tileID = 24);  // Town/Castle down
    mkDungeon, mkRuin, mkVCastle:
      Result := (tileID = 13);  // Dungeon-family down
  else
    Result := False;
  end;
end;

// ******************************************** HandleKlimb ********************************************

procedure HandleKlimb;
var
  t: Byte;
  moved: Boolean;
begin
  if ActiveKind = mkWorld then Exit;

  t := AM_Get(Player.XLoc, Player.YLoc);
  moved := False;

  if IsStairUp(t) then
  begin
    if LoadActiveLocalLevel(ActiveLevelIndex + 1) then
    begin
      WriteMessage('Going down.');
      moved := True;
    end
    else
      WriteLn('Klimb: no upper level available.');
  end
  else if IsStairDown(t) then
  begin
    if LoadActiveLocalLevel(ActiveLevelIndex - 1) then
    begin
      WriteMessage('Going up.');
      moved := True;
    end
    else
      WriteLn('Klimb: no lower level available.');
  end
  else
    WriteMessage('There isn''t a staircase here now is there?');

  if moved then
  begin
    LoadEncountersForCurrentLevel;  // <— reload the proper slice for this floor
    // update SignNum for multi-floor locations
    case ActiveKind of
      mkCastle:  SignNum := 6  + (ActiveLevelIndex + 1);
      mkVCastle: SignNum := 11 + (ActiveLevelIndex + 1);
      // dungeon keeps SignNum = 11; towns/afterlife are fixed
    end;
  end;
end;

//******************************************** Sign_Read ********************************************
function Sign_Read(const DataDir: string; Bank, MapX0, MapY0: Integer;
                   sx, sy: Integer; out s1, s2: ShortString): Boolean;
type
  TSignRec = packed record
    X, Y: Byte;
    Msg1: string[70];
    Msg2: string[70];
  end;
var
  f: file of TSignRec;
  sign: TSignRec;
  fname: string;
  a, b: Integer;
begin
  Result := False;
  s1 := ''; s2 := '';
  Inc(sx);
  Inc(sy);
  fname := IncludeTrailingPathDelimiter(DataDir) + 'SIGN.DAT';
  
  AssignFile(f, fname);
  try
    Reset(f);
   
  // Skip records for previous banks
  if (Bank > 1) then
  begin
  for a := 0 to (Bank-1) do
    for b := 0 to 2 do
      Read(f, sign);
  end;

    // Search through remaining records
    while not Eof(f) do
    begin
      Read(f, sign);
      // Check if coordinates match and the record is in the correct bank
      if (sign.X = sx) and (sign.Y = sy) then
      begin
          s1 := sign.Msg1;
          s2 := sign.Msg2;
          Result := True;
          Exit;
      end;
    end;
    
    // If we get here, no matching sign was found
    writeln('  No matching sign found in bank ', Bank);

  except
    on E: Exception do
    begin
      writeln('  Error reading sign record: ', E.Message);
    end;
  end;
  
  Close(f);
end;

//************************************************* DoLook *************************************************
procedure DoLook_Handle(sym: LongInt);
var
  dx, dy: Integer;
  tx, ty: Integer;
  t: Byte;
  s1, s2: ShortString;
  name: ShortString;
  num: Byte;
  weapon, armor: Byte;
  weapont : TWeaponView;
  armort : TArmorView;
begin
  dx := 0; dy := 0;

  case sym of
    SDLK_RIGHT: dx :=  1;
    SDLK_LEFT : dx := -1;
    SDLK_DOWN : dy :=  1;
    SDLK_UP   : dy := -1;
    else
    begin
      // Not an arrow → cancel look with a friendly nudge (optional)
      WriteMessage('Consult your DOS manual about the use of cursor keys.');
      LookPending := False;
      Exit;
    end;
  end;

  tx := Player.XLoc + dx;
  ty := Player.YLoc + dy;

  if not InBounds(tx, ty) then
  begin
    WriteMessage('Huh?  Where?');
    LookPending := False;
    Exit;
  end;
  if Mons_NPCAt(tx, ty) > -1 then
  begin
    Mons_GetNPCInfo(Mons_NPCAt(tx, ty), name, num, weapon, armor);
    WriteMessage(name);
    WriteMessage('There are '+ IntToStr(num)+' of them altogether.');
    weapont := DecodeWeapon(weapon);
    armort := DecodeArmor(armor);
    WriteMessage('Weapon: '+ weapont.Name);
    WriteMessage('Armor: '+ armort.Name);
    Exit;
  end;
  t := AM_Get(tx, ty);

  // TileId 5 = sign (same as the original)
  if t = 5 then
  begin
    // Use the same data-root convention as elsewhere: "data\..."
    if Sign_Read('data', SignNum, 0, 0, tx, ty, s1, s2) then
    begin
      WriteMessage('Sign reads:');
      if s1 <> '' then WriteMessage(s1);
      if s2 <> '' then WriteMessage(s2);
    end
    else
      WriteMessage('The sign is too weathered to read.');
  end
  else
    WriteMessage('Huh?  Where?');

  LookPending := False; // done with this look interaction
end;


// **************************************** Talk_Special ****************************************
procedure Talk_Special(n, msg2: ShortString);
var
  A : Byte;
  Gift : Integer;
  SS : String[4];
begin
  case n of
    '1' : Begin
       WriteMessage('Hello!  I''m the King''s wizard.');
       WriteMessage('I have created a new spell. Its called...');
       WriteMessage('Rust. For many months, I have done research');
       WriteMessage('on the Rust Monsters and Slimes.');
       WriteMessage('I was able to create this great spell.');
       WriteMessage('It can rust all your enemies'' metal armors.');
       WriteMessage('However, it requires a lot of Magic.');
       if Message_PromptYesNo('I''ll teach it to you for 500 gold pieces. Ok?') then
       if Player.Gold>=500 then
       begin
         WriteMessage('Thank you! Here you go, sir!');
         Player.Gold:=Player.Gold-500;
         PlayMagicSound3;
         //ChangeStats(2);
         Player.Items[4]:=True;
         WriteMessage('Use this spell wisely.');
         End
         else
         WriteMessage('Sorry, sir, but you need 500 gold.');
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
             //ChangeStats(2);
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
  //3: JudgeDay;
  '4': Begin
         If Player.Items[1] then
           begin
             WriteMessage('Sorry. One blue rose per customer.');
             exit;
           end;
         WriteMessage(Msg2);
         if Message_PromptYesNo('I''ll sell it to you for 500 gold pieces. Deal?') then
           Begin
             If Player.Gold<500 then
               begin
                 WriteMessage('Maybe some other day when you have the cash.');
                 Exit;
               End;
             Player.Gold:=Player.Gold-500;
             WriteMessage('Wise choice. It will save your life one day.');
             Player.Items[1]:=True;
             //ChangeStats(2);
           End
         Else
           WriteMessage('Ok, fine. You''ll regret it.');
       End;
  '5': Begin
         WriteMessage(Msg2);
         If ((Player.Mission[1]=true) and (Player.Mission[2]=true) and
         (Player.Mission[3]=true) and (Player.mission[4]=true) and
         (Player.Mission[5]=true)) Then
           Begin
             WriteMessage('I offer to take you to the castle where The Evil resides.');
             WriteMessage('However, it''s a long and treacherous journey.');
             WriteMessage('I must ask for 2000 gold pieces in payment. Agreed?');
             if Message_PromptYesNo('I must ask for 2000 gold pieces in payment. Agreed?') then
               begin
                 If Player.Gold<2000 then
                   Begin
                     WriteMessage('When you have the money, I''ll take you there.');
                     exit;
                   end;
                 Player.Gold:=Player.Gold-2000;
                 //ChangeStats(1);
                 WriteMessage('Well, let''s go...');
                 //LoadNewMapType(1);
                 //BoatTrip(17);
                 //DisplayLand(Player.Xloc,Player.Yloc);
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
          Player.Mission[2]:=True;
          Message_ShowPaged([
          'You inquire about Dalagash.  I have a tale for you.',
          'Dalagash is a powerful magic user.  Not too long ago,',
          'He discovered the location of the tomb of Vampyr.  He',
          'has also learned the reason why the Summoning failed.',
          'With those knowledges, he will try to resurrect Vampyr.',
          'If he succeeds, Vampyr would again enslave the entire',
          'Quilinor like he has done before.  You must stop',
          'Dalagash to insure the safety of Quilinor.',
          'Run along now, before the guards catch you.']);
       End;

    '7' : Begin
          Player.Mission[1]:=True;
          WriteMessage('< While he talked, you noticed a parchment on his desk. >');
          WriteMessage('< With your amazing thieving ability, you quickly snatched it. >');
          WriteMessage('... are you doing here? Well, just tell that ol... Hey! Give that back!');
          //CurrentMonSet[4]^.Status:=1;
          //CurrentMonSet[0]^.Status:=1;
          //CurrentMonSet[1]^.Status:=1;
          //CurrentMonSet[2]^.Status:=1;
        End;
    '8' : Begin
          Player.Mission[5]:=True;
          Message_ShowPaged([
          'I am a sage with great magical power. I have been alive ever',
          'since Vampyr''s first appearance in Quilinor. My magic has',
          'prolonged my life over the years. Anyway, I was captured not',
          'too long ago by Dalagash, who thought my knowledge was dangerous',
          'to the success of his plan. Now that you have found me, let me',
          'give you some infomation I discovered that are vital to stopping',
          'this madness. 1) Vampyr''s castle is on the island of Calatiki.',
          '2) You must seek Dalagash first. He has the Keystone. Without',
          'it, you cannot enter the catabomb that contains Vampyr''s tomb.',
          'Anyway, Dalagash should be there already. Who knows, he might',
          'even has set up a laboratory to prepare himself for the invocation.',
          'Well, thanks again for rescuing me. Good luck, for Quilinor''s sake!']);
          //CurrentMonSet[4]^.Status:=5;
        End;
    '9' : Begin
          Player.Items[2]:=True;
          WriteMessage(Msg2);
  //        CurrentMap^[CurrentMonSet[2]^.X,CurrentMonSet[2]^.Y]:=
  //        CurrentMonSet[2]^.OriPic;
  //        Dispose(CurrentMonSet[2]);
  //        CurrentMonSet[2]:=Nil;
  //        If Player.MiscMagic<>1 then BlockIt(TempXloc,TempYloc);
  //        DisplayMap(TempXloc,TempYloc);
        End;
    'A' : Begin
          WriteMessage(Msg2);
  //        CurrentMonSet[0]^.Status:=1;
  //        For B:=0 to 24 do
  //          Begin
  //            If CurrentMonSet[B]^.MonsterName=6 then
  //              CurrentMonSet[B]^.Status:=1;
  //          End;
        End;

  else
    // Unknown SPL — keep it benign.
    WriteMessage('They hint at matters of state... (story WIP)');
  end;
end;







// ******************************************** DoTalk_Handle ********************************************
// ---- Handle talk ----
// If you use SDLK_* as in DoLook_Handle
procedure DoTalk_Handle(sym: LongInt);
var
  dx, dy: Integer;
  tx, ty: Integer;
  tileID: Word;
  npcIdx: Integer;
  mapKind: TMapKind;
  name: ShortString;
  m1, m2: ShortString;
begin
  dx := 0; dy := 0;
  case sym of
    SDLK_RIGHT: dx :=  1;
    SDLK_LEFT : dx := -1;
    SDLK_DOWN : dy :=  1;
    SDLK_UP   : dy := -1;
  else
    WriteMessage('Consult your DOS manual about the use of cursor keys.');
    TalkPending := False;
    Exit;
  end;

  tx := Player.XLoc + dx;
  ty := Player.YLoc + dy;

  if not InBounds(tx, ty) then
  begin
    WriteMessage('Huh?  Where?');
    TalkPending := False;
    Exit;
  end;

  // --- Reach-over-counter rule ---
  mapKind := ActiveKind;
  tileID := Map_GetTileID(tx, ty);
  if (mapKind in [mkTown, mkCastle]) and (tileID in [21, 12]) then
  begin
    Inc(tx, dx); Inc(ty, dy);
  end
  else if (mapKind = mkAfterlife) and (tileID in [22, 19]) then
  begin
    Inc(tx, dx); Inc(ty, dy);
  end;

  // (Optional) refresh tileID after shifting target for clearer logs
  tileID := Map_GetTileID(tx, ty);

  WriteLn('[TALK] Player=(', Player.XLoc, ',', Player.YLoc, ') dir=(', dx, ',', dy, ')');
  WriteLn('[TALK] First target=(', tx, ',', ty, ') tileID=', tileID, ' ActiveKind=', Ord(ActiveKind));

  if not InBounds(tx, ty) then
  begin
    WriteMessage('Huh?  Where?');
    TalkPending := False;
    Exit;
  end;

  // --- Query NPC at target ---
  npcIdx := Mons_NPCAt(tx, ty);
  WriteLn('[TALK] Mons_NPCAt(', tx, ',', ty, ') = ', npcIdx);

  if npcIdx >= 0 then
  begin
    name := Mons_GetNPCName(npcIdx);
    Mons_GetNPCMsgs(npcIdx, m1, m2);

    // 1) SPL special handlers (wizard, king, etc.)
    if (Length(m1) >= 5) and
       (UpCase(m1[1]) = 'S') and (UpCase(m1[2]) = 'P') and (UpCase(m1[3]) = 'L') and (m1[4] = ' ')
    then
    begin
      Talk_Special(Trim(Copy(m1, 5, 3)), m2);
      TalkPending := False;
      Exit;
    end;

    // 2) Merchant branch (by name), but message-driven via Shop_Handle
    if (UpperCase(name) = 'MERCHANT') then
    begin
      // Optional pre-greeting if not SPL-coded
      //if (m1 <> '') and (Pos('SPL ', UpperCase(m1)) <> 1) then
      //  WriteMessage(m1);

      Shop_Handle(m1, m2, Player);
      TalkPending := False;
      Exit;
    end;

    // 3) Default NPC lines (non-merchant, non-SPL)
    if m1 <> '' then WriteMessage(m1);
    if m2 <> '' then WriteMessage(m2);

    TalkPending := False;
    Exit;
  end
  else
  begin
    // No NPC there — preserve your prior map-kind responses
    if ActiveKind = mkWorld then
      WriteMessage('No one wants to talk to you.')
    else if ActiveKind in [mkTown, mkCastle, mkAfterlife] then
      WriteMessage('Talking to yourself again.  Tsk tsk tsk.')
    else
      WriteMessage('The monster doesn''t want to talk. He wants to eat.');

    TalkPending := False;
    Exit;
  end;
end;

// ******************************************** CountLevels50x50 ********************************************

function CountLevels50x50(const path: string): Integer;
var
  f: File;
  sz: Int64;
begin
  Result := 0;
  if not FileExists(path) then Exit;
  AssignFile(f, path);
  Reset(f, 1);
  try
    sz := FileSize(f);
  finally
    CloseFile(f);
  end;
  // Each level is 50*50 bytes
  if sz > 0 then
    Result := sz div (50*50);
end;

// ******************************************** ClampI ********************************************
// Clamp helpers if you don't already have them:
function ClampI(v, lo, hi: Integer): Integer; inline;
begin
  if v < lo then Exit(lo);
  if v > hi then Exit(hi);
  Result := v;
end;



// ******************************************** BlitShim ********************************************
// Tiny wrapper to keep uMonster unchanged and simply adapts the pointer type 
procedure BlitShim(src: PDWord; x, y, w, h: LongInt); inline;
begin
  BlitTileScaledFromPtr_PutPixel(PUInt32(src), x, y, w, h);
end;

// **************************************** EnterHere_World ****************************************
procedure EnterHere_World;
var
  t: Byte;
  M: TMap;

  // Load one 50x50 chunk and also initialize level-navigation state
  function TryLoadChunk(const fn: AnsiString; const idx: Integer;
                        const newKind: TMapKind;
                        const spawnX, spawnY: Integer): Boolean;
  begin
    Result := False;
    WriteLn('EnterHere_World: TryLoad ', fn, ' idx=', idx);
    if not FileExists(fn) then
    begin
      WriteLn('EnterHere_World: MISSING FILE: ', fn);
      Exit;
    end;

    if LoadLocalChunk50x50(fn, idx, M) then
    begin
      ActiveMap   := M;
      ActiveKind  := newKind;

      // --- initialize local-level navigation state ---
      ActiveMapPath    := fn;
      ActiveLevelCount := CountLevels50x50(ActiveMapPath);
      ActiveLevelIndex := idx;    // 0-based, matches Seek index
      // ----------------------------------------------

      Player.XLoc := spawnX;
      Player.YLoc := spawnY;

      WriteLn('EnterHere_World: Loaded ', fn, ' idx=', idx, ' -> kind=', Ord(newKind),
              ' spawn=(', spawnX, ',', spawnY, ')  levels=', ActiveLevelCount);

      // Hook up ENCONTER.SET slice (unchanged)
      case newKind of
        mkCastle: Mons_LoadSet(msTown, MakeRange(200, 224), @GetTownMonTile_Int, 'ENCONTER.SET');
        mkTown:
          begin
            case idx of
              0: Mons_LoadSet(msTown, MakeRange(  0,  24), @GetTownMonTile_Int, 'ENCONTER.SET');
              1: Mons_LoadSet(msTown, MakeRange( 25,  49), @GetTownMonTile_Int, 'ENCONTER.SET');
              2: Mons_LoadSet(msTown, MakeRange( 50,  74), @GetTownMonTile_Int, 'ENCONTER.SET');
              3: Mons_LoadSet(msTown, MakeRange( 75,  99), @GetTownMonTile_Int, 'ENCONTER.SET');
              4: Mons_LoadSet(msTown, MakeRange(100, 124), @GetTownMonTile_Int, 'ENCONTER.SET');
              5: // Myron (missions path omitted; keep legacy else-path)
                 Mons_LoadSet(msTown, MakeRange(125, 149), @GetTownMonTile_Int, 'ENCONTER.SET');
            else
              Mons_Clear;
            end;
          end;
        mkDungeon:
          begin
            if (Player.XLoc = 44) and (Player.YLoc = 3) then
              Mons_LoadSet(msDungeon, MakeRange(265, 266), @GetDungMonTile_Int, 'ENCONTER.SET')
            else
              Mons_Clear;
          end;
        mkRuin:
          begin
            if (ReturnWorldY = 57) and (ReturnWorldX in [59,60]) then
              Mons_LoadSet(msRuin, MakeRange(255, 264), @GetRuinMonTile_Int, 'ENCONTER.SET')
            else if (ReturnWorldY = 17) and (ReturnWorldX in [20,21]) then
              Mons_LoadSet(msRuin, MakeRange(250, 254), @GetRuinMonTile_Int, 'ENCONTER.SET')
            else
              Mons_Clear;
          end;

        mkVCastle: Mons_LoadSet(msRuin, MakeRange(274, 276), @GetRuinMonTile_Int, 'ENCONTER.SET');
        mkAfterlife: Mons_LoadSet(msLife, MakeRange(225, 249), @GetLifeMonTile_Int, 'ENCONTER.SET');

      else
        Mons_Clear;
      end;

      Result := True;
    end
    else
      WriteLn('EnterHere_World: Load FAILED for ', fn, ' idx=', idx);
  end;

begin
  if ActiveKind <> mkWorld then
  begin
    WriteLn('EnterHere_World: not on world, ignoring.');
    Exit;
  end;

  t := AM_Get(Player.XLoc, Player.YLoc);
  WriteLn('EnterHere_World: t = ', t, ' Player.XLoc = ', Player.XLoc, ' Player.YLoc = ', Player.YLoc);

  //===============================
  // FRIENDLY: Towns/Castle (8,9,10,17)
  //===============================
  if (t in [8,9,10,17]) then
  begin
    WriteLn('EnterHere_World: t in [8,9,10,17] (Friendly)');
    ReturnWorldX := Player.XLoc; ReturnWorldY := Player.YLoc;

    // Castle: (41..42, 40) -> idx 2
    if (Player.YLoc = 40) and (Player.XLoc in [41,42]) then
      if TryLoadChunk('data\castle.map', 2, mkCastle, 24, 46) then
      begin
        ActiveEntrance := ekCastle;
        LoadEncountersForCurrentLevel; 
        SignNum := 9;  // Bank 9, records 27-29
        WriteMessage('Entering castle...');
        Exit;
      end;

    // Balinar (0) : (44..45,42)
    if (Player.YLoc = 42) and (Player.XLoc in [44,45]) then
      if TryLoadChunk('data\town.map', 0, mkTown, 24, 46) then
      begin
        ActiveEntrance := ekTown0;
        LoadEncountersForCurrentLevel;
        SignNum := 1;  // Balinar
        WriteMessage('Entering the town of Balinar...');
        Exit;
      end;

    // Rendyr (1) : (14..15,56)
    if (Player.YLoc = 56) and (Player.XLoc in [14,15]) then
      if TryLoadChunk('data\town.map', 1, mkTown, 24, 46) then
      begin
        ActiveEntrance := ekTown1;
        LoadEncountersForCurrentLevel;
        SignNum := 2;  // Rendyr
        WriteMessage('Entering the town of Rendyr...');
        Exit;
      end;

    // Maninox (2) : (85..86,58)
    if (Player.YLoc = 58) and (Player.XLoc in [85,86]) then
      if TryLoadChunk('data\town.map', 2, mkTown, 24, 46) then
      begin
        ActiveEntrance := ekTown2;
        LoadEncountersForCurrentLevel;
        SignNum := 3;  // Maninox
        WriteMessage('Entering the town of Maninox...');
        Exit;
      end;

    // Zachul (3) : (19..20,84)
    if (Player.YLoc = 84) and (Player.XLoc in [19,20]) then
      if TryLoadChunk('data\town.map', 3, mkTown, 24, 46) then
      begin
        ActiveEntrance := ekTown3;
        LoadEncountersForCurrentLevel;
        SignNum := 4;  // Zachul
        WriteMessage('Entering the town of Zachul...');
        Exit;
      end;

    // Trocines (4) : (39..40,80)
    if (Player.YLoc = 80) and (Player.XLoc in [39,40]) then
      if TryLoadChunk('data\town.map', 4, mkTown, 24, 46) then
      begin
        ActiveEntrance := ekTown4;
        LoadEncountersForCurrentLevel;
        SignNum := 5;  // Trocines
        WriteMessage('Entering the town of Trocines...');
        Exit;
      end;

    // Myron (5) : (55..56,91)
    if (Player.YLoc = 91) and (Player.XLoc in [55,56]) then
      if TryLoadChunk('data\town.map', 5, mkTown, 24, 46) then
      begin
        ActiveEntrance := ekTown5;
        LoadEncountersForCurrentLevel;
        SignNum := 6;  // Myron
        WriteMessage('Entering the town of Myron...');
        Exit;
      end;

    WriteLn('EnterHere_World: Friendly tile but coords didnt match any known entrance.');
    Exit;
  end;

  //========================================
  // NON-FRIENDLY: VCastle/Ruin/Dungeon (TileIDs 7,11,13,18,19)
  //
  // Apply -1 offset to original coordinates:
  //   Vampyr's Castle : (97, 92..93)          -> vcastle.map index 1
  //   Dungeon A       : (44, 3)               -> dungeon.map index 0
  //   Dungeon B       : (104, 9)              -> dungeon.map index 3
  //   Ruin A          : (59..60, 57)          -> ruin.map    index 0
  //   Ruin B          : (20..21, 17)          -> ruin.map    index 1
  //========================================
  if (t in [7,11,13,18,19]) then
  begin
    WriteLn('EnterHere_World: t in [7,11,13,18,19] (Non-friendly)');
    // Save return point
    ReturnWorldX := Player.XLoc; ReturnWorldY := Player.YLoc;

    // Vampyr's Castle (top/bottom tiles) around X=97, Y=92..93
    if (Player.XLoc = 97) and (Player.YLoc in [92,93]) then
      if TryLoadChunk('data\vcastle.map', 1, mkVCastle, 25, 46) then
      begin
        ActiveEntrance := ekVCastle;
        LoadEncountersForCurrentLevel;
        SignNum := 11;
        WriteMessage('Entering Vampyr''s Castle...');
        Exit;
      end;

    // Dungeons
    if (Player.XLoc = 44) and (Player.YLoc = 3) then
      if TryLoadChunk('data\dungeon.map', 0, mkDungeon, 25, 46) then
      begin
        ActiveEntrance := ekDungeonA;
        LoadEncountersForCurrentLevel;
        WriteMessage('Entering dungeon...');
        Exit;
      end;

    if (Player.XLoc = 104) and (Player.YLoc = 9) then
      if TryLoadChunk('data\dungeon.map', 3, mkDungeon, 25, 46) then
      begin
        ActiveEntrance := ekDungeonB;
        LoadEncountersForCurrentLevel;
        WriteMessage('Entering dungeon...');
        Exit;
      end;

    // Ruins
    if (Player.YLoc = 57) and (Player.XLoc in [59,60]) then
      if TryLoadChunk('data\ruin.map', 0, mkRuin, 24, 46) then
      begin
        ActiveEntrance := ekRuinA;
        LoadEncountersForCurrentLevel;
        WriteMessage('Entering ruin...');
        Exit;
      end;

    if (Player.YLoc = 17) and (Player.XLoc in [20,21]) then
      if TryLoadChunk('data\ruin.map', 1, mkRuin, 24, 46) then
      begin
        ActiveEntrance := ekRuinB;
        LoadEncountersForCurrentLevel;
        WriteMessage('Entering ruin...');
        Exit;
      end; 

    WriteLn('EnterHere_World: Hostile tile but coords didnt match any known entrance.');
    Exit;
  end;
end;

// ****************************** Show Player Stats ******************************
procedure ShowPlayerStats;
var
  i, slot: Integer;
  itemName: AnsiString;
  tempWeapon: Byte;
  tempDur: ShortInt;
  ch: Char;
  validSlots: AnsiString;
begin
  // Clear message area and show stats
  WriteMessage('Fighting attack : ' + IntToStr(Player.Skills[1]));
  WriteMessage('Fighting defense : ' + IntToStr(Player.Skills[2]));
  WriteMessage('Magic offensive : ' + IntToStr(Player.Skills[3]));
  WriteMessage('Magic defensive : ' + IntToStr(Player.Skills[4]));
  WriteMessage('Magic miscell. : ' + IntToStr(Player.Skills[5]));
  WriteMessage('Lock picking : ' + IntToStr(Player.Skills[6]));
  WriteMessage('Climbing : ' + IntToStr(Player.Skills[7]));
  WriteMessage('Stealing : ' + IntToStr(Player.Skills[8]));
  WriteMessage('Perception : ' + IntToStr(Player.Skills[9]));
  
  // Show backpack contents
  WriteMessage('Backpack contains:');
  for i := 1 to 5 do
  begin
    if Player.BackPack[i] = 0 then
      itemName := 'Nothing'
    else
      itemName := DecodeWeapon(Player.BackPack[i]).Name;
    WriteMessage(IntToStr(i) + '> ' + itemName);
  end;

  // Handle item management
  ch := Message_PromptLetterChoice('Do you want to swap or drop? [S/D]', 'SDsd' + #27);
  
  if UpCase(ch) = 'S' then  // Swap
  begin
    // Show weapon slots
    for i := 1 to 5 do
    begin
      if Player.BackPack[i] = 0 then
        WriteMessage(IntToStr(i) + '> Nothing')
      else
        WriteMessage(IntToStr(i) + '> ' + DecodeWeapon(Player.BackPack[i]).Name);
    end;
    
    ch := Message_PromptLetterChoice('Swap which weapon? [1-5] or ESC to cancel', '12345' + #27);
    if ch <> #27 then  // Not ESC
    begin
      slot := Ord(ch) - Ord('0');  // Convert '1'-'5' to 1-5
      
      // Swap the weapons
      tempWeapon := Player.Weapon;
      tempDur := Player.WeaponDur[0];
      
      Player.Weapon := Player.BackPack[slot];
      Player.WeaponDur[0] := Player.WeaponDur[slot];
      
      Player.BackPack[slot] := tempWeapon;
      Player.WeaponDur[slot] := tempDur;
      
      WriteMessage('Swapped.');
    end;
  end
  else if UpCase(ch) = 'D' then  // Drop
  begin
    // Build list of valid slots (non-empty)
    validSlots := '';
    for i := 1 to 5 do
    begin
      if Player.BackPack[i] <> 0 then
        validSlots := validSlots + IntToStr(i);
    end;
    
    if validSlots <> '' then
    begin
      // Show non-empty slots
      for i := 1 to Length(validSlots) do
      begin
        slot := Ord(validSlots[i]) - Ord('0');
        WriteMessage(IntToStr(slot) + '> ' + DecodeWeapon(Player.BackPack[slot]).Name);
      end;
      
      ch := Message_PromptLetterChoice('Drop which weapon? [' + validSlots + '] or ESC to cancel', validSlots + #27);
      if ch <> #27 then  // Not ESC
      begin
        slot := Ord(ch) - Ord('0');  // Convert to number
        WriteMessage('Dropped ' + DecodeWeapon(Player.BackPack[slot]).Name);
        Player.BackPack[slot] := 0;
      end;
    end
    else
    begin
      WriteMessage('No items to drop!');
    end;
  end;
end;


//******************************************* Draw Static UI Once *******************************************
//Draw static chrome once during init
procedure DrawStaticUIOnce;
begin
  ClearFB(COLOR_BLACK);
  DrawBorder;
  DrawVampyrLogo;
  Present;
end;


//********************************************** Handle Input **********************************************

procedure HandleInput;
var
  sym: LongInt;
begin
  while SDL_PollEvent(@Event) <> 0 do
  begin
    if Event.type_ = SDL_QUITEV then
      Running := False
    else if Event.type_ = SDL_KEYDOWN then
    begin
      sym := Event.key.keysym.sym;

      // If we’re waiting for a direction for Look/Talk, consume one key first
      if PendingAction <> paNone then
      begin
        if  ((sym = SDLK_UP) or (sym = SDLK_DOWN) or (sym = SDLK_LEFT) or (sym = SDLK_RIGHT)) then
        begin
          case PendingAction of
            paLook: DoLook_Handle(sym);
            paTalk: DoTalk_Handle(sym);
            paClimb: DoClimbWall_Handle(sym);
          end;
        end
        else
          WriteMessage('Consult your DOS manual about the use of cursor keys.');

        PendingAction := paNone;
        Continue; // keep polling other events this frame
      end;

      // Normal key handling
      case sym of
        SDLK_ESCAPE:
          begin
            if ActiveKind = mkWorld then Running := False;
          end;

        // --- TEST keys (keep/remove as you wish) ---
        SDLK_F1:
          begin
            EnableCollision := not EnableCollision;
            EnableOcclusion := not EnableOcclusion;
            WriteLn('TEST TOGGLE: Collision=', EnableCollision,
                    '  Occlusion=', EnableOcclusion);
          end;

        SDLK_F2:
          begin
            if FileExists('data\after.map') then
            begin
              if LoadLocalChunk50x50('data\after.map', 0, ActiveMap) then
              begin
                ActiveKind := mkAfterlife;
                ReturnWorldX := Player.XLoc; ReturnWorldY := Player.YLoc;
                Player.XLoc := 24; Player.YLoc := 46;
                SignNum := 10;
                ActiveEntrance := ekAfterlife;
                LoadEncountersForCurrentLevel;
              end
              else
                WriteLn('after.map load failed.');
            end
            else
              WriteLn('Missing data\after.map');
          end;

        // Begin modal prompts (mirror Look)
        // NOTE: SDL only defines lowercase letter keycodes like SDLK_t, not SDLK_T.
        SDLK_t:
          begin
            PendingAction := paTalk;
            LookPending := True;
            WriteMessage('Talk.  Which direction?');
          end;

        SDLK_l:
          begin
            PendingAction := paLook;
            LookPending := True;
            WriteMessage('Look.  Which direction?');
          end;

        SDLK_k:
          begin
            HandleKlimb;
          end;

        SDLK_c: 
          begin
            DoClimbWall_Begin;
          end;
        
        SDLK_z:
          begin
            ShowPlayerStats;
          end;

        // Movement & other actions
        SDLK_LEFT:  MovePlayer(-1, 0);
        SDLK_RIGHT: MovePlayer( 1, 0);
        SDLK_UP:    MovePlayer( 0,-1);
        SDLK_DOWN:  MovePlayer( 0, 1);

        SDLK_e:
          if ActiveKind = mkWorld then EnterHere_World;
      end; // case sym
    end; // keydown
  end; // while
end;


//************************************************ Run Game ************************************************
procedure RunGame;
begin
  // Initialize SDL and framebuffer
  if not GfxInit(SCREEN_WIDTH, SCREEN_HEIGHT, 1) then
  begin
    WriteLn('Failed to initialize graphics');
    Halt(1);
  end;

  if not Tiles_Init(BaseDir) then
  begin
    WriteLn('Tiles_Init failed (UNIV.CON / LAND.CON / PLAYER.CON).');
    Halt(1);
  end;

  Mons_Init(BaseDir);         // << init monster system (data dir)

  try
    WriteLn('Initializing game state...');
    //InitializeWorld;
    SoundInit('data\music');
    // Load world map
    WriteLn('Loading world map...');
    LoadWorldMap('data\WORLD.MAP');
    WriteLn('World map loaded. Dimensions: ', WORLD_WIDTH, 'x', WORLD_HEIGHT);
    // Load Vampyr logo art (optional)
    WriteLn('Loading Vampyr logo...');
    if not LoadVampyrLogo then
      WriteLn('Warning: Could not load Vampyr logo');

    // Draw static chrome once (border/logo)
    DrawStaticUIOnce;

    WriteLn('Entering main game loop...');
    Running   := True;
    FrameCount:= 0;
    LastTime  := SDL_GetTicks();

    Status_Init; // sets some default Player values for testing
    Message_Init;
    Message_SetRenderHook(@RenderFrame);
    Message_SetAutoDelay(200);
    WriteMessage('ABCDEFGHIJKLMNOPQRSTUVWXYZ,./\-+"~`[]');
    WriteMessage('abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+{}|:"<>?');
    while Running do
    begin
      HandleInput;      // movement-driven logic lives here
      RenderFrame;     // draw full frame if display is not frozen
      SDL_Delay(16);    // ~60 fps
      Inc(FrameCount);
    end;


  finally
    Tiles_Done;
    SoundShutdown;  
    GfxQuit;
  end;

end;

//************************************************ Main Begin ************************************************

begin
  // Run the game with all initialization handled in RunGame
  try
    RunGame;
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;

  end.