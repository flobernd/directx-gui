unit DXGUILabel;

interface

uses DXGUIFramework, DXGUITextControl, Winapi.Windows, DXGUITypes, DXGUIFont;

type
  TDXCustomLabel = class(TDXCustomTextControl)
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
  published
    property Align;
    property AlignWithMargins;
    property AutoSize;
    property Anchors;
    property Constraints;
    property Margins;
  end;

  TDXLabel = class(TDXCustomLabel)
  private
    FColor: TDXColor;
    FAlignment: TDXTextAlignment;
    FVerticalAlignment: TDXTextVerticalAlignment;
    FWordWrap: Boolean;
  private
    procedure SetColor(const Value: TDXColor);
    procedure SetAlignment(const Value: TDXTextAlignment);
    procedure SetVerticalAlignment(const Value: TDXTextVerticalAlignment);
    procedure SetWordWrap(const Value: Boolean);
  protected
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
  protected
    function CalculateClientRect(const ABoundsRect: TRect): TRect; override;
  protected
    procedure CMFontChanged(var Message: TCMTextControlFontChanged); override;
    procedure CMCaptionChanged(var Message: TCMTextControlCaptionChanged); override;
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
  published
    property Caption;
    property Font;
    property ParentFont;
    property AutoSize;
    property Color: TDXColor read FColor write SetColor default clWhite;
    property Alignment: TDXTextAlignment read FAlignment write SetAlignment default alLeft;
    property VerticalAlignment: TDXTextVerticalAlignment read FVerticalAlignment
      write SetVerticalAlignment default vaTop;
    property WordWrap: Boolean read FWordWrap write SetWordWrap default false;
  end;

implementation

uses
  System.Classes;

{ TDXCustomLabel }

constructor TDXCustomLabel.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  Exclude(FControlStyle, csAcceptChildControls);
end;

{ TDXLabel }

function TDXLabel.CalculateClientRect(const ABoundsRect: TRect): TRect;
begin
  Result :=
    Rect(ABoundsRect.Left + 2, ABoundsRect.Top + 2, ABoundsRect.Right - 2, ABoundsRect.Bottom - 2);
end;

function TDXLabel.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  TextRect: TRect;
begin
  Result := true;
  if WordWrap then
  begin
    TextRect :=
      Font.CalculateTextRect(Rect(0, 0, ClientRect.Width, 0), Caption, FAlignment,
      FVerticalAlignment, true);
  end else
  begin
    TextRect := Font.CalculateTextRect(Caption, FAlignment, FVerticalAlignment, false);
  end;
  NewWidth := TextRect.Width + 4 + BoundsRect.Width - ClientRect.Width;
  NewHeight := TextRect.Height + 2 + BoundsRect.Height - ClientRect.Height;
end;

procedure TDXLabel.CMCaptionChanged(var Message: TCMTextControlCaptionChanged);
begin
  inherited;
  if (AutoSize) then SetBounds(Left, Top, Width, Height);
  Invalidate;
end;

procedure TDXLabel.CMFontChanged(var Message: TCMTextControlFontChanged);
begin
  inherited;
  if (AutoSize) then SetBounds(Left, Top, Width, Height);
  Invalidate
end;

constructor TDXLabel.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FColor := clWhite;
  FAlignment := alLeft;
  FVerticalAlignment := vaTop;
  AutoSize := true;
end;

procedure TDXLabel.Paint(BoundsRect, ClientRect: TRect);
begin
  Font.DrawText(ClientRect, Caption, FColor, FAlignment, FVerticalAlignment, FWordWrap);
end;

procedure TDXLabel.SetAlignment(const Value: TDXTextAlignment);
begin
  if (FAlignment <> Value) then
  begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TDXLabel.SetColor(const Value: TDXColor);
begin
  if (FColor <> Value) then
  begin
    FColor := Value;
    Invalidate;
  end;
end;

procedure TDXLabel.SetVerticalAlignment(const Value: TDXTextVerticalAlignment);
begin
  if (FVerticalAlignment <> Value) then
  begin
    FVerticalAlignment := Value;
    Invalidate;
  end;
end;

procedure TDXLabel.SetWordWrap(const Value: Boolean);
begin
  if (FWordWrap <> Value) then
  begin
    FWordWrap := Value;
    Invalidate;
  end;
end;

end.
