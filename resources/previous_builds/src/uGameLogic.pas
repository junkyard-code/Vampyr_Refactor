unit uGameLogic;

{$mode objfpc}{$H+}

interface

uses
  uGameTypes, data_loaders, SysUtils;

procedure LoadMonstersForMap(var W: TWorldState);

implementation

procedure LoadMonstersForMap(var W: TWorldState);
var
  SetMonsterData: TSetMonsterDataArray;
  i: Integer;
  MonsterFile: string;
begin
  case W.CurrentMapType of
    mtWorld: MonsterFile := 'enconter.set';
    mtTown: MonsterFile := ''; // No monsters in town
    mtDungeon: MonsterFile := 'dungeon.set'; // Example for dungeon
  else
    MonsterFile := '';
  end;

  if MonsterFile = '' then
  begin
    SetLength(W.SetMonsters, 0); // Clear monsters if none for this map
    Exit;
  end;

  if LoadSetMonsters(DataPath(W.DataDir, MonsterFile), SetMonsterData) then
  begin
    SetLength(W.SetMonsters, Length(SetMonsterData));
    for i := 0 to High(SetMonsterData) do
    begin
      W.SetMonsters[i].MonsterName := SetMonsterData[i].MonsterName;
      W.SetMonsters[i].NumInGroup := SetMonsterData[i].NumInGroup;
      W.SetMonsters[i].X := SetMonsterData[i].X;
      W.SetMonsters[i].Y := SetMonsterData[i].Y;
      W.SetMonsters[i].Msg1 := SetMonsterData[i].Msg1;
      W.SetMonsters[i].Msg2 := SetMonsterData[i].Msg2;
      W.SetMonsters[i].OriPic := SetMonsterData[i].OriPic;
      W.SetMonsters[i].Status := msNormal;
    end;
  end
  else
  begin
    writeln('Failed to load set monsters from ', MonsterFile);
    SetLength(W.SetMonsters, 0);
  end;
end;

end.
