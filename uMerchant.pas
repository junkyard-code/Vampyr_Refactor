unit uMerchant;
{$mode objfpc}{$H+}

interface

uses
  SysUtils, uDisplay, uItems, StatusPanel; // use the canonical TPlayer here


type
  TVendorStock = record
    Count: Integer;       // number of items in stock
    Codes: array of Byte; // legacy item codes
  end;

type
  TItemKind = (ikNone, ikWeapon, ikArmor);

  TQuality = (qBase, qPlus1, qPlus2, qPlus3, qSpecial);

  // Decoded view of a legacy item code (Byte) from the original game
  TDecodedItem = record
    Kind: TItemKind;
    BaseId: Byte;        // 0..10 weapons, 0..10 armors (as per original)
    Quality: TQuality;   // derived from code thresholds (>10, >20, >30, 41+)
    Code: Byte;          // original code
  end;

type
  // A vendor builder proc (so you can pass Town vs Castle presets)
  TBuildStockProc = procedure(var Stock: TVendorStock);

// IMPORTANT: Use the exact TPlayer that callers have: StatusPanel.TPlayer
procedure Merchant_TradeStock(var Player: StatusPanel.TPlayer; SellOnlyKind: TItemKind; const MonMsg1, MonMsg2: ShortString);

function AdjustPriceByCha(const Cha: Byte; Base: Integer): Integer;

implementation


function WeaponPrice(const Code: Byte): Integer;
var
  basePrice: Integer;
begin
  basePrice := DecodeWeapon(Code).Price;
  WriteLn('WeaponPrice - Code: ', Code, ', Base Price: ', basePrice);
  Result := AdjustPriceByCha(Player.Stats.Cha, basePrice);
  WriteLn('WeaponPrice - Final Price: ', Result);
end;

function ArmorPrice(const Code: Byte): Integer;
begin
  Result := DecodeArmor(Code).Price;
  Result := AdjustPriceByCha(Player.Stats.Cha, Result);
end;


function AdjustPriceByCha(const Cha: Byte; Base: Integer): Integer;
var adj: Double;
begin
  adj := Base + Base * ((Integer(Cha) - 10) / 100.0);
  if adj < 0 then adj := 0;
  Result := Round(adj);
  WriteLn('Adjusting price by Cha:');
  WriteLn(Format('Base: %d, Cha: %d, Adj: %f, Result: %d', 
    [Base, Cha, adj, Result]));
end;


//********************************************* BuildStockFromMsg1_WP_AR *********************************************
// ---- Build stock from message 1 ----
procedure BuildStockFromMsg1_WP_AR(const m1: ShortString; out Stock: TVendorStock);
var
  count,i,code,err: Integer;
  s: String;
begin
  // default empty
  Stock.Count := 0; SetLength(Stock.Codes,0);

  // Parse m1[5..6] (two digits) to get item count that merchant carries
  if Length(m1) < 6 then Exit;
  Val(Copy(m1,5,2), count, err);
  if err<>0 then Exit;
  if count<=0 then Exit;

  SetLength(Stock.Codes, count);
  Stock.Count := count;

  // Now, parse each item code is two digits at offsets (i*3+8 .. +9) (1-based)
  for i:=0 to count-1 do
  begin
    if (i*3+9) > Length(m1) then begin Stock.Count := i; SetLength(Stock.Codes, Stock.Count); Exit; end;
    s := m1[i*3+8] + m1[i*3+9];
    Val(s, code, err);
    if err<>0 then code := 0;
    Stock.Codes[i] := Byte(code);
  end;
end;


// ========== SELL FLOWS (faithful chatter) ==========

procedure RunSellWeapons_Original(var P: StatusPanel.TPlayer);
var
  a, basePrice, baseDur, offer: Integer;
  z: Double;
  st: string;
  it: TWeaponView;
begin
  // list backpack 1..5 with names
  for a := 1 to 5 do
  begin
    if P.BackPack[a] = 0 then
      st := 'Nothing'
    else
      st := DecodeWeapon(P.BackPack[a]).Name;
    WriteMessage(IntToStr(a) + '> ' + st);
  end;

  // ask for slot using SDL-based prompt (no frame/dividers)
  if not Message_PromptDigitInline('Choose backpack slot (1-5):', 1, 5, a) then
  begin
    WriteMessage('Like I keep telling ya, LEARN TO USE THE NUMBER KEYS!');
    Exit;
  end;

  if (P.BackPack[a] <> 0) then
  begin
    basePrice := WeaponPrice(P.BackPack[a]);
    it := DecodeWeapon(P.BackPack[a]);
    basePrice := it.Price;
    baseDur   := it.Durability;

    // DOS-style condition factor
    z := basePrice + basePrice * (( (P.WeaponDur[a] div 2) - (baseDur div 4) ) / 100.0);
    if z < 0 then z := 0;
    offer := Round(z) div 2;

    if Message_PromptYesNoInline('I''ll give you ' + IntToStr(offer) + ' gold pieces for it, Ok?') then
    begin
      P.BackPack[a] := 0;
      P.WeaponDur[a] := 0;
      Inc(P.Gold, offer);
      WriteMessage('It has better be a good weapon.');
    end
    else
      WriteMessage('<Why you greedy little...>');
  end
  else
    WriteMessage('Like I keep telling ya, LEARN TO USE THE NUMBER KEYS!');
end;


procedure RunSellArmor_Original(var P: StatusPanel.TPlayer);
var
  offer: Integer;
  z: Double;
  it: TArmorView;
begin
  if P.Armor > 0 then
  begin
    it := DecodeArmor(P.Armor);
    z := it.Price + it.Price * (( (P.ArmorDur div 2) - (it.Durability div 4) ) / 100.0);
    if z < 0 then z := 0;
    offer := Round(z);
    offer := (offer div 2) + Random(3) - 1;  // -1..+1 wobble like DOS

    if Message_PromptYesNoInline('I''ll give you ' + IntToStr(offer) +
                                 ' gold pieces for your armor, Ok?') then
    begin
      P.Armor := 0;
      P.ArmorDur := 0;
      Inc(P.Gold, offer);
      WriteMessage('It has better be a good suit of armor.');
    end
    else
      WriteMessage('<Why you greedy little...>');
  end
  else
    WriteMessage('Oh, you''re selling your body. That''s nice.');
end;

function FirstEmptyBackpackSlot(const P: StatusPanel.TPlayer): Integer;
var
  i: Integer;
begin
  for i := Low(P.BackPack) to High(P.BackPack) do
    if P.BackPack[i] = 0 then
      Exit(i);
  Result := -1;
end;

procedure AddToBackpack(var P: StatusPanel.TPlayer; Code: Byte);
var
  slot: Integer;
  it: TWeaponView;
begin
  slot := FirstEmptyBackpackSlot(P);
  if slot < 0 then
  begin
    WriteMessage('Your pack is full.');
    Exit;
  end;

  // store the weapon
  P.BackPack[slot] := Code;

  // unified DOS-accurate durability cap
  it := DecodeWeapon(Code);
  P.WeaponDur[slot] := it.Durability;
end;

procedure RemoveBackpackSlot(var P: StatusPanel.TPlayer; Slot: Integer);
begin
  if (Slot < Low(P.BackPack)) or (Slot > High(P.BackPack)) then Exit;
  P.BackPack[Slot] := 0;
  P.WeaponDur[Slot] := 0;
end;



function LettersForCount(const Count: Integer): string;
var
  i: Integer;
begin
  Result := '';
  if Count <= 0 then Exit;

  // First 26 -> A..Z
  for i := 0 to Count - 1 do
  begin
    if i < 26 then
      Result := Result + Chr(Ord('A') + i)
    else if i < 52 then
      Result := Result + Chr(Ord('a') + (i - 26))
    else
      Break; // cap at 52 choices (extend if you ever need more)
  end;
end;

function LetterToIndex(const Ch: Char): Integer;
begin
  if (Ch >= 'A') and (Ch <= 'Z') then
    Exit(Ord(Ch) - Ord('A'));
  if (Ch >= 'a') and (Ch <= 'z') then
    Exit(26 + Ord(Ch) - Ord('a'));
  Result := -1;
end;



//********************************************* Merchant_TradeStock *********************************************

procedure Merchant_TradeStock(var Player: StatusPanel.TPlayer;
                              SellOnlyKind: TItemKind; const MonMsg1, MonMsg2: ShortString);
  // ---------- local helpers (scoped to this proc) ----------
  
  var 
    Stock: TVendorStock;
  

  function PadRight(const S: string; W: Integer): string;
  begin
    Result := S;
    while Length(Result) < W do Result := Result + ' ';
  end;

  function ItemNameByKind(Code: Byte; Kind: TItemKind): string;
  var itA: TArmorView;
      itW: TWeaponView;
  begin
    if Kind = ikArmor then begin itA := DecodeArmor(Code); Result := itA.Name end
                      else begin itW := DecodeWeapon(Code); Result := itW.Name end;
  end;


procedure RenderPageTwoColumns(const StartIdx, Rows: Integer);
// Renders Rows lines; each line shows up to two items (StartIdx + r*2, +1)
var
  r, li, ri, total, price: Integer;
  left, right: string;
begin
  total := Stock.Count;
  for r := 0 to Rows - 1 do
  begin
    li := StartIdx + (r * 2);
    if li >= total then Exit;

    // Get price based on item type
    if SellOnlyKind = ikArmor then
      price := ArmorPrice(Stock.Codes[li])
    else
      price := WeaponPrice(Stock.Codes[li]);
    
    left := Format('%s> %s [%d gp]',
                  [Chr(Ord('A') + StartIdx + r*2),
                  ItemNameByKind(Stock.Codes[li], SellOnlyKind), price]);

    ri := li + 1;
    if ri < total then
    begin
      // Get price for right column item
      if SellOnlyKind = ikArmor then
      begin
        //armorView := DecodeArmor(Stock.Codes[ri]);
        price := ArmorPrice(Stock.Codes[ri]);
      end
      else
      begin
        //weapView := DecodeWeapon(Stock.Codes[ri]);
        price := WeaponPrice(Stock.Codes[ri]);
      end;
      
      right := Format('%s> %s [%d gp]',
                     [Chr(Ord('A') + StartIdx + r*2 + 1),
                     ItemNameByKind(Stock.Codes[ri], SellOnlyKind), price]);
      WriteMessage(PadRight(left, 34) + right); // adjust gutter (34) if needed
    end
    else
      WriteMessage(left);
  end;
end;

  function FinalRowsNeeded(remainingItems: Integer): Integer;
  // When ≤10 items remain, we show ceil(remaining/2) rows, capped at 5
  var rows: Integer;
  begin
    Result := (remainingItems + 1) div 2;  // Round up to nearest row
    if Result > 6 then 
      Result := 6;  // Show max 6 rows (12 items) per page
  end;

function DoBuy_SelectIndex(out AbsIndex: Integer): Boolean;
const 
  FULL_ROWS = 6;
  ITEMS_PER_PAGE = FULL_ROWS * 2; // 12 items per page
var
  startIdx, remaining, rows, itemsOnPage: Integer;
  allowedAll: string; 
  key: Char;
begin
  Result := False; 
  AbsIndex := -1;
  if Stock.Count = 0 then Exit;

  // Build the FULL allowed set for ALL items, not just the last page
  allowedAll := LettersForCount(Stock.Count);
  if allowedAll = '' then Exit;

  startIdx := 0;
  while startIdx < Stock.Count do
  begin
    remaining := Stock.Count - startIdx;
    
    // Calculate how many items to show on this page
    if remaining > ITEMS_PER_PAGE then
    begin
      rows := FULL_ROWS;
      itemsOnPage := ITEMS_PER_PAGE;
    end
    else
    begin
      rows := FinalRowsNeeded(remaining);
      itemsOnPage := remaining;
    end;

    // Draw this page (labels must include startIdx so letters continue A..)
    RenderPageTwoColumns(startIdx, rows);

    if remaining >= ITEMS_PER_PAGE then
    begin
      // Full page - show "press any key" and go to next page
      Message_WaitAnyKey('Press any key to continue...');
      Inc(startIdx, ITEMS_PER_PAGE);
    end
    else
      Break; // last page rendered — fall through to final selection prompt
  end;

  // Final prompt — allow picking ANY letter shown on ANY page
  WriteMessage('Which item do you prefer?');
  key := Message_PromptLetterChoice('', allowedAll);
  if key = #0 then
  begin
    WriteMessage('Get outta here, scum!');
    Exit(False);
  end;

  // Map letter -> absolute index across the whole catalog
  AbsIndex := LetterToIndex(key);
  if (AbsIndex < 0) or (AbsIndex >= Stock.Count) then
  begin
    WriteMessage('Get outta here, scum!');
    Exit(False);
  end;

  Result := True;
end;


// ---------- main body ----------
var
  ch: Char;
  absIndex: Integer;
  code: Byte;
  price: Integer;
  itW: TWeaponView;
  itA: TArmorView;
  cap: SmallInt;
  slot: Integer;
begin
  // Build catalog from MonMsg1 (weapons/armor list)
  BuildStockFromMsg1_WP_AR(MonMsg1, Stock);

  // Faithful DOS greeting and branch choice
  ch := Message_PromptLetterChoice('Good day, Sir.  Would you like to (B)uy or (S)ell?', 'BS');
  if ch = #0 then
  begin
    WriteMessage('Get outta here, scum!');
    Exit;
  end;
  ch := UpCase(ch);

  // =============== SELL branch (use originals) ===============
  if ch = 'S' then
  begin
    if SellOnlyKind = ikWeapon then
      RunSellWeapons_Original(Player)
    else
      RunSellArmor_Original(Player);
    Exit;
  end;

  // Any other key besides B/S
  if ch <> 'B' then
  begin
    WriteMessage('Get outta here, scum!');
    Exit;
  end;

  // =============== BUY branch ===============
  // Original quirk: if wearing armor, only explicit 'N' continues
  if (SellOnlyKind = ikArmor) and (Player.Armor <> 0) then
  begin
    if Message_PromptYesNo('You are stilling wearing armor.  Sell it first?') then
    begin
      WriteMessage('Pay attention next time, huh?');
      Exit;
    end
    else
      WriteMessage('Ok... your choice...');
  end;

  // Let the player pick A.. via your paging UI
  if not DoBuy_SelectIndex(absIndex) then
    Exit;

  // Resolve item + price
  code  := Stock.Codes[absIndex];
  if SellOnlyKind = ikArmor then
  price := ArmorPrice(code)
else
  price := WeaponPrice(code);

  if Player.Gold < price then
  begin
    WriteMessage('You don''t have enough gold to buy that.');
    Exit;
  end;

  if SellOnlyKind = ikWeapon then
  begin
    // Backpack capacity like DOS (slots 1..5)
    slot := FirstEmptyBackpackSlot(Player);
    if slot < 0 then
    begin
      WriteMessage('You don''t have any room.');
      Exit;
    end;

    // Decode & initialize durability using your cap function
    itW  := DecodeWeapon(code);
    cap := itW.Durability;

    // Commit (UNLIMITED stock: do NOT remove from Stock)
    Dec(Player.Gold, price);
    DrawStatusArea;
    RenderFrame;
    Player.Backpack[slot] := code;
    Player.WeaponDur[slot] := cap;

    WriteMessage(MonMsg2); // classic “thank you” / merchant line
  end
  else
  begin
    // Armor purchase replaces current armor
    itA  := DecodeArmor(code);
    cap := itA.Durability;

    Dec(Player.Gold, price);
    Player.Armor := code;
    Player.ArmorDur := cap;
    DrawStatusArea;
    RenderFrame;

    WriteMessage(MonMsg2);
  end;
end;



end.
