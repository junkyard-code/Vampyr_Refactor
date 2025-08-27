unit uMonsterAI;

interface

uses
  SysUtils, Classes, uGameTypes;

procedure MonsterMovement(var World: TWorldState);

implementation

uses
  uWorldView;

procedure MonsterMovement(var World: TWorldState);
var
  i: Integer;
  dx, dy: Integer;
  newX, newY: Byte;

  function IsOccupied(x, y: Byte): Boolean;
  var
    j: Integer;
  begin
    // Check player position
    if (World.Player.XLoc = x) and (World.Player.YLoc = y) then
      Exit(True);

    // Check other monster positions
    for j := 0 to High(World.SetMonsters) do
    begin
      // Check if any other monster (not the current one) is at the target location
      if (i <> j) and (World.SetMonsters[j].X = x) and (World.SetMonsters[j].Y = y) then
        Exit(True);
    end;
    Result := False;
  end;

begin
  if High(World.SetMonsters) < 0 then Exit; // No monsters to move

  for i := 0 to High(World.SetMonsters) do
  begin
    if World.SetMonsters[i].Status = msChasing then
    begin
      // Simple chasing logic: move toward player
      dx := World.Player.XLoc - World.SetMonsters[i].X;
      dy := World.Player.YLoc - World.SetMonsters[i].Y;

      newX := World.SetMonsters[i].X;
      newY := World.SetMonsters[i].Y;

      // Move horizontally or vertically towards the player, whichever is greater
      if Abs(dx) > Abs(dy) then
      begin
        if dx > 0 then Inc(newX) else Dec(newX);
      end
      else if dy <> 0 then // Avoid moving if already on same column and dx=0
      begin
        if dy > 0 then Inc(newY) else Dec(newY);
      end;

      // Check if the new position is valid and not occupied
      if CanMoveTo(World, newX, newY) and not IsOccupied(newX, newY) then
      begin
        World.SetMonsters[i].X := newX;
        World.SetMonsters[i].Y := newY;
      end;
    end;
  end;
end;

end.
