unit Font8x8;
{$mode objfpc}{$H+}

interface

function LoadCP437Font8x8(const FileName: string): Boolean;
function Font8x8Row(ch: Byte; row: Integer): Byte;  // 8 bits, left→right in bits 7..0
var
  FONT8_LOADED: Boolean = False;

implementation

uses SysUtils;

var
  FONT8: array[0..255,0..7] of Byte;

function LoadCP437Font8x8(const FileName: string): Boolean;
var
  F: File;
  count: Integer;
begin
  Result := False;
  AssignFile(F, FileName);
  {$I-} Reset(F,1); {$I+}
  if IOResult <> 0 then Exit;
  try
    BlockRead(F, FONT8[0,0], SizeOf(FONT8), count);
    Result := (count = SizeOf(FONT8));
    FONT8_LOADED := Result;
  finally
    CloseFile(F);
  end;
end;

function Font8x8Row(ch: Byte; row: Integer): Byte;
begin
  if (row < 0) or (row > 7) then Exit(0);
  Result := FONT8[ch, row];
end;

end.