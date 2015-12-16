unit DXGUITypes;

interface

uses
  Winapi.Windows, System.SysUtils;

type
  TDXColor = type DWord;

  TDXPrimitiveType = (ptPointList, ptLineList, ptLineStrip, ptTriangleList, ptTriangleStrip,
    ptTriangleFan);

  PDXPixel = ^TDXPixel;
  TDXPixel = packed record
    case Integer of
      0: (B, G, R, A: Byte);
      1: (Color: TDXColor);
  end;

  PDXImageData = ^TDXImageData;
  TDXImageData = packed record
    Color: TDXColor;
  end;

  TDXVertex = packed record
    X, Y, Z, R: Single;
    Diff: TDXColor;
  end;
  TDXVertexArray = array of TDXVertex;

//type
  //EDXGUIFrameworkException = class(Exception);
  //EDXInvalidArgumentException = class(EDXGUIFrameworkException);
  //EDXRendererException = class(EDXGUIFrameworkException);

const
  clBlack = $FF000000;
  clWhite = $FFFFFFFF;
  clLime  = $FF00FF00;

function DXCOLOR_ARGB(A, R, G, B: DWord): TDXColor; inline;
function DXCOLOR_RGBA(R, G, B, A: DWord): TDXColor; inline;
function DXCOLOR_XRGB(R, G, B: DWord): TDXColor; inline;
function DXCOLOR_XYUV(Y, U, V: DWord): TDXColor; inline;
function DXCOLOR_AYUV(A, Y, U, V: DWord): TDXColor; inline;
procedure DXCOLOR_DECODE_ARGB(Color: TDXColor; var A, R, G, B: Byte); inline;

implementation

function DXCOLOR_ARGB(A, R, G, B: DWord): TDXColor;
begin
  Result := (A shl 24) or (R shl 16) or (G shl 8) or B;
end;

function DXCOLOR_RGBA(R, G, B, A: DWord): TDXColor;
begin
  Result := (A shl 24) or (R shl 16) or (G shl 8) or B;
end;

function DXCOLOR_XRGB(R, G, B: DWord): TDXColor;
begin
  Result := DWord($FF shl 24) or (R shl 16) or (G shl 8) or B;
end;

function DXCOLOR_XYUV(Y, U, V: DWord): TDXColor;
begin
  Result := DWord($FF shl 24) or (Y shl 16) or (U shl 8) or V;
end;

function DXCOLOR_AYUV(A, Y, U, V: DWord): TDXColor;
begin
  Result := (A shl 24) or (Y shl 16) or (U shl 8) or V;
end;

procedure DXCOLOR_DECODE_ARGB(Color: TDXColor; var A, R, G, B: Byte);
begin
  A := (Color and $FF000000) shr 24;
  R := (Color and $00FF0000) shr 16;
  G := (Color and $0000FF00) shr  8;
  B := (Color and $000000FF);
end;

end.
