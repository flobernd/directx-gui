unit DXGUITrackBar;

interface

uses
  Winapi.Windows, Winapi.Messages, DXGUIFramework, DXGUIRenderInterface, DXGUITypes;

const
  CM_TRACKBAR                   = WM_USER     + $9822;
  CM_TRACKBAR_MIN_CHANGED      = CM_TRACKBAR + $0001;
  CM_TRACKBAR_MAX_CHANGED      = CM_TRACKBAR + $0002;
  CM_TRACKBAR_POSITION_CHANGED = CM_TRACKBAR + $0003;

type
  TCMTrackBarMinChanged = TCMSimpleMessage;
  TCMTrackBarMaxChanged = TCMSimpleMessage;
  TCMTrackBarPositionChanged = TCMSimpleMessage;

type
  TDXCustomTrackBar = class(TDXControl)
  private
    FMin: Integer;
    FMax: Integer;
    FPosition: Integer;
    FWheelDelta: Integer;
  private
    FOnChanged: TDXNotifyEvent;
  private
    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetPosition(const Value: Integer);
  protected
    procedure CMMinChanged(var Message: TCMTrackBarMinChanged); message CM_TRACKBAR_MIN_CHANGED;
    procedure CMMaxChanged(var Message: TCMTrackBarMaxChanged); message CM_TRACKBAR_MAX_CHANGED;
    procedure CMTrackBarPositionChanged(var Message: TCMTrackBarPositionChanged);
      message CM_TRACKBAR_POSITION_CHANGED;
    procedure CMMouseWheelUp(var Message: TCMMouseWheelUp); override;
    procedure CMMouseWheelDown(var Message: TCMMouseWheelDown); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Constraints;
    property Margins;
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 10;
    property Position: Integer read FPosition write SetPosition default 0;
  published
    property OnChanged: TDXNotifyEvent read FOnChanged write FOnChanged;
  end;

  TDXTrackBarOrientation = (trHorizontal, trVertical);
  TDXTrackBarTickMarkPosition = (tmBottomRight, tmTopLeft, tmBoth);
  TDXTrackBarTickMarkFrequency = 1..MAXDWORD - 1;

  TDXTrackBar = class(TDXCustomTrackBar)
  private
    FOrientation: TDXTrackBarOrientation;
    FTickMarkPosition: TDXTrackBarTickMarkPosition;
    FTickMarksVisible: Boolean;
    FFrequency: TDXTrackBarTickMarkFrequency;
    FSliderVisible: Boolean;
    FThumbLength: Byte;
    FSliderLength: Byte;
    FDragActive: Boolean;
  private
    procedure SetFrequency(const Value: TDXTrackBarTickMarkFrequency);
    procedure SetOrientation(const Value: TDXTrackBarOrientation);
    procedure SetSliderVisible(const Value: Boolean);
    procedure SetThumbLength(const Value: Byte);
    procedure SetTickMarkPosition(const Value: TDXTrackBarTickMarkPosition);
    procedure SetTickMarksVisible(const Value: Boolean);
  private
    procedure PaintHorizontal(BoundsRect, ClientRect: TRect);
    procedure PaintVertical(BoundsRect, ClientRect: TRect);
  protected
    procedure CMLButtonDown(var Message: TCMLButtonDown); override;
    procedure CMLButtonUp(var Message: TCMLButtonUp); override;
    procedure CMMouseMove(var Message: TCMMouseMove); override;
    procedure CMMinChanged(var Message: TCMTrackBarMinChanged); override;
    procedure CMMaxChanged(var Message: TCMTrackBarMaxChanged); override;
    procedure CMTrackBarPositionChanged(var Message: TCMTrackBarPositionChanged); override;
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Orientation: TDXTrackBarOrientation read FOrientation write SetOrientation
      default trHorizontal;
    property TickMarkPosition: TDXTrackBarTickMarkPosition read FTickMarkPosition write
      SetTickMarkPosition default tmBottomRight;
    property TickMarksVisible: Boolean read FTickMarksVisible write SetTickMarksVisible
      default true;
    property Frequency: TDXTrackBarTickMarkFrequency read FFrequency write SetFrequency default 1;
    property SliderVisible: Boolean read FSliderVisible write SetSliderVisible default true;
    property ThumbLength: Byte read FThumbLength write SetThumbLength default 20;
  end;

implementation

uses
  System.Classes, DXGUIFont;

{ TDXCustomTrackBar }

procedure TDXCustomTrackBar.CMMaxChanged(var Message: TCMTrackBarMaxChanged);
begin

end;

procedure TDXCustomTrackBar.CMMinChanged(var Message: TCMTrackBarMinChanged);
begin

end;

procedure TDXCustomTrackBar.CMMouseWheelDown(var Message: TCMMouseWheelDown);
var
  T: Integer;
begin
  inherited;
  Dec(FWheelDelta, Message.Amount);
  T := FPosition - (FWheelDelta div WHEEL_DELTA);
  FWheelDelta := FWheelDelta mod WHEEL_DELTA;
  SetPosition(T);
end;

procedure TDXCustomTrackBar.CMMouseWheelUp(var Message: TCMMouseWheelUp);
var
  T: Integer;
begin
  inherited;
  Inc(FWheelDelta, Message.Amount);
  T := FPosition - (FWheelDelta div WHEEL_DELTA);
  FWheelDelta := FWheelDelta mod WHEEL_DELTA;
  SetPosition(T);
end;

procedure TDXCustomTrackBar.CMTrackBarPositionChanged(var Message: TCMTrackBarPositionChanged);
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

constructor TDXCustomTrackBar.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  Exclude(FControlStyle, csAcceptChildControls);
  FMin := 0;
  FMax := 10;
  FPosition := 0;
end;

destructor TDXCustomTrackBar.Destroy;
begin

  inherited;
end;

procedure TDXCustomTrackBar.SetMax(const Value: Integer);
var
  Message: TCMTrackBarMaxChanged;
begin
  if (FMax <> Value) and (Value >= FMin) then
  begin
    FMax := Value;
    Message.MessageId := CM_TRACKBAR_MAX_CHANGED;
    Self.Dispatch(Message);
    if (FPosition > FMax) then SetPosition(FMax);
  end;
end;

procedure TDXCustomTrackBar.SetMin(const Value: Integer);
var
  Message: TCMTrackBarMinChanged;
begin
  if (FMin <> Value) and (Value <= FMax) then
  begin
    FMin := Value;
    Message.MessageId := CM_TRACKBAR_MIN_CHANGED;
    Self.Dispatch(Message);
    if (FPosition < FMin) then SetPosition(FMin);
  end;
end;

procedure TDXCustomTrackBar.SetPosition(const Value: Integer);
var
  Message: TCMTrackBarPositionChanged;
  AValue: Integer;
begin
  AValue := Value;
  if (Value < FMin) then AValue := FMin;
  if (Value > FMax) then AValue := FMax;
  if (FPosition <> AValue) then
  begin
    FPosition := AValue;
    Message.MessageId := CM_TRACKBAR_POSITION_CHANGED;
    Self.Dispatch(Message);
  end;
end;

{ TDXTrackBar }

procedure TDXTrackBar.CMLButtonDown(var Message: TCMLButtonDown);
begin
  inherited;
  if (AbsoluteEnabled) then
  begin
    FDragActive := true;
    case FOrientation of
      trHorizontal:
        SetPosition(Round((Message.Pos.X * (FMax - FMin)) /
          (ClientRect.Width - FSliderLength) + FMin));
      trVertical:
        SetPosition(Round((Message.Pos.Y * (FMax - FMin)) /
          (ClientRect.Height - FSliderLength) + FMin));
    end;
    Invalidate;
  end;
end;

procedure TDXTrackBar.CMLButtonUp(var Message: TCMLButtonUp);
begin
  inherited;
  FDragActive := false;
end;

procedure TDXTrackBar.CMMaxChanged(var Message: TCMTrackBarMaxChanged);
begin
  inherited;
  Invalidate;
end;

procedure TDXTrackBar.CMMinChanged(var Message: TCMTrackBarMinChanged);
begin
  inherited;
  Invalidate;
end;

procedure TDXTrackBar.CMMouseMove(var Message: TCMMouseMove);
begin
  inherited;
  if (AbsoluteEnabled) and (FDragActive) then
  begin
    case FOrientation of
      trHorizontal:
        SetPosition(Round((Message.Pos.X * (FMax - FMin)) /
          (ClientRect.Width - FSliderLength) + FMin));
      trVertical:
        SetPosition(Round((Message.Pos.Y * (FMax - FMin)) /
          (ClientRect.Height - FSliderLength) + FMin));
    end;
    Invalidate;
  end;
end;

procedure TDXTrackBar.CMTrackBarPositionChanged(var Message: TCMTrackBarPositionChanged);
begin
  inherited;
  Invalidate;
end;

constructor TDXTrackBar.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FInvalidateEvents :=
    FInvalidateEvents + [ieEnabledChanged, iePressedChanged, ieMouseFocusChanged];
  FOrientation := trHorizontal;
  FTickMarkPosition := tmBottomRight;
  FTickMarksVisible := true;
  FFrequency := 1;
  FSliderVisible := true;
  FThumbLength := 20;
  FSliderLength := 15;
end;

destructor TDXTrackBar.Destroy;
begin

  inherited;
end;

procedure TDXTrackBar.Paint(BoundsRect, ClientRect: TRect);
begin
  case FOrientation of
    trHorizontal:
      PaintHorizontal(BoundsRect, ClientRect);
    trVertical:
      PaintVertical(BoundsRect, ClientRect);
  end;
end;

procedure TDXTrackBar.PaintHorizontal(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
  R: TRect;
  SliderPos: Integer;
  I: Integer;
begin
  Renderer := Manager.RenderInterface.Renderer;
  // INFO: Draw Slider Bar
  R := Rect(ClientRect.Left,
    ClientRect.Top + Round(ClientRect.Height / 2 - FThumbLength / 2), ClientRect.Width, 0);
  R.Height := FThumbLength;
  Renderer.DrawRect(R, DXCOLOR_RGBA(127, 127, 127, 255));
  // INFO: Draw Slider Button
  if (FSliderVisible) then
  begin
    SliderPos :=
      Round(((FPosition - FMin) / (FMax - FMin)) * (ClientRect.Width - FSliderLength));
    R := Rect(ClientRect.Left + SliderPos + 1,
      ClientRect.Top + Round(ClientRect.Height / 2 - FThumbLength / 2) + 1, 0, 0);
    R.Width := FSliderLength - 2;
    R.Height := FThumbLength - 2;
    Renderer.FillRect(R, DXCOLOR_RGBA(64, 64, 64, 255));
    Renderer.DrawRect(R, DXCOLOR_RGBA(255, 0, 200, 200));
  end;
  // INFO: Draw Ticks
  if (FTickMarksVisible) then
  begin
    for I := FMin to FMax do
    begin
      {$WARNINGS OFF}
      if ((I mod FFrequency) > 0) and (I <> FMin) and (I <> FMax) then Continue;
      {$WARNINGS ON}
      SliderPos := Round(((I - FMin) / (FMax - FMin)) * (ClientRect.Width - FSliderLength));
      if (FTickMarkPosition = tmBottomRight) or (FTickMarkPosition = tmBoth) then
      begin
        R := Rect(
          Round(ClientRect.Left + SliderPos + FSliderLength / 2) - 1,
          ClientRect.Bottom - 5,
          Round(ClientRect.Left + SliderPos + FSliderLength / 2),
          ClientRect.Bottom);
        Renderer.DrawRect(R, DXCOLOR_RGBA(127, 127, 127, 255));
      end;
      if (FTickMarkPosition = tmTopLeft) or (FTickMarkPosition = tmBoth) then
      begin
        R := Rect(
          Round(ClientRect.Left + SliderPos + FSliderLength / 2) - 1,
          ClientRect.Top,
          Round(ClientRect.Left + SliderPos + FSliderLength / 2),
          ClientRect.Top + 5);
        Renderer.DrawRect(R, DXCOLOR_RGBA(127, 127, 127, 255));
      end;
    end;
  end;
end;

procedure TDXTrackBar.PaintVertical(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
  R: TRect;
  SliderPos: Integer;
  I: Integer;
begin
  Renderer := Manager.RenderInterface.Renderer;
  // INFO: Draw Slider Bar
  R := Rect(ClientRect.Left + Round(ClientRect.Width / 2 - FThumbLength / 2),
    ClientRect.Top, 0, ClientRect.Bottom);
  R.Width := FThumbLength;
  Renderer.DrawRect(R, DXCOLOR_RGBA(127, 127, 127, 255));
  // INFO: Draw Slider Button
  if (FSliderVisible) then
  begin
    SliderPos :=
      Round(((FPosition - FMin) / (FMax - FMin)) * (ClientRect.Height - FSliderLength));
    R := Rect(ClientRect.Left + Round(ClientRect.Width / 2 - FThumbLength / 2) + 1,
      ClientRect.Top + SliderPos + 1, 0, 0);
    R.Width := FThumbLength - 2;
    R.Height := FSliderLength - 2;
    Renderer.FillRect(R, DXCOLOR_RGBA(64, 64, 64, 255));
    Renderer.DrawRect(R, DXCOLOR_RGBA(255, 0, 200, 200));
  end;
  // INFO: Draw Ticks
  if (FTickMarksVisible) then
  begin
    for I := FMin to FMax do
    begin
      {$WARNINGS OFF}
      if ((I mod FFrequency) > 0) and (I <> FMin) and (I <> FMax) then Continue;
      {$WARNINGS ON}
      SliderPos := Round(((I - FMin) / (FMax - FMin)) * (ClientRect.Height - FSliderLength));
      if (FTickMarkPosition = tmBottomRight) or (FTickMarkPosition = tmBoth) then
      begin
        R := Rect(
          ClientRect.Right - 5,
          Round(ClientRect.Top + SliderPos + FSliderLength / 2) - 1,
          ClientRect.Right,
          Round(ClientRect.Top + SliderPos + FSliderLength / 2));
        Renderer.DrawRect(R, DXCOLOR_RGBA(127, 127, 127, 255));
      end;
      if (FTickMarkPosition = tmTopLeft) or (FTickMarkPosition = tmBoth) then
      begin
        R := Rect(
          ClientRect.Left,
          Round(ClientRect.Top + SliderPos + FSliderLength / 2) - 1,
          ClientRect.Left + 5,
          Round(ClientRect.Top + SliderPos + FSliderLength / 2));
        Renderer.DrawRect(R, DXCOLOR_RGBA(127, 127, 127, 255));
      end;
    end;
  end;
end;

procedure TDXTrackBar.SetFrequency(const Value: TDXTrackBarTickMarkFrequency);
begin
  if (FFrequency <> Value) then
  begin
    FFrequency := Value;
    Invalidate;
  end;
end;

procedure TDXTrackBar.SetOrientation(const Value: TDXTrackBarOrientation);
begin
  if (FOrientation <> Value) then
  begin
    FOrientation := Value;
    Invalidate;
  end;
end;

procedure TDXTrackBar.SetSliderVisible(const Value: Boolean);
begin
  if (FSliderVisible <> Value) then
  begin
    FSliderVisible := Value;
    Invalidate;
  end;
end;

procedure TDXTrackBar.SetThumbLength(const Value: Byte);
begin
  if (FThumbLength <> Value) then
  begin
    FThumbLength := Value;
    FSliderLength := Round(3 / 4 * Value);
    Invalidate;
  end;
end;

procedure TDXTrackBar.SetTickMarkPosition(const Value: TDXTrackBarTickMarkPosition);
begin
  if (FTickMarkPosition <> Value) then
  begin
    FTickMarkPosition := Value;
    Invalidate;
  end;
end;

procedure TDXTrackBar.SetTickMarksVisible(const Value: Boolean);
begin
  if (FTickMarksVisible <> Value) then
  begin
    FTickMarksVisible := Value;
    Invalidate;
  end;
end;

initialization
  RegisterClass(TDXTrackBar);

end.
