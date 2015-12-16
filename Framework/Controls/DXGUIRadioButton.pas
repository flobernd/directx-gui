unit DXGUIRadioButton;

interface

uses
  Winapi.Windows, Winapi.Messages, DXGUIFramework, DXGUIRenderInterface, DXGUITypes,
  DXGUITextControl, DXGUIAnimations;

const
  CM_RADIOBUTTON                    = WM_USER        + $3877;
  CM_RADIOBUTTON_CHECKSTATE_CHANGED = CM_RADIOBUTTON + $0001;

type
  TCMRadioButtonCheckstateChanged = TCMSimpleMessage;

type
  TDXCheckStateChangeEvent = procedure(Sender: TObject; NewCheckState: Boolean;
    var AllowChange: Boolean) of object;

type
  TDXCustomRadioButton = class(TDXCustomTextControl)
  private
    FChecked: Boolean;
  private
    FOnCheckStateChanging: TDXCheckStateChangeEvent;
    FOnCheckStateChanged: TDXNotifyEvent;
  private
    procedure SetChecked(const Value: Boolean);
  protected
    procedure CMMouseClick(var Message: TCMMouseClick); override;
    procedure CMCheckstateChanged(var Message: TCMRadioButtonCheckstateChanged);
      message CM_RADIOBUTTON_CHECKSTATE_CHANGED;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Align;
    property AlignWithMargins;
    property AutoSize;
    property Anchors;
    property Constraints;
    property Margins;
    property Font;
    property Caption;
    property ParentFont;
    property Checked: Boolean read FChecked write SetChecked;
  published
    property OnCheckStateChanging: TDXCheckStateChangeEvent read FOnCheckStateChanging write
      FOnCheckStateChanging;
    property OnCheckStateChanged: TDXNotifyEvent read FOnCheckStateChanged write
      FOnCheckStateChanged;
  end;

  TDXRadioButton = class(TDXCustomRadioButton)
  private type
    TDXRadioButtonFadeAnimation = class(TDXCustomAnimation)
    private type
      TDXRadioButtonFadeStyle = (fsNormal, fsMouseFocus, fsPressed);
    private
      FBorderColorNormal: TDXColor;
      FBorderColorMouseFocus: TDXColor;
      FBorderColorPressed: TDXColor;
      FInnerColorNormal: TDXColor;
      FInnerColorMouseFocus: TDXColor;
      FInnerColorPressed: TDXColor;
      FCheckmarkColorChecked: TDXColor;
      FCheckmarkColorMouseFocus: TDXColor;
      FRadioButton: TDXRadioButton;
      FBorderSA, FBorderSR, FBorderSG, FBorderSB: Byte;
      FBorderFA, FBorderFR, FBorderFG, FBorderFB: Byte;
      FInnerSA, FInnerSR, FInnerSG, FInnerSB: Byte;
      FInnerFA, FInnerFR, FInnerFG, FInnerFB: Byte;
      FCheckmarkSA, FCheckmarkSR, FCheckmarkSG, FCheckmarkSB: Byte;
      FCheckmarkFA, FCheckmarkFR, FCheckmarkFG, FCheckmarkFB: Byte;
    protected
      procedure UpdateAnimation(EasingValue: Single); override;
    public
      procedure Start(Duration: DWord; const EasingCurve: IDXEasingCurve = nil;
        RadioButton: TDXRadioButton = nil; TargetStyle: TDXRadioButtonFadeStyle = fsNormal);
    public
      property BorderColorNormal: TDXColor read FBorderColorNormal write FBorderColorNormal;
      property BorderColorMouseFocus: TDXColor read FBorderColorMouseFocus write
        FBorderColorMouseFocus;
      property BorderColorPressed: TDXColor read FBorderColorPressed write FBorderColorPressed;
      property InnerColorNormal: TDXColor read FInnerColorNormal write FInnerColorNormal;
      property InnerColorMouseFocus: TDXColor read FInnerColorMouseFocus write
        FInnerColorMouseFocus;
      property InnerColorPressed: TDXColor read FInnerColorPressed write FInnerColorPressed;
      property CheckmarkColorChecked: TDXColor read FCheckmarkColorChecked write
        FCheckmarkColorChecked;
      property CheckmarkColorMouseFocus: TDXColor read FCheckmarkColorMouseFocus write
        FCheckmarkColorMouseFocus;
    end;
  private
    FBorderColor: TDXColor;
    FInnerColor: TDXColor;
    FCheckmarkColor: TDXColor;
    FAnimation: TDXRadioButtonFadeAnimation;
  private
    procedure TriggerAnimation;
  protected
    procedure CMLButtonDown(var Message: TCMLButtonDown); override;
    procedure CMLButtonUp(var Message: TCMLButtonUp); override;
    procedure CMMouseEnter(var Message: TCMMouseEnter); override;
    procedure CMMouseLeave(var Message: TCMMouseLeave); override;
    procedure CMCheckstateChanged(var Message: TCMRadioButtonCheckstateChanged); override;
    procedure CMFontChanged(var Message: TCMTextControlFontChanged); override;
    procedure CMCaptionChanged(var Message: TCMTextControlCaptionChanged); override;
  protected
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager;AOwner: TDXComponent);
    destructor Destroy; override;
  end;

implementation

uses
  System.Classes, DXGUIFont;

{ TDXCustomRadioButton }

procedure TDXCustomRadioButton.CMCheckstateChanged(var Message: TCMRadioButtonCheckstateChanged);
begin
  if Assigned(FOnCheckStateChanged) then
  begin
    FOnCheckStateChanged(Self);
  end;
end;

procedure TDXCustomRadioButton.CMMouseClick(var Message: TCMMouseClick);
var
  AllowChange: Boolean;
begin
  inherited;
  if Assigned(FOnCheckStateChanging) then
  begin
    AllowChange := true;
    FOnCheckStateChanging(Self, not FChecked, AllowChange);
    if (not AllowChange) then Exit;
  end;
  SetChecked(not FChecked);
end;

constructor TDXCustomRadioButton.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  Exclude(FControlStyle, csAcceptChildControls);
  Height := 20;
  Width := 150;
end;

destructor TDXCustomRadioButton.Destroy;
begin

  inherited;
end;

procedure TDXCustomRadioButton.SetChecked(const Value: Boolean);
var
  I: Integer;
  C: TDXCustomRadioButton;
  Message: TCMRadioButtonCheckstateChanged;
begin
  if (Value) and (FChecked <> Value) then
  begin
    Message.MessageId := CM_RADIOBUTTON_CHECKSTATE_CHANGED;
    if Assigned(Parent) then
    begin
      for I := 0 to Parent.ControlCount - 1 do
      begin
        if (Parent.Controls[I] is TDXCustomRadioButton) then
        begin
          C := TDXCustomRadioButton(Parent.Controls[I]);
          C.FChecked := false;
          C.Dispatch(Message);
        end;
      end;
    end;
    FChecked := Value;
    Self.Dispatch(Message);
  end;
end;

{ TDXRadioButton }

function TDXRadioButton.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  TextRect: TRect;
begin
  Result := true;
  TextRect := Font.CalculateTextRect(Caption, alLeft, vaCenter, false);
  NewWidth := TextRect.Width + 4 + 22;
end;

procedure TDXRadioButton.CMCaptionChanged(var Message: TCMTextControlCaptionChanged);
begin
  inherited;
  if (AutoSize) then SetBounds(Left, Top, Width, Height);
  Invalidate
end;

procedure TDXRadioButton.CMCheckstateChanged(var Message: TCMRadioButtonCheckstateChanged);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXRadioButton.CMFontChanged(var Message: TCMTextControlFontChanged);
begin
  inherited;
  if (AutoSize) then SetBounds(Left, Top, Width, Height);
  Invalidate
end;

procedure TDXRadioButton.CMLButtonDown(var Message: TCMLButtonDown);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXRadioButton.CMLButtonUp(var Message: TCMLButtonUp);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXRadioButton.CMMouseEnter(var Message: TCMMouseEnter);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXRadioButton.CMMouseLeave(var Message: TCMMouseLeave);
begin
  inherited;
  TriggerAnimation;
end;

constructor TDXRadioButton.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FInvalidateEvents :=
    FInvalidateEvents + [ieEnabledChanged, iePressedChanged, ieMouseFocusChanged];
  FAnimation := TDXRadioButtonFadeAnimation.Create;
  FAnimation.BorderColorNormal := DXCOLOR_RGBA(112, 112, 112, 255);
  FAnimation.InnerColorNormal := DXCOLOR_RGBA(255, 255, 255, 255);
  FAnimation.BorderColorMouseFocus := DXCOLOR_RGBA(51, 153, 255, 255);
  FAnimation.InnerColorMouseFocus := DXCOLOR_RGBA(255, 255, 255, 255);
  FAnimation.BorderColorPressed := DXCOLOR_RGBA(0, 124, 229, 255);
  FAnimation.InnerColorPressed := DXCOLOR_RGBA(217, 236, 255, 255);
  FAnimation.CheckmarkColorChecked := DXCOLOR_RGBA(60, 60, 60, 255);
  FAnimation.CheckmarkColorMouseFocus := DXCOLOR_RGBA(127, 127, 127, 255);
  FBorderColor := FAnimation.BorderColorNormal;
  FInnerColor := FAnimation.InnerColorNormal;
  FCheckmarkColor := DXCOLOR_RGBA(127, 127, 127, 0)
end;

destructor TDXRadioButton.Destroy;
begin
  FAnimation.Free;
  inherited;
end;

procedure TDXRadioButton.Paint(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
  R: TRect;
begin
  Renderer := Manager.RenderInterface.Renderer;
  R := Rect(0, Round((Height / 2) - 9), 18, Round((Height / 2) + 9));
  Renderer.FillRect(R, FInnerColor);
  Renderer.DrawRect(R, FBorderColor);
  R.Inflate(-5, -5);
  Renderer.FillRect(R, FCheckmarkColor);
  BoundsRect.Left := BoundsRect.Left + 22;
  Font.DrawText(BoundsRect, Caption, DXCOLOR_RGBA(0, 0, 0, 255), alLeft, vaCenter);
  if (FAnimation.Running) then
  begin
    FAnimation.Update;
    Invalidate;
  end;
end;

procedure TDXRadioButton.TriggerAnimation;
var
  Duration: DWord;
  EasingCurve: IDXEasingCurve;
  TargetStyle: TDXRadioButtonFadeAnimation.TDXRadioButtonFadeStyle;
begin
  if (IsPressed) then
  begin
    Duration := 100;
    EasingCurve := TDXOutQuadEasingCurve.Create;
    TargetStyle := fsPressed;
  end else
  begin
    if (HasMouseFocus) then
    begin
      Duration := 200;
      EasingCurve := TDXOutQuadEasingCurve.Create;
      TargetStyle := fsMouseFocus;
    end else
    begin
      Duration := 200;
      EasingCurve := TDXOutQuadEasingCurve.Create;
      TargetStyle := fsNormal;
    end;
  end;
  if (FAnimation.Running) then FAnimation.Cancel;
  FAnimation.Start(Duration, EasingCurve, Self, TargetStyle);
  Invalidate;
end;

{ TDXRadioButton.TDXRadioButtonFadeAnimation }

procedure TDXRadioButton.TDXRadioButtonFadeAnimation.Start(Duration: DWord;
  const EasingCurve: IDXEasingCurve; RadioButton: TDXRadioButton;
  TargetStyle: TDXRadioButtonFadeStyle);
begin
  FRadioButton := RadioButton;
  DXCOLOR_DECODE_ARGB(FRadioButton.FBorderColor, FBorderSA, FBorderSR, FBorderSG, FBorderSB);
  DXCOLOR_DECODE_ARGB(FRadioButton.FInnerColor, FInnerSA, FInnerSR, FInnerSG, FInnerSB);
  DXCOLOR_DECODE_ARGB(FRadioButton.FCheckmarkColor, FCheckmarkSA, FCheckmarkSR, FCheckmarkSG,
    FCheckmarkSB);
  if (FRadioButton.Checked) then
  begin
    DXCOLOR_DECODE_ARGB(FCheckmarkColorChecked, FCheckmarkFA, FCheckmarkFR, FCheckmarkFG,
      FCheckmarkFB);
  end else
  begin
    DXCOLOR_DECODE_ARGB(FCheckmarkColorMouseFocus, FCheckmarkFA, FCheckmarkFR, FCheckmarkFG,
      FCheckmarkFB);
  end;
  case TargetStyle of
    fsNormal:
      begin
        DXCOLOR_DECODE_ARGB(FBorderColorNormal, FBorderFA, FBorderFR, FBorderFG, FBorderFB);
        DXCOLOR_DECODE_ARGB(FInnerColorNormal, FInnerFA, FInnerFR, FInnerFG, FInnerFB);
        if (not FRadioButton.Checked) then FCheckmarkFA := 0;
      end;
    fsMouseFocus:
      begin
        DXCOLOR_DECODE_ARGB(FBorderColorMouseFocus, FBorderFA, FBorderFR, FBorderFG, FBorderFB);
        DXCOLOR_DECODE_ARGB(FInnerColorMouseFocus, FInnerFA, FInnerFR, FInnerFG, FInnerFB);
      end;
    fsPressed:
      begin
        DXCOLOR_DECODE_ARGB(FBorderColorPressed, FBorderFA, FBorderFR, FBorderFG, FBorderFB);
        DXCOLOR_DECODE_ARGB(FInnerColorPressed, FInnerFA, FInnerFR, FInnerFG, FInnerFB);
        DXCOLOR_DECODE_ARGB(FCheckmarkColorChecked, FCheckmarkFA, FCheckmarkFR, FCheckmarkFG,
          FCheckmarkFB);
      end;
  end;
  inherited Start(Duration, EasingCurve);
end;

procedure TDXRadioButton.TDXRadioButtonFadeAnimation.UpdateAnimation(EasingValue: Single);
begin
  FRadioButton.FBorderColor := DXCOLOR_ARGB(
    Round(EasingValue * FBorderFA + (1 - EasingValue) * FBorderSA),
    Round(EasingValue * FBorderFR + (1 - EasingValue) * FBorderSR),
    Round(EasingValue * FBorderFG + (1 - EasingValue) * FBorderSG),
    Round(EasingValue * FBorderFB + (1 - EasingValue) * FBorderSB)
  );
  FRadioButton.FInnerColor := DXCOLOR_ARGB(
    Round(EasingValue * FInnerFA + (1 - EasingValue) * FInnerSA),
    Round(EasingValue * FInnerFR + (1 - EasingValue) * FInnerSR),
    Round(EasingValue * FInnerFG + (1 - EasingValue) * FInnerSG),
    Round(EasingValue * FInnerFB + (1 - EasingValue) * FInnerSB)
  );
  FRadioButton.FCheckmarkColor := DXCOLOR_ARGB(
    Round(EasingValue * FCheckmarkFA + (1 - EasingValue) * FCheckmarkSA),
    Round(EasingValue * FCheckmarkFR + (1 - EasingValue) * FCheckmarkSR),
    Round(EasingValue * FCheckmarkFG + (1 - EasingValue) * FCheckmarkSG),
    Round(EasingValue * FCheckmarkFB + (1 - EasingValue) * FCheckmarkSB)
  );
end;

initialization
  RegisterClass(TDXRadioButton);

end.
