unit DXGUIProgressBar;

interface

uses
  Winapi.Windows, Winapi.Messages, DXGUIFramework, DXGUIRenderInterface, DXGUITypes,
  DXGUIAnimations;

const
  CM_PROGRESSBAR                  = WM_USER        + $1168;
  CM_PROGRESSBAR_MIN_CHANGED      = CM_PROGRESSBAR + $0001;
  CM_PROGRESSBAR_MAX_CHANGED      = CM_PROGRESSBAR + $0002;
  CM_PROGRESSBAR_POSITION_CHANGED = CM_PROGRESSBAR + $0003;

type
  TCMProgressBarMinChanged = TCMSimpleMessage;
  TCMProgressBarMaxChanged = TCMSimpleMessage;
  TCMProgressBarPositionChanged = TCMSimpleMessage;

type
  TDXCustomProgressBar = class(TDXControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
  private
    FOnChanged: TDXNotifyEvent;
  private
    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetPosition(const Value: Integer);
  protected
    procedure CMMinChanged(var Message: TCMProgressBarMinChanged);
      message CM_PROGRESSBAR_MIN_CHANGED;
    procedure CMMaxChanged(var Message: TCMProgressBarMaxChanged);
      message CM_PROGRESSBAR_MAX_CHANGED;
    procedure CMProgressbarChanged(var Message: TCMProgressBarPositionChanged);
      message CM_PROGRESSBAR_POSITION_CHANGED;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Constraints;
    property Margins;
    property Min: Integer read FMin write SetMin default 1;
    property Max: Integer read FMax write SetMax default 100;
    property Position: Integer read FPosition write SetPosition default 0;
  published
    property OnChanged: TDXNotifyEvent read FOnChanged write FOnChanged;
  end;

  TDXProgressBar = class(TDXCustomProgressBar)
  private
    FColor: TDXColor;
    FAnimation: TDXSimpleAnimation;
    FPositionStart: Double;
    FPositionDelta: Double;
    FPositionCurrent: Double;
  private
    procedure SetColor(const Value: TDXColor);
  private
    procedure UpdatePosition;
  protected
    procedure CMMinChanged(var Message: TCMProgressBarMinChanged); override;
    procedure CMMaxChanged(var Message: TCMProgressBarMaxChanged); override;
    procedure CMProgressbarChanged(var Message: TCMProgressBarPositionChanged); override;
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Color: TDXColor read FColor write SetColor default clWhite;
  end;

implementation

uses
  System.Classes;

{ TDXCustomProgressBar }

procedure TDXCustomProgressBar.CMMaxChanged(var Message: TCMProgressBarMaxChanged);
begin

end;

procedure TDXCustomProgressBar.CMMinChanged(var Message: TCMProgressBarMinChanged);
begin

end;

procedure TDXCustomProgressBar.CMProgressbarChanged(var Message: TCMProgressBarPositionChanged);
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

constructor TDXCustomProgressBar.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  Exclude(FControlStyle, csAcceptChildControls);
  Height := 20;
  Width := 150;
  FMin := 1;
  FMax := 100;
  FPosition := 0;
end;

destructor TDXCustomProgressBar.Destroy;
begin

  inherited;
end;

procedure TDXCustomProgressBar.SetMax(const Value: Integer);
var
  Message: TCMProgressBarMaxChanged;
begin
  if (FMax <> Value) and (Value >= FMin) then
  begin
    FMax := Value;
    Message.MessageId := CM_PROGRESSBAR_MAX_CHANGED;
    Self.Dispatch(Message);
    if (FPosition > FMax) then SetPosition(FMax);
  end;
end;

procedure TDXCustomProgressBar.SetMin(const Value: Integer);
var
  Message: TCMProgressBarMinChanged;
begin
  if (FMin <> Value) and (Value <= FMax) then
  begin
    FMin := Value;
    Message.MessageId := CM_PROGRESSBAR_MIN_CHANGED;
    Self.Dispatch(Message);
    if (FPosition < FMin) then SetPosition(FMin);
  end;
end;

procedure TDXCustomProgressBar.SetPosition(const Value: Integer);
var
  Message: TCMProgressBarPositionChanged;
  AValue: Integer;
begin
  AValue := Value;
  if (Value < (FMin - 1)) then AValue := (FMin - 1);
  if (Value > FMax) then AValue := FMax;
  if (FPosition <> AValue) then
  begin
    FPosition := AValue;
    Message.MessageId := CM_PROGRESSBAR_POSITION_CHANGED;
    Self.Dispatch(Message);
  end;
end;

{ TDXProgressBar }

procedure TDXProgressBar.CMMaxChanged(var Message: TCMProgressBarMaxChanged);
begin
  inherited;
  UpdatePosition;
end;

procedure TDXProgressBar.CMMinChanged(var Message: TCMProgressBarMinChanged);
begin
  inherited;
  UpdatePosition;
end;

procedure TDXProgressBar.CMProgressbarChanged(var Message: TCMProgressBarPositionChanged);
begin
  inherited;
  UpdatePosition;
end;

constructor TDXProgressBar.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FInvalidateEvents := FInvalidateEvents + [ieEnabledChanged];
  FColor := DXCOLOR_RGBA(6, 176, 37, 255);
  FAnimation := TDXSimpleAnimation.Create;
end;

destructor TDXProgressBar.Destroy;
begin
  FAnimation.Free;
  inherited;
end;

procedure TDXProgressBar.Paint(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
begin
  Renderer := Manager.RenderInterface.Renderer;
  Renderer.FillRect(BoundsRect, DXCOLOR_RGBA(230, 230, 230, 255));
  Renderer.DrawRect(BoundsRect, DXCOLOR_RGBA(188, 188, 188, 255));
  BoundsRect.Top    := BoundsRect.Top    + 1;
  BoundsRect.Left   := BoundsRect.Left   + 1;
  BoundsRect.Bottom := BoundsRect.Bottom - 1;
  BoundsRect.Right  := BoundsRect.Right  - 1;
  BoundsRect.Right  := BoundsRect.Left + Round(FPositionCurrent * BoundsRect.Width);
  Renderer.FillRect(BoundsRect, FColor);
  if (FAnimation.Running) then
  begin
    FAnimation.Update;
    FPositionCurrent := FAnimation.CurrentEasingValue * FPositionDelta + FPositionStart;
    Invalidate;
  end;
end;

procedure TDXProgressBar.SetColor(const Value: TDXColor);
begin
  if (FColor <> Value) then
  begin
    FColor := Value;
    Invalidate;
  end;
end;

procedure TDXProgressBar.UpdatePosition;
begin
  if (FAnimation.Running) then FAnimation.Cancel;
  FPositionStart := FPositionCurrent;
  FPositionDelta := (FPosition - FMin + 1) / (FMax - FMin + 1) - FPositionStart;
  FAnimation.Start(500, TDXOutQuadEasingCurve.Create);
  Invalidate;
end;

initialization
  RegisterClass(TDXProgressBar);

end.
