unit uShops;
{$mode objfpc}{$H+}

interface

uses
  UConTiles, uGfx_fb, SDL2, SysUtils, uItems, uMerchant, StatusPanel, uDisplay, fb_viewer;

type
  TShopKind = (skNone, skPub, skInn, skWeapon, skArmor, skTransport, skTraining);
  TStatusRefreshProc = procedure;  // Callback type for status refresh
  TWorldSwitchProc = procedure;    // Callback type for world map switch



type
  TSkillArray = array[1..9] of Byte;

var
  OnStatusRefresh: TStatusRefreshProc = nil;  // Will be assigned by main program
  OnEnsureWorldMap: TWorldSwitchProc = nil;    // Will be assigned by main program

function Shop_DetectKind(const m1: ShortString): TShopKind;
procedure Shop_Handle(const m1, m2: ShortString; var P: StatusPanel.TPlayer);

implementation

// Map a 1-based skill ID (1..9) to the backing array index, using Low(...) for safety.
function SkillIndex0(const P: StatusPanel.TPlayer; SkillId1: Integer): Integer;
begin
  // Works whether Skills is [0..8] or [1..9]
  Result := Low(P.Skills) + (SkillId1 - 1);
end;

function GetSkill(const P: StatusPanel.TPlayer; SkillId1: Integer): Byte;
begin
  Result := P.Skills[ SkillIndex0(P, SkillId1) ];
end;

procedure SetSkill(var P: StatusPanel.TPlayer; SkillId1: Integer; Value: Byte);
begin
  P.Skills[ SkillIndex0(P, SkillId1) ] := Value;
end;

function GetTempSkill(const P: StatusPanel.TPlayer; SkillId1: Integer): Byte;
begin
  Result := P.TempSkills[ SkillIndex0(P, SkillId1) ];
end;

procedure AddTempSkill(var P: StatusPanel.TPlayer; SkillId1: Integer; Delta: Integer);
var
  idx: Integer;
begin
  idx := SkillIndex0(P, SkillId1);
  P.TempSkills[idx] := P.TempSkills[idx] + Delta;
end;

// === XP table exactly like DOS ===
function NextLevelXP(Level: Integer): Integer;
const
  XPTable: array[1..14] of Integer = (
    300, 900, 1800, 2900, 4200, 5600, 7200, 9000, 11000, 13500, 16500, 20000, 24000, 28000
  );
begin
  if (Level >= 1) and (Level <= High(XPTable)) then
    Exit(XPTable[Level])
  else
    Exit(0);
end;

// Parse m1 like the DOS trainer: m1[5]=count; then ids at 7,9,11,...
procedure ParseTrainerOffers(const m1: ShortString; out Offered: array of Boolean);
var
  n, i, id, err: Integer;
begin
  FillChar(Offered[0], Length(Offered) * SizeOf(Boolean), 0);
  n := 0;
  if Length(m1) >= 5 then Val(m1[5], n, err);
  for i := 0 to n - 1 do
  begin
    if (i * 2 + 7) <= Length(m1) then
    begin
      Val(m1[i * 2 + 7], id, err);
      if (err = 0) and (id >= 1) and (id <= 9) then
        Offered[id - 1] := True;
    end;
  end;
end;

function SkillName(Id1Based: Integer): AnsiString;
begin
  case Id1Based of
    1: Result := 'F. Attack';
    2: Result := 'F. Defense';
    3: Result := 'M. Offensive';
    4: Result := 'M. Defensive';
    5: Result := 'M. Miscell.';
    6: Result := 'T. Lock Picking';
    7: Result := 'T. Climbing';
    8: Result := 'T. Stealing';
    9: Result := 'T. Perception';
  else
    Result := 'Unknown';
  end;
end;

procedure Training_DrawPanel(const OfferedIds: array of Integer;
                             const Base, Cur: TSkillArray;
                             SelIdx, PointsLeft: Integer);
var
  n, rowsAvail, headerRows, rowsPerCol: Integer;
  col0Count, col1Count: Integer;
  row: Integer;
  x0, x1, y0: Integer;
  charW, colSepChars: Integer;
  S: AnsiString;
  idx, skillId: Integer;
  curVal, baseVal: Integer;
begin 
  // Clear the message region
  DrawMessageArea;

  // Header (same look as WriteMessage)
  ugfx_fb.BlitText6x8('Training: Use arrow keys to select skill, +/- to adjust, Enter to confirm',
                      MESSAGE_AREA_X, MESSAGE_AREA_Y, MSG_COLOR, MSG_SCALE);
  ugfx_fb.BlitText6x8('Points left: ' + IntToStr(PointsLeft),
                      MESSAGE_AREA_X, MESSAGE_AREA_Y + MSG_LINE_HEIGHT, MSG_COLOR, MSG_SCALE);

  // Layout
  headerRows := 2;
  rowsAvail  := MSG_MAX_LINES - headerRows;
  if rowsAvail < 3 then rowsAvail := 3;

  n := Length(OfferedIds);
  rowsPerCol := (n + 1) div 2;                 // ceil(n/2)
  if rowsPerCol > rowsAvail then rowsPerCol := rowsAvail;

  col0Count := rowsPerCol;
  col1Count := n - col0Count;
  if col1Count < 0 then col1Count := 0;

  // Column positions (you tuned this)
  charW := 6 * MSG_SCALE;
  colSepChars := 26; // adjust to taste
  x0 := MESSAGE_AREA_X;
  x1 := MESSAGE_AREA_X + colSepChars * charW;

  // First list row under header
  y0 := MESSAGE_AREA_Y + headerRows * MSG_LINE_HEIGHT;

  // Left column
  for row := 0 to col0Count - 1 do
  begin
    idx     := row;                 // 0-based index into OfferedIds
    skillId := OfferedIds[idx];     // 1..9
    curVal  := Cur[skillId];
    baseVal := Base[skillId];

    S := '';
    if idx = SelIdx then S := '>';
    S := S + IntToStr(skillId) + ') ' + SkillName(skillId);
    S := S + '  ' + IntToStr(curVal) + ' (was ' + IntToStr(baseVal) + ')';

    ugfx_fb.BlitText6x8(S, x0, y0 + row * MSG_LINE_HEIGHT, MSG_COLOR, MSG_SCALE);
  end;

  // Right column
  for row := 0 to col1Count - 1 do
  begin
    idx     := col0Count + row;
    skillId := OfferedIds[idx];
    curVal  := Cur[skillId];
    baseVal := Base[skillId];

    S := '';
    if idx = SelIdx then S := '>';
    S := S + IntToStr(skillId) + ') ' + SkillName(skillId);
    S := S + '  ' + IntToStr(curVal) + ' (was ' + IntToStr(baseVal) + ')';

    ugfx_fb.BlitText6x8(S, x1, y0 + row * MSG_LINE_HEIGHT, MSG_COLOR, MSG_SCALE);
  end;
end;


function Training_AllocateSkills(var P: StatusPanel.TPlayer;
                                 const OfferedMask: array of Boolean): Boolean;
var
  Base, Cur: TSkillArray;
  OfferedIds: array of Integer;
  i, need, cap, points: Integer;
  ev: TSDL_Event;
  sym: LongInt;

  // two-column navigation
  sel, n, rowsAvail, headerRows, rowsPerCol: Integer;
  col0Count, col1Count: Integer;
  col, row: Integer;
  sId: Integer;

  function IndexToCol(idx: Integer): Integer;
  begin
    if idx < col0Count then Result := 0 else Result := 1;
  end;

  function IndexToRow(idx: Integer): Integer;
  begin
    if idx < col0Count then Result := idx else Result := idx - col0Count;
  end;

  function ColRowToIndex(aCol, aRow: Integer): Integer;
  begin
    if aCol = 0 then Result := aRow else Result := col0Count + aRow;
  end;

  function RowsInCol(aCol: Integer): Integer;
  begin
    if aCol = 0 then Result := col0Count else Result := col1Count;
  end;

  procedure RecomputeLayout;
  begin
    headerRows := 2;
    rowsAvail  := MSG_MAX_LINES - headerRows;
    if rowsAvail < 3 then rowsAvail := 3;

    n := Length(OfferedIds);
    rowsPerCol := (n + 1) div 2;
    if rowsPerCol > rowsAvail then rowsPerCol := rowsAvail;

    col0Count := rowsPerCol;
    col1Count := n - col0Count;
    if col1Count < 0 then col1Count := 0;
  end;

begin
  // snapshot current skills
  for i := 1 to 9 do begin Base[i] := P.Skills[i]; Cur[i] := Base[i]; end;

  // offered ids
  SetLength(OfferedIds, 0);
  for i := 0 to High(OfferedMask) do
    if OfferedMask[i] then
    begin
      SetLength(OfferedIds, Length(OfferedIds) + 1);
      OfferedIds[High(OfferedIds)] := i + 1; // 1..9
    end;
  if Length(OfferedIds) = 0 then Exit(True);

  // points pool (45 humanish, 60 other), cap by remaining room to 100
  if P.Race <= 4 then points := 45 else points := 60;
  cap := 0;
  for i := 0 to High(OfferedIds) do
  begin
    need := 100 - Base[OfferedIds[i]];
    if need > 0 then Inc(cap, need);
  end;
  if points > cap then points := cap;

  // layout
  RecomputeLayout;

  // start at the first offered item
  sel := 0;

  // first draw
  DrawStatusArea; Status_Draw;
  Training_DrawPanel(OfferedIds, Base, Cur, sel, points);
  Present;

  // modal loop
  while SDL_WaitEvent(@ev) <> 0 do
  begin
    if ev.type_ = SDL_KEYDOWN then
    begin
      sym := ev.key.keysym.sym;

      case sym of
        // selection
        SDLK_UP:
          begin
            if Length(OfferedIds) > 0 then
            begin
              col := IndexToCol(sel);
              row := IndexToRow(sel);
              Dec(row);
              if row < 0 then row := RowsInCol(col) - 1;
              sel := ColRowToIndex(col, row);
            end;
          end;

        SDLK_DOWN:
          begin
            if Length(OfferedIds) > 0 then
            begin
              col := IndexToCol(sel);
              row := IndexToRow(sel);
              Inc(row);
              if row >= RowsInCol(col) then row := 0;
              sel := ColRowToIndex(col, row);
            end;
          end;

        SDLK_LEFT:
          begin
            if Length(OfferedIds) > 0 then
            begin
              col := IndexToCol(sel);
              row := IndexToRow(sel);
              if col = 1 then
              begin
                if row >= RowsInCol(0) then row := RowsInCol(0) - 1;
                sel := ColRowToIndex(0, row);
              end
              else
              begin
                if row < RowsInCol(1) then
                  sel := ColRowToIndex(1, row);
              end;
            end;
          end;

        SDLK_RIGHT:
          begin
            if Length(OfferedIds) > 0 then
            begin
              col := IndexToCol(sel);
              row := IndexToRow(sel);
              if col = 0 then
              begin
                if row < RowsInCol(1) then
                  sel := ColRowToIndex(1, row);
              end
              else
              begin
                if row >= RowsInCol(0) then row := RowsInCol(0) - 1;
                sel := ColRowToIndex(0, row);
              end;
            end;
          end;

        // adjust value
        SDLK_PLUS, SDLK_EQUALS, SDLK_KP_PLUS:
          begin
            sId := OfferedIds[sel];
            {$IFDEF DEBUG}
              writeln('[TRAIN] + sel=', sel, ' sId=', sId, ' cur=', Cur[sId], ' points=', points);
            {$ENDIF}
            if (points > 0) and (Cur[sId] < 100) then
            begin
              Inc(Cur[sId]);
              Dec(points);
            end;
          end;

        SDLK_MINUS, SDLK_KP_MINUS:
          begin
            sId := OfferedIds[sel];
            {$IFDEF DEBUG}
              writeln('[TRAIN] - sel=', sel, ' sId=', sId, ' cur=', Cur[sId], ' points=', points);
            {$ENDIF}
            if Cur[sId] > Base[sId] then
            begin
              Dec(Cur[sId]);
              Inc(points);
            end;
          end;

        // commit when all points spent
        SDLK_RETURN, SDLK_KP_ENTER:
          begin
            if points = 0 then
            begin
              for sId := 1 to 9 do
              begin
                if Cur[sId] <> Base[sId] then
                begin
                  if (sId >= 1) and (sId <= 4) and (Cur[sId] > Base[sId]) then
                    Inc(P.TempSkills[sId], Cur[sId] - Base[sId]);
                  P.Skills[sId] := Cur[sId];
                  {$IFDEF DEBUG}
                    writeln('[TRAIN] commit sId=', sId, ' -> ', Cur[sId]);
                  {$ENDIF}
                end;
              end;
              Exit(True);
            end;
          end;

        SDLK_ESCAPE:
          Exit(False);
      end;

      // redraw
      DrawStatusArea; Status_Draw;
      Training_DrawPanel(OfferedIds, Base, Cur, sel, points);
      Present;
    end;
  end;

  Result := False;
end;

procedure ShowTrainerOfferedSkills(const OfferedMask: array of Boolean);
var
  i, shown, onLine: Integer;
  line: AnsiString;
begin
  // Lead-in line
  WriteMessage('I can train you in:');

  shown := 0;
  onLine := 0;
  line := '';

  // Make short labeled items like: "1) F. Attack"
  for i := 0 to High(OfferedMask) do
    if OfferedMask[i] then
    begin
      if onLine > 0 then
        line := line + ', ';
      line := line + IntToStr(i+1) + ') ' + SkillName(i+1);
      Inc(onLine);
      Inc(shown);

      // Wrap lines after ~4 items to keep it tidy in the message area
      if (onLine >= 4) then
      begin
        WriteMessage(line);
        line := '';
        onLine := 0;
      end;
    end;

  if line <> '' then
    WriteMessage(line);
end;

//********************************************* SleepSequence *********************************************
// ---- A minimal “sleep sequence” that mirrors the DOS timing & healing ----
procedure SleepSequence(var P: StatusPanel.TPlayer; const SleepTileX, SleepTileY, DoorTileX, DoorTileY: Integer);

var
  ticks, t: Integer;
  oldSrc: TTileSource;
  oldIdx: Word;
  r: Integer;
begin
  // Snapshot current effective player sprite so we can restore it later
  PlayerSprite_Get(oldSrc, oldIdx);

  try
    // Move player to the bed
    Player.XLoc := SleepTileX-1;
    Player.YLoc := SleepTileY-1;

    // Show 3-tile radius while sleeping
    Display_SetOcclusionRadius(3);

    // (Optional) unlock door
    if (DoorTileX > 0) and (DoorTileX <= ActiveMap.W) and
       (DoorTileY > 0) and (DoorTileY <= ActiveMap.H) then
      ActiveMap.Data[(DoorTileX-1) + (DoorTileY-1)*ActiveMap.W] := 14;

    // Switch player overlay to the sleeping sprite
    PlayerSprite_Set(tsTownMon, 11);

    WriteMessage('Zzzzzz...');
    SDL_Delay(280);
    ticks := 3 + Random(3);   // 3..5 ticks

    // If you have a Darkness(128) or similar fade, call it ONCE here (outside the loop)
    // Darkness(128);

    // First frame
    DrawMapView;       // background + animated tiles + SLEEP overlay (center)
    DrawStatusArea;    // fills panel + draws logo each frame
    Status_Draw;
    DrawMessageArea;   // fills panel
    Message_Render;
    Present;

    // === Ticks ===
    r := 3;
    for t := 1 to ticks do
    begin
      SDL_Delay(600);

      // Heal progress
      if P.CLife < P.Life then
      begin
        P.CLife := P.CLife + 8 + Random(6);
        if P.CLife > P.Life then P.CLife := P.Life;
      end;

      if P.CMagic < P.Magic then
      begin
        P.CMagic := P.CMagic + 8 + Random(3);
        if P.CMagic > P.Magic then P.CMagic := P.Magic;
      end;

      // Shrink occlusion radius as you had (clamped)
      Dec(r);
      if r < 0 then r := 0;
      Display_SetOcclusionRadius(r);

      // Redraw full scene each tick so the unified player overlay is applied
      DrawMapView;       // draws sleeper tile at center via PlayerSprite_* selector
      DrawStatusArea;
      Status_Draw;
      DrawMessageArea;
      Message_Render;
      Present;
    end;

    // Restore player overlay to what it was before sleep
    PlayerSprite_Set(oldSrc, oldIdx);

    // Wake: step off the bed (adjust as you prefer)
    Player.XLoc := SleepTileX - 1;
    Player.YLoc := SleepTileY - 1;

    // Bright scene again
    Display_SetOcclusionRadius(3);
    DrawMapView;
    DrawStatusArea;
    Status_Draw;
    DrawMessageArea;
    Message_Render;
    Present;

    WriteMessage('Boy, do you feel better!');
    if P.MiscMagic <> 0 then
    begin
      WriteMessage('Your misc. spell wore out while you slept.');
      P.MiscMagic := 0;
    end;

  finally
    // Ensure occlusion is back to default for normal play
    Display_SetOcclusionRadius(3);

  end;
end;




//********************************************* Shop_DetectKind *********************************************
// ---- Detect shop kind ----
function Shop_DetectKind(const m1: ShortString): TShopKind;
var a,b: Char;
begin
  if Length(m1) < 2 then Exit(skNone);
  a := UpCase(m1[1]); b := UpCase(m1[2]);
  if (a='P') and (b='U') then Exit(skPub);
  if (a='I') and (b='N') then Exit(skInn);
  if (a='W') and (b='P') then Exit(skWeapon);
  if (a='A') and (b='R') then Exit(skArmor);
  if (a='T') and (b='N') then Exit(skTransport);
  if (a='T') and (b='R') then Exit(skTraining);
  Result := skNone;
end;


//********************************************* Pub_Handle *********************************************
// ---- Handle pub ----
procedure Pub_Handle(const m1, m2: ShortString; var P: StatusPanel.TPlayer);
  function Wants(const labelTxt: string; cost: Integer): Boolean;
  begin
    Result := Message_PromptYesNo(labelTxt + ' ['+IntToStr(cost)+' gp] ?');
    if Result then
    begin
      if P.Gold < cost then begin WriteMessage('You''ve got no cash! Get out!'); Exit(False); end;
      Dec(P.Gold, cost);
    end;
  end;
var special: Char;
begin
  special := #0;
  if Length(m1) >= 5 then special := m1[5];

  // Simple Y/N prompts (keeps UI consistent with your MessageSys)
  if Wants('Ale', 1)   then WriteMessage('<Belch!> Not bad!');
  if Wants('Bread', 1) then WriteMessage('<Belch!> Not bad!');
  if Wants('Beer', 1)  then WriteMessage('<Belch!> Not bad!');
  if Wants('Mutton', 4) then WriteMessage('<Belch!> Not bad!');
  if Wants('Wine', 5)  then WriteMessage('<Belch!> Not bad!');
  if Wants('Round of drinks', 10) then
  begin
    P.Items[3] := True;
    WriteMessage('"You are an okay guy..."');
  end;

  // If the player happened to press exactly the configured digit in the DOS version,
  // the game printed Msg2. We’ll preserve the spirit: if special matches any of '1'..'6',
  // echo the bonus line once.
  if special in ['1'..'6'] then
    WriteMessage(m2);
end;


//********************************************* Transport_Handle *********************************************
// ---- Handle transport ----
procedure Transport_Handle(const m1, m2: ShortString; var P: StatusPanel.TPlayer);
var
  F: File;                            // untyped file (record size = 25)
  Seg: array[0..24] of Byte;         // one segment from BOAT.DAT
  route, price, code, rec, i: Integer;
  dx, dy: Integer;
  SX,SY,EX,EY: Integer;
begin
  if (Length(m1) < 16) or (UpCase(m1[1]) <> 'T') or (UpCase(m1[2]) <> 'N') then Exit;

  Val(Copy(m1,5,2), route, code); if code <> 0 then route := 0;
  Val(Copy(m1,13,4), price, code); if code <> 0 then price := 0;

  WriteMessage('Welcome to the transport.');
  WriteMessage('The trip will take you to ' + m2 + '.');

  if not Message_PromptYesNo('It will only cost you ' + IntToStr(price) + ' gold pieces. Ok?') then
  begin
    WriteMessage('Go drown in a sea.');
    Exit;
  end;

  if P.Gold < price then
  begin
    WriteMessage('Sorry. No gold, no trip.');
    Exit;
  end;

  Dec(P.Gold, price);
  DrawStatusArea;

  // Route bounds (legacy BoatTrip case table)
  SX:=P.XLoc; SY:=P.YLoc; EX:=P.XLoc; EY:=P.YLoc;
  case route of
     0: begin SX:=14; SY:=57; EX:=18; EY:=83; end;
     2: begin SX:=18; SY:=84; EX:=15; EY:=57; end;
     4: begin SX:=41; SY:=80; EX:=55; EY:=90; end;
     5: begin SX:=54; SY:=90; EX:=15; EY:=57; end;
     8: begin SX:=54; SY:=90; EX:=45; EY:=43; end;
    11: begin SX:=87; SY:=58; EX:=45; EY:=43; end;
    17: begin SX:=87; SY:=58; EX:=87; EY:=92; end;
  end;

  // Force world view (simple & explicit)
  // Start offshore like DOS, and draw once
  Player.XLoc := SX; Player.YLoc := SY;
  PlayerSprite_Set(tsLand, 9);  // boat from LAND.CON index 9
  AM_SetActiveToWorld;

  WriteMessage('Full sail ahead...');
    DrawMapView;       // background + animated tiles + SLEEP overlay (center)
    DrawStatusArea;    // fills panel + draws logo each frame
    Status_Draw;
    DrawMessageArea;   // fills panel
    Message_Render;
    Present;

  // Open BOAT.DAT (fixed 25-byte records)
  Assign(F, 'data' + DirectorySeparator + 'BOAT.DAT');
  {$I-} Reset(F, 25); {$I+}
  if IOResult <> 0 then
  begin
    WriteMessage('No boats today (missing BOAT.DAT).');
    PlayerSprite_Set(tsPlayer, 0);
    DrawMapView;       // background + animated tiles + SLEEP overlay (center)
    DrawStatusArea;    // fills panel + draws logo each frame
    Status_Draw;
    DrawMessageArea;   // fills panel
    Message_Render;
    Present;
    Exit;
  end;

  rec := route;
  repeat
    {$I-} Seek(F, rec); BlockRead(F, Seg, 1); {$I+}
    if IOResult <> 0 then Break;

    for i := 0 to 24 do
    begin
      // Legacy cue: ~6 steps before first zero inside segment
      if (i < 19) and (Seg[i+6] = 0) then
        WriteMessage('Port ahead, captain!');

      // Step decode (1=N,2=E,3=W,4=S)
      dx := 0; dy := 0;
      case Seg[i] of
        1: dy := -1; // N
        2: dx := +1; // E
        3: dx := -1; // W
        4: dy := +1; // S
      end;
      if Seg[i] in [1..4] then
      begin
        Inc(Player.XLoc, dx); Inc(Player.YLoc, dy);
        DrawMapView;       // background + animated tiles + SLEEP overlay (center)
        DrawStatusArea;    // fills panel + draws logo each frame
        Status_Draw;
        DrawMessageArea;   // fills panel
        Message_Render;
        Present;
        SDL_Delay(200); // pacing similar to DOS feel
      end;
    end;

    if Seg[24] <> 0 then
      Inc(rec)
    else
      Break;
  until False;

  Close(F);

  WriteMessage('There you go, sir.');

  // Snap to the dock/port tile on land (legacy behavior)
  Player.XLoc := EX; Player.YLoc := EY;

  // Restore normal player sprite and draw
  PlayerSprite_Set(tsPlayer, 0);
  DrawMapView;       // background + animated tiles + SLEEP overlay (center)
  DrawStatusArea;    // fills panel + draws logo each frame
  Status_Draw;
  DrawMessageArea;   // fills panel
  Message_Render;
  Present;
end;


//********************************************* Training_Handle *********************************************
// ---- Handle training ----
procedure Training_Handle(const m1, m2: ShortString; var P: StatusPanel.TPlayer);
var
  OfferedMask: array[0..8] of Boolean; // 9 skills
  xpNext, cost, need: Integer;
  priceF: Double;
  ok: Boolean;
  // level-up math
  conBonus, menBonus, B, roll, tries, statIdx: Integer;
begin
  ParseTrainerOffers(m1, OfferedMask);

  xpNext := NextLevelXP(P.Level);
  if xpNext = 0 then
  begin
    WriteMessage('You''re too powerful already.');
    Exit;
  end;

  if P.XP < xpNext then
  begin
    need := xpNext - P.XP;
    WriteMessage('You need ' + IntToStr(need) + ' Ex. points to reach the next level.');
    Exit;
  end;

  // Price = xpNext / (Level + 8), then CHA discount (+CHA > cheaper; <10 pricier)
  cost := xpNext div (P.Level + 8);
  priceF := cost - cost * ((P.Stats.Cha - 10) / 100.0);
  if priceF < 1.0 then priceF := 1.0;
  cost := Round(priceF);

ShowTrainerOfferedSkills(OfferedMask);

  // Ask for confirmation with the price
  if not Message_PromptYesNo('For only ' + IntToStr(cost) + ' gold pieces. Ok?') then
    begin
      WriteMessage('Maybe another time.');
    Exit;
    end;

  if P.Gold < cost then
  begin
    WriteMessage('Maybe another time.');
    Exit;
  end;

  // Deduct up front (matches DOS feel)
  Dec(P.Gold, cost);

  // Modal allocation
  ok := Training_AllocateSkills(P, OfferedMask);
  if not ok then
  begin
    // If you prefer NOT to refund on cancel, remove the next line
    Inc(P.Gold, cost);
    WriteMessage('Training canceled.');
    Exit;
  end;

  // Level up
  Inc(P.Level);

  // HP gain: 5..8 + CON bonus if >10
  if P.Stats.Con > 10 then conBonus := (P.Stats.Con - 10) div 2 else conBonus := 0;
  Inc(P.Life, 5 + Random(4) + conBonus);
  P.CLife := P.Life;

  // MP gain: 2..4 + MEN bonus if >13
  if P.Stats.MenStr > 13 then menBonus := (P.Stats.MenStr - 13) div 2 else menBonus := 0;
  Inc(P.Magic, 2 + Random(3) + menBonus);
  P.CMagic := P.Magic;

  // Chance to raise a base stat: B = Level*3 + (Con-10)
  B := P.Level * 3 + (P.Stats.Con - 10);
  if B < 0 then B := 0;
  roll := Random(100) + 1;
  if roll <= B then
  begin
    for tries := 1 to 24 do
    begin
      statIdx := 1 + Random(6);
      case statIdx of
        1: if P.Stats.PhyStr < 20 then begin Inc(P.Stats.PhyStr); Break; end;
        2: if P.Stats.MenStr < 20 then begin Inc(P.Stats.MenStr); Break; end;
        3: if P.Stats.Dex   < 20 then begin Inc(P.Stats.Dex);    Break; end;
        4: if P.Stats.Con   < 20 then begin Inc(P.Stats.Con);    Break; end;
        5: if P.Stats.Cha   < 20 then begin Inc(P.Stats.Cha);    Break; end;
        6: if P.Stats.Luck  < 20 then begin Inc(P.Stats.Luck);   Break; end;
      end;
    end;
  end;

  if Length(m2) > 0 then
    WriteMessage(m2)
  else
    WriteMessage('You feel more capable already.');

  DrawStatusArea; Status_Draw; Present;
end;

//********************************************* Shop_Handle *********************************************
// ---- Handle shop ----
procedure Shop_InnHandle(const m1, m2: ShortString; var P: StatusPanel.TPlayer);
var
  price, err: Integer;
  tempX, tempY: Integer;  // “display map” center (we’ll use the bed coords instead)
  tileX, tileY: Integer;  // bed tile where we place SLEEP_TILE_ID
  oldPX, oldPY: Integer;  // <-- save/restore player location
begin
  if Length(m1) < 17 then
  begin
    WriteMessage('The innkeeper shrugs; something seems off with this inn.');
    Exit;
  end;

  if m2 <> '' then WriteMessage(m2);
  Val(m1[5], price, err); if err <> 0 then price := 0;
  
  if P.Gold < price then
  begin
    WriteMessage('No gold, no nap.');
    Exit;
  end;
  if not Message_PromptYesNo('A night of rest will cost you ' + IntToStr(price) + ' gold pieces. Pay?') then
  begin
    WriteMessage('Get outta here, then!');
    Exit;
  end;

  // Player pays for Inn
  Dec(P.Gold, price);
  DrawStatusArea;
  RenderFrame;

  // Parse coords (same layout as DOS)
  Val(Copy(m1, 7, 2),  tempX, err); if err<>0 then tempX := P.XLoc;   // not used to center anymore
  Val(Copy(m1,10, 2),  tempY, err); if err<>0 then tempY := P.YLoc;
  Val(Copy(m1,13, 2),  tileX, err); if err<>0 then tileX := tempX;
  Val(Copy(m1,16, 2),  tileY, err); if err<>0 then tileY := tempY;

  // Sleep sequence places player at tempX, tempY, and unlock door at tileX, tileY
  SleepSequence(P, tempX, tempY, tileX, tileY);


end;


//********************************************* Shop_Handle *********************************************
// ---- Handle shop ----
procedure Shop_Handle(const m1, m2: ShortString; var P: StatusPanel.TPlayer);
var
  kind: TShopKind;
  sellOnlyKind:  TItemKind;
begin
  kind := Shop_DetectKind(m1);
  case kind of
    skInn:
      begin
        Shop_InnHandle(m1, m2, P); // your inn handler
        Exit;
      end;
    skWeapon:
      begin
        sellOnlyKind := ikWeapon;
        Merchant_TradeStock(P, sellOnlyKind, m1,m2); // restrict sells to weapons
        Exit;
      end;
    skArmor:
      begin
        sellOnlyKind := ikArmor;
        Merchant_TradeStock(P, sellOnlyKind, m1,m2);  // restrict sells to armor
        Exit;
      end;
    skPub:
      begin
        Pub_Handle(m1, m2, P);
        Exit;
      end;
    skTransport:
      begin
        Transport_Handle(m1, m2, P);
        Exit;
      end;
    skTraining:
      begin
        Training_Handle(m1, m2, P);
        Exit;
      end;
  else
    WriteMessage('The shopkeeper stares blankly.');
  end;
end;


end.
