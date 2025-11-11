unit UConTiles;
{$mode objfpc}{$H+}

interface


uses
SysUtils, Classes;



const
  TILE_W = 18;
  TILE_H = 18;
  TILE_PIXELS = TILE_W * TILE_H; // 324


// When calling Tiles_RenderView7x7ToFB we scale to the caller's
// tile size; here we only decode native 16×16 tiles.


// .CON decode mode: 0 = packed nibbles (A in high nibble, B in low)
// 1 = planar EGA (4 planes × 32 bytes, MSB first)
CON_DECODE_MODE = 0; // try 0 first; if visuals look wrong, set to 1

// Some .CON packs low-nibble first; set TRUE to swap nibble order
CON_PACKED_LOW_NIBBLE_FIRST = True;  // try toggling this

// If your .CON has a small header, skip these bytes before decoding
CON_FILE_SKIP_BYTES = 16;              // try 0, 16, 32, 128

// Standard 16‑color EGA palette in ARGB32 (A=FF)
const
EGA_ARGB: array[0..15] of LongWord = (
$FF000000, // 0 black
$FF0000AA, // 1 blue
$FF00AA00, // 2 green
$FF00AAAA, // 3 cyan
$FFAA0000, // 4 red
$FFAA00AA, // 5 magenta
$FFAA5500, // 6 brown
$FFAAAAAA, // 7 light gray
$FF555555, // 8 dark gray
$FF5555FF, // 9 light blue
$FF55FF55, // 10 light green
$FF55FFFF, // 11 light cyan
$FFFF5555, // 12 light red
$FFFF55FF, // 13 light magenta
$FFFFFF55, // 14 yellow
$FFFFFFFF // 15 white
);

// Which source a logical tile comes from
type TTileSource = (tsUniv, tsLand, tsTown, tsDungeon, tsPlayer, tsAfter, tsTownMon);
type TMapEntry = packed record src: TTileSource; index: Word; end;
type TGetWorldTileID = function (X, Y: Integer): Word;

type
TTileARGB = array[0..TILE_PIXELS-1] of LongWord; // A8R8G8B8
PTileARGB = ^TTileARGB;
TTileArray = array of TTileARGB;

type
   TMapKind = (mkWorld, mkTown, mkCastle, mkDungeon, mkRuin, mkVCastle, mkAfterlife);


// WORLD.MAP logical TileID → (source .CON, index inside that .CON)
// Extend this table as you expand your mapping spreadsheet.
const
// WORLD.MAP logical TileID → (source .CON, index)

WORLD_TILE_LUT: array[0..21] of TMapEntry = (
  (src: tsUniv; index: 0),   // 0 Water (deep)
  (src: tsUniv; index: 1),   // 1 Water (shallow)
  (src: tsUniv; index: 2),   // 2 Bridge
  (src: tsUniv; index: 3),   // 3 Forest
  (src: tsUniv; index: 4),   // 4 Bushes
  (src: tsUniv; index: 5),   // 5 Sign
  (src: tsUniv; index: 6),   // 6 Grass
  (src: tsLand; index: 0),   // 7 Vampyr’s Castle [TOP]
  (src: tsLand; index: 1),   // 8 Town [RIGHT]
  (src: tsLand; index: 2),   // 9 Town [LEFT]
  (src: tsLand; index: 3),   // 10 Castle [RIGHT]
  (src: tsLand; index: 4),   // 11 Ruin [RIGHT]
  (src: tsLand; index: 5),   // 12 Mountains
  (src: tsLand; index: 6),   // 13 Mountains + Dungeon
  (src: tsLand; index: 7),   // 14 Swamp
  (src: tsLand; index: 8),   // 15 Tropical Trees
  (src: tsLand; index: 9),   // 16 Boat
  (src: tsLand; index: 10),  // 17 Castle [LEFT]
  (src: tsLand; index: 11),  // 18 Ruin [LEFT]
  (src: tsLand; index: 12),  // 19 Vampyr’s Castle [BOTTOM]
  (src: tsLand; index: 13),  // 20 Hills
  (src: tsLand; index: 14)   // 21 Clearing
);

// LOCAL.MAP (Town / Castle / Dungeon / Ruin / VCastle)
// logical TileID → (source .CON, index)

LOCAL_TILE_LUT: array[0..27] of TMapEntry = (
  (src: tsUniv;    index: 0),  // 0 Water (deep)
  (src: tsUniv;    index: 1),  // 1 Water (shallow)
  (src: tsUniv;    index: 2),  // 2 Bridge
  (src: tsUniv;    index: 3),  // 3 Forest
  (src: tsUniv;    index: 4),  // 4 Bushes
  (src: tsUniv;    index: 5),  // 5 Sign
  (src: tsUniv;    index: 6),  // 6 Grass
  (src: tsUniv;    index: 7),  // 7 Treasure Chest   <-- FIXED HERE
  (src: tsTown;    index: 0),  // 8 Red Brick Wall
  (src: tsTown;    index: 1),  // 9 Gray Brick Walkway
  (src: tsTown;    index: 2),  // 10 Red Brick Wall (secret)
  (src: tsTown;    index: 3),  // 11 Purple Tile Flooring
  (src: tsTown;    index: 4),  // 12 Window
  (src: tsTown;    index: 5),  // 13 Gray Wall
  (src: tsTown;    index: 6),  // 14 Door (Unlocked)
  (src: tsTown;    index: 7),  // 15 Pub Sign
  (src: tsTown;    index: 8),  // 16 Armory Sign
  (src: tsTown;    index: 9),  // 17 Weaponry Sign
  (src: tsTown;    index: 10), // 18 Transport Sign
  (src: tsTown;    index: 11), // 19 Tavern Sign
  (src: tsTown;    index: 12), // 20 Inn Sign
  (src: tsTown;    index: 13), // 21 Brown Table/Bed
  (src: tsTown;    index: 14), // 22 Pillar
  (src: tsTown;    index: 15), // 23 Stairs (up)
  (src: tsTown;    index: 16), // 24 Stairs (down)
  (src: tsTown;    index: 17), // 25 Door (Locked)
  (src: tsTown;    index: 18), // 26 Boat
  (src: tsTown;    index: 19)  // 27 Fence on Grass
);

var
  ActiveKind: TMapKind = mkWorld;
// Global tile arrays for each .CON tile source
  GPlayer : TTileArray; // at least index 0 is the player tile
  GUniv : TTileArray;
  GLand : TTileArray;
  GTown : TTileArray;
  GDungeon : TTileArray;
  GAfter: TTileArray;
  GTownMon: TTileArray;
  GDungMon: TTileArray;
  GRuinMon: TTileArray;
  GLifeMon: TTileArray;


function Tiles_Init(const BaseDir: string): Boolean;
procedure Tiles_Done;
function Tiles_GetTile(const LogicalTileID: Word): PUInt32; // -> ARGB32[256]
procedure Tiles_BlitTileToFB(const LogicalTileID: Word; FB: PUInt32; FBWidth: Integer; DstX, DstY: Integer);
procedure Tiles_RenderView7x7ToFB(FB: PUInt32; FBWidth: Integer; CamX, CamY: Integer; WorldWidth, WorldHeight: Integer; GetWorldTileID: TGetWorldTileID);
function Tiles_Get_Univ(const Index: Word): PUInt32;
function Tiles_Get_Land(const Index: Word): PUInt32;
function Tiles_Get_Town(const Index: Word): PUInt32;
function Tiles_Get_Dungeon(const Index: Word): PUInt32;
function Tiles_GetPlayerTile(const Index: Word): PUInt32; // -> ARGB32[ TILE_W * TILE_H ]
function Tiles_PlayerCount: Integer;
function Tiles_GetAnimatedTilePtr(LogicalID: Word; NowMs: LongWord): PUInt32;
function TilePtrBySource(const S: TTileSource; const Idx: Word): PUInt32;
function Tiles_Get_Player(const Index: Word): PUInt32;
function Tiles_GetAnimatedTilePtr_ForKind(const tileID: Byte; const kind: TTileSource; const nowMs: LongWord): PUInt32;
function TileCollides(const kind: TMapKind; const tileID: Byte): Boolean;
function TileOccludes(const kind: TMapKind; const tileID: Byte): Boolean;
function Tiles_Get_After(const idx: Integer): PUInt32;
function GetTilePtrForActive(const tileID: Byte; const nowMs: QWord): PUInt32;
function Tiles_Get_TownMon(const index: Word): PUInt32;
function Tiles_Get_Mon_ForActive(const index: Word): PUInt32;
function Tiles_Get_LifeMon(const Index: Word): PUInt32;
function Tiles_Get_RuinMon(const Index: Word): PUInt32;
function Tiles_Get_DungeonMon(const Index: Word): PUInt32;
function Tiles_MonCount(const kind: TMapKind): Integer;


implementation

// -----------------------------------------------------------------------------
// Internals
// -----------------------------------------------------------------------------



type
TAlt = record   // 2-frame for animation tracking and mapping
  enabled : Boolean;
  src     : TTileSource; // where frame-B lives
  index   : Word;        // .CON index for frame-B
  periodMs: Word;        // frame toggle period
end;

const

 // Local anim tables are disabled by default; we’ll flip entries on later.
  // Town/Castle local TileID 8..27 → 0..19 here
  ALT_TOWN: array[0..19] of TAlt = (
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300),
    (enabled:false; src:tsTown; index:0; periodMs:300)
  );

  // Dungeon/Ruin/VCastle local TileID 8..25 → 0..17 here
  ALT_DUN: array[0..17] of TAlt = (
    (enabled:true; src:tsDungeon; index:18; periodMs:300),
    (enabled:true; src:tsDungeon; index:19; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300),
    (enabled:false; src:tsDungeon; index:0; periodMs:300)
  );

  // AFTER local TileID 8..26 -> slot 0..18 here
  ALT_AFTER: array[0..18] of TAlt = (
    (enabled:true;  src:tsAfter; index:19; periodMs:300),  // 0 -> Brazier (0<->19)
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 1 Gray Brick Walkway
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 2 Red Brick Wall
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 3 Armory Sign
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 4 Purple Tile
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 5 Fence
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 6 Computer
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 7 Pillar
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 8 Door (unlocked)
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 9 Door (locked)
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 10 Clouds
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 11 Window
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 12 Purple Tile w/ashes
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 13 Stone Wall
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 14 Table/Bed
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 15 Sky
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 16 Weaponry Sign
    (enabled:false; src:tsAfter; index:0;  periodMs:300),  // 17 Justice Sign [L]
    (enabled:false; src:tsAfter; index:0;  periodMs:300)   // 18 Justice Sign [R]
  );

  ALT_FRAMES: array[0..21] of TAlt = (
    // 0..6 live in UNIV.CON
    (enabled:true;  src:tsUniv; index:12; periodMs:300), // 0 Water (deep)     -> UNIV 12
    (enabled:true;  src:tsUniv; index:13; periodMs:300), // 1 Water (shallow)  -> UNIV 13
    (enabled:false; src:tsUniv; index:0;  periodMs:0  ), // 2 Bridge
    (enabled:false; src:tsUniv; index:0;  periodMs:0  ), // 3 Forest
    (enabled:false; src:tsUniv; index:0;  periodMs:0  ), // 4 Bushes
    (enabled:false; src:tsUniv; index:0;  periodMs:0  ), // 5 Sign (on grass)
    (enabled:false; src:tsUniv; index:0;  periodMs:0  ), // 6 Grass

    // 7..21 live in LAND.CON
    (enabled:true;  src:tsLand; index:15; periodMs:300), // 7  Vampyr's Castle [TOP] -> LAND 15
    (enabled:true;  src:tsLand; index:16; periodMs:300), // 8  Town [LEFT]            -> LAND 17
    (enabled:true;  src:tsLand; index:17; periodMs:300), // 9  Town [RIGHT]           -> LAND 16
    (enabled:true; src:tsLand; index:18;  periodMs:300), // 10 Castle [LEFT]
    (enabled:true; src:tsLand; index:19;  periodMs:300), // 11 Ruin [LEFT]
    (enabled:false; src:tsLand; index:0;  periodMs:0  ), // 12 Mountains
    (enabled:false; src:tsLand; index:0;  periodMs:0  ), // 13 Mountains with Dungeon
    (enabled:false; src:tsLand; index:0;  periodMs:0  ), // 14 Swamp
    (enabled:false; src:tsLand; index:0;  periodMs:0  ), // 15 Tropical Trees
    (enabled:false; src:tsLand; index:0;  periodMs:0  ), // 16 Boat
    (enabled:false;  src:tsLand; index:0; periodMs:0), // 17 Castle [RIGHT]         -> LAND 18
    (enabled:false;  src:tsLand; index:0; periodMs:0), // 18 Ruin [RIGHT]           -> LAND 19
    (enabled:false; src:tsLand; index:0;  periodMs:0  ), // 19 Vampyr's Castle [Bottom]
    (enabled:false; src:tsLand; index:0;  periodMs:0  ), // 20 Hills
    (enabled:false; src:tsLand; index:0;  periodMs:0  )  // 21 Clearing
  );


const
  WORLD_COLLIDES: array[0..21] of Boolean = (
    True, True, False, False, False, True, False, False,
    False, False, False, False, True, False, False, False,
    False, False, False, False, False, False
  );

const
  WORLD_OCCLUDES: array[0..21] of Boolean = (
    False, False, False, True, False, False, False, False,
    False, False, False, False, True, True, False, True,
    False, False, False, False, False, False
  );

const
  TOWN_COLLIDES: array[0..27] of Boolean = (
    True, True, False, False, False, True, False, False,
    False, False, True, False, True, True, False, True,
    True, True, True, True, True, True, True, False,
    False, True, False, True
  );

const
  TOWN_OCCLUDES: array[0..27] of Boolean = (
    False, False, False, True, False, False, False, False,
    True, False, True, False, False, True, True, True,
    True, True, True, True, True, False, False, False,
    False, True, False, False
  );

const
  DUN_COLLIDES: array[0..25] of Boolean = (
    True, True, False, False, False, True, False, False,
    True, False, True, True, False, False, False, False,
    False, True, False, False, True, False, True, True,
    True, True
  );

const
  DUN_OCCLUDES: array[0..25] of Boolean = (
    False, False, False, True, False, False, False, False,
    False, False, False, False, False, False, False, False,
    False, True, True, False, False, True, False, True,
    True, False
  );

const
  AFTER_COLLIDES: array[0..26] of Boolean = (
    // --- UNIV.CON 0..7 ---
    True,  // 0  Water (deep)
    True,  // 1  Water (shallow)
    False, // 2  Bridge
    False, // 3  Forest
    False, // 4  Bushes
    True,  // 5  Sign (on grass)
    False, // 6  Grass
    False, // 7  Treasure Chest

    // --- AFTER.CON 0..18 ---
    True,  // 8   Brazier
    False, // 9   Gray Brick Walkway
    True,  // 10  Red Brick Wall
    True,  // 11  Armory Sign
    False, // 12  Purple Tile Flooring
    True,  // 13  Fence on Grass
    True,  // 14  Computer
    True,  // 15  Pillar on Purple Tile
    False, // 16  Door (unlocked)
    True,  // 17  Door (Locked)
    True,  // 18  Clouds in Sky
    True,  // 19  Window
    False, // 20  Purple Tile w/ ashes
    True,  // 21  Stone Wall
    True,  // 22  Brown Table/Bed
    True,  // 23  Sky
    True,  // 24  Weaponry Sign
    True,  // 25  Justice Sign [LEFT]
    True   // 26  Justice Sign [RIGHT]
  );

  AFTER_OCCLUDES: array[0..26] of Boolean = (
    False, False, False, True, False, False, False, False,
    False, // 0  Brazier
    False, // 1  Walkway
    True,  // 2  Red Brick Wall
    True,  // 3  Armory Sign
    False, // 4  Purple Tile Flooring
    False, // 5  Fence
    False, // 6  Computer
    False, // 7  Pillar
    True,  // 8  Door (unlocked)
    True,  // 9  Door (Locked)
    False, // 10 Clouds
    False, // 11 Window
    False, // 12 Purple Tile w/ashes
    True,  // 13 Stone Wall
    False, // 14 Table/Bed
    False, // 15 Sky
    True,  // 16 Weaponry Sign
    True,  // 17 Justice Sign [LEFT]
    True   // 18 Justice Sign [RIGHT]
  );





// ****************************************** Tiles_EGAtoRGB *****************************************

function Tiles_EGAtoRGB(idx: Byte): LongWord; inline;
begin
  if idx <= High(EGA_ARGB) then
    Result := EGA_ARGB[idx]
  else
    Result := $FF000000;
end;


// **************************************** GetAnimatedTilePtr ****************************************

function Tiles_GetAnimatedTilePtr_ForKind(const tileID: Byte;
  const kind: TTileSource; const nowMs: LongWord): PUInt32;
var idx: Integer; alt: TAlt;
begin
  Result := nil;

  case kind of
    tsTown: // local TileID 8..27
      if (tileID >= 8) and (tileID <= 27) then
      begin
        idx := tileID - 8;
        alt := ALT_TOWN[idx];
        if alt.enabled and (alt.periodMs > 0) and (((nowMs div alt.periodMs) and 1) = 1) then
          case alt.src of
            tsTown:    Exit(Tiles_Get_Town(alt.index));
            tsUniv:    Exit(Tiles_Get_Univ(alt.index));
            tsLand:    Exit(Tiles_Get_Land(alt.index));
            tsPlayer:  Exit(Tiles_Get_Player(alt.index));
            tsDungeon: Exit(Tiles_Get_Dungeon(alt.index));
            tsAfter:   Exit(Tiles_Get_After(alt.index));
          end;
      end;

    tsDungeon: // local TileID 8..25
      if (tileID >= 8) and (tileID <= 25) then
      begin
        idx := tileID - 8;
        alt := ALT_DUN[idx];
        if alt.enabled and (alt.periodMs > 0) and (((nowMs div alt.periodMs) and 1) = 1) then
          case alt.src of
            tsDungeon: Exit(Tiles_Get_Dungeon(alt.index));
            tsUniv:    Exit(Tiles_Get_Univ(alt.index));
            tsLand:    Exit(Tiles_Get_Land(alt.index));
            tsTown:    Exit(Tiles_Get_Town(alt.index));
            tsPlayer:  Exit(Tiles_Get_Player(alt.index));
            tsAfter:   Exit(Tiles_Get_After(alt.index));
          end;
      end;
    
    tsAfter: // local TileID 8..26
          if (tileID >= 8) and (tileID <= 26) then
          begin
            idx := tileID - 8;  // 8->0, 9->1, ..., 26->18
            if (idx >= 0) and (idx <= High(ALT_AFTER)) then
            begin
              alt := ALT_AFTER[idx];
              if alt.enabled and (alt.periodMs > 0) and (((nowMs div alt.periodMs) and 1) = 1) then
                  case alt.src of
                    tsAfter:   Exit(Tiles_Get_After(alt.index));  // brazier path
                    tsUniv:    Exit(Tiles_Get_Univ(alt.index));
                    tsLand:    Exit(Tiles_Get_Land(alt.index));
                    tsTown:    Exit(Tiles_Get_Town(alt.index));
                    tsDungeon: Exit(Tiles_Get_Dungeon(alt.index));
                    tsPlayer:  Exit(Tiles_Get_Player(alt.index));
                  end;
            end;
          end;
    end;
end;


// **************************************** ReadAllBytes ****************************************

function ReadAllBytes(const FileName: string; out Data: TBytes): Boolean;
var fs: TFileStream;

begin
  Result := False;
  if not FileExists(FileName) then Exit(False);
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Data, fs.Size);
    if fs.Size > 0 then fs.ReadBuffer(Data[0], fs.Size);
    Result := True;
  finally
    fs.Free;
  end;
end;


// **************************************** Decode_Indexed8 ****************************************

procedure Decode_Indexed8(const Src: PByte; var OutTile: TTileARGB; const ZeroIsTransparent: Boolean);
var
  y, x, p: Integer;
  idx: Byte;
  dx, dy: Integer;
  color: LongWord;
begin
  // Source is 8bpp indexed, rotated 90° CW on decode
  p := 0;
  for y := 0 to TILE_H - 1 do
    for x := 0 to TILE_W - 1 do
    begin
      idx := Src[p]; Inc(p);

      // palette lookup (opaque by default)
      color := EGA_ARGB[idx and $0F];

      // make index 0 transparent only if caller asked
      if ZeroIsTransparent and ((idx and $0F) = 0) then
        color := $00000000;

      // CW rotate: (x, y) -> (x' = TILE_H-1-y, y' = x)
      dx := TILE_H - 1 - y;
      dy := x;

      OutTile[dy * TILE_W + dx] := color;
    end;
end;


// **************************************** Decode_PackedNibbles ****************************************

procedure Decode_PackedNibbles(const Src: PByte; var OutTile: TTileARGB);
var
  i, p: Integer;
  b, hi, lo: Byte;
begin
  // 128 bytes → 256 pixels, two pixels per byte
  p := 0;
  for i := 0 to 127 do
  begin
    b  := Src[i];
    hi := (b shr 4) and $0F;
    lo := b and $0F;
    if CON_PACKED_LOW_NIBBLE_FIRST then
    begin
      OutTile[p] := EGA_ARGB[lo]; Inc(p);
      OutTile[p] := EGA_ARGB[hi]; Inc(p);
    end
    else
    begin
      OutTile[p] := EGA_ARGB[hi]; Inc(p);
      OutTile[p] := EGA_ARGB[lo]; Inc(p);
    end;
  end;
end;


// **************************************** Decode_EGAPlanar ****************************************

procedure Decode_EGAPlanar(const Src: PByte; var OutTile: TTileARGB);
// 4 planes × 32 bytes per tile; per row: 2 bytes per plane (MSB first)
var 
  row, col, bit, plane: Integer; 
  pIndex: Integer; color: Byte;
  planeBase: Integer;

begin
  for row := 0 to TILE_H-1 do
  begin
    for col := 0 to TILE_W-1 do
    begin
      bit := 7 - (col and 7);
      pIndex := (row * 2) + (col div 8) * 2; // 2 bytes per row per plane
      color := 0;
      for plane := 0 to 3 do
      begin
        planeBase := plane * 32; // 32 bytes per plane per tile
        if ((Src[planeBase + pIndex] and (1 shl bit)) <> 0) then
          color := color or (1 shl plane);
      end;
      OutTile[row*TILE_W + col] := EGA_ARGB[color];
    end;
  end;
end;


// **************************************** LoadConAsTiles ****************************************

function LoadConAsTiles(const FileName: string; out Tiles: TTileArray;
  const ZeroIsTransparent: Boolean): Boolean;
const
  W = 18; H = 18; BYTES_PER_TILE = W*H; // 324
var
  bytes: TBytes;
  usable, count, i: Integer;
  ptr: PByte;
  tile: TTileARGB;
  x, y, srcOff, dstOff: Integer;
  idx: Byte;
begin
  Result := False;
  SetLength(Tiles, 0);

  if not ReadAllBytes(FileName, bytes) then
    Exit(False);

  usable := Length(bytes);
  count  := usable div BYTES_PER_TILE;
  if count <= 0 then
    Exit(False);

  SetLength(Tiles, count);

  for i := 0 to count - 1 do
  begin
    ptr := @bytes[i * BYTES_PER_TILE];

    // Decode one 18x18 tile (no rotate/flip needed).
    // Old tool layout: Icon[X,Y] with Y varying fastest: srcOff = X*H + Y
    for x := 0 to W - 1 do
      for y := 0 to H - 1 do
      begin
        srcOff := x * H + y;          // file order
        dstOff := y * W + x;          // row-major in-memory
        idx := ptr[srcOff];           // 0..15 palette index
        // transparency for Player spirit
        if ZeroIsTransparent and (idx = 0) then  
          tile[dstOff] := 0
        else
        tile[dstOff] := Tiles_EGAtoRGB(idx);
      end;

    Tiles[i] := tile;
  end;

  Result := True;
end;


// **************************************** Tiles_Init ****************************************
function Tiles_Init(const BaseDir: string): Boolean;
var
  pUniv, pLand, pPlayer, pTown, pDungeon, pAfter: string;
  pTownMon, pDungMon, pRuinMon, pLifeMon: string;
  ok: Boolean;
begin
  pPlayer  := IncludeTrailingPathDelimiter(BaseDir) + 'PLAYER.CON';
  pUniv    := IncludeTrailingPathDelimiter(BaseDir) + 'UNIV.CON';
  pLand    := IncludeTrailingPathDelimiter(BaseDir) + 'LAND.CON';
  pTown    := IncludeTrailingPathDelimiter(BaseDir) + 'TOWN.CON';
  pDungeon := IncludeTrailingPathDelimiter(BaseDir) + 'DUNGEON.CON';
  pAfter   := IncludeTrailingPathDelimiter(BaseDir) + 'AFTER.CON';

  // monster sheets
  pTownMon := IncludeTrailingPathDelimiter(BaseDir) + 'TOWNMON.CON';
  pDungMon := IncludeTrailingPathDelimiter(BaseDir) + 'DUNGMON.CON';
  pRuinMon := IncludeTrailingPathDelimiter(BaseDir) + 'RUINMON.CON';
  pLifeMon := IncludeTrailingPathDelimiter(BaseDir) + 'LIFEMON.CON';

  ok := True;
  // load land tiles (no transparency)
  ok := LoadConAsTiles(pUniv,    GUniv,    False) and ok;
  ok := LoadConAsTiles(pLand,    GLand,    False) and ok;
  ok := LoadConAsTiles(pTown,    GTown,    False) and ok;
  ok := LoadConAsTiles(pDungeon, GDungeon, False) and ok;
  ok := LoadConAsTiles(pAfter,   GAfter,   False) and ok;

  // load monsters (no transparency unless your art uses index 0 as alpha)
  ok := LoadConAsTiles(pTownMon, GTownMon, False) and ok;
  ok := LoadConAsTiles(pDungMon, GDungMon, False) and ok;
  ok := LoadConAsTiles(pRuinMon, GRuinMon, False) and ok;
  ok := LoadConAsTiles(pLifeMon, GLifeMon, False) and ok;
  ok := LoadConAsTiles(pPlayer,  GPlayer,  False) and ok;

  if not ok then
  begin
    if not FileExists(pTownMon) then WriteLn('Missing: ', pTownMon);
    if not FileExists(pDungMon) then WriteLn('Missing: ', pDungMon);
    if not FileExists(pRuinMon) then WriteLn('Missing: ', pRuinMon);
    if not FileExists(pLifeMon) then WriteLn('Missing: ', pLifeMon);
    // …(you already print others)
  end;

  Result := ok;
end;


// ******************************************* Tiles_Done *******************************************

procedure Tiles_Done;
begin
  SetLength(GUniv, 0);
  SetLength(GLand, 0);
  SetLength(GPlayer, 0);
end;


// ****************************************** Tiles_GetTile ******************************************

function Tiles_GetTile(const LogicalTileID: Word): PUInt32;
var entry: TMapEntry;

begin
  Result := nil;
  if LogicalTileID > High(WORLD_TILE_LUT) then Exit(nil);
  entry := WORLD_TILE_LUT[LogicalTileID];

  case entry.src of
    tsUniv:
      if (entry.index < Length(GUniv)) then Result := @GUniv[entry.index][0];
    tsLand:
      if (entry.index < Length(GLand)) then Result := @GLand[entry.index][0];
    tsPlayer:
      if (entry.index < Length(GPlayer)) then Result := @GPlayer[entry.index][0];
  end;
end;


// **************************************** Tiles_PlayerCount ****************************************

function Tiles_PlayerCount: Integer;
begin
  Result := Length(GPlayer);
end;


// **************************************** Tiles_GetPlayerTile ****************************************

function Tiles_GetPlayerTile(const Index: Word): PUInt32;
begin
  Result := nil;
  if (Index < Length(GPlayer)) then
    Result := @GPlayer[Index][0];
end;


// **************************************** BlitNearest ****************************************

procedure BlitNearest(const src: PUInt32; FB: PUInt32; FBWidth: Integer; DstX, DstY: Integer);
var x,y,sx,sy: Integer; srcRow, dst: PUInt32;

begin
  for y := 0 to TILE_H-1 do
  begin
    srcRow := src + y*TILE_W;
    for sy := 0 to 2 do // SCALE_Y = 3 (default)
    begin
      dst := FB + (DstY + y*3 + sy)*FBWidth + DstX;
      for x := 0 to TILE_W-1 do
      begin
        for sx := 0 to 1 do // SCALE_X = 2
        begin
          dst^ := (srcRow + x)^;
          Inc(dst);
        end;
      end;
    end;
  end;
end;

// **************************************** Tiles_BlitTileToFB ****************************************

procedure Tiles_BlitTileToFB(const LogicalTileID: Word; FB: PUInt32; FBWidth: Integer; DstX, DstY: Integer);
var tile: PUInt32;

begin
  tile := Tiles_GetTile(LogicalTileID);
  if tile = nil then Exit;
  BlitNearest(tile, FB, FBWidth, DstX, DstY);
end;


// **************************************** Tiles_RenderView7x7ToFB ****************************************

procedure Tiles_RenderView7x7ToFB(FB: PUInt32; FBWidth: Integer; CamX, CamY: Integer; WorldWidth, WorldHeight: Integer; GetWorldTileID: TGetWorldTileID);
const
DST_TILE_W = TILE_W * 2; // 32
DST_TILE_H = TILE_H * 3; // 48
var vx, vy, wx, wy: Integer; tileID: Word; dstX, dstY: Integer;

begin
  for vy := 0 to 6 do
  begin
    for vx := 0 to 6 do
    begin
      wx := CamX + vx; wy := CamY + vy;
      if (wx < 0) or (wy < 0) or (wx >= WorldWidth) or (wy >= WorldHeight) then
        Continue;
      tileID := GetWorldTileID(wx, wy);
      dstX := vx * DST_TILE_W;
      dstY := vy * DST_TILE_H;
      Tiles_BlitTileToFB(tileID, FB, FBWidth, dstX, dstY);
    end;
  end;
end;


// ********************************************* Tiles_Get_Univ *********************************************

function Tiles_Get_Univ(const Index: Word): PUInt32;
begin
  Result := TilePtrBySource(tsUniv, Index);
end;

function Tiles_Get_Land(const Index: Word): PUInt32;
begin
  Result := TilePtrBySource(tsLand, Index);
end;

function Tiles_Get_Town(const Index: Word): PUInt32;
begin
  Result := TilePtrBySource(tsTown, Index);
end;

function Tiles_Get_Dungeon(const Index: Word): PUInt32;
begin
  Result := TilePtrBySource(tsDungeon, Index);
end;

function TilePtrBySource(const S: TTileSource; const Idx: Word): PUInt32;
begin
  case S of
    tsUniv:    if Idx < Length(GUniv)    then Exit(@GUniv[Idx][0]);
    tsLand:    if Idx < Length(GLand)    then Exit(@GLand[Idx][0]);
    tsPlayer:  if Idx < Length(GPlayer)  then Exit(@GPlayer[Idx][0]);
    tsTown:    if Idx < Length(GTown)    then Exit(@GTown[Idx][0]);
    tsDungeon: if Idx < Length(GDungeon) then Exit(@GDungeon[Idx][0]);
    tsTownMon: if Idx < Length(GTownMon) then Exit(@GTownMon[Idx][0]);
  end;
  Result := nil;
end;

// **************************************** Tiles_GetAnimatedTilePtr ****************************************

function Tiles_GetAnimatedTilePtr(LogicalID: Word; NowMs: LongWord): PUInt32;
var
  alt : TAlt;
  onB : Boolean;
begin
  // Frame-A = current logical tile
  Result := Tiles_GetTile(LogicalID);
  if (LogicalID > High(ALT_FRAMES)) then Exit;

  alt := ALT_FRAMES[LogicalID];
  if (not alt.enabled) or (alt.periodMs = 0) then Exit;

  onB := ((NowMs div alt.periodMs) and 1) <> 0; // toggle every period
  if onB then
  begin
    // Try to swap to the B-frame pointer
    Result := TilePtrBySource(alt.src, alt.index);
    if Result = nil then
      Result := Tiles_GetTile(LogicalID); // fallback to A-frame
  end;
end;


// ******************************************** GetTilePtrForActive ********************************************

// Decide which tile atlas to use based on ActiveKind and tileID
function GetTilePtrForActive(const tileID: Byte; const nowMs: QWord): PUInt32;
begin
  Result := nil;

  case ActiveKind of
    // -------------------------------------------------------------------
    // WORLD: use the world alt table first, then the base world LUT
    // -------------------------------------------------------------------
    mkWorld:
      begin
        Result := Tiles_GetAnimatedTilePtr(tileID, nowMs); // world ALT_FRAMES
        if Result = nil then
          Result := Tiles_GetTile(tileID);                 // WORLD_TILE_LUT
      end;

    // -------------------------------------------------------------------
    // LOCAL FRIENDLY (Town / Castle)
    // UNIV 0..6 may animate; UNIV 7 = Treasure Chest (no world-alt lookup)
    // local tiles start at 8 -> TOWN.CON (tileID-8)
    // -------------------------------------------------------------------
    mkTown, mkCastle:
      begin
        if tileID <= 6 then
        begin
          // water/bridge/forest/bushes/sign/grass can animate the same way
          Result := Tiles_GetAnimatedTilePtr(tileID, nowMs);
          if Result = nil then
            Result := Tiles_Get_Univ(tileID);
        end
        else if tileID = 7 then
        begin
          // IMPORTANT: chest comes from UNIV.CON #7, never use world alt
          Result := Tiles_Get_Univ(7);
        end
        else
        begin
          // local town/castle tiles (8..27) – try local alt, then base
          Result := Tiles_GetAnimatedTilePtr_ForKind(tileID, tsTown, nowMs);
          if Result = nil then
            Result := Tiles_Get_Town(tileID - 8);
        end;
      end;

    // -------------------------------------------------------------------
    // LOCAL HOSTILE (Dungeon / Ruin / VCastle)
    // Same handling for 0..7 as above; local tiles are from DUNGEON.CON
    // -------------------------------------------------------------------
    mkDungeon, mkRuin, mkVCastle:
      begin
        if tileID <= 6 then
        begin
          Result := Tiles_GetAnimatedTilePtr(tileID, nowMs);
          if Result = nil then
            Result := Tiles_Get_Univ(tileID);
        end
        else if tileID = 7 then
        begin
          // UNIV.CON #7 chest — never ask the world alt table
          Result := Tiles_Get_Univ(7);
        end
        else
        begin
          // local dungeon-family tiles (8..25) – try local alt, then base
          Result := Tiles_GetAnimatedTilePtr_ForKind(tileID, tsDungeon, nowMs);
          if Result = nil then
            Result := Tiles_Get_Dungeon(tileID - 8);
        end;
      end;
    // -------------------------------------------------------------------
    // AFTERLIFE
    // Same handling for 0..7 as above; local tiles are from AFTER.CON
    // -------------------------------------------------------------------
    mkAfterlife:
      begin
        if tileID <= 6 then
        begin
          Result := Tiles_GetAnimatedTilePtr(tileID, nowMs); // UNIV anims (water)
          if Result = nil then
            Result := Tiles_Get_Univ(tileID);
        end
        else if tileID = 7 then
        begin
          // UNIV.CON #7 chest — never ask the world alt table
          Result := Tiles_Get_Univ(7);
        end
        else
        begin
          Result := Tiles_GetAnimatedTilePtr_ForKind(tileID, tsAfter, nowMs);
          if Result = nil then
            Result := Tiles_Get_After(tileID - 8);
        end;
      end;
  end;
end;


// **************************************** Tiles_Get_Player ****************************************

function Tiles_Get_Player(const Index: Word): PUInt32;
begin
  Result := TilePtrBySource(tsPlayer, Index);
end;

// **************************************** Tiles_Get_After ****************************************

function Tiles_Get_After(const idx: Integer): PUInt32;
begin
  if (idx >= 0) and (idx < Length(GAfter)) then
    Result := @GAfter[idx][0]
  else
    Result := nil;
end;


// **************************************** TileCollides ****************************************

function TileCollides(const kind: TMapKind; const tileID: Byte): Boolean;
begin
  case kind of
    mkWorld:
      if tileID <= High(WORLD_COLLIDES) then Exit(WORLD_COLLIDES[tileID]) else Exit(False);

    mkTown, mkCastle:
      // locals: 0..7 are UNIV entries placed in local table too (sheet provides rows)
      if tileID <= High(TOWN_COLLIDES) then Exit(TOWN_COLLIDES[tileID]) else Exit(False);

    mkDungeon, mkRuin, mkVCastle:
      if tileID <= High(DUN_COLLIDES) then Exit(DUN_COLLIDES[tileID]) else Exit(False);

    mkAfterlife:
      if tileID <= High(AFTER_COLLIDES) then Exit(AFTER_COLLIDES[tileID]) else Exit(False);

  else
    Exit(False);
  end;
end;

// **************************************** TileOccludes ****************************************

function TileOccludes(const kind: TMapKind; const tileID: Byte): Boolean;
begin
  case kind of
    mkWorld:
      if tileID <= High(WORLD_OCCLUDES) then Exit(WORLD_OCCLUDES[tileID]) else Exit(False);

    mkTown, mkCastle:
      if tileID <= High(TOWN_OCCLUDES) then Exit(TOWN_OCCLUDES[tileID]) else Exit(False);

    mkDungeon, mkRuin, mkVCastle:
      if tileID <= High(DUN_OCCLUDES) then Exit(DUN_OCCLUDES[tileID]) else Exit(False);

    mkAfterlife:
      if tileID <= High(AFTER_OCCLUDES) then Exit(AFTER_OCCLUDES[tileID]) else Exit(False);
  else
    Exit(False);
  end;
end;

// ************************************* Tiles_Get_TownMon *************************************
function Tiles_Get_TownMon(const Index: Word): PUInt32;
begin
  if Index < Length(GTownMon) then Result := @GTownMon[Index][0] else Result := nil;
end;

function Tiles_Get_DungeonMon(const Index: Word): PUInt32;
begin
  if Index < Length(GDungMon) then Result := @GDungMon[Index][0] else Result := nil;
end;

function Tiles_Get_RuinMon(const Index: Word): PUInt32;
begin
  if Index < Length(GRuinMon) then Result := @GRuinMon[Index][0] else Result := nil;
end;

function Tiles_Get_LifeMon(const Index: Word): PUInt32;
begin
  if Index < Length(GLifeMon) then Result := @GLifeMon[Index][0] else Result := nil;
end;

function Tiles_MonCount(const kind: TMapKind): Integer;
begin
  case kind of
    mkTown, mkCastle:   Exit(Length(GTownMon));
    mkDungeon:          Exit(Length(GDungMon));
    mkRuin, mkVCastle:  Exit(Length(GRuinMon));
    mkAfterlife:        Exit(Length(GLifeMon));
  else
    Exit(0);
  end;
end;

// ********************************** Tiles_Get_Mon_ForActive **********************************
function Tiles_Get_Mon_ForActive(const index: Word): PUInt32;
begin
  case ActiveKind of
    mkTown, mkCastle:   Exit(Tiles_Get_TownMon(index));
    mkDungeon:          Exit(Tiles_Get_DungeonMon(index));
    mkRuin, mkVCastle:  Exit(Tiles_Get_RuinMon(index));
    mkAfterlife:        Exit(nil); // ← suppress monsters in Afterlife
  end;
  Result := nil;
end;


end.

