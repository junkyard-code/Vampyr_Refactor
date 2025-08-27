unit uWorldMap;
{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

type
  TWorld = record
    W,H: Integer;
    Data: array of Byte; // size W*H
  end;

function LoadWorldMap(const FN: AnsiString): TWorld;
function GetTileID(const M: TWorld; X,Y: Integer): Byte;

implementation

function LoadWorldMap(const FN: AnsiString): TWorld;
var
  fs: TFileStream;
  size: Int64;
  W,H: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  if not FileExists(FN) then Exit;
  fs := TFileStream.Create(FN, fmOpenRead or fmShareDenyNone);
  try
    size := fs.Size;
    if (size=11000) then begin W:=100; H:=110; end
    else begin
      W:=100; H:=size div 100;
    end;
    Result.W := W; Result.H := H;
    SetLength(Result.Data, W*H);
    fs.ReadBuffer(Result.Data[0], Length(Result.Data));
  finally
    fs.Free;
  end;
end;

function GetTileID(const M: TWorld; X,Y: Integer): Byte;
begin
  if (X<0) or (Y<0) or (X>=M.W) or (Y>=M.H) then Exit(0);
  Result := M.Data[Y*M.W + X];
end;

end.
