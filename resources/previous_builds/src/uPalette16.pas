unit uPalette16;
{$mode objfpc}{$H+}
interface
type TRGB = record r,g,b: Byte; end;
const
  PALETTE16: array[0..15] of TRGB = (
    (r:0;  g:0;  b:0),
    (r:0;  g:0;  b:170),
    (r:0;  g:170; b:0),
    (r:0;  g:170; b:170),
    (r:170;g:0;  b:0),
    (r:170;g:0;  b:170),
    (r:170;g:85; b:0),
    (r:170;g:170;b:170),
    (r:85; g:85; b:85),
    (r:85; g:85; b:255),
    (r:85; g:255;b:85),
    (r:85; g:255;b:255),
    (r:255;g:85; b:85),
    (r:255;g:85; b:255),
    (r:255;g:255;b:85),
    (r:255;g:255;b:255)
  );
implementation end.
