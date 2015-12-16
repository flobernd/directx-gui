unit DXGUIPanel;

interface

uses
  Winapi.Windows, DXGUIFramework, DXGUITypes, DXGUITextControl;

type
  TDXCustomPanel = class(TDXCustomTextControl)
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Constraints;
    property Margins;
    property Padding;
  end;

  TDXPanel = class(TDXCustomPanel)
  private
    FShowCaption: Boolean;
  private
    procedure SetShowCaption(const Value: Boolean);
  protected
    procedure Paint(BoundsRect, ClientRect: TRect); override;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  published
    property Font;
    property Caption;
    property ParentFont;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption default true;
  end;

implementation

uses
  System.Classes, DXGUIRenderInterface, DXGUIFont;

{ TDXCustomPanel }

constructor TDXCustomPanel.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);

end;

{ TDXPanel }

constructor TDXPanel.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FInvalidateEvents := FInvalidateEvents + [ieEnabledChanged];
  FShowCaption := true;
end;

destructor TDXPanel.Destroy;
begin

  inherited;
end;

procedure TDXPanel.Paint(BoundsRect, ClientRect: TRect);
var
  Renderer: TDXRenderer;
begin
  Renderer := Manager.RenderInterface.Renderer;
  Renderer.DrawRect(BoundsRect, DXCOLOR_RGBA(172, 172, 172, 255));
  BoundsRect.Top    := BoundsRect.Top    + 1;
  BoundsRect.Left   := BoundsRect.Left   + 1;
  BoundsRect.Bottom := BoundsRect.Bottom - 1;
  BoundsRect.Right  := BoundsRect.Right  - 1;
  //Renderer.FillRect(BoundsRect, DXCOLOR_RGBA(40, 40, 40, 255));
  if (FShowCaption) then
  begin
    Font.DrawText(BoundsRect, Caption, DXCOLOR_RGBA(0, 0, 0, 255), alCenter, vaCenter);
  end;
end;

procedure TDXPanel.SetShowCaption(const Value: Boolean);
begin
  if (FShowCaption <> Value) then
  begin
    FShowCaption := Value;
    Invalidate;
  end;
end;

initialization
  RegisterClass(TDXPanel);

end.
