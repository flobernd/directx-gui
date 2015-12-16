unit DXGUIStatusBar;

interface

uses
  Winapi.Windows, DXGUIFramework, DXGUIRenderInterface, DXGUITextControl;

// TODO: Prüfen, ob Form resized werden darf

type
  TDXStatusBar = class(TDXCustomTextControl)
  private
    FSizeGrip: Boolean;
    FResizeWindow: TDXControl;
    FResizeRect: TRect;
    FResizeStart: TPoint;
    FResizeActive: Boolean;
  private
    procedure SetSizeGrip(const Value: Boolean);
  private
    function FindParentWindow: TDXControl;
  protected
    procedure CMLButtonDown(var Message: TCMLButtonDown); override;
    procedure CMLButtonUp(var Message: TCMLButtonUp); override;
    procedure CMMouseMove(var Message: TCMMouseMove); override;
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Constraints;
    property Margins;
    property Font;
    property ParentFont;
    property SizeGrip: Boolean read FSizeGrip write SetSizeGrip default true;
  end;

implementation

uses
  System.Types, System.SysUtils, System.Classes, DXGUITypes;

{ TDXStatusBar }

procedure TDXStatusBar.CMLButtonDown(var Message: TCMLButtonDown);
begin
  inherited;
  if (FSizeGrip) and (Rect(AbsoluteBoundsRect.Right - 20, AbsoluteBoundsRect.Top,
    AbsoluteBoundsRect.Right, AbsoluteBoundsRect.Bottom).Contains(
    Point(Message.Pos.X + AbsoluteBoundsRect.Left, Message.Pos.Y + AbsoluteBoundsRect.Top))) then
  begin
    FResizeWindow := FindParentWindow;
    if (Assigned(FResizeWindow)) then
    begin
      FResizeRect := FResizeWindow.BoundsRect;
      FResizeStart := Message.Pos;
      FResizeActive := true;
    end;
  end;
end;

procedure TDXStatusBar.CMLButtonUp(var Message: TCMLButtonUp);
begin
  inherited;
  FResizeActive := false;
end;

procedure TDXStatusBar.CMMouseMove(var Message: TCMMouseMove);
begin
  inherited;
  if (FResizeActive) then
  begin
    FResizeWindow.SetBounds(FResizeWindow.Left, FResizeWindow.Top,
      FResizeRect.Width + Message.Pos.X - FResizeStart.X + 1,
      FResizeRect.Height + Message.Pos.Y - FResizeStart.Y + 1);
  end;
end;

constructor TDXStatusBar.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  Exclude(FControlStyle, csAcceptChildControls);
  Height := 22;
  Align := alBottom;
  FSizeGrip := true;
end;

destructor TDXStatusBar.Destroy;
begin

  inherited;
end;

function TDXStatusBar.FindParentWindow: TDXControl;
var
  C: TDXControl;
begin
  Result := nil;
  C := Self;
  while Assigned(C.Parent) do
  begin
    C := C.Parent;
  end;
  if (Supports(C, IDXWindow)) then Result := C;
end;

procedure TDXStatusBar.Paint(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
  I, J: Integer;
  R: TRect;
begin
  Renderer := Manager.RenderInterface.Renderer;
  Renderer.FillRect(BoundsRect, DXCOLOR_RGBA(240, 240, 240, 255));
  Renderer.DrawLine(Point(BoundsRect.Left, BoundsRect.Top), Point(BoundsRect.Right, BoundsRect.Top),
    DXCOLOR_RGBA(215, 215, 215, 255));
  if (FSizeGrip) then
  begin
    for I := 0 to 2 do
    begin
      R := Rect(ClientRect.Right - 4, ClientRect.Bottom - 4 - 3 * I, ClientRect.Right - 2,
        ClientRect.Bottom - 2 - 3 * I);
      for J := 0 to 2 - I do
      begin
        Renderer.FillRect(R, DXCOLOR_RGBA(191, 191, 191, 255));
        R.Left := R.Left - 3;
        R.Right := R.Right - 3;
      end;
    end;
  end;
end;

procedure TDXStatusBar.SetSizeGrip(const Value: Boolean);
begin
  if (FSizeGrip <> Value) then
  begin
    FSizeGrip := Value;
    Invalidate;
  end;
end;

initialization
  RegisterClass(TDXStatusBar);

end.
