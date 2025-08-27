
PlayerType = Record
           Name : String[10];
           Race : Byte;
           Life, XP, Gold : Integer;
           Stats : Array[1..6] Of Byte;
           Attack : Byte;
           Defense : Byte;
           Offensive : Byte;
           Defensive : Byte;
           Healing : Byte;
           Picking : Byte;
           Climbing : Byte;
           Stealing : Byte;
           Perception : Byte;
           Weapon, Armor : Byte;
           Mission : Array[1..5] Of Boolean;
           End;

WeaponType : Byte;
           { 0  = None }
           { 1  = Staff }
           { 2  = Dagger }
           { 3  = Mace }
           { 4  = Morning Star }
           { 5  = Axe }
           { 6  = Long Sword }
           { 7  = Two Handed Sword }
           { 8  = Long Bow }
           { 9  = Sling }
           { 10 = Halberd }
           { 11 = 20 +1 of the above weapon }
           { 21 = 30 +2 of the above weapon }
           { 31 = 40 +3 of the above weapon }
           { 41 = Dragon Claws }
           { ....}
           { ....}


ArmorType : Byte;
           {  0 = None }
           {  1 = Cloth }
           {  2 = Padded Armor }
           {  3 = Leather Armor }
           {  4 = Studded Armor }
           {  5 = Ring Mail }
           {  6 = Scale Mail }
           {  7 = Chain Mail }
           {  8 = Splinted Mail }
           {  9 = Plate Mail }
           { 10 = Full Plate Mail }
           { 11 = 20 +1 of the above armor }
           { 21 = 30 +2 of the above armor }
           { 31 = 40 +3 of the above armor }
           { 41 = Dragon Scales }
           { ... }
           { ... }



Needed Procedures

Procedure WeaponInfo(N:WeaponType; VAR Name:String[23]; VAR Damage:Byte);
    { Returns name of weapon and the damage it does }
  Var
     Plus : Byte;
    Begin
      Plus:=0;
      If (N>10) And (N<21) Then Begin
                           Plus:=1; N:=N Mod 10;
                           End;
      If (N>20) And (N<31) Then Begin
                           Plus:=2; N:=N Mod 20;
                           End;
      If (N>30) And (N<41) Then Begin
                           Plus:=3; N:=N Mod 30;
                           End;
      Case Of N Do
           1  :  Begin Name:='Dagger';
                       Damage:=Random(4)+(Plus+1);
                 End;
           ....
           ....
           ....
           0  :  Begin
                  If Plus=0 Then Begin
                            Name:='Hands';
                            Damage(2)+1;
                            End Else
                            Name:='Halberd';
                            Damage:=Random(8)+(Plus+2)
                            End;
           41 :  Begin
                 Name:='Claws';
                 Damage(10)+10;
                 End;
           ....
           ....
           ....
           End;
End;




Procedure ArmorInfo(N:ArmorType; VAR Name:String[17]; VAR Defense:Byte);
    { Return name of armor and the defense }

     { Same as weaponinfo but with armor and will return name and defense }



Procedure MissleWeapon(Which:Byte; X1,Y2:Byte; Direction:Byte);
    { Animates missle icon on combat screen starting at (x,y) and going }
    { direction until hit by monster or player. }


Procedure Town

Type
   PeopleType = Record
              Status : Byte;  { 0 = Standing }
                              { 1 = Wandering }
                              { 2 = Chasing Player }

              Talk : Arrary[1..2] Of String[50];
                              { Talk[1] What person says anytime }
                              { Talk[2] What person says sometimes}

              Which : Byte;  { Which monster data to load in combat }

              Job : Byte;   { 0 = Guard }
                            { 1 = Merchant }
                            { 2 = Normal }
                            { 3 = Special, ex. Pirate that has a boat }
                                          { to take the player to     }
                                          { Vampyr's Castle. or King  }

              XLocation,YLocation : Byte;
              Weapon, Armor : Byte;
              End;


Var

   People : Array[1..20] Of PeopleType;  { 2180 Byte of memory }
