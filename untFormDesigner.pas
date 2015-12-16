unit untFormDesigner;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.Direct3D9, Winapi.D3DX9, System.Classes, Vcl.Controls,
  Vcl.ExtCtrls, Vcl.Forms, DXGUIFramework, DXGUIRenderInterface, DXGUIDX9RenderInterface;

type
  TDXFormDesigner = class(TCustomPanel)
  private
    FDevice: IDirect3DDevice9;
    FGUIManager: TDXGUIManager;
    FRenderInterface: TDXRenderInterface;
    FInitialized: Boolean;
    FNeedsRepaint: Boolean;
    FSelectedControl: TDXControl;
    FDrawFocusRect: Boolean;
    FDrawDragPoints: Boolean;
    FDragPoints: array[1..3, 1..3] of TPoint;
    FDragActive: Boolean;
    FDragPoint: TPoint;
    FDragStart: TPoint;
    FDragRect: TRect;
  private
    FOnInitialized: TNotifyEvent;
    FOnFinalized: TNotifyEvent;
    FOnSelectedControlChanged: TNotifyEvent;
    FOnBeforePaint: TNotifyEvent;
    FOnAfterPaint: TNotifyEvent;
  private
    function GetNeedsRepaint: Boolean;
  private
    procedure SetDrawDragPoints(const Value: Boolean);
    procedure SetDrawFocusRect(const Value: Boolean);
  private
    procedure Initialize;
    procedure Finalize;
  private
    procedure CalculateDragPoints;
    function GetDragPointIndex(X, Y: Integer): TPoint;
    procedure PaintFocusRect;
    procedure PaintDragPoints;
  protected
    procedure CreateHandle; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure WndProc(var Message: TMessage); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    procedure SelectControl(AControl: TDXControl);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    property Initialized: Boolean read FInitialized;
    property NeedsRepaint: Boolean read GetNeedsRepaint;
    property GUIManager: TDXGUIManager read FGUIManager;
    property RenderInterface: TDXRenderInterface read FRenderInterface;
    property SelectedControl: TDXControl read FSelectedControl;
  published
    property Align;
    property Alignment;
    property Anchors;
    property Constraints;
    property Enabled;
    property PopupMenu;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnAlignPosition;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property DrawFocusRect: Boolean read FDrawFocusRect write SetDrawFocusRect;
    property DrawDragPoints: Boolean read FDrawDragPoints write SetDrawDragPoints;
  published
    property OnInitialized: TNotifyEvent read FOnInitialized write FOnInitialized;
    property OnFinalized: TNotifyEvent read FOnFinalized write FOnFinalized;
    property OnSelectedControlChanged: TNotifyEvent read FOnSelectedControlChanged write
      FOnSelectedControlChanged;
    property OnBeforePaint: TNotifyEvent read FOnBeforePaint write FOnBeforePaint;
    property OnAfterPaint: TNotifyEvent read FOnAfterPaint;
  end;

implementation

uses
  Winapi.DXTypes, System.Types, System.SysUtils, DXGUITypes;

{ TDXFormDesigner }

procedure TDXFormDesigner.CalculateDragPoints;
var
  R: TRect;
  X, Y: Integer;
begin
  if (not Assigned(FSelectedControl)) then Exit;
  R := Rect(FSelectedControl.AbsoluteBoundsRect.Left - 2,
    FSelectedControl.AbsoluteBoundsRect.Top - 2,
    FSelectedControl.AbsoluteBoundsRect.Right + 2,
    FSelectedControl.AbsoluteBoundsRect.Bottom + 2);
  for Y := 1 to 3 do
  begin
    for X := 1 to 3 do
    begin
      case X of
        1: FDragPoints[Y, X].X := R.Left;
        2: FDragPoints[Y, X].X := Round((R.Left + R.Right) / 2);
        3: FDragPoints[Y, X].X := R.Right;
      end;
      case Y of
        1: FDragPoints[Y, X].Y := R.Top;
        2: FDragPoints[Y, X].Y := Round((R.Top + R.Bottom) / 2);
        3: FDragPoints[Y, X].Y := R.Bottom;
      end;
    end;
  end;
end;

constructor TDXFormDesigner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ShowCaption := false;
  BorderStyle := bsNone;
  BevelInner := bvNone;
  BevelKind := bkNone;
  BevelOuter := bvNone;
end;

procedure TDXFormDesigner.CreateHandle;
begin
  inherited;
  if (WindowHandle > 0) then
  begin
    Initialize;
  end;
end;

destructor TDXFormDesigner.Destroy;
begin
  Finalize;
  inherited;
end;

procedure TDXFormDesigner.Finalize;
begin
  FInitialized := false;
  SelectControl(nil);
  if (Assigned(FGUIManager)) then FreeAndNil(FGUIManager);
  if (Assigned(FRenderInterface)) then FreeAndNil(FRenderInterface);
  if (Assigned(FOnFinalized)) then FOnFinalized(Self);
end;

function TDXFormDesigner.GetDragPointIndex(X, Y: Integer): TPoint;
var
  I, J: Integer;
begin
  Result.X := 0;
  Result.Y := 0;
  for I := 1 to 3 do
  begin
    for J := 1 to 3 do
    begin
      if (X >= FDragPoints[J, I].X - 2) and (X <= FDragPoints[J, I].X + 2) and
        (Y >= FDragPoints[J, I].Y - 2) and (Y <= FDragPoints[J, I].Y + 2) then
      begin
        Result.X := I;
        Result.Y := J;
        Break;
      end;
    end;
  end;
end;

function TDXFormDesigner.GetNeedsRepaint: Boolean;
begin
  Result := (FInitialized and FGUIManager.NeedsRepaint) or FNeedsRepaint;
end;

procedure TDXFormDesigner.Initialize;
var
  Direct3D: IDirect3D9;
  PresentParameters: TD3DPresentParameters;
begin
  Finalize;
  Direct3D := Direct3DCreate9(D3D_SDK_VERSION);
  if (Direct3D = nil) then Exit;
  FillChar(PresentParameters, SizeOf(PresentParameters), 0);
  PresentParameters.Windowed := true;
  PresentParameters.SwapEffect := D3DSWAPEFFECT_DISCARD;
  PresentParameters.BackBufferFormat := D3DFMT_A8R8G8B8;
  //PresentParameters.EnableAutoDepthStencil := true;
  //PresentParameters.AutoDepthStencilFormat := D3DFMT_D24S8;
  if FAILED(Direct3D.CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, WindowHandle,
    D3DCREATE_HARDWARE_VERTEXPROCESSING, @PresentParameters, FDevice)) then
  begin
    raise Exception.Create('Could not initialize render surface.');
  end;
  FRenderInterface := TDXDX9RenderInterface.Create(FDevice);
  FGUIManager := TDXGUIManager.Create(FRenderInterface);
  FInitialized := true;
  if Assigned(FOnInitialized) then FOnInitialized(Self);
end;

procedure TDXFormDesigner.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  DPI: TPoint;
begin
  DPI := GetDragPointIndex(X, Y);
  if (FDrawDragPoints) and (Assigned(FSelectedControl)) and (DPI.X > 0) and (DPI.Y > 0) then
  begin
    FDragPoint := DPI;
    FDragRect := FSelectedControl.BoundsRect;
    FDragStart.X := X;
    FDragStart.Y := Y;
    FDragActive := true;
  end else
  begin
    SelectControl(FGUIManager.GetControlAtAbsolute(X, Y));
  end;
  inherited;
end;

procedure TDXFormDesigner.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  C: TDXControl;
begin
  if (FDrawDragPoints) and (Assigned(FSelectedControl)) and (FDragActive) then
  begin
    C := FSelectedControl;
    case FDragPoint.Y of
      1:
        begin
          case FDragPoint.X of
            1: C.SetBounds(FDragRect.Left + X - FDragStart.X,
              FDragRect.Top + Y - FDragStart.Y, FDragRect.Width + FDragStart.X - X + 1,
              FDragRect.Height + FDragStart.Y - Y + 1);
            2: C.SetBounds(C.Left, FDragRect.Top + Y - FDragStart.Y, C.Width,
              FDragRect.Height + FDragStart.Y - Y + 1);
            3: C.SetBounds(C.Left, FDragRect.Top + Y - FDragStart.Y,
              FDragRect.Width + X - FDragStart.X + 1, FDragRect.Height + FDragStart.Y - Y + 1);
          end;
        end;
      2:
        begin
          case FDragPoint.X of
            1: C.SetBounds(FDragRect.Left + X - FDragStart.X, FDragRect.Top,
              FDragRect.Width + FDragStart.X - X + 1, C.Height);
            2: C.SetBounds(FDragRect.Left + X - FDragStart.X,
              FDragRect.Top + Y - FDragStart.Y, C.Width, C.Height);
            3: C.SetBounds(C.Left, C.Top, FDragRect.Width + X - FDragStart.X + 1, C.Height);
          end;
        end;
      3:
        begin
          case FDragPoint.X of
            1: C.SetBounds(FDragRect.Left + X - FDragStart.X, C.Top,
              FDragRect.Width + FDragStart.X - X + 1, FDragRect.Height + Y - FDragStart.Y + 1);
            2: C.SetBounds(C.Left, C.Top, C.Width, FDragRect.Height + Y - FDragStart.Y + 1);
            3: C.SetBounds(C.Left, C.Top, FDragRect.Width + X - FDragStart.X + 1,
              FDragRect.Height + Y - FDragStart.Y + 1);
          end;
        end;
    end;
  end;
  inherited;
end;

procedure TDXFormDesigner.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragActive := false;
  inherited;
end;

procedure TDXFormDesigner.Paint;
begin
  if (not FInitialized) then Exit;
  FNeedsRepaint := false;
  CalculateDragPoints;
  FDevice.Clear(0, nil, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0, 50, 100), 0, 0);
  if (SUCCEEDED(FDevice.BeginScene)) then
  begin
    if Assigned(FOnBeforePaint) then FOnBeforePaint(Self);
    FGUIManager.PerformPaint;
    if Assigned(FSelectedControl) then
    begin
      if (FDrawFocusRect) then PaintFocusRect;
      if (FDrawDragPoints) then PaintDragPoints;
    end;
    if Assigned(FOnAfterPaint) then FOnAfterPaint(Self);
    FDevice.EndScene;
  end;
  FDevice.Present(nil, nil, 0, nil);
end;

procedure TDXFormDesigner.PaintDragPoints;
var
  X, Y: Integer;
begin
  for Y := 1 to 3 do
  begin
    for X := 1 to 3 do
    begin
      FRenderInterface.Renderer.FillRect(Rect(
        FDragPoints[Y, X].X - 2, FDragPoints[Y, X].Y - 2,
        FDragPoints[Y, X].X + 2, FDragPoints[Y, X].Y + 2), DXCOLOR_RGBA(255, 255, 0, 255));
    end;
  end;
end;

procedure TDXFormDesigner.PaintFocusRect;
var
  R: TRect;
begin
  R := Rect(FSelectedControl.AbsoluteBoundsRect.Left - 2,
    FSelectedControl.AbsoluteBoundsRect.Top - 2,
    FSelectedControl.AbsoluteBoundsRect.Right + 2,
    FSelectedControl.AbsoluteBoundsRect.Bottom + 2);
  FRenderInterface.Renderer.DrawRect(R, DXCOLOR_RGBA(255, 0, 0, 255));
end;

procedure TDXFormDesigner.Resize;
begin
  Initialize;
  inherited;
end;

procedure TDXFormDesigner.SelectControl(AControl: TDXControl);
begin
  if (FSelectedControl <> AControl) then
  begin
    FSelectedControl := AControl;
    CalculateDragPoints;
    if (FDrawFocusRect) or (FDrawDragPoints) then
    begin
      FNeedsRepaint := true;
    end;
    if Assigned(FOnSelectedControlChanged) then FOnSelectedControlChanged(Self);
  end;
end;

procedure TDXFormDesigner.SetDrawDragPoints(const Value: Boolean);
begin
  if (FDrawDragPoints <> Value) then
  begin
    FDrawDragPoints := Value;
    if (Value) then CalculateDragPoints;
    FNeedsRepaint := true;
  end;
end;

procedure TDXFormDesigner.SetDrawFocusRect(const Value: Boolean);
begin
  if (FDrawFocusRect <> Value) then
  begin
    FDrawFocusRect := Value;
    FNeedsRepaint := true;
  end;
end;

procedure TDXFormDesigner.WndProc(var Message: TMessage);
var
  Msg: TMsg;
begin
  Msg.hwnd := WindowHandle;
  Msg.message := Message.Msg;
  Msg.wParam := Message.WParam;
  Msg.lParam := Message.LParam;
  if (FInitialized) then FGUIMAnager.PerformWindowMessage(Msg);
  inherited;
end;

end.
