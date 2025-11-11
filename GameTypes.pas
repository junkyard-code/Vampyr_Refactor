unit GameTypes;
{$mode objfpc}{$H+}
{$packrecords 1}  //important so BlockRead matches the on-disk layout byte-for-byte.

interface

type
   TMapKind = (mkWorld, mkTown, mkCastle, mkDungeon, mkRuin, mkVCastle, mkAfterlife);


implementation




end.

