unit uConLoader;
{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..0] of Byte;

  TCon = record
    TileCount: Integer;
    Data: PByteArray; // contiguous tiles, each 18*18 bytes
  end;

function LoadCon(const FN: AnsiString): TCon;
procedure FreeCon(var C: TCon);

implementation

const
  TILE_W=18; TILE_H=18; TILE_SIZE=TILE_W*TILE_H;

function LoadCon(const FN: AnsiString): TCon;
var
  fs: TFileStream;
  size: Int64;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FileExists(FN) then Exit;
  fs := TFileStream.Create(FN, fmOpenRead or fmShareDenyNone);
  try
    size := fs.Size;
    if (size<=0) or (size mod TILE_SIZE<>0) then Exit;
    Result.TileCount := size div TILE_SIZE;
    GetMem(Result.Data, size);
    fs.ReadBuffer(Result.Data^, size);
  finally
    fs.Free;
  end;
end;

procedure FreeCon(var C: TCon);
begin
  if C.Data<>nil then FreeMem(C.Data);
  FillChar(C, SizeOf(C), 0);
end;

end.
