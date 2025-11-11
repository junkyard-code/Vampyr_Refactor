unit uItems;
{$mode objfpc}{$H+}

interface

uses SysUtils, Math;

type
  // Lightweight “view” records used by callers
  TWeaponView = record
    Name: ShortString;
    BaseRange: Byte;   // Random(BaseRange)
    BaseBonus: Byte;   // + BaseBonus
    Plus: Byte;        // 0..3 (players only)
    Price: Integer;
    Durability: SmallInt;
    IsMonster: Boolean;
  end;

  TArmorView = record
    Name: ShortString;
    Defense: Byte;     // base defense before Plus
    Plus: Byte;        // 0..3 (players only)
    Price: Integer;
    Durability: SmallInt;
    IsMonster: Boolean;
  end;

  // Public API
  function DecodeWeapon(Code: Byte): TWeaponView;
  function DecodeArmor(Code: Byte): TArmorView;
  function DurabilityBand(Code: Byte; CodeDur, Dur:SmallInt): string;

implementation

type
  TWeapBase = record
    Name: ShortString;
    Rng: Byte;  // Random(Rng)
    Bon: Byte;  // + Bon
    Price: Integer;
    Dur: SmallInt;
  end;

  TArmBase = record
    Name: ShortString;
    Def: Byte;
    Price: Integer;
    Dur: SmallInt;
  end;

// ------------------------- Player base WEAPONS (0..10) -------------------------
const
  // Index 0/10 are special (Hands/Club) and handled in DecodeWeapon.
  CPlayerWeap: array[0..10] of TWeapBase = (
    (Name:'Hands';      Rng:2;  Bon:1; Price: 0; Dur:0),   // 0
    (Name:'Dagger';     Rng:3;  Bon:2; Price: 10; Dur:45),   // 1
    (Name:'Staff';      Rng:4;  Bon:1; Price: 5; Dur:50),   // 2
    (Name:'Mace';       Rng:5;  Bon:2; Price: 25; Dur:55),   // 3
    (Name:'Morn. Star'; Rng:6;  Bon:3; Price: 45; Dur:60),   // 4
    (Name:'Axe';        Rng:6;  Bon:2; Price: 30; Dur:70),   // 5
    (Name:'Long Sword'; Rng:9;  Bon:2; Price: 55; Dur:75),   // 6
    (Name:'2H Sword';   Rng:13; Bon:3; Price: 75; Dur:80),   // 7
    (Name:'Long Bow';   Rng:7;  Bon:1; Price: 40; Dur:60),   // 8
    (Name:'Sling';      Rng:5;  Bon:1; Price: 25; Dur:45),   // 9
    (Name:'Club';       Rng:6;  Bon:1; Price: 20; Dur:45)    // 10
  );

// ------------------------- Monster WEAPONS (41..53) ----------------------------
const
  // Sparse table: we map exact monster codes to entries.
  // For simplicity, store them in a flat array and scan (few items).
  CMonWeap: array[1..13] of record Code: Byte; B: TWeapBase end = (
    (Code:41; B:(Name:'Slime';          Rng:2;  Bon:1;  Price: 0; Dur:0)),
    (Code:42; B:(Name:'Bite';           Rng:3;  Bon:1;  Price: 0; Dur:0)),
    (Code:43; B:(Name:'Big Bite';       Rng:6;  Bon:2;  Price: 0; Dur:0)),
    (Code:44; B:(Name:'Giant Bite';     Rng:8;  Bon:3;  Price: 0; Dur:0)),
    (Code:45; B:(Name:'Fist';           Rng:3;  Bon:1;  Price: 0; Dur:0)),
    (Code:46; B:(Name:'Big Fist';       Rng:5;  Bon:2;  Price: 0; Dur:0)),
    (Code:47; B:(Name:'Giant Fist';     Rng:11; Bon:5;  Price: 0; Dur:0)),
    (Code:48; B:(Name:'Claws';          Rng:3;  Bon:2;  Price: 0; Dur:0)),
    (Code:49; B:(Name:'Big Claws';      Rng:7;  Bon:2;  Price: 0; Dur:0)),
    (Code:50; B:(Name:'Giant Claws';    Rng:13; Bon:3;  Price: 0; Dur:0)),
    (Code:51; B:(Name:'Vampire Touch';  Rng:10; Bon:3;  Price: 0; Dur:0)),
    (Code:52; B:(Name:'Vampyr Touch';   Rng:16; Bon:5;  Price: 0; Dur:0)),
    (Code:53; B:(Name:'Big Broom';      Rng:21; Bon:100; Price: 0; Dur:0))
  );

// ------------------------- Player base ARMOR (0..11) ---------------------------
const
  // 0/10 are special (Nude/Full Plate) and handled in DecodeArmor.
  CPlayerArmor: array[0..10] of TArmBase = (
    (Name:'Nude';       Def:0;  Price: 0; Dur:0),   // 0
    (Name:'Cloth';      Def:3;  Price: 5; Dur:10),  // 1
    (Name:'Padded';     Def:6;  Price: 15; Dur:30),  // 2
    (Name:'Leather';    Def:10; Price: 25; Dur:45),  // 3
    (Name:'Studded';    Def:13; Price: 40; Dur:55),  // 4
    (Name:'Ring Mail';  Def:17; Price: 60; Dur:65),  // 5
    (Name:'Scale M.';   Def:20; Price: 75; Dur:65),  // 6
    (Name:'Chain M.';   Def:25; Price: 100; Dur:75),  // 7
    (Name:'Splint M.';  Def:30; Price: 150; Dur:75),  // 8
    (Name:'Plate M.';   Def:33; Price: 200; Dur:75),  // 9
    (Name:'Full Plate'; Def:35; Price: 300; Dur:80)   // 10 (used for 10/20/30/40 codes)
  );

// ------------------------- Monster ARMOR (41..49) ------------------------------
const
  CMonArmor: array[1..9] of record Code: Byte; B: TArmBase end = (
    (Code:41; B:(Name:'Bones';          Def:10; Price: 0; Dur:0)),
    (Code:42; B:(Name:'Thick Skin';     Def:13; Price: 0; Dur:0)),
    (Code:43; B:(Name:'Transparency';   Def:30; Price: 0; Dur:0)),
    (Code:44; B:(Name:'Fur';            Def:6;  Price: 0; Dur:0)),
    (Code:45; B:(Name:'Thick Fur';      Def:15; Price: 0; Dur:0)),
    (Code:46; B:(Name:'Scales';         Def:27; Price: 0; Dur:0)),
    (Code:47; B:(Name:'Magic Robe';     Def:25; Price: 0; Dur:0)),
    (Code:48; B:(Name:'Hard Bark';      Def:23; Price: 0; Dur:0)),
    (Code:49; B:(Name:'Slime Coating';  Def:5;  Price: 0; Dur:0))
  );

function DecodeWeapon(Code: Byte): TWeaponView;
var
  base, plus: Byte;
  i: Integer;
  W: TWeapBase;
  isMonster: Boolean;
begin
  // defaults
  Result.Name := '';
  Result.BaseRange := 0;
  Result.BaseBonus := 0;
  Result.Plus := 0;
  Result.IsMonster := False;
  Result.Price := 0;
  Result.Durability := 0;
  plus := 0;
  isMonster := False;

  if Code >= 41 then
  begin
    // Monster lookup (table assumed complete; no fallback)
    for i := Low(CMonWeap) to High(CMonWeap) do
      if CMonWeap[i].Code = Code then
      begin
        W := CMonWeap[i].B;
        isMonster := True;
        Break;
      end;
  end
  else
  begin
    // Player decode
    base := Code;
    if (Code >= 11) and (Code <= 40) then
    begin
      // 11..20 => +1, 21..30 => +2, 31..40 => +3
      plus := (Code - 1) div 10;   // 1..3
      base := Code mod 10;         // 0..9
      if base = 0 then base := 10; // legacy rule: 0 +X => Club +X (not Hands)
    end;

    if base > High(CPlayerWeap) then base := 0; // safety: 0 = Hands
    W := CPlayerWeap[base];
  end;

  // ---- single assignment block ----
  Result.IsMonster  := isMonster;
  Result.Plus       := plus;        // monsters keep 0 (default)
  Result.Name       := W.Name;
  Result.BaseRange  := W.Rng;
  Result.BaseBonus  := W.Bon;
  Result.Price      := W.Price;
  Result.Durability := W.Dur;

  if (not isMonster) and (plus > 0) then
    begin
      Result.Name := Result.Name + ' +' + IntToStr(plus);
      Result.BaseBonus := Result.BaseBonus + (plus*2)+1;
      If (plus=1) Then begin Result.Price:=Result.Price+150; Result.Durability:=Result.Durability+15; end;
      If (plus=2) Then begin Result.Price:=Result.Price+300; Result.Durability:=Result.Durability+15; end;
      If (plus=3) Then begin Result.Price:=Result.Price+500; Result.Durability:=Result.Durability+17; end;
    end;
end;


function DecodeArmor(Code: Byte): TArmorView;
var
  base, plus: Byte;
  i: Integer;
  A: TArmBase;
  isMonster: Boolean;
begin
  // defaults
  Result.Name := '';
  Result.Defense := 0;
  Result.Plus := 0;
  Result.IsMonster := False;
  Result.Price := 0;
  Result.Durability := 0;
  plus := 0;
  isMonster := False;

  if Code >= 41 then
  begin
    // Monster lookup (table assumed complete)
    for i := Low(CMonArmor) to High(CMonArmor) do
      if CMonArmor[i].Code = Code then
      begin
        A := CMonArmor[i].B;
        isMonster := True;
        Break;
      end;
  end
  else
  begin
    // Player decode
    base := Code;
    if (Code >= 11) and (Code <= 40) then
    begin
      // 11..20 => +1, 21..30 => +2, 31..40 => +3
      plus := (Code - 1) div 10;   // 1..3
      base := Code mod 10;         // 0..9
      if base = 0 then base := 10; // legacy rule: 0 +X => Full Plate +X
    end;

    // Safety clamp: Nude = 0.. default defense = 0
    if base > High(CPlayerArmor) then base := 0;
    A := CPlayerArmor[base];
  end;

  // ---- single assignment block ----
  Result.IsMonster := isMonster;
  Result.Plus      := plus;
  Result.Name      := A.Name;
  Result.Defense   := A.Def;
  Result.Price     := A.Price;
  Result.Durability := A.Dur;

  // Apply +X suffix and defense bonus for players only
  if not isMonster then
  begin
    if plus > 0 then
    begin
      Result.Defense := Result.Defense + (plus * 4);
      Result.Name := Result.Name + ' +' + IntToStr(plus);
      If (plus=1) Then begin Result.Price:=Result.Price+200; Result.Durability:=Result.Durability+15; end;
      If (plus=2) Then begin Result.Price:=Result.Price+500; Result.Durability:=Result.Durability+15; end;
      If (plus=3) Then begin Result.Price:=Result.Price+1000; Result.Durability:=Result.Durability+17; end;
    end;
  end;
end;

function RollWeaponDamage(const W: TWeaponView; playerStr: Byte): Integer;
begin
  Result := Random(W.BaseRange) + W.BaseBonus;

  // Player “Plus” adds (Plus*2)+1 to damage, monsters have Plus=0
  if (not W.IsMonster) and (W.Plus > 0) then
    Inc(Result, (W.Plus * 2) + 1);

  // Preserve the original 1989 logic exactly (if enabled):
    // Original:
    // if Player.Stats[1] > 17 then Damage := Damage + (17 - Player.Stats[1]);
    // (This *reduces* damage when STR > 17.)
    //if playerStr > 17 then
    //  Inc(Result, 17 - playerStr); // negative when >17

    // Likely intended:
    // if playerStr > 17 then Damage := Damage + (playerStr - 17);
    if playerStr > 17 then
      Inc(Result, playerStr - 17);

  if Result < 0 then Result := 0; // safety clamp
end;



// Text bands matching your original “DurLook”
function DurabilityBand(Code: Byte; CodeDur, Dur:SmallInt): string;
begin
  Result := 'Very Bad';
  if Dur > (CodeDur div 6) then Result := 'Poor';
  if Dur > (CodeDur div 3) then Result := 'Fair';
  if Dur > (CodeDur div 2) then Result := 'Average';
  if Dur > Round(CodeDur/1.4) then Result := 'Good';
  if Dur > Round(CodeDur/1.2) then Result := 'Excellent!';
  if Dur > CodeDur then Result := 'Super!!!';
end;

end.
