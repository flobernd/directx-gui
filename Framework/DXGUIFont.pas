unit DXGUIFont;

interface

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI, System.Classes, Generics.Collections,
  DXGUIFramework, DXGUIRenderInterface, DXGUITypes;

type
  TDXFontCharset = 0..255;
  TDXFontPitch   = (fpDefault, fpVariable, fpFixed);
  TDXFontStyle   = (fsBold, fsItalic, fsUnderline, fsStrikeOut);
  TDXFontStyles  = set of TDXFontStyle;
  TDXFontName    = type String;

  TDXTextAlignment         = (alLeft, alCenter, alRight);
  TDXTextVerticalAlignment = (vaTop, vaCenter, vaBottom);

  TDXFontCacheSize = 1..1024;

type
  TDXFont = class(TDXPersistent)
  private
    FFamily: TDXFontName;
    FCharset: TDXFontCharset;
    FPitch: TDXFontPitch;
    FSize: Integer;
    FStyle: TDXFontStyles;
    FAntiAliased: Boolean;
    FCached: Boolean;
    FCacheSize: TDXFontCacheSize;
    FGraphics: TGPGraphics;
    FFont: TGPFont;
    FBrush: TGPBrush;
    FFormat: TGPStringFormat;
    FTexture: TDXTexture;
    FCacheItems: TDictionary<String, TDXTexture>;
    FCacheKeys: TList<String>;
    FDeviceContext: HDC;
    FFontHandle: HFONT;
  private
    procedure SetFamily(const Value: TDXFontName);
    procedure SetCharset(const Value: TDXFontCharset);
    procedure SetPitch(const Value: TDXFontPitch);
    procedure SetAntiAliased(const Value: Boolean);
    procedure SetSize(const Value: Integer);
    procedure SetStyle(const Value: TDXFontStyles);
    procedure SetCached(const Value: Boolean);
    procedure SetCacheSize(const Value: TDXFontCacheSize);
  private
    function TranslateAlignment(Value: TDXTextAlignment): StringAlignment;
    function TranslateVerticalAlignment(Value: TDXTextVerticalAlignment): StringAlignment;
  private
    function CreateFontTexture(R: TRect; const Text: String; Alignment: TDXTextAlignment;
      VerticalAlignment: TDXTextVerticalAlignment; WordWrap: Boolean): TDXTexture;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  protected
    procedure UpdateFont;
  public
    procedure DrawText(X, Y: Integer; const Text: String;
      const Color: TDXColor = clBlack; const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
    procedure DrawText(X, Y, Width, Height: Integer; const Text: String;
      const Color: TDXColor = clBlack; const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
    procedure DrawText(R: TRect; const Text: String; const Color: TDXColor = clBlack;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
  public
    function CalculateTextRect(R: TRect; const Text: String;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false): TRect; overload;
    function GetTextWidth(R: TRect; const Text: String;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false): Integer; overload;
    function GetTextHeight(R: TRect;
      const Text: String; const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false): Integer; overload;
    function CalculateTextRect(const Text: String;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false): TRect; overload;
    function GetTextWidth(const Text: String;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false): Integer; overload;
    function GetTextHeight(const Text: String; const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false): Integer; overload;
  public
    constructor Create(Manager: TDXGUIManager);
    destructor Destroy; override;
  published
    property Family: TDXFontName read FFamily write SetFamily;
    property Charset: TDXFontCharset read FCharset write SetCharset;
    property Pitch: TDXFontPitch read FPitch write SetPitch default fpDefault;
    property Size: Integer read FSize write SetSize default 10;
    property Style: TDXFontStyles read FStyle write SetStyle default [];
    property AntiAliased: Boolean read FAntiAliased write SetAntiAliased default false;
    property Cached: Boolean read FCached write SetCached default true;
    property CacheSize: TDXFontCacheSize read FCacheSize write SetCacheSize default 32;
  end;

// TODO: Alle Funktionen mit unterschiedlichen Parametern testen
// TODO: Evtl. Orientation implementieren

implementation

uses
  System.Types, DXGUIExceptions;

resourcestring
  SGDIPMeasureStringError = 'Could not calculate text rect.';
  SGDIPLockBitmapDataError = 'Could not lock bitmap data.';
  SGDIPUnlockBitmapDataError = 'Could not unlock bitmap data.';
  SGDIPGraphicsCreateError = 'Could not create GDI+ graphics object.';
  SGDIPBrushCreateError = 'Could not create GDI+ brush object.';
  SGDIPStringFormatCreateError = 'Could not create GDI+ string format object.';
  SGDIPBitmapCreateError = 'Could not create GDI+ bitmap object.';
  SGDIPDrawStringError = 'Could not draw string to GDI+ bitmap.';
  SGDIPCreateFontError = 'Could not create GDI+ font object.';
  SFontNameTooLongException = 'Font name is too long.';

// ============================================================================================== //
{ TDXFont }

function TDXFont.CalculateTextRect(R: TRect; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): TRect;
var
  Flags: DWord;
begin
  Flags := 0;
  if (WordWrap) then
  begin
    Flags := Flags or DT_WORDBREAK;
  end;
  case Alignment of
    alLeft  : Flags := Flags or DT_LEFT;
    alCenter: Flags := Flags or DT_CENTER;
    alRight : Flags := Flags or DT_RIGHT;
  end;
  case VerticalAlignment of
    vaTop   : Flags := Flags or DT_TOP;
    vaCenter: Flags := Flags or DT_VCENTER;
    vaBottom: Flags := Flags or DT_BOTTOM;
  end;
  Result := R;
  Winapi.Windows.DrawText(FDeviceContext, Text, Length(Text), Result, DT_CALCRECT or Flags);
{var
  LayoutRect,
  TextRect: TGPRectF;
begin
  FFormat.SetAlignment(StringAlignmentNear);
  FFormat.SetLineAlignment(StringAlignmentNear);
  case WordWrap of
    false: FFormat.SetFormatFlags(StringFormatFlagsNoWrap or StringFormatFlagsMeasureTrailingSpaces);
    true : FFormat.SetFormatFlags(StringFormatFlagsMeasureTrailingSpaces);
  end;
  case FAntiAliased of
    false: FGraphics.SetTextRenderingHint(TextRenderingHintSingleBitPerPixelGridFit);
    true : FGraphics.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);
  end;
  LayoutRect.X := R.Left;
  LayoutRect.Y := R.Top;
  LayoutRect.Width := R.Width;
  LayoutRect.Height := R.Height;
  FGraphics.MeasureString(Text + ' ', Length(Text) + 1, FFont, LayoutRect, FFormat, TextRect);
  Result := Rect(Round(TextRect.X), Round(TextRect.Y), Round(TextRect.X + TextRect.Width),
    Round(TextRect.Y + TextRect.Height));  }
end;

procedure TDXFont.AssignTo(Dest: TPersistent);
var
  Font: TDXFont;
begin
  if (Dest is TDXFont) then
  begin
    Font := TDXFont(Dest);
    if (Font.FFamily <> FFamily) or (Font.FCharset <> FCharset) or (Font.FPitch <> FPitch) or
      (Font.FSize <> FSize) or (Font.FStyle <> FStyle) or (Font.FAntiAliased <> FAntiAliased) then
    begin
      Font.FFamily := FFamily;
      Font.FCharset := FCharset;
      Font.FPitch := FPitch;
      Font.FSize := FSize;
      Font.FStyle := FStyle;
      Font.FAntiAliased := FAntiAliased;
      Font.UpdateFont;
    end;
  end else inherited;
end;

function TDXFont.CalculateTextRect(const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): TRect;
begin
  Result := CalculateTextRect(Rect(0, 0, 0, 0), Text, Alignment, VerticalAlignment, WordWrap);
end;

constructor TDXFont.Create(Manager: TDXGUIManager);
begin
  inherited Create(Manager);
  FTexture := Manager.RenderInterface.CreateTexture;
  FCacheItems := TObjectDictionary<String, TDXTexture>.Create([doOwnsValues]);
  FCacheKeys := TList<String>.Create;
  FFamily := 'Tahoma';
  FCharset := ANSI_CHARSET;
  FPitch := fpDefault;
  FStyle := [];
  FAntiAliased := false;
  FSize := 10;
  FCached := true;
  FCacheSize := 32;
  FGraphics := TGPGraphics.Create(GetDC(0));
  if (FGraphics.GetLastStatus <> Ok) then
  begin
    raise EDXRendererException.CreateRes(@SGDIPGraphicsCreateError);
  end;
  FGraphics.SetPageUnit(UnitPixel);
  FBrush := TGPSolidBrush.Create(MakeColor(255, 255, 255, 255));
  if (FBrush.GetLastStatus <> Ok) then
  begin
    raise EDXRendererException.CreateRes(@SGDIPBrushCreateError);
  end;
  FFormat := TGPStringFormat.GenericTypographic.Clone;
  if (FFormat.GetLastStatus <> Ok) then
  begin
    raise EDXRendererException.CreateRes(@SGDIPStringFormatCreateError);
  end;
  UpdateFont;
end;

function TDXFont.CreateFontTexture(R: TRect; const Text: String; Alignment: TDXTextAlignment;
  VerticalAlignment: TDXTextVerticalAlignment; WordWrap: Boolean): TDXTexture;

function GetCacheKey(R: TRect; const Text: String; Alignment: TDXTextAlignment;
  VerticalAlignment: TDXTextVerticalAlignment; WordWrap: Boolean): String; inline;
var
  S: AnsiString;
begin
  S := '                    ';
  CopyMemory(@S[1], @R, 16);
  S[17] := AnsiChar(Alignment);
  S[18] := AnsiChar(VerticalAlignment);
  S[19] := AnsiChar(WordWrap);
  {$WARNINGS OFF}
  Result := Text + S;
  {$WARNINGS ON}
end;

var
  CacheKey: String;
  Bitmap: TGPBitmap;
  Graphics: TGPGraphics;
  LayoutRect: TGPRectF;
begin
  Result := nil;
  CacheKey := GetCacheKey(R, Text, Alignment, VerticalAlignment, WordWrap);
  if (FCached) then
  begin
    if FCacheItems.TryGetValue(CacheKey, Result) then Exit;
  end;
  case FCached of
    false: Result := FTexture;
    true : Result := Manager.RenderInterface.CreateTexture;
  end;
  Bitmap := TGPBitmap.Create(R.Width, R.Height, PixelFormat32bppARGB);
  try
    if (Bitmap.GetLastStatus <> Ok) then
    begin
      raise EDXRendererException.CreateRes(@SGDIPBitmapCreateError);
    end;
    Graphics := TGPGraphics.Create(Bitmap);
    try
      if (Graphics.GetLastStatus <> Ok) then
      begin
        raise EDXRendererException.CreateRes(@SGDIPGraphicsCreateError);
      end;
      FFormat.SetAlignment(TranslateAlignment(Alignment));
      FFormat.SetLineAlignment(TranslateVerticalAlignment(VerticalAlignment));
      case WordWrap of
        false: FFormat.SetFormatFlags(StringFormatFlagsNoWrap);
        true : FFormat.SetFormatFlags(0);
      end;
      case FAntiAliased of
        false: Graphics.SetTextRenderingHint(TextRenderingHintSingleBitPerPixelGridFit);
        true : Graphics.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);
      end;
      Graphics.SetPageUnit(UnitPixel);
      LayoutRect.X := 0;
      LayoutRect.Y := 0;
      LayoutRect.Width := R.Width;
      LayoutRect.Height := R.Height;
      if (Graphics.DrawString(Text, Length(Text), FFont, LayoutRect, FFormat, FBrush) <> Ok) then
      begin
        raise EDXRendererException.CreateRes(@SGDIPDrawStringError);
      end;
      Result.LoadFromBitmap(Bitmap);
    finally
      Graphics.Free;
    end;
  finally
    Bitmap.Free;
  end;
  if (FCached) then
  begin
    FCacheKeys.Add(CacheKey);
    while (FCacheKeys.Count > FCacheSize) do
    begin
      FCacheItems.Remove(FCacheKeys[0]);
      FCacheKeys.Delete(0);
    end;
    FCacheItems.Add(CacheKey, Result);
  end;
end;

destructor TDXFont.Destroy;
begin
  FTexture.Free;
  FCacheItems.Free;
  FCacheKeys.Free;
  FGraphics.Free;
  FBrush.Free;
  FFormat.Free;
  if Assigned(FFont) then
  begin
    FFont.Free;
  end;
  inherited;
end;

procedure TDXFont.DrawText(X, Y: Integer; const Text: String; const Color: TDXColor;
  const Alignment: TDXTextAlignment; const VerticalAlignment: TDXTextVerticalAlignment;
  const WordWrap: Boolean);
var
  R: TRect;
begin
  R := CalculateTextRect(Text, Alignment, VerticalAlignment, WordWrap);
  DrawText(X, Y, R.Width, R.Height, Text, Color, Alignment, VerticalAlignment, WordWrap);
end;

procedure TDXFont.DrawText(R: TRect; const Text: String; const Color: TDXColor;
  const Alignment: TDXTextAlignment; const VerticalAlignment: TDXTextVerticalAlignment;
  const WordWrap: Boolean);
var
  Texture: TDXTexture;
begin
  Texture := CreateFontTexture(R, Text, Alignment, VerticalAlignment, WordWrap);
  Manager.RenderInterface.Renderer.DrawTexture(Texture, R, Color);
end;

procedure TDXFont.DrawText(X, Y, Width, Height: Integer; const Text: String; const Color: TDXColor;
  const Alignment: TDXTextAlignment; const VerticalAlignment: TDXTextVerticalAlignment;
  const WordWrap: Boolean);
begin
  DrawText(Rect(X, Y, X + Width, Y + Height), Text, Color, Alignment, VerticalAlignment, WordWrap);
end;

function TDXFont.GetTextHeight(R: TRect; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin
  Result := CalculateTextRect(R, Text, Alignment, VerticalAlignment, WordWrap).Height;
end;

function TDXFont.GetTextHeight(const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin
  Result := CalculateTextRect(Text, Alignment, VerticalAlignment, WordWrap).Height;
end;

function TDXFont.GetTextWidth(const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin
  Result := CalculateTextRect(Text, Alignment, VerticalAlignment, WordWrap).Width;
end;

function TDXFont.GetTextWidth(R: TRect; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin
  Result := CalculateTextRect(R, Text, Alignment, VerticalAlignment, WordWrap).Width;
end;

procedure TDXFont.SetAntiAliased(const Value: Boolean);
begin
  FAntiAliased := Value;
  if (FCached) then
  begin
    FCacheKeys.Clear;
    FCacheItems.Clear;
  end;
  SendChangeNotifications;
end;

procedure TDXFont.SetCached(const Value: Boolean);
begin
  if (FCached <> Value) then
  begin
    FCached := Value;
    FCacheItems.Clear;
    FCacheKeys.Clear;
  end;
end;

procedure TDXFont.SetCacheSize(const Value: TDXFontCacheSize);
begin
  if (FCacheSize <> Value) then
  begin
    FCacheSize := Value;
    if (FCached) then
    begin
      while (FCacheKeys.Count > FCacheSize) do
      begin
        FCacheItems.Remove(FCacheKeys[0]);
        FCacheKeys.Delete(0);
      end;
    end;
  end;
end;

procedure TDXFont.SetCharset(const Value: TDXFontCharset);
begin
  if (FCharset <> Value) then
  begin
    FCharset := Value;
    UpdateFont;
  end;
end;

procedure TDXFont.SetFamily(const Value: TDXFontName);
begin
  if (FFamily <> Value) then
  begin
    FFamily := Value;
    UpdateFont;
  end;
end;

procedure TDXFont.SetPitch(const Value: TDXFontPitch);
begin
  if (FPitch <> Value) then
  begin
    FPitch := Value;
    UpdateFont;
  end;
end;

procedure TDXFont.SetSize(const Value: Integer);
begin
  if (FSize <> Value) then
  begin
    FSize := Value;
    UpdateFont;
  end;
end;

procedure TDXFont.SetStyle(const Value: TDXFontStyles);
begin
  if (FStyle <> Value) then
  begin
    FStyle := Value;
    UpdateFont;
  end;
end;

function TDXFont.TranslateAlignment(Value: TDXTextAlignment): StringAlignment;
begin
  Result := StringAlignmentNear;
  case Value of
    alCenter: Result := StringAlignmentCenter;
    alRight : Result := StringAlignmentFar;
  end;
end;

function TDXFont.TranslateVerticalAlignment(Value: TDXTextVerticalAlignment): StringAlignment;
begin
  Result := StringAlignmentNear;
  case Value of
    vaCenter: Result := StringAlignmentCenter;
    vaBottom: Result := StringAlignmentFar;
  end;
end;

procedure TDXFont.UpdateFont;
var
  LF: LOGFONT;
  Font: TGPFont;
  DeviceContext: HDC;
  FontHandle: HFONT;
begin
  FillChar(LF, SizeOf(LF), #0);
  LF.lfHeight := -MulDiv(FSize, GetDeviceCaps(GetDC(0), LOGPIXELSY), 72);
  LF.lfWidth := 0;
  LF.lfEscapement := 0;
  LF.lfWeight := FW_NORMAL;
  if fsBold in FStyle then
  begin
    LF.lfWeight := FW_BOLD
  end;
  LF.lfItalic := Byte(fsItalic in FStyle);
  LF.lfUnderline := Byte(fsUnderline in FStyle);
  LF.lfStrikeOut := Byte(fsStrikeOut in FStyle);
  LF.lfCharSet := FCharset;
  LF.lfOutPrecision := OUT_DEFAULT_PRECIS;
  LF.lfClipPrecision := CLIP_DEFAULT_PRECIS;
  LF.lfQuality := DEFAULT_QUALITY;
  LF.lfPitchAndFamily := FF_DONTCARE;
  case FPitch of
    fpDefault : LF.lfPitchAndFamily := LF.lfPitchAndFamily or DEFAULT_PITCH;
    fpVariable: LF.lfPitchAndFamily := LF.lfPitchAndFamily or VARIABLE_PITCH;
    fpFixed   : LF.lfPitchAndFamily := LF.lfPitchAndFamily or FIXED_PITCH;
  end;
  if (Length(FFamily) - 1 > Length(LF.lfFaceName)) then
  begin
    raise EDXInvalidArgumentException.CreateRes(@SFontNameTooLongException);
  end;
  CopyMemory(@LF.lfFaceName[0], @FFamily[1], Length(FFamily) * SizeOf(FFamily[1]));
  Font := TGPFont.Create(GetDC(0), PLogFontW(@LF));
  if (Font.GetLastStatus <> Ok) then
  begin
    raise EDXRendererException.CreateRes(@SGDIPCreateFontError);
  end;
  if Assigned(FFont) then
  begin
    FFont.Free;
  end;
  FFont := Font;

  //
  DeviceContext := CreateCompatibleDC(GetDC(0));
  if (DeviceContext = 0) then
  begin
    raise EDXGUIFrameworkException.Create('Could not create GDI device context.');
  end;
  FontHandle := CreateFontIndirect(LF);
  if (FontHandle = 0) then
  begin
    DeleteDC(DeviceContext);
    raise EDXGUIFrameworkException.Create('Could not create GDI font object.');
  end;
  if (SelectObject(DeviceContext, FontHandle) = 0) then
  begin
    DeleteObject(FontHandle);
    DeleteDC(DeviceContext);
    raise EDXGUIFrameworkException.Create('Could not select GDI font object.');
  end;
  if (FFontHandle > 0) then
  begin
    DeleteObject(FontHandle);
  end;
  if (FDeviceContext > 0) then
  begin
    DeleteDC(FDeviceContext);
  end;
  FDeviceContext := DeviceContext;
  FFontHandle := FontHandle;
  //

  if (FCached) then
  begin
    FCacheKeys.Clear;
    FCacheItems.Clear;
  end;
  SendChangeNotifications;
end;

end.
