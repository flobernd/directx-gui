unit DXGUIPageControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Generics.Collections, DXGUIFramework,
  DXGUIRenderInterface, DXGUITextControl, DXGUIAnimations, DXGUIImageList;

// TODO: Methode einbauen, um Tab Buttons zu scrollen, falls die Breite des Page Controls zu
//       gering ist.

type
  TDXTabSheet = class;

  TDXTabChangingEvent = procedure(Sender: TObject; OldTab, NewTab: TDXTabSheet;
    var AllowChange: Boolean) of object;

  TDXPageControl = class(TDXCustomTextControl)
  private type
    TDXSlideDirection = (sdLeftToRight, sdRightToLeft);
  private
    FPages: TList<TDXTabSheet>;
    FActivePage: TDXTabSheet;
    FAnimated: Boolean;
    FImages: TDXImageList;
    FAnimationSlideIn: TDXSimpleAnimation;
    FAnimationSlideOut: TDXSimpleAnimation;
    FAnimationPageIn: TDXTabSheet;
    FAnimationPageOut: TDXTabSheet;
    FAnimationDirectionOut: TDXSlideDirection;
    FAnimationDirectionIn: TDXSlideDirection;
    FButtonRects: array of TRect;
  private
    FOnChanging: TDXTabChangingEvent;
    FOnChanged: TDXNotifyEvent;
  private
    function GetPageCount: Integer;
    function GetPage(Index: Integer): TDXTabSheet;
  private
    procedure SetActivePage(const Value: TDXTabSheet);
    procedure SetAnimated(const Value: Boolean);
    procedure SetImages(const Value: TDXImageList);
  private
    procedure CalculateButtonRects;
    procedure PageChanged(OldPage, NewPage: TDXTabSheet);
  protected
    procedure CMControlChildInserted(var Message: TCMControlChildInserted);
      message CM_CONTROL_CHILD_INSERTED;
    procedure CMControlChildRemoved(var Message: TCMControlChildRemoved);
      message CM_CONTROL_CHILD_REMOVED;
    procedure CMLButtonDown(var Message: TCMLButtonDown); override;
    procedure CMFontChanged(var Message: TCMTextControlFontChanged); override;
  protected
    procedure ValidateInsert(AComponent: TComponent); override;
  protected
    function CalculateClientRect(const ABoundsRect: TRect): TRect; override;
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  public
    property PageCount: Integer read GetPageCount;
    property Pages[Index: Integer]: TDXTabSheet read GetPage;
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Constraints;
    property Margins;
    property Font;
    property ParentFont;
    property ActivePage: TDXTabSheet read FActivePage write SetActivePage;
    property Animated: Boolean read FAnimated write SetAnimated default false;
    property Images: TDXImageList read FImages write SetImages;
  published
    property OnChanging: TDXTabChangingEvent read FOnChanging write FOnChanging;
    property OnChanged: TDXNotifyEvent read FOnChanged write FOnChanged;
  end;

  TDXTabSheet = class(TDXCustomTextControl)
  private
    FImageIndex: Integer;
    procedure SetImageIndex(const Value: Integer);
  protected
    procedure CMCaptionChanged(var Message: TCMTextControlCaptionChanged); override;
  protected
    procedure ValidateContainer(AComponent: TComponent); override;
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
  published
    property AlignWithMargins;
    property Padding;
    property Font;
    property Caption;
    property ParentFont;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
  end;

implementation

uses
  System.Types, DXGUITypes, DXGUIExceptions, DXGUIFont;

resourcestring
  SInvalidContainerEx = '%s is not a valid container for %s components.';
  SInvalidInsertEx    = '%s can not be inserted into a %s container.';

{ TDXPageControl }

procedure TDXPageControl.CalculateButtonRects;
var
  I, Offset, TextWidth: Integer;
begin
  Offset := 0;
  SetLength(FButtonRects, PageCount);
  for I := 0 to FPages.Count - 1 do
  begin
    TextWidth := Font.GetTextWidth(TDXTabSheet(FPages[I]).Caption, alCenter, vaCenter, false);
    if (FPages[I] = ActivePage) then
    begin
      FButtonRects[I] := Rect(Offset, 2, Offset + TextWidth + 20, 31);
    end else
    begin
      FButtonRects[I] := Rect(Offset, 5, Offset + TextWidth + 20, 31);
    end;
    if Assigned(FImages) and (FPages[I].ImageIndex >= 0) then
    begin
      FButtonRects[I].Width := FButtonRects[I].Width + FImages.Width + 4;
    end;
    Inc(Offset, FButtonRects[I].Width - 1);
  end;
end;

function TDXPageControl.CalculateClientRect(const ABoundsRect: TRect): TRect;
begin
  Result := Rect(ABoundsRect.Left, ABoundsRect.Top + 30, AboundsRect.Right,
    ABoundsRect.Bottom);
end;

procedure TDXPageControl.CMControlChildInserted(var Message: TCMControlChildInserted);
begin
  inherited;
  if (Message.Control is TDXTabSheet) then
  begin
    FPages.Add(TDXTabSheet(Message.Control));
    if (not Assigned(FActivePage)) then
    begin
      SetActivePage(TDXTabSheet(Message.Control));
    end;
    CalculateButtonRects;
  end;
end;

procedure TDXPageControl.CMControlChildRemoved(var Message: TCMControlChildRemoved);
var
  Index: Integer;
begin
  inherited;
  if (Message.Control is TDXTabSheet) then
  begin
    Index := FPages.IndexOf(TDXTabSheet(Message.Control));
    FPages.Remove(TDXTabSheet(Message.Control));
    if (Message.Control = FActivePage) then
    begin
      if (FPages.Count > 0) then
      begin
        Dec(Index);
        if (Index < 0) then Inc(Index, 2);
        SetActivePage(FPages[Index]);
      end else
      begin
        FActivePage := nil;
      end;
    end;
    CalculateButtonRects;
  end;
end;

procedure TDXPageControl.CMFontChanged(var Message: TCMTextControlFontChanged);
begin
  inherited;
  Invalidate;
end;

procedure TDXPageControl.CMLButtonDown(var Message: TCMLButtonDown);
var
  I: Integer;
begin
  inherited;
  for I := Low(FButtonRects) to High(FButtonRects) do
  begin
    if (FButtonRects[I].Contains(Message.Pos)) then
    begin
      SetActivePage(Pages[I]);
      Break;
    end;
  end;
end;

constructor TDXPageControl.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FInvalidateEvents :=
    FInvalidateEvents + [ieEnabledChanged, iePressedChanged, ieMouseFocusChanged];
  FPages := TList<TDXTabSheet>.Create;
  FAnimationSlideIn := TDXSimpleAnimation.Create;
  FAnimationSlideOut := TDXSimpleAnimation.Create;
end;

destructor TDXPageControl.Destroy;
begin
  FPages.Free;
  FAnimationSlideIn.Free;
  FAnimationSlideOut.Free;
  inherited;
end;

function TDXPageControl.GetPage(Index: Integer): TDXTabSheet;
begin
  Result := FPages[Index];
end;

function TDXPageControl.GetPageCount: Integer;
begin
  Result := FPages.Count;
end;

procedure TDXPageControl.PageChanged(OldPage, NewPage: TDXTabSheet);
begin
  if (FAnimated) then
  begin
    FAnimationPageOut := OldPage;
    FAnimationPageIn := NewPage;
    if Assigned(OldPage) then
    begin
      FAnimationDirectionOut := sdLeftToRight;
      if FPages.IndexOf(OldPage) < FPages.IndexOf(NewPage) then
        FAnimationDirectionOut := sdRightToLeft;
      FAnimationSlideOut.Cancel;
      FAnimationSlideOut.Start(250, TDXOutQuintEasingCurve.Create);
    end;
    if Assigned(NewPage) then
    begin
      FAnimationDirectionIn := sdLeftToRight;
      if FPages.IndexOf(OldPage) < FPages.IndexOf(NewPage) then
        FAnimationDirectionIn := sdRightToLeft;
      NewPage.Visible := true;
      FAnimationSlideIn.Cancel;
      FAnimationSlideIn.Start(250, TDXOutQuintEasingCurve.Create);
    end;
  end else
  begin
    if Assigned(OldPage) then OldPage.Visible := false;
    if Assigned(NewPage) then NewPage.Visible := true;
  end;
  CalculateButtonRects;
  Invalidate;
end;

procedure TDXPageControl.Paint(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
  I, PageLeft: Integer;
  R: TRect;
begin
  Renderer := Manager.RenderInterface.Renderer;
  Renderer.FillRect(ClientRect, DXCOLOR_RGBA(246, 246, 246, 255));
  Renderer.DrawRect(ClientRect, DXCOLOR_RGBA(172, 172, 172, 255));
  for I := Low(FButtonRects) to High(FButtonRects) do
  begin
    Renderer.FillRect(FButtonRects[I], DXCOLOR_RGBA(236, 236, 236, 255));
    R := FButtonRects[I];
    if Assigned(FImages) and (FPages[I].ImageIndex >= 0) then
    begin
      R.Left := R.Left + 5;
      R.Width := FImages.Width + 2;
      R.Top := R.Top + 1;
      FImages.DrawCentered(FPages[I].ImageIndex, R);
      R := FButtonRects[I];
      R.Left := R.Left + FImages.Width;
    end;
    Font.DrawText(R, FPages[I].Caption, DXCOLOR_RGBA(0, 0, 0, 255), alCenter, vaCenter, false);
    Renderer.DrawRect(FButtonRects[I], DXCOLOR_RGBA(172, 172, 172, 255));
  end;
  if (FAnimated) then
  begin
    if Assigned(FAnimationPageOut) then
    begin
      if (FAnimationSlideOut.Running) then
      begin
        FAnimationSlideOut.Update;
        if (FAnimationDirectionOut = sdLeftToRight) then
        begin
          PageLeft := Round((ClientRect.Width) * FAnimationSlideOut.CurrentEasingValue);
        end else
        begin
          PageLeft := Round((- ClientRect.Width) * FAnimationSlideOut.CurrentEasingValue);
        end;
        FAnimationPageOut.Align := alNone;
        R := Rect(PageLeft, 0, PageLeft + ClientRect.Width, ClientRect.Height);
        if (FAnimationPageOut.AlignWithMargins) then
        begin
          R := Rect(R.Left + FAnimationPageOut.Margins.Left,
            R.Top + FAnimationPageOut.Margins.Top,
            R.Right - FAnimationPageOut.Margins.Right,
            R.Bottom - FAnimationPageOut.Margins.Bottom);
        end;
        FAnimationPageOut.SetBounds(R.Left, R.Top, R.Width, R.Height);
        Invalidate;
      end;
      if (not FAnimationSlideOut.Running) then
      begin
        FAnimationPageOut.Visible := false;
        FAnimationPageOut.Align := alClient;
        FAnimationPageOut := nil;
      end;
    end;
    if Assigned(FAnimationPageIn) then
    begin
      if (FAnimationSlideIn.Running) then
      begin
        FAnimationSlideIn.Update;
        if (FAnimationDirectionIn = sdLeftToRight) then
        begin
          PageLeft :=
            Round(- ClientRect.Width + (ClientRect.Width * FAnimationSlideIn.CurrentEasingValue));
        end else
        begin
          PageLeft :=
            Round(ClientRect.Width - (ClientRect.Width * FAnimationSlideIn.CurrentEasingValue));
        end;
        FAnimationPageIn.Align := alNone;
        R := Rect(PageLeft, 0, PageLeft + ClientRect.Width, ClientRect.Height);
        if (FAnimationPageIn.AlignWithMargins) then
        begin
          R := Rect(R.Left + FAnimationPageIn.Margins.Left,
            R.Top + FAnimationPageIn.Margins.Top,
            R.Right - FAnimationPageIn.Margins.Right,
            R.Bottom - FAnimationPageIn.Margins.Bottom);
        end;
        FAnimationPageIn.SetBounds(R.Left, R.Top, R.Width, R.Height);
        Invalidate;
      end;
      if (not FAnimationSlideIn.Running) then
      begin
        FAnimationPageIn.Align := alClient;
        FAnimationPageIn.Visible := true;
        FAnimationPageIn := nil;
      end;
    end;
  end;
end;

procedure TDXPageControl.SetActivePage(const Value: TDXTabSheet);
var
  AllowChange: Boolean;
  OldPage: TDXTabSheet;
begin
  if Assigned(Value) and (Value <> FActivePage) then
  begin
    if Assigned(FOnChanging) then
    begin
      AllowChange := true;
      FOnChanging(Self, FActivePage, Value, AllowChange);
      if (not AllowChange) then Exit;
    end;
    OldPage := FActivePage;
    FActivePage := Value;
    PageChanged(OldPage, FActivePage);
    if Assigned(FOnChanged) then
    begin
      FOnChanged(Self);
    end;
  end;
end;

procedure TDXPageControl.SetAnimated(const Value: Boolean);
begin
  if (FAnimated <> Value) then
  begin
    FAnimated := Value;
  end;
end;

procedure TDXPageControl.SetImages(const Value: TDXImageList);
begin
  if (FImages <> Value) then
  begin
    FImages := Value;
    CalculateButtonRects;
    Invalidate;
  end;
end;

procedure TDXPageControl.ValidateInsert(AComponent: TComponent);
begin
  inherited;
  if (not (AComponent is TDXTabSheet)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidInsertEx,
      [AComponent.ClassName, ClassName]);
  end;
end;

{ TDXTabSheet }

procedure TDXTabSheet.CMCaptionChanged(var Message: TCMTextControlCaptionChanged);
begin
  inherited;
  if Assigned(Parent) and (Parent is TDXPageControl) then
  begin
    TDXPageControl(Parent).CalculateButtonRects;
    TDXPageControl(Parent).Invalidate;
  end;
end;

constructor TDXTabSheet.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  Visible := false;
  Align := alClient;
  FImageIndex := -1;
end;

procedure TDXTabSheet.Paint(BoundsRect, ClientRect: TRect);
begin
  inherited;

end;

procedure TDXTabSheet.SetImageIndex(const Value: Integer);
begin
  if (FImageIndex <> Value) then
  begin
    FImageIndex := Value;
    if Assigned(Parent) and (Parent is TDXPageControl) then
    begin
      TDXPageControl(Parent).CalculateButtonRects;
      TDXPageControl(Parent).Invalidate;
    end;
  end;
end;

procedure TDXTabSheet.ValidateContainer(AComponent: TComponent);
begin
  inherited;
  if (not (AComponent is TDXPageControl)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidContainerEx,
      [AComponent.ClassName, ClassName]);
  end;
end;

initialization
  RegisterClasses([TDXPageControl, TDXTabSheet]);

end.
