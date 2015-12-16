unit DXGUIButton;

interface

uses
  Winapi.Windows, DXGUIFramework, DXGUITypes, DXGUITextControl, DXGUIImageList, DXGUIAnimations;

type
  TDXCustomButton = class(TDXCustomTextControl)
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Constraints;
    property Margins;
  end;

  TDXButton = class(TDXCustomButton)
  private type
    TDXButtonFadeAnimation = class(TDXCustomAnimation)
    private type
      TDXButtonFadeStyle = (fsNormal, fsMouseFocus, fsPressed);
    private
      FBorderColorNormal: TDXColor;
      FBorderColorMouseFocus: TDXColor;
      FBorderColorPressed: TDXColor;
      FInnerColorNormal: TDXColor;
      FInnerColorMouseFocus: TDXColor;
      FInnerColorPressed: TDXColor;
      FBorderColorDisabled: TDXColor;
      FInnerColorDisabled: TDXColor;
      FFontColorEnabled: TDXColor;
      FFontColorDisabled: TDXColor;
      FButton: TDXButton;
      FStartBorder: TDXColor;
      FStartInner: TDXColor;
      FStartFont: TDXColor;
      FFinalBorder: TDXColor;
      FFinalInner: TDXColor;
      FFinalFont: TDXColor;
    protected
      procedure UpdateAnimation(EasingValue: Single); override;
    public
      procedure Start(Duration: DWord; const EasingCurve: IDXEasingCurve = nil;
        Button: TDXButton = nil; TargetStyle: TDXButtonFadeStyle = fsNormal);
    public
      property BorderColorNormal: TDXColor read FBorderColorNormal write FBorderColorNormal;
      property BorderColorMouseFocus: TDXColor read FBorderColorMouseFocus write
        FBorderColorMouseFocus;
      property BorderColorPressed: TDXColor read FBorderColorPressed write FBorderColorPressed;
      property InnerColorNormal: TDXColor read FInnerColorNormal write FInnerColorNormal;
      property InnerColorMouseFocus: TDXColor read FInnerColorMouseFocus write
        FInnerColorMouseFocus;
      property InnerColorPressed: TDXColor read FInnerColorPressed write FInnerColorPressed;
      property BorderColorDisabled: TDXColor read FBorderColorDisabled write FBorderColorDisabled;
      property InnerColorDisabled: TDXColor read FInnerColorDisabled write FInnerColorDisabled;
      property FontColorEnabled: TDXColor read FFontColorEnabled write FFontColorEnabled;
      property FontColorDisabled: TDXColor read FFontColorDisabled write FFontColorDisabled;
    end;
  private
    FImages: TDXImageList;
    FImageIndex: Integer;
    FAnimation: TDXButtonFadeAnimation;
    FBorderColor: TDXColor;
    FInnerColor: TDXColor;
    FFontColor: TDXColor;
  private
    procedure SetImageIndex(const Value: Integer);
    procedure SetImages(const Value: TDXImageList);
  private
    procedure TriggerAnimation;
  protected
    procedure CMChangeNotification(var Message: TCMChangeNotification); override;
    procedure CMControlEnabledChanged(var Message: TCMControlEnabledChanged);
      message CM_CONTROL_ENABLED_CHANGED;
    procedure CMLButtonDown(var Message: TCMLButtonDown); override;
    procedure CMLButtonUp(var Message: TCMLButtonUp); override;
    procedure CMMouseEnter(var Message: TCMMouseEnter); override;
    procedure CMMouseLeave(var Message: TCMMouseLeave); override;
    procedure CMFontChanged(var Message: TCMTextControlFontChanged); override;
    procedure CMCaptionChanged(var Message: TCMTextControlCaptionChanged); override;
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Font;
    property Caption;
    property ParentFont;
    property Images: TDXImageList read FImages write SetImages;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
  end;

implementation

uses
  System.Classes, DXGUIRenderInterface, DXGUIFont;

{ TDXCustomButton }

constructor TDXCustomButton.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  Exclude(FControlStyle, csAcceptChildControls);
  Width := 120;
  Height := 27;
end;

{ TDXButton }

procedure TDXButton.TriggerAnimation;
var
  Duration: DWord;
  EasingCurve: IDXEasingCurve;
  TargetStyle: TDXButtonFadeAnimation.TDXButtonFadeStyle;
begin
  if (Enabled) then
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
        Duration := 400;
        EasingCurve := TDXInQuadEasingCurve.Create;
        TargetStyle := fsNormal;
      end;
    end;
    if (FAnimation.Running) then FAnimation.Cancel;
    FAnimation.Start(Duration, EasingCurve, Self, TargetStyle);
  end else
  begin
    FBorderColor := FAnimation.BorderColorDisabled;
    FInnerColor := FAnimation.InnerColorDisabled;
    FFontColor := FAnimation.FontColorDisabled;
  end;
  Invalidate;
end;

procedure TDXButton.CMCaptionChanged(var Message: TCMTextControlCaptionChanged);
begin
  inherited;
  Invalidate;
end;

procedure TDXButton.CMChangeNotification(var Message: TCMChangeNotification);
begin
  inherited;
  if (Message.Sender = FImages) then
  begin
    Invalidate;
  end;
end;

procedure TDXButton.CMControlEnabledChanged(var Message: TCMControlEnabledChanged);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXButton.CMFontChanged(var Message: TCMTextControlFontChanged);
begin
  inherited;
  Invalidate;
end;

procedure TDXButton.CMLButtonDown(var Message: TCMLButtonDown);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXButton.CMLButtonUp(var Message: TCMLButtonUp);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXButton.CMMouseEnter(var Message: TCMMouseEnter);
begin
  inherited;
  TriggerAnimation;
end;

procedure TDXButton.CMMouseLeave(var Message: TCMMouseLeave);
begin
  inherited;
  TriggerAnimation;
end;

constructor TDXButton.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FInvalidateEvents :=
    FInvalidateEvents + [ieEnabledChanged, iePressedChanged, ieMouseFocusChanged];
  FImageIndex := -1;
  FAnimation := TDXButtonFadeAnimation.Create;
  FAnimation.BorderColorNormal := DXCOLOR_RGBA(172, 172, 172, 255);
  FAnimation.InnerColorNormal := DXCOLOR_RGBA(236, 236, 236, 255);
  FAnimation.BorderColorMouseFocus := DXCOLOR_RGBA(126, 180, 234, 255);
  FAnimation.InnerColorMouseFocus := DXCOLOR_RGBA(231, 242, 252, 255);
  FAnimation.BorderColorPressed := DXCOLOR_RGBA(86, 157, 229, 255);
  FAnimation.InnerColorPressed := DXCOLOR_RGBA(207, 230, 252, 255);
  FAnimation.BorderColorDisabled := DXCOLOR_RGBA(217, 217, 217, 255);
  FAnimation.InnerColorDisabled := DXCOLOR_RGBA(239, 239, 239, 255);
  FAnimation.FontColorEnabled := DXCOLOR_RGBA(0, 0, 0, 255);
  FAnimation.FontColorDisabled := DXCOLOR_RGBA(127, 127, 127, 255);
  FBorderColor := FAnimation.BorderColorNormal;
  FInnerColor := FAnimation.InnerColorNormal;
  FFontColor := FAnimation.FontColorEnabled;
end;

destructor TDXButton.Destroy;
begin
  FAnimation.Free;
  if Assigned(FImages) then FImages.RemoveChangeObserver(Self);
  inherited;
end;

procedure TDXButton.Paint(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
begin
  Renderer := Manager.RenderInterface.Renderer;
  Renderer.DrawRect(BoundsRect, FBorderColor);
  BoundsRect.Top    := BoundsRect.Top    + 1;
  BoundsRect.Left   := BoundsRect.Left   + 1;
  BoundsRect.Bottom := BoundsRect.Bottom - 1;
  BoundsRect.Right  := BoundsRect.Right  - 1;
  Renderer.FillRect(BoundsRect, FInnerColor);
  Font.DrawText(BoundsRect, Caption, FFontColor, alCenter, vaCenter);
  if Assigned(FImages) and (FImageIndex >= 0) then
  begin
    BoundsRect.Left  := BoundsRect.Left + 4;
    BoundsRect.Top   := BoundsRect.Top  + 0;
    BoundsRect.Right := BoundsRect.Left + FImages.Width;
    if Enabled then
    begin
      FImages.DrawCentered(FImageIndex, BoundsRect, clWhite);
    end else
    begin
      FImages.DrawCentered(FImageIndex, BoundsRect, DXCOLOR_RGBA(255, 255, 255, 127));
    end;
  end;
  if (FAnimation.Running) then
  begin
    FAnimation.Update;
    Invalidate;
  end;
end;

procedure TDXButton.SetImageIndex(const Value: Integer);
begin
  if (FImageIndex <> Value) then
  begin
    FImageIndex := Value;
    Invalidate;
  end;
end;

procedure TDXButton.SetImages(const Value: TDXImageList);
begin
  if (FImages <> Value) then
  begin
    if Assigned(FImages) then
    begin
      FImages.RemoveChangeObserver(Self);
    end;
    FImages := Value;
    if Assigned(FImages) then
    begin
      FImages.InsertChangeObserver(Self);
    end;
    Invalidate;
  end;
end;

{ TDXButton.TDXButtonFadeAnimation }

procedure TDXButton.TDXButtonFadeAnimation.Start(Duration: DWord; const EasingCurve: IDXEasingCurve;
  Button: TDXButton; TargetStyle: TDXButtonFadeStyle);
begin
  FButton := Button;
  FStartBorder := FButton.FBorderColor;
  FStartInner := FButton.FInnerColor;
  FStartFont := FButton.FFontColor;
  case TargetStyle of
    fsNormal:
      begin
        FFinalBorder := FBorderColorNormal;
        FFinalInner := FInnerColorNormal;
      end;
    fsMouseFocus:
      begin
        FFinalBorder := FBorderColorMouseFocus;
        FFinalInner := FInnerColorMouseFocus;
      end;
    fsPressed:
      begin
        FFinalBorder := FBorderColorPressed;
        FFinalInner := FInnerColorPressed;
      end;
  end;
  case FButton.Enabled of
    false: FFinalFont := FFontColorDisabled;
    true : FFinalFont := FFontColorEnabled;
  end;
  inherited Start(Duration, EasingCurve);
end;

procedure TDXButton.TDXButtonFadeAnimation.UpdateAnimation(EasingValue: Single);
begin
  {FButton.FBorderColor := FStartBorder.Modulate(FFinalBorder, EasingValue);
  FButton.FInnerColor := FStartInner.Modulate(FFinalInner, EasingValue);
  FButton.FFontColor := FStartFont.Modulate(FFinalFont, EasingValue); }
end;

initialization
  RegisterClass(TDXButton);

end.
