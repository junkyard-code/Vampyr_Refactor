unit StatusPanel;
{$mode objfpc}{$H+}

interface

uses
  uItems, SysUtils;

type
  TStats = record
    PhyStr: Byte;  // Physical Strength
    MenStr: Byte;  // Mental Strength
    Dex   : Byte;  // Dexterity
    Con   : Byte;  // Constitution
    Cha   : Byte;  // Charisma
    Luck  : Byte;  // Luck
  end;

  TPlayer = record
    Name     : AnsiString;
    Race     : Byte;
    Level    : Byte;
    Life     : Integer;
    CLife    : Integer;
    Gold     : Integer;
    XP       : LongInt;
    Magic    : Byte;
    CMagic   : Byte;
    Stats    : TStats;
    Weapon   : Byte;
    Armor    : Byte;

    TempSkills : Array[1..4] Of Byte;
    Skills : Array[1..9] Of Byte;
    Mission : Array[1..6] Of Boolean;  { 6 = Killed Vampyr }
    KingTalk : Array[1..5] Of Boolean;
    Items : Array[1..4] Of Boolean; { 1 = Rose 2 = Meet Dalagash }
                        { 3= Bought round of drinks 4= Learned Rust Spell }
    XLoc,YLoc : Byte;
    MiscMagic,StepsWalked:Byte;
    BackPack : Array[1..5] of Byte; {contains weapons, 0 for none}
    WeaponDur : Array[0..5] Of ShortInt;
    ArmorDur : ShortInt;

  end;


var
  Player: TPlayer;

procedure Status_Init;
procedure Status_Draw;
function RaceToText(r: Byte): AnsiString;

implementation

uses
  uGfx_fb; // FB, ScreenW/ScreenH, BlitText6x8

// ============================ LAYOUT & COLORS ============================

const
  STATUS_X         = 528;           // left edge in pixels
  STATUS_Y         = 124;          // top edge in pixels (adjust to sit under your logo)
  STATUS_W         = 740;          // panel width to clear
  STATUS_H         = 392;          // panel height to clear

  STATUS_SCALE     = 3;            // match your message scale
  STATUS_LINE_H    = 36;           // match your message line height

  COL1_X           = STATUS_X + 40;
  COL2_X           = STATUS_X + 400;
  COL_TOP_Y        = STATUS_Y + 30;

  ROW_SPACING      = STATUS_LINE_H;
  COLON_PAD_PX     = 0;            // gap between header end and ':'
  VALUE_PAD_PX     = 8;            // gap between ':' and value

  HDR_COLOR        = $FF707070;    // gray headers
  VAL_COLOR        = $FF00A7A7;    // teal values
  PANEL_BG         = $FF000000;    // black background

// ============================ helpers ============================

// 5x8 advance (since you’re rendering 6x8 as 5x8 tighter)
function TextWidth5x8(const s: AnsiString; scale: Integer): Integer;
begin
  // 5 columns + 1px intra-glyph spacing at chosen scale
  Result := Length(s) * (5*scale + scale);
end;

function RaceToText(r: Byte): AnsiString;
begin
  case r of
    0: Result := 'Human';
    1: Result := 'Dwarf';
    2: Result := 'Elf';
    3: Result := 'Gnome';
    4: Result := 'god';
    5: Result := 'god';
  else
    Result := 'Unknown';
  end;
end;

// simple rectangle fill directly on FB[]
procedure FillRectFB(x, y, w, h: Integer; color: LongWord);
var
  yy, xx, idx: Integer;
begin
  if w <= 0 then Exit;
  if h <= 0 then Exit;
  if x < 0 then begin w += x; x := 0; end;
  if y < 0 then begin h += y; y := 0; end;
  if x + w > ScreenW then w := ScreenW - x;
  if y + h > ScreenH then h := ScreenH - y;
  if (w <= 0) or (h <= 0) then Exit;

  for yy := 0 to h - 1 do
  begin
    idx := (y + yy) * ScreenW + x;
    for xx := 0 to w - 1 do
      FB[idx + xx] := color;
  end;
end;

// compute max header width (in pixels) for colon alignment
function MaxHeaderWidthPx(const headers: array of AnsiString): Integer;
var
  i, w: Integer;
begin
  Result := 0;
  for i := 0 to High(headers) do
  begin
    w := TextWidth5x8(headers[i], STATUS_SCALE) + COLON_PAD_PX;
    if w > Result then Result := w;
  end;
end;

var
  MaxHdrWCol1, MaxHdrWCol2: Integer;

function ColonStopForColumn(const baseX: Integer): Integer;
begin
  if baseX = COL1_X then
    Result := MaxHdrWCol1
  else
    Result := MaxHdrWCol2;
end;

procedure DrawLabelValue(const baseX, y: Integer; const header, value: AnsiString; const color: LongWord);
var
  colonX, valueX: Integer;
begin
  // header
  BlitText6x8(header, baseX, y, HDR_COLOR, STATUS_SCALE);
  // colon aligned at the column stop
  colonX := baseX + ColonStopForColumn(baseX);
  BlitText6x8(':', colonX, y, HDR_COLOR, STATUS_SCALE);
  // value
  valueX := colonX + TextWidth5x8(':', STATUS_SCALE) + VALUE_PAD_PX;
  BlitText6x8(value, valueX, y, color, STATUS_SCALE);
end;

// ============================ public API ============================

procedure Status_Init;
var
  x: Integer;
begin
  // test defaults; replace as you wire your loader
  Player.Name   := 'Balin';
  Player.Race   := 1;
  Player.Level  := 1;
  Player.Life   := 30;  Player.CLife := 30;
  Player.Magic  := 5;   Player.CMagic:= 5;
  Player.Gold   := 520;
  Player.XP     := 400;
  Player.Stats.PhyStr := 10;
  Player.Stats.MenStr := 8;
  Player.Stats.Dex    := 9;
  Player.Stats.Con    := 10;
  Player.Stats.Cha    := 13;
  Player.Stats.Luck   := 6;
  Player.Weapon := 1;
  Player.Armor  := 1;

  for x := 1 to 4 do Player.TempSkills[x] := 25;
  for x := 1 to 9 do Player.Skills[x] := 25;
  for x := 1 to 6 do Player.Mission[x] := False;
  for x := 1 to 5 do Player.KingTalk[x] := False;
  for x := 1 to 4 do Player.Items[x] := False;
                        { 3= Bought round of drinks 4= Learned Rust Spell }
  Player.XLoc := 43;
  Player.YLoc := 44;
  Player.MiscMagic := 0;
  Player.StepsWalked := 0;
  for x := 1 to 5 do Player.BackPack[x] := 0;
  for x := 0 to 5 do Player.WeaponDur[x] := 0;
  Player.ArmorDur := 0;


end;

procedure Status_Draw;
const
  COL1_HDR: array[0..7] of AnsiString = (
    'Name','Race','Life','Magic','X.P.','Gold','Weapon','Armor'
  );
  COL2_HDR: array[0..6] of AnsiString = (
    'Level','Phy. Strength','Men. Strength','Dexterity','Constitution','Charisma','Luck'
  );
var
  y: Integer;
  v: AnsiString;
begin
  // clear status panel area to black (prevents ghosting)
  FillRectFB(STATUS_X, STATUS_Y, STATUS_W, STATUS_H, PANEL_BG);

  // measure header stops for both columns
  MaxHdrWCol1 := MaxHeaderWidthPx(COL1_HDR);
  MaxHdrWCol2 := MaxHeaderWidthPx(COL2_HDR);

  // left column
  y := COL_TOP_Y;
  DrawLabelValue(COL1_X, y, 'Name',  Player.Name, VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL1_X, y, 'Race',  RaceToText(Player.Race), VAL_COLOR); y += ROW_SPACING;
  v := Format('%d/%d',[Player.CLife, Player.Life]);
  Case Player.CLife Of
    1..5 : DrawLabelValue(COL1_X, y, 'Life',  v, $FFFF5555);  // low health displays red
    6..10 : DrawLabelValue(COL1_X, y, 'Life',  v, $FFFFFF55);  // medium health displays yellow
    Else DrawLabelValue(COL1_X, y, 'Life',  v, VAL_COLOR);  // else display in default teal
  End;
  y += ROW_SPACING;
  v := Format('%d/%d',[Player.CMagic, Player.Magic]);
  DrawLabelValue(COL1_X, y, 'Magic', v, VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL1_X, y, 'X.P.',  IntToStr(Player.XP), VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL1_X, y, 'Gold',  IntToStr(Player.Gold), VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL1_X, y, 'Weapon', DecodeWeapon(Player.Weapon).Name, VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL1_X, y, 'Armor',  DecodeArmor(Player.Armor).Name, VAL_COLOR); y += ROW_SPACING;
  
  //DrawLabelValue(COL1_X, y, 'Weapon', WeaponToText(Player.Weapon), VAL_COLOR); y += ROW_SPACING;
  //DrawLabelValue(COL1_X, y, 'Armor',  ArmorToText(Player.Armor), VAL_COLOR);

  // right column
  y := COL_TOP_Y;
  DrawLabelValue(COL2_X, y, 'Level', IntToStr(Player.Level), VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL2_X, y, 'Phy. Strength', IntToStr(Player.Stats.PhyStr), VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL2_X, y, 'Men. Strength', IntToStr(Player.Stats.MenStr), VAL_COLOR); y += ROW_SPACING;
  DrawLabelValue(COL2_X, y, 'Dexterity',     IntToStr(Player.Stats.Dex),    VAL_COLOR);    y += ROW_SPACING;
  DrawLabelValue(COL2_X, y, 'Constitution',  IntToStr(Player.Stats.Con),    VAL_COLOR);    y += ROW_SPACING;
  DrawLabelValue(COL2_X, y, 'Charisma',      IntToStr(Player.Stats.Cha),    VAL_COLOR);    y += ROW_SPACING;
  DrawLabelValue(COL2_X, y, 'Luck',          IntToStr(Player.Stats.Luck), VAL_COLOR);
end;

end.
