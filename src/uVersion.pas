unit uVersion;
{$mode objfpc}{$H+}

interface

uses SDL2;

const
  APP_NAME    = 'Vampyr World Viewer';
  APP_VERSION = '7.8.3';
  APP_BUILD   = 'world-xform+clamp';

procedure PrintStartupBanner(
  const DataPath: AnsiString;
  const ScaleDefault: Integer;
  const AnimEnabled: Boolean;
  const AnimDelayMs: Integer;
  const WorldTransform: Integer
);

procedure SetWindowTitle(const W: PSDL_Window);

implementation

uses SysUtils;

procedure PrintStartupBanner(
  const DataPath: AnsiString;
  const ScaleDefault: Integer;
  const AnimEnabled: Boolean;
  const AnimDelayMs: Integer;
  const WorldTransform: Integer
);
var
  AnimState: AnsiString;
begin
  if AnimEnabled then AnimState := 'ON' else AnimState := 'OFF';
  WriteLn('=== ', APP_NAME, ' v', APP_VERSION, ' (', APP_BUILD, ') ===');
  WriteLn('Data path: ', DataPath);
  WriteLn('Defaults  : scale x', ScaleDefault, ', animation ', AnimState, ', delay ', AnimDelayMs, ' ms');
  WriteLn('Transform : ', WorldTransform, ' (0=identity,1=flipX,2=flipY,3=rotCW,4=rotCCW,5=diagXY,6=antiDiag)');
  WriteLn('Controls  : Arrows pan | F2/F4 scale | A toggle anim | +/- delay | O cycle xform | Click enter | B back | Esc quit');
  WriteLn;
end;

procedure SetWindowTitle(const W: PSDL_Window);
var
  Title: AnsiString;
begin
  if W = nil then Exit;
  Title := APP_NAME + ' v' + APP_VERSION;
  SDL_SetWindowTitle(W, PChar(Title));
end;

end.
