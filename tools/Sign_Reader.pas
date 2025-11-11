program sign_reader;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes;

type
  TSignRec = packed record
    X, Y: Byte;
    Msg1: string[70];
    Msg2: string[70];
  end;

// **************************************** ReadAndDisplaySigns ****************************************
procedure ReadAndDisplaySigns(const filename: string);
var
  f: file of TSignRec;
  sign: TSignRec;
  recNum: Integer;
begin
  if not FileExists(filename) then
  begin
    WriteLn('Error: File not found: ', filename);
    Exit;
  end;

  AssignFile(f, filename);
  try
    Reset(f);
    recNum := 0;
    WriteLn('Reading sign records from: ', filename);
    WriteLn(StringOfChar('-', 80));
    
    while not Eof(f) do
    begin
      Read(f, sign);
      WriteLn('Record #', recNum);
      WriteLn('  Bank: ', recNum div 3, ', Position in bank: ', recNum mod 3);
      WriteLn('  X: ', sign.X, ', Y: ', sign.Y);
      WriteLn('  Msg1: ', sign.Msg1);
      WriteLn('  Msg2: ', sign.Msg2);
      WriteLn(StringOfChar('-', 80));
      Inc(recNum);
    end;
    
    WriteLn('Total records: ', recNum, ' (', (recNum + 2) div 3, ' banks)');
  except
    on E: Exception do
      WriteLn('Error reading file: ', E.Message);
  end;
  
  CloseFile(f);
end;

var
  dataDir, signFile: string;
begin
  // Default to looking in the 'data' subdirectory
  dataDir := ExtractFilePath(ParamStr(0)) + 'data' + PathDelim;
  signFile := dataDir + 'SIGN.DAT';
  
  // Allow specifying a custom path as a command-line parameter
  if ParamCount > 0 then
    signFile := ParamStr(1);
    
  ReadAndDisplaySigns(signFile);
  
  if not FileExists(signFile) then
    WriteLn('Please ensure the file exists: ', signFile);
    
  WriteLn('Press Enter to exit...');
  ReadLn;
end.