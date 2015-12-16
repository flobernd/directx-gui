unit DXGUIFont_new;

interface

uses
  Winapi.Windows, System.Classes, Generics.Collections, DXGUIFramework, DXGUIRenderInterface,
  DXGUITypes;

type
  TDXFontCharset = 0..255;
  TDXFontPitch   = (fpDefault, fpVariable, fpFixed);
  TDXFontStyle   = (fsBold, fsItalic, fsUnderline, fsStrikeOut);
  TDXFontStyles  = set of TDXFontStyle;
  TDXFontName    = type String;

  TDXTextAlignment         = (alLeft, alCenter, alRight);
  TDXTextVerticalAlignment = (vaTop, vaCenter, vaBottom);

type
  TDXFont = class(TDXPersistent)
  private
    FFamily: TDXFontName;
    FCharset: TDXFontCharset;
    FPitch: TDXFontPitch;
    FSize: Integer;
    FStyle: TDXFontStyles;
    FClearType: Boolean;
    FColor: TDXColor;
    FDeviceContext: HDC;
    FFontHandle: HFONT;
  private
    procedure SetFamily(const Value: TDXFontName);
    procedure SetCharset(const Value: TDXFontCharset);
    procedure SetPitch(const Value: TDXFontPitch);
    procedure SetClearType(const Value: Boolean);
    procedure SetSize(const Value: Integer);
    procedure SetStyle(const Value: TDXFontStyles);
    procedure SetColor(const Value: TDXColor);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  protected
    procedure UpdateFont;
  public
    procedure DrawText(X, Y: Integer; const Text: String;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
    procedure DrawText(X, Y, Width, Height: Integer; const Text: String;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
    procedure DrawText(R: TRect; const Text: String;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
    procedure DrawText(X, Y: Integer; const Text: String; Color: TDXColor;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
    procedure DrawText(X, Y, Width, Height: Integer; const Text: String; Color: TDXColor;
      const Alignment: TDXTextAlignment = alLeft;
      const VerticalAlignment: TDXTextVerticalAlignment = vaTop;
      const WordWrap: Boolean = false); overload;
    procedure DrawText(R: TRect; const Text: String; Color: TDXColor;
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
    property ClearType: Boolean read FClearType write SetClearType default true;
    property Color: TDXColor  read FColor write SetColor default clBlack;
  end;

implementation

uses
  System.Types, DXGUIExceptions;


{ TDXFont }

procedure TDXFont.AssignTo(Dest: TPersistent);
begin
  //inherited;

end;

function TDXFont.CalculateTextRect(R: TRect; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): TRect;
begin

end;

function TDXFont.CalculateTextRect(const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): TRect;
begin

end;

constructor TDXFont.Create(Manager: TDXGUIManager);
begin
  inherited Create(Manager);

end;

destructor TDXFont.Destroy;
begin

  inherited;
end;

procedure TDXFont.DrawText(X, Y, Width, Height: Integer; const Text: String;
  const Alignment: TDXTextAlignment; const VerticalAlignment: TDXTextVerticalAlignment;
  const WordWrap: Boolean);
begin

end;

procedure TDXFont.DrawText(R: TRect; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean);
begin

end;

procedure TDXFont.DrawText(X, Y: Integer; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean);
begin

end;

function TDXFont.GetTextHeight(R: TRect; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin

end;

function TDXFont.GetTextHeight(const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin

end;

function TDXFont.GetTextWidth(const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin

end;

function TDXFont.GetTextWidth(R: TRect; const Text: String; const Alignment: TDXTextAlignment;
  const VerticalAlignment: TDXTextVerticalAlignment; const WordWrap: Boolean): Integer;
begin

end;

procedure TDXFont.SetCharset(const Value: TDXFontCharset);
begin
  if (FCharset <> Value) then
  begin
    FCharset := Value;
    UpdateFont;
  end;
end;

procedure TDXFont.SetClearType(const Value: Boolean);
begin
  if (FClearType <> Value) then
  begin
    FClearType := Value;
    UpdateFont;
  end;
end;

procedure TDXFont.SetColor(const Value: TDXColor);
begin
  if (FColor <> Value) then
  begin
    FColor := Value;
    SendChangeNotifications;
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

procedure TDXFont.UpdateFont;
begin

  SendChangeNotifications;
end;

procedure TDXFont.DrawText(X, Y: Integer; const Text: String; Color: TDXColor;
  const Alignment: TDXTextAlignment; const VerticalAlignment: TDXTextVerticalAlignment;
  const WordWrap: Boolean);
begin

end;

procedure TDXFont.DrawText(X, Y, Width, Height: Integer; const Text: String; Color: TDXColor;
  const Alignment: TDXTextAlignment; const VerticalAlignment: TDXTextVerticalAlignment;
  const WordWrap: Boolean);
begin

end;

procedure TDXFont.DrawText(R: TRect; const Text: String; Color: TDXColor;
  const Alignment: TDXTextAlignment; const VerticalAlignment: TDXTextVerticalAlignment;
  const WordWrap: Boolean);
begin

end;

end.
