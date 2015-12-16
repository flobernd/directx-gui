unit DXGUIWindow;

interface

uses
  Winapi.Windows, System.Classes, Generics.Collections, DXGUIFramework, DXGUITypes,
  DXGUITextControl, DXGUIImageList;

{ Interface }

type
  TDXCustomWindow = class(TDXCustomTextControl, IDXWindow)
  private
    FAllowDrag: Boolean;
    FAllowClientDrag: Boolean;
    FIsActive: Boolean;
    FDragActive: Boolean;
    FDragStart: TPoint;
  private
    FOnActivate: TDXNotifyEvent;
    FOnDeactivate: TDXNotifyEvent;
  protected
    procedure CMLButtonDown(var Message: TCMLButtonDown); override;
    procedure CMLButtonUp(var Message: TCMLButtonUp); override;
    procedure CMMouseMove(var Message: TCMMouseMove); override;
    procedure CMActivate(var Message: TCMWindowActivate); message CM_WINDOW_ACTIVATE;
    procedure CMDeactivate(var Message: TCMWindowDeactivate); message CM_WINDOW_DEACTIVATE;
  public
    constructor Create(Manager: TDXGUIManager);
    destructor Destroy; override;
  public
    property IsActive: Boolean read FIsActive;
  published
    property Constraints;
    property Padding;
    property AllowDrag: Boolean read FAllowDrag write FAllowDrag default true;
    property AllowClientDrag: Boolean read FAllowClientDrag write FAllowClientDrag default false;
  published
    property OnActivate: TDXNotifyEvent read FOnActivate write FOnActivate;
    property OnDeactivate: TDXNotifyEvent read FOnDeactivate write FOnDeactivate;
  end;

  TDXWindowBorderIcon = (biIcon, biClose, biMinimize, biMaximize);
  TDXWindowBorderIcons = set of TDXWindowBorderIcon;

  TDXWindow = class(TDXCustomWindow)
  private
    FIcons: TDXImageList;
    FIconIndex: Integer;
    FBorderIcons: TDXWindowBorderIcons;
  private
    procedure SetIconIndex(const Value: Integer);
    procedure SetIcons(const Value: TDXImageList);
    procedure SetBorderIcons(const Value: TDXWindowBorderIcons);
  protected
    procedure CMFontChanged(var Message: TCMTextControlFontChanged); override;
    procedure CMCaptionChanged(var Message: TCMTextControlCaptionChanged); override;
    procedure CMActivate(var Message: TCMWindowActivate); override;
    procedure CMDeactivate(var Message: TCMWindowDeactivate); override;
    procedure CMChangeNotification(var Message: TCMChangeNotification); override;
  protected
    function CalculateClientRect(const ABoundsRect: TRect): TRect; override;
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager);
    destructor Destroy; override;
  published
    property Font;
    property Caption;
    property ParentFont;
    property Icons: TDXImageList read FIcons write SetIcons;
    property IconIndex: Integer read FIconIndex write SetIconIndex default -1;
    property BorderIcons: TDXWindowBorderIcons read FBorderIcons write SetBorderIcons
      default [biIcon, biClose];
  end;

implementation

uses
  System.Types, System.SysUtils, DXGUIRenderInterface, DXGUIFont;

{ TDXCustomWindow }

procedure TDXCustomWindow.CMActivate(var Message: TCMWindowActivate);
begin
  FIsActive := true;
  if Assigned(FOnActivate) then FOnActivate(Self);
end;

procedure TDXCustomWindow.CMDeactivate(var Message: TCMWindowDeactivate);
begin
  FIsActive := false;
  if Assigned(FOnDeactivate) then FOnDeactivate(Self);
end;

procedure TDXCustomWindow.CMLButtonDown(var Message: TCMLButtonDown);
begin
  inherited;
  if (AbsoluteEnabled) and (FAllowDrag) then
  begin
    if (not FAllowClientDrag) then
    begin
      if (ClientRect.Contains(Point(Message.Pos.X + AbsoluteBoundsRect.Left,
        Message.Pos.Y + AbsoluteBoundsRect.Top))) then Exit;
    end;
    FDragActive := true;
    FDragStart := Message.Pos;
    FDragStart.X := FDragStart.X - Left;
    FDragStart.Y := FDragStart.Y - Top;
  end;
end;

procedure TDXCustomWindow.CMLButtonUp(var Message: TCMLButtonUp);
begin
  inherited;
  FDragActive := false;
end;

procedure TDXCustomWindow.CMMouseMove(var Message: TCMMouseMove);
begin
  inherited;
  if (AbsoluteEnabled) and (FDragActive) then
  begin
    Left := Message.Pos.X - FDragStart.X;
    Top := Message.Pos.Y - FDragStart.Y;
  end;
end;

constructor TDXCustomWindow.Create(Manager: TDXGUIManager);
begin
  inherited Create(Manager, nil);
  FAllowDrag := true;
  FAllowClientDrag := false;
end;

destructor TDXCustomWindow.Destroy;
begin

  inherited;
end;

{ TDXWindow }

function TDXWindow.CalculateClientRect(const ABoundsRect: TRect): TRect;
begin
  Result := Rect(ABoundsRect.Left + 8, ABoundsRect.Top + 31, AboundsRect.Right - 8,
    ABoundsRect.Bottom - 8);
end;

procedure TDXWindow.CMActivate(var Message: TCMWindowActivate);
begin
  inherited;
  AlphaBlend := 255;
end;

procedure TDXWindow.CMCaptionChanged(var Message: TCMTextControlCaptionChanged);
begin
  inherited;
  Invalidate;
end;

procedure TDXWindow.CMChangeNotification(var Message: TCMChangeNotification);
begin
  inherited;
  if (Message.Sender = FIcons) then
  begin
    Invalidate;
  end;
end;

procedure TDXWindow.CMDeactivate(var Message: TCMWindowDeactivate);
begin
  inherited;
  AlphaBlend := 235;
end;

procedure TDXWindow.CMFontChanged(var Message: TCMTextControlFontChanged);
begin
  inherited;
  Invalidate;
end;

constructor TDXWindow.Create(Manager: TDXGUIManager);
begin
  inherited Create(Manager);
  FIconIndex := -1;
  FBorderIcons := [biIcon, biClose];
end;

destructor TDXWindow.Destroy;
begin
  if Assigned(FIcons) then FIcons.RemoveChangeObserver(Self);
  inherited;
end;

procedure TDXWindow.Paint(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
  R: TRect;
begin
  Renderer := Manager.RenderInterface.Renderer;
  Renderer.FillRect(BoundsRect, DXCOLOR_RGBA(99, 180, 251, 255));
  Renderer.FillRect(ClientRect, DXCOLOR_RGBA(223, 233, 245, 255));
  Renderer.DrawRect(BoundsRect, DXCOLOR_RGBA(76, 138, 192, 255));
  ClientRect.Inflate(1, 1);
  Renderer.DrawRect(ClientRect, DXCOLOR_RGBA(76, 138, 192, 255));
  BoundsRect.Height := 30;
  Font.DrawText(BoundsRect, Caption, DXCOLOR_RGBA(0, 0, 0, 255), alCenter, vaCenter);
  if (biIcon in FBorderIcons) and Assigned(FIcons) and (FIconIndex >= 0) then
  begin
    FIcons.DrawCentered(FIconIndex, Rect(BoundsRect.Left + 7, BoundsRect.Top + 2,
      BoundsRect.Left + 7 + FIcons.Width, BoundsRect.Bottom - 0));
  end;

  if (biClose in FBorderIcons) then
  begin
    R := Rect(BoundsRect.Right - 7 - 45, BoundsRect.Top + 1, BoundsRect.Right - 7, BoundsRect.Top + 1 + 20);
    Renderer.FillRect(R, DXCOLOR_RGBA(199, 80, 80, 255));
    Font.DrawText(R, 'X', clWhite, alCenter, vaCenter, false);
  end;

end;

procedure TDXWindow.SetBorderIcons(const Value: TDXWindowBorderIcons);
begin
  if (FBorderIcons <> Value) then
  begin
    FBorderIcons := Value;
    Invalidate;
  end;
end;

procedure TDXWindow.SetIconIndex(const Value: Integer);
begin
  if (FIconIndex <> Value) then
  begin
    FIconIndex := Value;
    Invalidate;
  end;
end;

procedure TDXWindow.SetIcons(const Value: TDXImageList);
begin
  if (FIcons <> Value) then
  begin
    if Assigned(FIcons) then
    begin
      FIcons.RemoveChangeObserver(Self);
    end;
    FIcons := Value;
    if Assigned(FIcons) then
    begin
      FIcons.InsertChangeObserver(Self);
    end;
    Invalidate;
  end;
end;

initialization
  RegisterClass(TDXWindow);

end.
