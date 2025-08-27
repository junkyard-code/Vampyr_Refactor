unit uConfig;
{$mode objfpc}{$H+}

interface

type
  TViewerConfig = record
    ScaleDefault: Integer;
    AnimationEnabled: Boolean;
    AnimationDelayMs: Integer;
    WorldTransform: Integer;
  end;

procedure LoadViewerConfig(out Cfg: TViewerConfig; const BaseDir: AnsiString);

implementation

uses SysUtils;

function TrimLower(const S: AnsiString): AnsiString;
begin
  Result := LowerCase(Trim(S));
end;

function ParseBool(const S: AnsiString; const DefaultVal: Boolean): Boolean;
var L: AnsiString;
begin
  L := TrimLower(S);
  if (L='true') or (L='1') or (L='yes') then Exit(True);
  if (L='false') or (L='0') or (L='no') then Exit(False);
  Exit(DefaultVal);
end;

function ParseInt(const S: AnsiString; const DefaultVal: Integer): Integer;
begin
  try Result := StrToInt(Trim(S)); except Result := DefaultVal; end;
end;

procedure LoadViewerConfig(out Cfg: TViewerConfig; const BaseDir: AnsiString);
var
  FN, Line, Key, Val: AnsiString;
  F: TextFile;
begin
  Cfg.ScaleDefault := 4;
  Cfg.AnimationEnabled := True;
  Cfg.AnimationDelayMs := 380;
  Cfg.WorldTransform := 5; // default to diagXY based on latest feedback

  FN := IncludeTrailingPathDelimiter(BaseDir) + 'config' + DirectorySeparator + 'viewer.ini';
  if not FileExists(FN) then Exit;

  AssignFile(F, FN); {$I-} Reset(F); {$I+} if IOResult<>0 then Exit;
  try
    while not Eof(F) do
    begin
      ReadLn(F, Line);
      Line := Trim(Line);
      if (Line='') or (Line[1] in [';','#','[']) then Continue;
      if Pos('=', Line)>0 then
      begin
        Key := Trim(Copy(Line, 1, Pos('=', Line)-1));
        Val := Trim(Copy(Line, Pos('=', Line)+1, Length(Line)));
        case LowerCase(Key) of
          'scaledefault'     : Cfg.ScaleDefault     := ParseInt(Val, Cfg.ScaleDefault);
          'animationenabled' : Cfg.AnimationEnabled := ParseBool(Val, Cfg.AnimationEnabled);
          'animationdelayms' : Cfg.AnimationDelayMs := ParseInt(Val, Cfg.AnimationDelayMs);
          'worldtransform'   : Cfg.WorldTransform   := ParseInt(Val, Cfg.WorldTransform);
        end;
      end;
    end;
  finally
    CloseFile(F);
  end;

  if (Cfg.ScaleDefault<>2) and (Cfg.ScaleDefault<>4) then Cfg.ScaleDefault := 4;
  if (Cfg.AnimationDelayMs<20) then Cfg.AnimationDelayMs := 20;
  if (Cfg.WorldTransform<0) or (Cfg.WorldTransform>6) then Cfg.WorldTransform := 0;
end;

end.
