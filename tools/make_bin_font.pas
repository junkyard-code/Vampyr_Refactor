program make_bin_font;
{$mode objfpc}{$H+}

uses
  Windows, Classes, SysUtils;

type
  PByte = ^Byte;

function TryCreate8x8(const face: PChar; const charset: BYTE; const height: Integer; out h: HFONT): Boolean;
var
  lf: LOGFONT;
  dc: HDC;
  tm: TEXTMETRIC;
  old: HGDIOBJ;
begin
  Result := False;
  h := 0;

  FillChar(lf, SizeOf(lf), 0);
  lf.lfHeight := height;        // -8 preferred (exact pixel height), try also -7 as fallback
  lf.lfWidth  := 0;             // let GDI choose width for fixed raster
  lf.lfWeight := FW_NORMAL;
  lf.lfCharSet := charset;      // OEM_CHARSET or DEFAULT_CHARSET
  lf.lfOutPrecision := OUT_DEFAULT_PRECIS;
  lf.lfClipPrecision := CLIP_DEFAULT_PRECIS;
  lf.lfQuality := NONANTIALIASED_QUALITY;
  lf.lfPitchAndFamily := FIXED_PITCH or FF_MODERN;
  if face <> nil then
    StrPLCopy(lf.lfFaceName, face, Length(lf.lfFaceName)-1);

  h := CreateFontIndirect(lf);
  if h = 0 then Exit;

  // Validate it is truly 8×8
  dc := CreateCompatibleDC(0);
  if dc <> 0 then
  begin
    old := SelectObject(dc, h);
    if GetTextMetrics(dc, tm) then
    begin
      // We want cell height and cell width both 8
      if (tm.tmHeight = 8) and (tm.tmAveCharWidth = 8) then
        Result := True;
    end;
    SelectObject(dc, old);
    DeleteDC(dc);
  end;

  if not Result then
  begin
    DeleteObject(h);
    h := 0;
  end;
end;

function Create8x8FromFON(const fonPath: string; const faceName: string; out h: HFONT): Boolean;
const
  // Try a few charsets and pixel heights (most common combos for .FON raster strikes)
  Charsets: array[0..1] of BYTE = (OEM_CHARSET, DEFAULT_CHARSET);
  Heights : array[0..1] of Integer = (-8, -7);
var
  i, j: Integer;
  face: PChar;
begin
  Result := False;
  h := 0;

  // Register the FON (process-wide). If already installed, return may be 0; that’s ok.
  AddFontResource(PChar(fonPath));

  if faceName <> '' then
    face := PChar(faceName)
  else
    face := nil; // let GDI match by charset/size (less reliable)

  // Try combinations until we get an exact 8×8 strike
  for i := Low(Charsets) to High(Charsets) do
    for j := Low(Heights) to High(Heights) do
      if TryCreate8x8(face, Charsets[i], Heights[j], h) then
        Exit(True);

  // If a specific face name was provided and failed, optionally try nil face as fallback:
  if (face <> nil) then
    for i := Low(Charsets) to High(Charsets) do
      for j := Low(Heights) to High(Heights) do
        if TryCreate8x8(nil, Charsets[i], Heights[j], h) then
          Exit(True);
end;

procedure UnregisterFON(const fonPath: string);
begin
  RemoveFontResource(PChar(fonPath));
end;

// Draw a single glyph (byte codepoint) into an 8×8 32-bpp DIB and
// return it as 8 bytes (1 bit per pixel, MSB = leftmost).
function RenderGlyph8x8(hFont: HFONT; ch: Byte; outRows: PByte): Boolean;
var
  memDC: HDC;
  oldFont: HFONT;
  bmp: HBITMAP;
  oldBmp: HGDIOBJ;
  bi: BITMAPINFO;
  bits: Pointer;
  s: AnsiString;
  x, y: Integer;
  rowByte, mask: Byte;
  p: PByte; // raw BGRA
begin
  Result := False;

  FillChar(bi, SizeOf(bi), 0);
  bi.bmiHeader.biSize := SizeOf(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth := 8;
  bi.bmiHeader.biHeight := -8;  // top-down
  bi.bmiHeader.biPlanes := 1;
  bi.bmiHeader.biBitCount := 32;
  bi.bmiHeader.biCompression := BI_RGB;

  memDC := CreateCompatibleDC(0);
  if memDC = 0 then Exit;

  bmp := CreateDIBSection(memDC, bi, DIB_RGB_COLORS, bits, 0, 0);
  if bmp = 0 then
  begin
    DeleteDC(memDC);
    Exit;
  end;

  oldBmp  := SelectObject(memDC, bmp);
  oldFont := SelectObject(memDC, hFont);

  // clear to black
  PatBlt(memDC, 0, 0, 8, 8, BLACKNESS);

  // white text, no AA
  SetBkMode(memDC, TRANSPARENT);
  SetTextColor(memDC, RGB(255,255,255));
  SetTextCharacterExtra(memDC, 0);
  SetTextAlign(memDC, TA_TOP or TA_LEFT);

  // draw the character at (0,0)
  s := AnsiString(Chr(ch));
  TextOutA(memDC, 0, 0, PAnsiChar(s), 1);

  // convert to packed 1bpp rows (left-to-right, MSB first)
  for y := 0 to 7 do
  begin
    rowByte := 0;
    mask := $80;
    p := PByte(bits) + (y * 8 * 4); // 4 bytes per pixel
    for x := 0 to 7 do
    begin
      // BGRA in memory: any non-black -> set bit
      if (p^ <> 0) or (PByte(p+1)^ <> 0) or (PByte(p+2)^ <> 0) then
        rowByte := rowByte or mask;
      Inc(p, 4);
      mask := mask shr 1;
    end;
    outRows[y] := rowByte;
  end;

  // restore & cleanup
  SelectObject(memDC, oldFont);
  SelectObject(memDC, oldBmp);
  DeleteObject(bmp);
  DeleteDC(memDC);

  Result := True;
end;

var
  fonPath, outBin, faceName: string;
  hFont: HFONT;
  fs: TFileStream;
  rows: array[0..7] of Byte;
  i: Integer;
begin
  if (ParamCount < 2) or (ParamCount > 3) then
  begin
    Writeln('Usage: make_bin_font <path-to-.FON> <out-bin> [faceName]');
    Halt(1);
  end;

  fonPath := ParamStr(1);
  outBin  := ParamStr(2);
  if ParamCount = 3 then faceName := ParamStr(3) else faceName := '';

  if not FileExists(fonPath) then
  begin
    Writeln('FON not found: ', fonPath);
    Halt(1);
  end;

  if not Create8x8FromFON(fonPath, faceName, hFont) then
  begin
    Writeln('Could not obtain a TRUE 8x8 strike from "', fonPath,
            '". Try passing the exact face name as the 3rd argument.');
    Halt(1);
  end;

  fs := TFileStream.Create(outBin, fmCreate);
  try
    for i := 0 to 255 do
    begin
      if not RenderGlyph8x8(hFont, i, @rows[0]) then
        FillChar(rows, SizeOf(rows), 0);
      fs.WriteBuffer(rows[0], 8); // 8 rows per glyph
    end;
  finally
    fs.Free;
    DeleteObject(hFont);
    UnregisterFON(fonPath);
  end;

  Writeln('Wrote ', outBin, ' (2048 bytes).');
end.