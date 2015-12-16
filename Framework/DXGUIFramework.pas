unit DXGUIFramework;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Generics.Collections,
  DXGUIRenderInterface;

////////////////////////////////////////////////////////////////////////////////////////////////////
///  TODO:  ////////////////////////////////////////////////////////////////////////////////////////
///
/// [ ] TDXObject Klasse erstellen und Change & Destroy Notifications implementieren
/// [ ] TDXPersistent von TDXObject ableiten und Methoden von TPersistent implementieren
/// [ ] TDXComponent von TDXPersistent ableiten und benötigte Methoden von TComponent
///     implementieren
/// [ ] Momentane TDXComponent.ValidateContainer und ValidateInsert Methoden leeren
/// [ ] Eigene De/Serialization Technik auf Grundlage von TDXPersistent implementieren
///
/// [ ] Controls nicht komplett invalidieren, sondern ermöglichen einzelne Bereiche des Controls
///     neu zeichen zu lassen (per Stencil Buffer, GDI Clipping, etc.)
///
/// [ ] Color Property in TDXFont einbauen
///
/// [ ] Coordinaten von BoundRects mit gezeichneten DrawRects, DrawLine, etc. abgleichen.
///     Siehe PageControl Pixeldifferenzen
///     [ ] Die Verwendung von TRect an ALLEN Stellen prüfen. Windows definiert den Right und
///         Bottom Point als nicht mehr im Rect liegend
///
////////////////////////////////////////////////////////////////////////////////////////////////////

{ Interface }

{$REGION 'Messages: Message Values'}
const
  { Basic Framework Message     }
  CM_GUIFRAMEWORK               = WM_USER         + $4820;
  CM_CHANGE_NOTIFICATION        = CM_GUIFRAMEWORK + $0001;
  CM_DESTROY_NOTIFICATION       = CM_GUIFRAMEWORK + $0002;
  { Basic Control Messages      }
  CM_CONTROL_BOUNDS_CHANGED     = CM_GUIFRAMEWORK + $0003;
  CM_CONTROL_PARENT_CHANGED     = CM_GUIFRAMEWORK + $0004;
  CM_CONTROL_CHILD_INSERTED     = CM_GUIFRAMEWORK + $0005;
  CM_CONTROL_CHILD_REMOVED      = CM_GUIFRAMEWORK + $0006;
  CM_CONTROL_VISIBLE_CHANGED    = CM_GUIFRAMEWORK + $0007;
  CM_CONTROL_ENABLED_CHANGED    = CM_GUIFRAMEWORK + $0008;
  { Basic Window Messages       }
  CM_WINDOW_ACTIVATE            = CM_GUIFRAMEWORK + $0009;
  CM_WINDOW_DEACTIVATE          = CM_GUIFRAMEWORK + $000A;
  { Mouse Event Messages        }
  CM_LBUTTONDBLCLK              = CM_GUIFRAMEWORK + $000B;
  CM_LBUTTONDOWN                = CM_GUIFRAMEWORK + $000C;
  CM_LBUTTONUP                  = CM_GUIFRAMEWORK + $000D;
  CM_MBUTTONDBLCLK              = CM_GUIFRAMEWORK + $000E;
  CM_MBUTTONDOWN                = CM_GUIFRAMEWORK + $000F;
  CM_MBUTTONUP                  = CM_GUIFRAMEWORK + $0010;
  CM_RBUTTONDBLCLK              = CM_GUIFRAMEWORK + $0011;
  CM_RBUTTONDOWN                = CM_GUIFRAMEWORK + $0012;
  CM_RBUTTONUP                  = CM_GUIFRAMEWORK + $0013;
  CM_MOUSEMOVE                  = CM_GUIFRAMEWORK + $0014;
  CM_MOUSECLICK                 = CM_GUIFRAMEWORK + $0015;
  CM_MOUSE_ENTER                = CM_GUIFRAMEWORK + $0016;
  CM_MOUSE_LEAVE                = CM_GUIFRAMEWORK + $0017;
  CM_MOUSEWHEEL_UP              = CM_GUIFRAMEWORK + $0018;
  CM_MOUSEWHEEL_DOWN            = CM_GUIFRAMEWORK + $0019;
{$ENDREGION}

type
  IDXWindow = interface['{BA415125-3A7B-4E3D-ACA5-9E8FE9D3F8CA}'] end;

  TDXComponent = class;
  TDXControl = class;

  TDXMouseButton = (mbLeft, mbRight, mbMiddle);

  {$REGION 'Messages: Message Structs'}
  TCMSimpleMessage = record
    MessageId: Cardinal;
  end;
  TCMChangeNotification = record
    MessageId: Cardinal;
    Sender: TObject;
  end;
  TCMDestroyNotification = record
    MessageId: Cardinal;
    Sender: TObject;
  end;
  TCMControlBoundsChanged = record
    MessageId: Cardinal;
    BoundsRectOld: TRect;
    BoundsRectNew: TRect;
  end;
  TCMControlParentChanged = record
    MessageId: Cardinal;
    ParentOld: TDXControl;
    ParentNew: TDXControl;
  end;
  TCMControlChildInserted = record
    MessageId: Cardinal;
    Control: TDXControl;
  end;
  TCMControlChildRemoved = record
    MessageId: Cardinal;
    Control: TDXControl;
  end;
  TCMControlVisibleChanged = TCMSimpleMessage;
  TCMControlEnabledChanged = TCMSimpleMessage;

  TCMWindowActivate = TCMSimpleMessage;
  TCMWindowDeactivate = TCMSimpleMessage;

  TCMMouse = record
    MessageId: Cardinal;
    Pos: TPoint;
    KeyState: Word;
  end;
  TCMLButtonDblClk = TCMMouse;
  TCMLButtonDown   = TCMMouse;
  TCMLButtonUp     = TCMMouse;
  TCMMButtonDblClk = TCMMouse;
  TCMMButtonDown   = TCMMouse;
  TCMMButtonUp     = TCMMouse;
  TCMRButtonDblClk = TCMMouse;
  TCMRButtonDown   = TCMMouse;
  TCMRButtonUp     = TCMMouse;
  TCMMouseMove     = TCMMouse;
  TCMMouseClick    = TCMMouse;
  TCMMouseEnter    = TCMSimpleMessage;
  TCMMouseLeave    = TCMSimpleMessage;
  TCMMouseWheel = record
    MessageId: Cardinal;
    Pos: TPoint;
    KeyState: Word;
    Amount: DWord;
  end;
  TCMMouseWheelUp = TCMMouseWheel;
  TCMMouseWheelDown = TCMMouseWheel;
  {$ENDREGION}

  TDXGUIManager = class(TObject)
  private
    FRenderInterface: TDXRenderInterface;
    FWindows: TList<TDXControl>;
    FActiveWindow: TDXControl;
    FMouseButtonDown: Boolean;
    FActiveMouseControl: TDXControl;
    FActiveMouseControlBounds: TRect;
    FNeedsRepaint: Boolean;
  private
    function GetWindow(Index: Integer): TDXControl;
    function GetWindowCount: Integer;
  private
    procedure ControlDestroyed(AControl: TDXControl);
  private
    procedure InsertWindow(AWindow: TDXControl);
    procedure RemoveWindow(AWindow: TDXControl);
  public
    function GetControlAtAbsolute(X, Y: Integer;
      const Recursive: Boolean = true;
      const CheckVisibility: Boolean = true): TDXControl;
    function GetControlAt(X, Y: Integer;
      const Recursive: Boolean = true;
      const CheckVisibility: Boolean = true): TDXControl;
    function GetWindowAtAbsolute(X, Y: Integer;
      const CheckVisibility: Boolean = true): TDXControl;
    function GetWindowAt(X, Y: Integer;
      const CheckVisibility: Boolean = true): TDXControl;
  public
    procedure ActivateWindow(Window: TDXControl);
    procedure FlashWindow(Window: TDXControl);
    procedure ShowWindow(Window: TDXControl);
    procedure ShowWindowModal(Parent, Window: TDXControl);
  public
    function PerformWindowMessage(Msg: TMsg): Boolean;
    function PerformMouseDown(X, Y: Integer; Button: TDXMouseButton; KeyState: Word): Boolean;
    function PerformMouseUp(X, Y: Integer; Button: TDXMouseButton; KeyState: Word): Boolean;
    function PerformDoubleClick(X, Y: Integer; Button: TDXMouseButton; KeyState: Word): Boolean;
    function PerformMouseMove(X, Y: Integer; KeyState: Word): Boolean;
    function PerformMouseWheelUp(X, Y: Integer; KeyState: Word; Amount: DWord): Boolean;
    function PerformMouseWheelDown(X, Y: Integer; KeyState: Word;  Amount: DWord): Boolean;
    function PerformPaint: Boolean;
  public
    constructor Create(RenderInterface: TDXRenderInterface);
    destructor Destroy; override;
  public
    property RenderInterface: TDXRenderInterface read FRenderInterface;
    property Windows[Index: Integer]: TDXControl read GetWindow;
    property WindowCount: Integer read GetWindowCount;
    property ActiveWindow: TDXControl read FActiveWindow;
    property ActiveMouseControl: TDXControl read FActiveMouseControl;
    property NeedsRepaint: Boolean read FNeedsRepaint;
  end;

  TDXPersistent = class(TPersistent)
  private
    FManager: TDXGUIManager;
    FChangeObservers: TList<TObject>;
    FDestroyObservers: TList<TObject>;
  protected
    procedure SendChangeNotifications; virtual;
    procedure SendDestroyNotifications; virtual;
  public
    procedure InsertChangeObserver(AObserver: TObject);
    procedure RemoveChangeObserver(AObserver: TObject);
    procedure InsertDestroyObserver(AObserver: TObject);
    procedure RemoveDestroyObserver(AObserver: TObject);
  public
    constructor Create(Manager: TDXGUIManager);
    destructor Destroy; override;
  public
    property Manager: TDXGUIManager read FManager;
  end;

  TDXComponent = class(TComponent)
  private
    FManager: TDXGUIManager;
    FChangeObservers: TList<TObject>;
    FDestroyObservers: TList<TObject>;
  protected
    procedure ValidateContainer(AComponent: TComponent); override;
    procedure ValidateInsert(AComponent: TComponent); override;
  protected
    procedure SendChangeNotifications; virtual;
    procedure SendDestroyNotifications; virtual;
  public
    procedure InsertChangeObserver(AObserver: TObject);
    procedure RemoveChangeObserver(AObserver: TObject);
    procedure InsertDestroyObserver(AObserver: TObject);
    procedure RemoveDestroyObserver(AObserver: TObject);
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent); reintroduce; {TODO: ?}
    destructor Destroy; override;
  public
    property Manager: TDXGUIManager read FManager;
  end;

  TDXConstraintSize = 0..MaxInt;

  TDXSizeConstraints = class(TDXPersistent)
  private
    FMaxHeight: TDXConstraintSize;
    FMaxWidth: TDXConstraintSize;
    FMinHeight: TDXConstraintSize;
    FMinWidth: TDXConstraintSize;
  private
    procedure SetConstraints(Index: Integer; Value: TDXConstraintSize);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(Manager: TDXGUIManager); virtual;
  published
    property MaxHeight: TDXConstraintSize index 0 read FMaxHeight write SetConstraints default 0;
    property MaxWidth: TDXConstraintSize index 1 read FMaxWidth write SetConstraints default 0;
    property MinHeight: TDXConstraintSize index 2 read FMinHeight write SetConstraints default 0;
    property MinWidth: TDXConstraintSize index 3 read FMinWidth write SetConstraints default 0;
  end;

  TDXMarginSize = 0..MaxInt;

  TDXMargins = class(TDXPersistent)
  private
    FLeft: TDXMarginSize;
    FTop: TDXMarginSize;
    FRight: TDXMarginSize;
    FBottom: TDXMarginSize;
  private
    procedure SetMargin(Index: Integer; Value: TDXMarginSize);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  protected
    class procedure InitDefaults(Margins: TDXMargins); virtual;
  public
    constructor Create(Manager: TDXGUIManager);
  published
    property Left: TDXMarginSize index 0 read FLeft write SetMargin default 3;
    property Top: TDXMarginSize index 1 read FTop write SetMargin default 3;
    property Right: TDXMarginSize index 2 read FRight write SetMargin default 3;
    property Bottom: TDXMarginSize index 3 read FBottom write SetMargin default 3;
  end;

  TDXPadding = class(TDXMargins)
  protected
    class procedure InitDefaults(Margins: TDXMargins); override;
  published
    property Left default 0;
    property Top default 0;
    property Right default 0;
    property Bottom default 0;
  end;

  TDXControlStyles = (csAcceptChildControls);
  TDXControlStyle = set of TDXControlStyles;

  TDXInvalidateEvent = (ieAlphaBlendChanged, ieEnabledChanged, ieVisibleChanged,
    iePressedChanged, ieMouseFocusChanged);
  TDXInvalidateEvents = set of TDXInvalidateEvent;

  TDXNotifyEvent = procedure(Sender: TObject) of object;

  TDXCanResizeEvent = procedure(Sender: TObject; var NewWidth, NewHeight: Integer;
    var Resize: Boolean) of object;
  TDXConstrainedResizeEvent = procedure(Sender: TObject; var MinWidth, MinHeight, MaxWidth,
    MaxHeight: Integer) of object;

  TDXMouseEvent = procedure(Sender: TObject; Button: TDXMouseButton; X, Y: Integer) of object;
  TDXMouseMoveEvent = procedure(Sender: TObject; X, Y: Integer) of object;

  TDXEffectEventReturn = (eerAnotherPass, eerContinue);
  TDXPrePaintEvent = procedure(Sender: TObject; Pass: Cardinal) of object;
  TDXPostPaintEvent = function(Sender: TObject; Pass: Cardinal): TDXEffectEventReturn of object;
  TDXPreFlipEvent = procedure(Sender: TObject; Pass: Cardinal) of object;
  TDXPostFlipEvent = function(Sender: TObject; Pass: Cardinal): TDXEffectEventReturn of object;

  TDXAlign = (alNone, alTop, alBottom, alLeft, alRight, alClient);
  TDXAlignSet = set of TDXAlign;
  TDXAnchorKind = (akLeft, akTop, akRight, akBottom);
  TDXAnchors = set of TDXAnchorKind;

  TDXControl = class(TDXComponent)
  private
    FSurface: TDXSurface;
    FParent: TDXControl;
    FControls: TList<TDXControl>;
    FLeft: Integer;
    FTop: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FAlphaBlend: Byte;
    FVisible: Boolean;
    FEnabled: Boolean;
    //
    FAlign: TDXAlign;
    FAlignWithMargins: Boolean;
    FAutoSize: Boolean;
    FAnchors: TDXAnchors;
    FConstraints: TDXSizeConstraints;
    FMargins: TDXMargins;
    FPadding: TDXPadding;
    FAligning: Boolean;
    FExplicitLeft: Integer;
    FExplicitTop: Integer;
    FExplicitWidth: Integer;
    FExplicitHeight: Integer;
    FAnchorRect: TRect;
    //
    FBoundsRect: TRect;
    FClientRect: TRect;
    FAbsoluteBoundsRect: TRect;
    FAbsoluteClientRect: TRect;
    FRenderBoundsRect: TRect;
    FRenderClientRect: TRect;
    FFlipRect: TRect;
    FAbsoluteVisible: Boolean;
    FAbsoluteEnabled: Boolean;
    //
    FHasMouseFocus: Boolean;
    FIsPressed: Boolean;
    FHasDirtyRegions: Boolean;
  private
    FOnCanResize: TDXCanResizeEvent;
    FOnResize: TDXNotifyEvent;
    FOnConstrainedResize: TDXConstrainedResizeEvent;
    FOnClick: TDXNotifyEvent;
    FOnDblClick: TDXNotifyEvent;
    FOnMouseDown: TDXMouseEvent;
    FOnMouseUp: TDXMouseEvent;
    FOnMouseMove: TDXMouseMoveEvent;
    FOnMouseEnter: TDXNotifyEvent;
    FOnMouseLeave: TDXNotifyEvent;
    FOnPrePaintEvent: TDXPrePaintEvent;
    FOnPostPaintEvent: TDXPostPaintEvent;
    FOnPreFlipEvent: TDXPreFlipEvent;
    FOnPostFlipEvent: TDXPostFlipEvent;
  private
    function GetControl(Index: Integer): TDXControl;
    function GetControlCount: Integer;
  private
    procedure SetParent(const Value: TDXControl);
    procedure SetLeft(const Value: Integer);
    procedure SetTop(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure SetVisible(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
    procedure SetAlphaBlend(const Value: Byte);
    procedure SetAlign(const Value: TDXAlign);
    procedure SetAlignWithMargins(const Value: Boolean);
    procedure SetAutoSize(const Value: Boolean);
    procedure SetAnchors(const Value: TDXAnchors);
    procedure SetConstraints(const Value: TDXSizeConstraints);
    procedure SetMargins(const Value: TDXMargins);
    procedure SetPadding(const Value: TDXPadding);
  private
    procedure Insert(AControl: TDXControl);
    procedure Remove(AControl: TDXControl);
  private
    function CheckNewSize(var NewWidth, NewHeight: Integer): Boolean;
    function DoCanResize(var NewWidth, NewHeight: Integer): Boolean;
    function DoCanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
    procedure DoConstrainedResize(var NewWidth, NewHeight: Integer);
    procedure Realign;
    procedure RequestAlign;
    procedure AlignControl(AControl: TDXControl);
    procedure ResizeAnchoredControls;
  private
    procedure UpdateAbsoluteRects;
    procedure UpdateAbsoluteEnabled;
    procedure UpdateAbsoluteVisible;
  private
    procedure Render;
  protected
    procedure CMChangeNotification(var Message: TCMChangeNotification);
      message CM_CHANGE_NOTIFICATION;
    procedure CMLButtonDblClk(var Message: TCMLButtonDblClk); message CM_LBUTTONDBLCLK;
    procedure CMLButtonDown(var Message: TCMLButtonDown); message CM_LBUTTONDOWN;
    procedure CMLButtonUp(var Message: TCMLButtonUp); message CM_LBUTTONUP;
    procedure CMMButtonDblClk(var Message: TCMMButtonDblClk); message CM_MBUTTONDBLCLK;
    procedure CMMButtonDown(var Message: TCMMButtonDown); message CM_MBUTTONDOWN;
    procedure CMMButtonUp(var Message: TCMMButtonUp); message CM_MBUTTONUP;
    procedure CMRButtonDblClk(var Message: TCMRButtonDblClk); message CM_RBUTTONDBLCLK;
    procedure CMRButtonDown(var Message: TCMRButtonDown); message CM_RBUTTONDOWN;
    procedure CMRButtonUp(var Message: TCMRButtonUp); message CM_RBUTTONUP;
    procedure CMMouseClick(var Message: TCMMouseClick); message CM_MOUSECLICK;
    procedure CMMouseMove(var Message: TCMMouseMove); message CM_MOUSEMOVE;
    procedure CMMouseEnter(var Message: TCMMouseEnter); message CM_MOUSE_ENTER;
    procedure CMMouseLeave(var Message: TCMMouseLeave); message CM_MOUSE_LEAVE;
    procedure CMMouseWheelUp(var Message: TCMMouseWheelUp); message CM_MOUSEWHEEL_UP;
    procedure CMMouseWheelDown(var Message: TCMMouseWheelDown); message CM_MOUSEWHEEL_DOWN;
  protected
    FControlStyle: TDXControlStyle;
    FInvalidateEvents: TDXInvalidateEvents;
  protected
    procedure ValidateContainer(AComponent: TComponent); override;
    procedure ValidateInsert(AComponent: TComponent); override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
  protected
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; virtual;
    function CanResize(var NewWidth, NewHeight: Integer): Boolean; virtual;
  protected
    function CalculateClientRect(const ABoundsRect: TRect): TRect; virtual;
    procedure Paint(BoundsRect, ClientRect: TRect); virtual; abstract;
  protected
    procedure Invalidate;
    procedure InvalidateRect(R: TRect);
    procedure InvalidateParent;
    procedure InvalidateParentRect(R: TRect);
  public
    function HasParent: Boolean; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  public
    procedure InsertControl(AControl: TDXControl);
    procedure RemoveControl(AControl: TDXControl);
  public
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); virtual;
  public
    function GetControlAtAbsolute(X, Y: Integer; const Recursive: Boolean = true;
      const CheckVisibility: Boolean = true): TDXControl;
    function GetControlAt(X, Y: Integer; const Recursive: Boolean = true;
      const CheckVisibility: Boolean = true): TDXControl;
  public
    procedure Show;
    procedure Hide;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  protected
    property Align: TDXAlign read FAlign write SetAlign default alNone;
    property AlignWithMargins: Boolean read FAlignWithMargins write SetAlignWithMargins
      default false;
    property AutoSize: Boolean read FAutoSize write SetAutoSize default false;
    property Anchors: TDXAnchors read FAnchors write SetAnchors default [akLeft, akTop];
    property Constraints: TDXSizeConstraints read FConstraints write SetConstraints;
    property Margins: TDXMargins read FMargins write SetMargins;
    property Padding: TDXPadding read FPadding write SetPadding;
  public
    property Parent: TDXControl read FParent write SetParent;
    property Controls[Index: Integer]: TDXControl read GetControl;
    property ControlCount: Integer read GetControlCount;
    property ControlStyle: TDXControlStyle read FControlStyle;
    property BoundsRect: TRect read FBoundsRect;
    property ClientRect: TRect read FClientRect;
    property AbsoluteBoundsRect: TRect read FAbsoluteBoundsRect;
    property AbsoluteClientRect: TRect read FAbsoluteClientRect;
    property AbsoluteVisible: Boolean read FAbsoluteVisible;
    property AbsoluteEnabled: Boolean read FAbsoluteEnabled;
    property HasMouseFocus: Boolean read FHasMouseFocus;
    property IsPressed: Boolean read FIsPressed;
  published
    property Left: Integer read FLeft write SetLeft;
    property Top: Integer read FTop write SetTop;
    property Width: Integer read FWidth write SetWidth;
    property Height: Integer read FHeight write SetHeight;
    property Visible: Boolean read FVisible write SetVisible default true;
    property Enabled: Boolean read FEnabled write SetEnabled default true;
    property AlphaBlend: Byte read FAlphaBlend write SetAlphaBlend default 255;
  published
    property OnCanResize: TDXCanResizeEvent read FOnCanResize write FOnCanResize;
    property OnResize: TDXNotifyEvent read FOnResize write FOnResize;
    property OnConstrainedResize: TDXConstrainedResizeEvent read FOnConstrainedResize write
      FOnConstrainedResize;
    property OnClick: TDXNotifyEvent read FOnClick write FOnClick;
    property OnDblClick: TDXNotifyEvent read FOnDblClick write FOnDblClick;
    property OnMouseDown: TDXMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp: TDXMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseMove: TDXMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnMouseEnter: TDXNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseLeave: TDXNotifyEvent read FOnMouseLeave write FOnMouseLeave;
    property OnPrePaint: TDXPrePaintEvent read FOnPrePaintEvent write FOnPrePaintEvent;
    property OnPostPaint: TDXPostPaintEvent read FOnPostPaintEvent write FOnPostPaintEvent;
    property OnPreFlip: TDXPreFlipEvent read FOnPreFlipEvent write FOnPreFlipEvent;
    property OnPostFlip: TDXPostFlipEvent read FOnPostFlipEvent write FOnPostFlipEvent;
  end;

implementation

uses
  System.Types, DXGUITypes, DXGUIMessages, DXGUIExceptions;

resourcestring
  SErrorInvalidManagerInstance =
    'Could not create %s: The given instance of TDXGUIManager is not initialized.';
  SInvalidContainerEx = '%s is not a valid container for %s components.';
  SInvalidInsertEx    = '%s can not be inserted into a %s container.';
  SInvalidContainer   = '%s can not contain any child components.';
  SInvalidInsert      = '%s can not be inserted into any container component.';
  SInvalidWindowControl = '%s is not a valid window class.';

{ TDXGUIManager }

procedure TDXGUIManager.ActivateWindow(Window: TDXControl);
var
  Message: TCMSimpleMessage;
begin
  if Assigned(FActiveWindow) then
  begin
    Message.MessageId := CM_WINDOW_DEACTIVATE;
    FActiveWindow.Dispatch(Message);
  end;
  if Assigned(Window) then
  begin
    if (not Supports(Window, IDXWindow)) then
    begin
      raise EDXInvalidArgumentException.CreateResFmt(@SInvalidWindowControl, [Window.ClassName]);
    end;
    if (FWindows.Contains(Window)) then
    begin
      Message.MessageId := CM_WINDOW_ACTIVATE;
      Window.Dispatch(Message);
      FWindows.Remove(Window);
      FWindows.Add(Window);
    end;
  end;
  FActiveWindow := Window;
end;

procedure TDXGUIManager.ControlDestroyed(AControl: TDXControl);
begin
  // INFO: Dieser Callback wird von jeder TDXControl Instanz aufgerufen, bevor Diese zerstört wird.
  if (AControl = FActiveMouseControl) then
  begin
    FMouseButtonDown := false;
    FActiveMouseControl := nil;
  end;
end;

constructor TDXGUIManager.Create(RenderInterface: TDXRenderInterface);
begin
  inherited Create;
  FRenderInterface := RenderInterface;
  FWindows := TList<TDXControl>.Create;
end;

destructor TDXGUIManager.Destroy;
begin
  while (FWindows.Count > 0) do
  begin
    FWindows.Last.Free;
  end;
  FWindows.Free;
  inherited;
end;

procedure TDXGUIManager.FlashWindow(Window: TDXControl);
begin
  // TODO: Implement
end;

function TDXGUIManager.GetControlAt(X, Y: Integer; const Recursive,
  CheckVisibility: Boolean): TDXControl;
begin
  Result := GetControlAtAbsolute(X, Y, Recursive, CheckVisibility);
end;

function TDXGUIManager.GetControlAtAbsolute(X, Y: Integer; const Recursive,
  CheckVisibility: Boolean): TDXControl;
var
  I: Integer;
begin
  Result := nil;
  for I := FWindows.Count - 1 downto 0 do
  begin
    Result := FWindows[I].GetControlAtAbsolute(X, Y, Recursive, CheckVisibility);
    if Assigned(Result) then Break;
  end;
end;

function TDXGUIManager.GetWindow(Index: Integer): TDXControl;
begin
  Result := FWindows[Index];
end;

function TDXGUIManager.GetWindowAt(X, Y: Integer; const CheckVisibility: Boolean): TDXControl;
begin
  Result := GetControlAtAbsolute(X, Y, CheckVisibility);
end;

function TDXGUIManager.GetWindowAtAbsolute(X, Y: Integer;
  const CheckVisibility: Boolean): TDXControl;
begin
  Result := GetControlAtAbsolute(X, Y, false, CheckVisibility);
end;

function TDXGUIManager.GetWindowCount: Integer;
begin
  Result := FWindows.Count;
end;

procedure TDXGUIManager.InsertWindow(AWindow: TDXControl);
begin
  FWindows.Insert(0, AWindow);
  if (not Assigned(FActiveWindow)) then ActivateWindow(AWindow);
end;

function TDXGUIManager.PerformDoubleClick(X, Y: Integer; Button: TDXMouseButton;
  KeyState: Word): Boolean;
var
  C: TDXControl;
  Message: TCMMouse;
begin
  C := GetControlAtAbsolute(X, Y, true, true);
  Result := Assigned(C);
  if Result and (C.AbsoluteEnabled) then
  begin
    case Button of
      mbLeft  : Message.MessageId := CM_LBUTTONDBLCLK;
      mbMiddle: Message.MessageId := CM_MBUTTONDBLCLK;
      mbRight : Message.MessageId := CM_RBUTTONDBLCLK;
    end;
    Message.Pos.X := X - C.AbsoluteClientRect.Left;
    Message.Pos.Y := Y - C.AbsoluteClientRect.Top;
    Message.KeyState := KeyState;
    C.Dispatch(Message);
  end;
end;

function TDXGUIManager.PerformMouseDown(X, Y: Integer; Button: TDXMouseButton;
  KeyState: Word): Boolean;
var
  C, W: TDXControl;
  Message: TCMMouse;
begin
  C := GetControlAtAbsolute(X, Y, true, true);
  Result := Assigned(C);
  if Result then
  begin
    if (Button = mbLeft) then
    begin
      FMouseButtonDown := true;
      FActiveMouseControl := C;
      FActiveMouseControlBounds := FActiveMouseControl.AbsoluteBoundsRect;
    end;
    case Button of
      mbLeft  : Message.MessageId := CM_LBUTTONDOWN;
      mbMiddle: Message.MessageId := CM_MBUTTONDOWN;
      mbRight : Message.MessageId := CM_RBUTTONDOWN;
    end;
    Message.Pos.X := X - FActiveMouseControlBounds.Left;
    Message.Pos.Y := Y - FActiveMouseControlBounds.Top;
    Message.KeyState := KeyState;
    FActiveMouseControl.Dispatch(Message);
  end;
  W := GetWindowAtAbsolute(X, Y);
  if (FActiveWindow <> W) then
  begin
    ActivateWindow(W);
  end;
end;

function TDXGUIManager.PerformMouseMove(X, Y: Integer; KeyState: Word): Boolean;
var
  C: TDXControl;
  MessageA: TCMMouseMove;
  MessageB: TCMMouseEnter;
  MessageC: TCMMouseLeave;
begin
  C := GetControlAtAbsolute(X, Y, true, true);
  Result := (Assigned(C) or FMouseButtonDown);
  if (not FMouseButtonDown) then
  begin
    if (FActiveMouseControl <> C) then
    begin
      if Assigned(FActiveMouseControl) then
      begin
        MessageC.MessageId := CM_MOUSE_LEAVE;
        FActiveMouseControl.Dispatch(MessageC);
      end;
      FActiveMouseControl := C;
      if Assigned(FActiveMouseControl) then
      begin
        MessageB.MessageId := CM_MOUSE_ENTER;
        FActiveMouseControl.Dispatch(MessageB);
      end;
    end;
  end;
  if Assigned(FActiveMouseControl) then
  begin
    MessageA.MessageId := CM_MOUSEMOVE;
    MessageA.Pos.X := X - FActiveMouseControlBounds.Left;
    MessageA.Pos.Y := Y - FActiveMouseControlBounds.Top;
    MessageA.KeyState := KeyState;
    FActiveMouseControl.Dispatch(MessageA);
  end;
end;

function TDXGUIManager.PerformMouseUp(X, Y: Integer; Button: TDXMouseButton;
  KeyState: Word): Boolean;
var
  C: TDXControl;
  Message: TCMMouse;
begin
  if Assigned(FActiveMouseControl) then
  begin
    case Button of
      mbLeft  : Message.MessageId := CM_LBUTTONUP;
      mbMiddle: Message.MessageId := CM_MBUTTONUP;
      mbRight : Message.MessageId := CM_RBUTTONUP;
    end;
    Message.Pos.X := X - FActiveMouseControlBounds.Left;
    Message.Pos.Y := Y - FActiveMouseControlBounds.Top;
    Message.KeyState := KeyState;
    FActiveMouseControl.Dispatch(Message);
  end;
  C := GetControlAtAbsolute(X, Y, true, true);
  Result := (Assigned(C) and (not FMouseButtonDown));
  FMouseButtonDown := false;
  if Assigned(C) and (C <> FActiveMouseControl) then
  begin
    PerformMouseMove(X, Y, KeyState);
  end;
end;

function TDXGUIManager.PerformMouseWheelDown(X, Y: Integer; KeyState: Word; Amount: DWord): Boolean;
var
  C: TDXControl;
  Message: TCMMouseWheelDown;
begin
  C := GetControlAtAbsolute(X, Y, true, true);
  Result := Assigned(C);
  if (Result) then
  begin
    Message.MessageId := CM_MOUSEWHEEL_DOWN;
    Message.Pos.X := X;
    Message.Pos.Y := Y;
    Message.KeyState := KeyState;
    Message.Amount := Amount;
    C.Dispatch(Message);
  end;
end;

function TDXGUIManager.PerformMouseWheelUp(X, Y: Integer; KeyState: Word; Amount: DWord): Boolean;
var
  C: TDXControl;
  Message: TCMMouseWheelUp;
begin
  C := GetControlAtAbsolute(X, Y, true, true);
  Result := Assigned(C);
  if (Result) then
  begin
    Message.MessageId := CM_MOUSEWHEEL_UP;
    Message.Pos.X := X;
    Message.Pos.Y := Y;
    Message.KeyState := KeyState;
    Message.Amount := Amount;
    C.Dispatch(Message);
  end;
end;

function TDXGUIManager.PerformPaint: Boolean;
var
  Window: TDXControl;
begin
  FRenderInterface.Renderer.BeginSequence;
  try
    FNeedsRepaint := false;
    for Window in FWindows do
    begin
      Window.Render;
      FNeedsRepaint := FNeedsRepaint or Window.FHasDirtyRegions;
    end;
  finally
    FRenderInterface.Renderer.EndSequence;
  end;
  Result := FNeedsRepaint;
end;

function TDXGUIManager.PerformWindowMessage(Msg: TMsg): Boolean;
var
  Pos: TPoint;
  KeyState: Word;
  WheelDelta: SmallInt;
begin
  Result := false;
  case Msg.message of
    WM_MOUSEMOVE,
    WM_LBUTTONDOWN  , WM_MBUTTONDOWN  , WM_RBUTTONDOWN,
    WM_LBUTTONUP    , WM_MBUTTONUP    , WM_RBUTTONUP,
    WM_LBUTTONDBLCLK, WM_MBUTTONDBLCLK, WM_RBUTTONDBLCLK:
      begin
        Pos := MAKEPOINTS(Msg.lParam);
        KeyState := GET_KEYSTATE_WPARAM(Msg.wParam);
        case Msg.message of
          WM_MOUSEMOVE    : Result := PerformMouseMove  (Pos.X, Pos.Y,           KeyState);
          WM_LBUTTONDOWN  : Result := PerformMouseDown  (Pos.X, Pos.Y, mbLeft  , KeyState);
          WM_MBUTTONDOWN  : Result := PerformMouseDown  (Pos.X, Pos.Y, mbMiddle, KeyState);
          WM_RBUTTONDOWN  : Result := PerformMouseDown  (Pos.X, Pos.Y, mbRight , KeyState);
          WM_LBUTTONUP    : Result := PerformMouseUp    (Pos.X, Pos.Y, mbLeft  , KeyState);
          WM_MBUTTONUP    : Result := PerformMouseUp    (Pos.X, Pos.Y, mbMiddle, KeyState);
          WM_RBUTTONUP    : Result := PerformMouseUp    (Pos.X, Pos.Y, mbRight , KeyState);
          WM_LBUTTONDBLCLK: Result := PerformDoubleClick(Pos.X, Pos.Y, mbLeft  , KeyState);
          WM_MBUTTONDBLCLK: Result := PerformDoubleClick(Pos.X, Pos.Y, mbMiddle, KeyState);
          WM_RBUTTONDBLCLK: Result := PerformDoubleClick(Pos.X, Pos.Y, mbRight , KeyState);
        end;
      end;
    WM_MOUSEWHEEL:
      begin
        Pos := MAKEPOINTS(Msg.lParam);
        if (not ScreenToClient(Msg.hwnd, Pos)) then Exit;
        KeyState := GET_KEYSTATE_WPARAM(Msg.wParam);
        WheelDelta := GET_WHEEL_DELTA_WPARAM(Msg.wParam);
        if (WheelDelta > 0) then
          Result := PerformMouseWheelUp(Pos.X, Pos.Y, KeyState, WheelDelta);
        if (WheelDelta < 0) then
          Result := PerformMouseWheelDown(Pos.X, Pos.Y, KeyState, -WheelDelta);
      end;
  end;
end;

procedure TDXGUIManager.RemoveWindow(AWindow: TDXControl);
begin
  FWindows.Remove(AWindow);
  if (AWindow = FActiveWindow) then
  begin
    FActiveWindow := nil;
  end;
end;

procedure TDXGUIManager.ShowWindow(Window: TDXControl);
begin
  if (not FWindows.Contains(Window)) then Exit;
  if (not Supports(Window, IDXWindow)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidWindowControl, [Window.ClassName]);
  end;
  ActivateWindow(Window);
  if (not Window.Visible) then Window.Show;
end;

procedure TDXGUIManager.ShowWindowModal(Parent, Window: TDXControl);
begin
  if (not FWindows.Contains(Window)) then Exit;
  if (not Supports(Window, IDXWindow)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidWindowControl, [Window.ClassName]);
  end;
  // TODO: Implement
end;

{ TDXPersistent }

constructor TDXPersistent.Create(Manager: TDXGUIManager);
begin
  inherited Create;
  if (not Assigned(Manager)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SErrorInvalidManagerInstance, [ClassName]);
  end;
  FManager := Manager;
  FChangeObservers := TList<TObject>.Create;
  FDestroyObservers := TList<TObject>.Create;
end;

destructor TDXPersistent.Destroy;
begin
  SendDestroyNotifications;
  FChangeObservers.Free;
  FDestroyObservers.Free;
  inherited;
end;

procedure TDXPersistent.InsertChangeObserver(AObserver: TObject);
begin
  if Assigned(AObserver) then FChangeObservers.Add(AObserver);
end;

procedure TDXPersistent.InsertDestroyObserver(AObserver: TObject);
begin
  if Assigned(AObserver) then FDestroyObservers.Add(AObserver);
end;

procedure TDXPersistent.RemoveChangeObserver(AObserver: TObject);
begin
  FChangeObservers.Remove(AObserver);
end;

procedure TDXPersistent.RemoveDestroyObserver(AObserver: TObject);
begin
  FDestroyObservers.Remove(AObserver);
end;

procedure TDXPersistent.SendChangeNotifications;
var
  Message: TCMChangeNotification;
  Observer: TObject;
begin
  Message.MessageId := CM_CHANGE_NOTIFICATION;
  Message.Sender := Self;
  for Observer in FChangeObservers do
  begin
    Observer.Dispatch(Message);
  end;
end;

procedure TDXPersistent.SendDestroyNotifications;
var
  Message: TCMDestroyNotification;
  Observer: TObject;
begin
  Message.MessageId := CM_DESTROY_NOTIFICATION;
  Message.Sender := Self;
  for Observer in FDestroyObservers do
  begin
    Observer.Dispatch(Message);
  end;
end;

{ TDXComponent }

constructor TDXComponent.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(AOwner);
  if (not Assigned(Manager)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SErrorInvalidManagerInstance, [ClassName]);
  end;
  FManager := Manager;
  FChangeObservers := TList<TObject>.Create;
  FDestroyObservers := TList<TObject>.Create;
  Name := ClassName + IntToHex(Random($0FFFFFFF), 8);
end;

destructor TDXComponent.Destroy;
begin
  SendDestroyNotifications;
  FChangeObservers.Free;
  FDestroyObservers.Free;
  inherited;
end;

procedure TDXComponent.InsertChangeObserver(AObserver: TObject);
begin
  if Assigned(AObserver) then FChangeObservers.Add(AObserver);
end;

procedure TDXComponent.InsertDestroyObserver(AObserver: TObject);
begin
  if Assigned(AObserver) then FDestroyObservers.Add(AObserver);
end;

procedure TDXComponent.RemoveChangeObserver(AObserver: TObject);
begin
  FChangeObservers.Remove(AObserver);
end;

procedure TDXComponent.RemoveDestroyObserver(AObserver: TObject);
begin
  FDestroyObservers.Remove(AObserver);
end;

procedure TDXComponent.SendChangeNotifications;
var
  Message: TCMChangeNotification;
  Observer: TObject;
begin
  Message.MessageId := CM_CHANGE_NOTIFICATION;
  Message.Sender := Self;
  for Observer in FChangeObservers do
  begin
    Observer.Dispatch(Message);
  end;
end;

procedure TDXComponent.SendDestroyNotifications;
var
  Message: TCMDestroyNotification;
  Observer: TObject;
begin
  Message.MessageId := CM_DESTROY_NOTIFICATION;
  Message.Sender := Self;
  for Observer in FDestroyObservers do
  begin
    Observer.Dispatch(Message);
  end;
end;

procedure TDXComponent.ValidateContainer(AComponent: TComponent);
begin
  inherited;
  // INFO: Exception schmeißen, wenn versucht ein TDXComponent Objekt in eine Containerkomponente
  //       einzufügen, welche selbst nicht von TDXComponent abgeleitet ist
  //       [ TComponent.InsertComponent(TDXComponent) ]
  if (not (AComponent is TDXComponent)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidContainerEx,
      [AComponent.ClassName, ClassName]);
  end;
end;

procedure TDXComponent.ValidateInsert(AComponent: TComponent);
begin
  inherited;
  // INFO: Exception schmeißen, wenn versucht wird ein TDXComponent Objekt als Container für eine
  //       TComponent Instanz zu verwenden, welche selbst nicht von TDXComponent abgeleitet ist
  //       [ TDXComponent.InsertComponent(TComponent) ]
  if (not (AComponent is TDXComponent)) then
  begin
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidInsertEx,
      [AComponent.ClassName, ClassName]);
  end;
end;

{ TDXSizeConstraints }

procedure TDXSizeConstraints.AssignTo(Dest: TPersistent);
begin
  if Dest is TDXSizeConstraints then
  begin
    with TDXSizeConstraints(Dest) do
    begin
      FMinHeight := Self.FMinHeight;
      FMaxHeight := Self.FMaxHeight;
      FMinWidth := Self.FMinWidth;
      FMaxWidth := Self.FMaxWidth;
      SendChangeNotifications;
    end;
  end else inherited AssignTo(Dest);
end;

constructor TDXSizeConstraints.Create(Manager: TDXGUIManager);
begin
  inherited Create(Manager);

end;

procedure TDXSizeConstraints.SetConstraints(Index: Integer; Value: TDXConstraintSize);
begin
  case Index of
    0:
      if (Value <> FMaxHeight) then
      begin
        FMaxHeight := Value;
        if (Value > 0) and (Value < FMinHeight) then FMinHeight := Value;
        SendChangeNotifications;
      end;
    1:
      if (Value <> FMaxWidth) then
      begin
        FMaxWidth := Value;
        if (Value > 0) and (Value < FMinWidth) then FMinWidth := Value;
        SendChangeNotifications;
      end;
    2:
      if (Value <> FMinHeight) then
      begin
        FMinHeight := Value;
        if (FMaxHeight > 0) and (Value > FMaxHeight) then FMaxHeight := Value;
        SendChangeNotifications;
      end;
    3:
      if (Value <> FMinWidth) then
      begin
        FMinWidth := Value;
        if (FMaxWidth > 0) and (Value > FMaxWidth) then FMaxWidth := Value;
        SendChangeNotifications;
      end;
  end;
end;

{ TDXMargins }

procedure TDXMargins.AssignTo(Dest: TPersistent);
begin
  if Dest is TDXMargins then
  begin
    with TDXMargins(Dest) do
    begin
      FLeft := Self.FLeft;
      FTop := Self.FTop;
      FRight := Self.FRight;
      FBottom := Self.FBottom;
      SendChangeNotifications;
    end;
  end else inherited;
end;

constructor TDXMargins.Create(Manager: TDXGUIManager);
begin
  inherited Create(Manager);
  InitDefaults(Self);
end;

class procedure TDXMargins.InitDefaults(Margins: TDXMargins);
begin
  with Margins do
  begin
    FLeft := 3;
    FRight := 3;
    FTop := 3;
    FBottom := 3;
  end;
end;

procedure TDXMargins.SetMargin(Index: Integer; Value: TDXMarginSize);
begin
  case Index of
    0:
      if (Value <> FLeft) then
      begin
        FLeft := Value;
        SendChangeNotifications;
      end;
    1:
      if (Value <> FTop) then
      begin
        FTop := Value;
        SendChangeNotifications;
      end;
    2:
      if (Value <> FRight) then
      begin
        FRight := Value;
        SendChangeNotifications;
      end;
    3:
      if (Value <> FBottom) then
      begin
        FBottom := Value;
        SendChangeNotifications;
      end;
  end;
end;

{ TDXPadding }

class procedure TDXPadding.InitDefaults(Margins: TDXMargins);
begin

end;

{ TDXControl }

var
  AnchorAlign: array[TDXAlign] of TDXAnchors = (
    { alNone }
    [akLeft, akTop],
    { alTop }
    [akLeft, akTop, akRight],
    { alBottom }
    [akLeft, akRight, akBottom],
    { alLeft }
    [akLeft, akTop, akBottom],
    { alRight }
    [akRight, akTop, akBottom],
    { alClient }
    [akLeft, akTop, akRight, akBottom]
  );

procedure TDXControl.AfterConstruction;
begin
  inherited;
  if (Supports(Self, IDXWindow)) then
  begin
    Manager.InsertWindow(Self);
  end;
end;

procedure TDXControl.AlignControl(AControl: TDXControl);
var
  AligningClientRect: TRect;

procedure FindAlignedControls(Align: TDXAlign; const List: TList<TDXControl>);
var
  C: TDXControl;
  I, Index: Integer;
begin
  List.Clear;
  for C in FControls do
  begin
    if (not C.Visible) or (C.Align <> Align) then Continue;
    Index := List.Count;
    for I := 0 to List.Count - 1 do
    begin
      case Align of
        alNone  : Break;
        alTop   :
          if (List[I].Top > C.Top) then
          begin
            Index := I;
            Break;
          end;
        alBottom:
          if (List[I].Top < C.Top) then
          begin
            Index := I;
            Break;
          end;
        alLeft  :
          if (List[I].Left > C.Left) then
          begin
            Index := I;
            Break;
          end;
        alRight :
          if (List[I].Left < C.Left) then
          begin
            Index := I;
            Break;
          end;
        alClient: Break;
      end;
    end;
    List.Insert(Index, C);
  end;
end;

procedure AlignTopControls;
var
  List: TList<TDXControl>;
  C: TDXControl;
  R: TRect;
  Offset: Integer;
begin
  List := TList<TDXControl>.Create;
  try
    FindAlignedControls(alTop, List);
    Offset := FPadding.Top;
    for C in List do
    begin
      R := Rect(FPadding.Left, Offset, FClientRect.Width - FPadding.Right, Offset + C.Height);
      if (C.AlignWithMargins) then
      begin
        R.Left := R.Left + C.Margins.Left;
        R.Top := R.Top + C.Margins.Top;
        R.Right := R.Right - C.Margins.Right;
        R.Bottom := R.Bottom + C.Margins.Top;
        Inc(Offset, C.Margins.Top + C.Margins.Bottom);
      end;
      Inc(Offset, R.Height);
      C.FAligning := true;
      C.SetBounds(R.Left, R.Top, R.Width + 1, R.Height);
      C.FAligning := false;
    end;
    AligningClientRect.Top := Offset;
  finally
    List.Free;
  end;
end;

procedure AlignBottomControls;
var
  List: TList<TDXControl>;
  C: TDXControl;
  R: TRect;
  Offset: Integer;
begin
  List := TList<TDXControl>.Create;
  try
    FindAlignedControls(alBottom, List);
    Offset := FClientRect.Height - Padding.Bottom;
    for C in List do
    begin
      R := Rect(Padding.Left, Offset - C.Height, FClientRect.Width - Padding.Right, Offset);
      if (C.AlignWithMargins) then
      begin
        R.Left := R.Left + C.Margins.Left;
        R.Top := R.Top - C.Margins.Bottom;
        R.Right := R.Right - C.Margins.Right;
        R.Bottom := R.Bottom - C.Margins.Bottom;
        Dec(Offset, C.Margins.Top + C.Margins.Bottom);
      end;
      Dec(Offset, R.Height);
      C.FAligning := true;
      C.SetBounds(R.Left, R.Top + 1, R.Width + 1, R.Height);
      C.FAligning := false;
    end;
    AligningClientRect.Bottom := Offset;
  finally
    List.Free;
  end;
end;

procedure AlignLeftControls;
var
  List: TList<TDXControl>;
  C: TDXControl;
  R: TRect;
  Offset: Integer;
begin
  List := TList<TDXControl>.Create;
  try
    FindAlignedControls(alLeft, List);
    Offset := Padding.Left;
    for C in List do
    begin
      R := Rect(Offset, AligningClientRect.Top, Offset + C.Width, AligningClientRect.Bottom);
      if (C.AlignWithMargins) then
      begin
        R.Left := R.Left + C.Margins.Left;
        R.Top := R.Top + C.Margins.Top;
        R.Right := R.Right + C.Margins.Left;
        R.Bottom := R.Bottom - C.Margins.Bottom;
        Inc(Offset, C.Margins.Left + C.Margins.Right);
      end;
      Inc(Offset, R.Width);
      C.FAligning := true;
      C.SetBounds(R.Left, R.Top, R.Width, R.Height + 1);
      C.FAligning := false;
    end;
    AligningClientRect.Left := Offset;
  finally
    List.Free;
  end;
end;

procedure AlignRightControls;
var
  List: TList<TDXControl>;
  C: TDXControl;
  R: TRect;
  Offset: Integer;
begin
  List := TList<TDXControl>.Create;
  try
    FindAlignedControls(alRight, List);
    Offset := FClientRect.Width - Padding.Right;
    for C in List do
    begin
      R := Rect(Offset - C.Width, AligningClientRect.Top, Offset, AligningClientRect.Bottom);
      if (C.AlignWithMargins) then
      begin
        R.Left := R.Left - C.Margins.Right;
        R.Top := R.Top + C.Margins.Top;
        R.Right := R.Right - C.Margins.Right;
        R.Bottom := R.Bottom - C.Margins.Bottom;
        Dec(Offset, C.Margins.Left + C.Margins.Right);
      end;
      Dec(Offset, R.Width);
      C.FAligning := true;
      C.SetBounds(R.Left + 1, R.Top, R.Width, R.Height + 1);
      C.FAligning := false;
    end;
    AligningClientRect.Right := Offset;
  finally
    List.Free;
  end;
end;

procedure AlignClientControls;
var
  List: TList<TDXControl>;
  C: TDXControl;
  R: TRect;
begin
  List := TList<TDXControl>.Create;
  try
    FindAlignedControls(alClient, List);
    for C in List do
    begin
      R := AligningClientRect;
      if (C.AlignWithMargins) then
      begin
        R.Inflate(- C.Margins.Left, - C.Margins.Top, - C.Margins.Right, - C.Margins.Bottom);
      end;
      C.FAligning := true;
      C.SetBounds(R.Left, R.Top, R.Width + 1, R.Height + 1);
      C.FAligning := false;
    end;
  finally
    List.Free;
  end;
end;

begin
  if Assigned(AControl) and (AControl.Align = alNone) then
  begin
    AControl.SetBounds(AControl.FExplicitLeft, AControl.FExplicitTop,
      AControl.FExplicitWidth, AControl.FExplicitHeight);
  end;
  AlignTopControls;
  AlignBottomControls;
  AlignLeftControls;
  AlignRightControls;
  AlignClientControls;
end;

procedure TDXControl.BeforeDestruction;
begin
  inherited;
  if (Supports(Self, IDXWindow)) then
  begin
    Manager.RemoveWindow(Self);
  end;
end;

function TDXControl.CalculateClientRect(const ABoundsRect: TRect): TRect;
begin
  Result := ABoundsRect;
end;

function TDXControl.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := true;
end;

function TDXControl.CanResize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := true;
  if Assigned(FOnCanResize) then FOnCanResize(Self, NewWidth, NewHeight, Result);
end;

function TDXControl.CheckNewSize(var NewWidth, NewHeight: Integer): Boolean;
var
  W, H, W2, H2: Integer;
begin
  Result := false;
  W := NewWidth;
  H := NewHeight;
  if DoCanResize(W, H) then
  begin
    W2 := W;
    H2 := H;
    Result :=
      not AutoSize or (DoCanAutoSize(W2, H2) and (W2 = W) and (H2 = H)) or DoCanResize(W2, H2);
    if Result then
    begin
      NewWidth := W2;
      NewHeight := H2;
    end;
  end;
end;

procedure TDXControl.CMChangeNotification(var Message: TCMChangeNotification);
begin
  if (Message.Sender = FConstraints) then
  begin
    SetBounds(FLeft, FTop, FWidth, FHeight);
  end;
  if (Message.Sender = FMargins) then
  begin
    RequestAlign;
  end;
  if (Message.Sender = FPadding) then
  begin
    Realign;
  end;
end;

procedure TDXControl.CMLButtonDblClk(var Message: TCMLButtonDblClk);
begin
  if Assigned(FOnDblClick) then FOnDblClick(Self);
end;

procedure TDXControl.CMLButtonDown(var Message: TCMLButtonDown);
begin
  FIsPressed := true;
  if (iePressedChanged in FInvalidateEvents) then
  begin
    Invalidate;
  end;
  if Assigned(FOnMouseDown) then FOnMouseDown(Self, mbLeft, Message.Pos.X, Message.Pos.Y);
end;

procedure TDXControl.CMLButtonUp(var Message: TCMLButtonUp);
var
  MessageClick: TCMMouseClick;
begin
  if (FIsPressed) then
  begin
    MessageClick.MessageId := CM_MOUSECLICK;
    Self.Dispatch(MessageClick);
  end;
  FIsPressed := false;
  if (iePressedChanged in FInvalidateEvents) then
  begin
    Invalidate;
  end;
  if Assigned(FOnMouseUp) then FOnMouseUp(Self, mbLeft, Message.Pos.X, Message.Pos.Y);
end;

procedure TDXControl.CMMButtonDblClk(var Message: TCMMButtonDblClk);
begin
  if Assigned(FOnDblClick) then FOnDblClick(Self);
end;

procedure TDXControl.CMMButtonDown(var Message: TCMMButtonDown);
begin
  if Assigned(FOnMouseDown) then FOnMouseDown(Self, mbMiddle, Message.Pos.X, Message.Pos.Y);
end;

procedure TDXControl.CMMButtonUp(var Message: TCMMButtonUp);
begin
  if Assigned(FOnMouseUp) then FOnMouseUp(Self, mbMiddle, Message.Pos.X, Message.Pos.Y);
end;

procedure TDXControl.CMMouseClick(var Message: TCMMouseClick);
begin
  if Assigned(FOnClick) then FOnClick(Self);
end;

procedure TDXControl.CMMouseEnter(var Message: TCMMouseEnter);
begin
  FHasMouseFocus := true;
  if Assigned(FOnMouseEnter) then FOnMouseEnter(Self);
  if (ieMouseFocusChanged in FInvalidateEvents) then
  begin
    Invalidate;
  end;
end;

procedure TDXControl.CMMouseLeave(var Message: TCMMouseLeave);
begin
  FHasMouseFocus := false;
  if Assigned(FOnMouseLeave) then FOnMouseLeave(Self);
  if (ieMouseFocusChanged in FInvalidateEvents) then
  begin
    Invalidate;
  end;
end;

procedure TDXControl.CMMouseMove(var Message: TCMMouseMove);
begin
  if Assigned(FOnMouseMove) then FOnMouseMove(Self, Message.Pos.X, Message.Pos.Y);
end;

procedure TDXControl.CMMouseWheelDown(var Message: TCMMouseWheelDown);
begin
  // TODO: Event
end;

procedure TDXControl.CMMouseWheelUp(var Message: TCMMouseWheelUp);
begin
  // TODO: Event
end;

procedure TDXControl.CMRButtonDblClk(var Message: TCMRButtonDblClk);
begin
  if Assigned(FOnDblClick) then FOnDblClick(Self);
end;

procedure TDXControl.CMRButtonDown(var Message: TCMRButtonDown);
begin
  if Assigned(FOnMouseDown) then FOnMouseDown(Self, mbRight, Message.Pos.X, Message.Pos.Y);
end;

procedure TDXControl.CMRButtonUp(var Message: TCMRButtonUp);
begin
  if Assigned(FOnMouseUp) then FOnMouseUp(Self, mbRight, Message.Pos.X, Message.Pos.Y);
end;

constructor TDXControl.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FSurface := Manager.RenderInterface.CreateSurface(FWidth, FHeight);
  FControls := TList<TDXControl>.Create;
  FControlStyle := [csAcceptChildControls];
  FInvalidateEvents := [ieAlphaBlendChanged, ieVisibleChanged];
  FAlphaBlend := 255;
  FVisible := true;
  FAbsoluteVisible := FVisible;
  FEnabled := true;
  FAbsoluteEnabled := FEnabled;
  FAnchors := [akLeft, akTop];
  FConstraints := TDXSizeConstraints.Create(Manager);
  FConstraints.InsertChangeObserver(Self);
  FMargins := TDXMargins.Create(Manager);
  FMargins.InsertChangeObserver(Self);
  FPadding := TDXPadding.Create(Manager);
  FPadding.InsertChangeObserver(Self);
  SetBounds(FLeft, FTop, 100, 100); { TODO: ? }
end;

destructor TDXControl.Destroy;
begin
  Manager.ControlDestroyed(Self);
  FControls.Free;
  FSurface.Free;
  FConstraints.Free;
  FMargins.Free;
  FPadding.Free;
  inherited;
end;

function TDXControl.DoCanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  W, H: Integer;
begin
  if (FAlign <> alClient) then
  begin
    W := NewWidth;
    H := NewHeight;
    Result := CanAutoSize(W, H);
    if (FAlign in [alNone, alLeft, alRight]) then NewWidth  := W; { TODO: ? }
    if (FAlign in [alNone, alTop, alBottom]) then NewHeight := H;
  end else Result := true;
end;

function TDXControl.DoCanResize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := CanResize(NewWidth, NewHeight);
  if Result then DoConstrainedResize(NewWidth, NewHeight);
end;

procedure TDXControl.DoConstrainedResize(var NewWidth, NewHeight: Integer);
var
  MinWidth, MinHeight, MaxWidth, MaxHeight: Integer;
begin
  MinWidth := 0;
  MinHeight := 0;
  MaxWidth := 0;
  MaxHeight := 0;
  if (FConstraints.MinWidth  > 0) then MinWidth  := FConstraints.MinWidth;
  if (FConstraints.MinHeight > 0) then MinHeight := FConstraints.MinHeight;
  if (FConstraints.MaxWidth  > 0) then MaxWidth  := FConstraints.MaxWidth;
  if (FConstraints.MaxHeight > 0) then MaxHeight := FConstraints.MaxHeight;
  if Assigned(FOnConstrainedResize) then
  begin
    FOnConstrainedResize(Self, MinWidth, MinHeight, MaxWidth, MaxHeight);
  end;
  if (MaxWidth > 0) and (NewWidth > MaxWidth) then
  begin
    NewWidth := MaxWidth;
  end else if (MinWidth > 0) and (NewWidth < MinWidth) then
  begin
    NewWidth := MinWidth;
  end;
  if (MaxHeight > 0) and (NewHeight > MaxHeight) then
  begin
    NewHeight := MaxHeight;
  end else if (MinHeight > 0) and (NewHeight < MinHeight) then
  begin
    NewHeight := MinHeight;
  end;
end;

procedure TDXControl.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
  Control: TDXControl;
  OwnedComponent: TComponent;
begin
  // INFO: Liefert alle registrierten Child Controls der aktuellen Instanz zurück
  //       [Sub.Owner = Self and Sub.Parent = Self]
  for I := 0 to ControlCount - 1 do
  begin
    Control := FControls[I];
    if (Control.Owner = Root) then Proc(Control);
  end;
  if (Supports(Self, IDXWindow)) then
  begin
    // INFO: Erweitert die Liste um Child Komponenten, welche keinen Parent besitzen. Hierdurch
    //       wird das Control zum geeigneten Top-Level Container für alle Komponenten
    if (Root = Self) then
    begin
      for I := 0 to ComponentCount - 1 do
      begin
        OwnedComponent := Components[I];
        if not OwnedComponent.HasParent then Proc(OwnedComponent);
      end;
    end;
  end;
end;

function TDXControl.GetControl(Index: Integer): TDXControl;
begin
  Result := FControls[Index];
end;

function TDXControl.GetControlAt(X, Y: Integer; const Recursive,
  CheckVisibility: Boolean): TDXControl;
begin
  Result := GetControlAtAbsolute(AbsoluteBoundsRect.Left + X, AbsoluteBoundsRect.Top + Y,
    Recursive, CheckVisibility);
end;

function TDXControl.GetControlAtAbsolute(X, Y: Integer; const Recursive,
  CheckVisibility: Boolean): TDXControl;
var
  I: Integer;
begin
  Result := nil;
  if (FAbsoluteBoundsRect.Contains(Point(X, Y))) and ((not CheckVisibility) or (FVisible)) then
  begin
    if (Recursive) then
    begin
      for I := FControls.Count - 1 downto 0 do
      begin
        Result := FControls[I].GetControlAtAbsolute(X, Y, true, CheckVisibility);
        if Assigned(Result) then Exit;
      end;
    end;
    if (not Assigned(Result)) then Result := Self;
  end;
end;

function TDXControl.GetControlCount: Integer;
begin
  Result := FControls.Count;
end;

function TDXControl.HasParent: Boolean;
begin
  Result := Assigned(FParent);
end;

procedure TDXControl.Hide;
begin
  SetVisible(false);
end;

procedure TDXControl.Insert(AControl: TDXControl);
var
  OldParent: TDXControl;
  MessageA: TCMControlParentChanged;
  MessageB: TCMControlChildInserted;
begin
  OldParent := AControl.Parent;
  if Assigned(AControl.Parent) then
  begin
    AControl.Parent.RemoveControl(AControl);
  end;
  FControls.Add(AControl);
  AControl.UpdateAbsoluteRects;
  AControl.UpdateAbsoluteEnabled;
  AControl.UpdateAbsoluteVisible;
  AControl.FParent := Self;
  MessageA.MessageId := CM_CONTROL_PARENT_CHANGED;
  MessageA.ParentOld := OldParent;
  MessageA.ParentNew := Self;
  AControl.Dispatch(MessageA);
  MessageB.MessageId := CM_CONTROL_CHILD_INSERTED;
  MessageB.Control := AControl;
  Self.Dispatch(MessageB);
  if (AControl.Align <> alNone) then AlignControl(AControl);
  InvalidateRect(AControl.BoundsRect);
end;

procedure TDXControl.InsertControl(AControl: TDXControl);
begin
  if (Assigned(AControl)) and (AControl <> Self) and (not FControls.Contains(AControl)) then
  begin
    AControl.ValidateContainer(Self);
    Insert(AControl);
  end;
end;

procedure TDXControl.Invalidate;
begin
  // TODO:
  InvalidateRect(FRenderBoundsRect);
end;

procedure TDXControl.InvalidateParent;
begin
  // TODO:
  if Assigned(FParent) then
  begin
    InvalidateParentRect(FParent.BoundsRect);
  end;
end;

procedure TDXControl.InvalidateParentRect(R: TRect);
begin
  // TODO:
  if Assigned(FParent) then
  begin
    FParent.InvalidateRect(R);
  end else if Supports(Self, IDXWindow) then
  begin
    FManager.FNeedsRepaint := true;
  end
end;

procedure TDXControl.InvalidateRect(R: TRect);
begin
  // TODO:
  FHasDirtyRegions := true;
  if Assigned(FParent) then
  begin
    FParent.InvalidateRect(Rect(R.Left + FLeft, R.Top + FTop, R.Width, R.Height));
  end else if Supports(Self, IDXWindow) then
  begin
    FManager.FNeedsRepaint := true;
  end;
end;

procedure TDXControl.Realign;
begin
  AlignControl(nil);
end;

procedure TDXControl.Remove(AControl: TDXControl);
var
  MessageA: TCMControlParentChanged;
  MessageB: TCMControlChildRemoved;
begin
  FControls.Remove(AControl);
  AControl.UpdateAbsoluteRects;
  AControl.UpdateAbsoluteEnabled;
  AControl.UpdateAbsoluteVisible;
  InvalidateRect(AControl.BoundsRect);
  Realign;
  MessageA.MessageId := CM_CONTROL_PARENT_CHANGED;
  MessageA.ParentOld := AControl.FParent;
  MessageA.ParentNew := nil;
  AControl.FParent := nil;
  AControl.Dispatch(MessageA);
  MessageB.MessageId := CM_CONTROL_CHILD_REMOVED;
  MessageB.Control := AControl;
  Self.Dispatch(MessageB);
end;

procedure TDXControl.RemoveControl(AControl: TDXControl);
begin
  if (FControls.Contains(AControl)) then Remove(AControl);
end;

procedure TDXControl.Render;
var
  LastSurface: TDXSurface;
  I, Pass: Integer;
  LastPass: Boolean;
begin
  if (FWidth = 0) or (FHeight = 0) then Exit;
  if (FAbsoluteVisible) then
  begin
    if (FHasDirtyRegions) then
    begin
      FHasDirtyRegions := false;
      LastSurface := Manager.RenderInterface.Renderer.ActiveSurface;
      Manager.RenderInterface.Renderer.ActiveSurface := FSurface;
      try
        Manager.RenderInterface.Renderer.Clear;
        //
        Pass := 0;
        LastPass := true;
        repeat
        begin
          if Assigned(OnPrePaint) then OnPrePaint(Self, Pass);
          Paint(FRenderBoundsRect, FRenderClientRect);
          if Assigned(OnPostPaint) then LastPass := (OnPostPaint(Self, Pass) = eerContinue);
          Inc(Pass, 1);
        end
        until LastPass;
        //
        for I := 0 to FControls.Count - 1 do
        begin
          FControls[I].Render;
        end;
      finally
        Manager.RenderInterface.Renderer.ActiveSurface := LastSurface;
      end;
    end;
    //
    Pass := 0;
    LastPass := true;
    repeat
    begin
      if Assigned(OnPreFlip) then OnPreFlip(Self, Pass);
      FSurface.Flip(FFlipRect.Left, FFLipRect.Top, DXCOLOR_RGBA(255, 255, 255, FAlphaBlend));
      if Assigned(OnPostFlip) then LastPass := (OnPostFlip(Self, Pass) = eerContinue);
      Inc(Pass, 1);
    end
    until LastPass;
    //
  end;
end;

procedure TDXControl.RequestAlign;
begin
  if Assigned(FParent) then FParent.AlignControl(Self);
end;

procedure TDXControl.ResizeAnchoredControls;
var
  C: TDXControl;
  A: TDXAnchors;
  R: TRect;
begin
  for C in FControls do
  begin
    A := C.Anchors;
    if (C.Align <> alNone) then
    begin
      A := A + AnchorAlign[C.Align];
    end;
    if (A = [akLeft, akTop]) then Continue;
    R := C.BoundsRect;
    if (not (akLeft in A)) then
    begin
      R.Left := R.Left + (FBoundsRect.Width - FAnchorRect.Width);
      if (not (akRight in A)) then
      begin
        R.Right := R.Right + (FBoundsRect.Width - FAnchorRect.Width);
      end;
    end;
    if (not (akTop in A)) then
    begin
      R.Top := R.Top + (FBoundsRect.Height - FAnchorRect.Height);
      if (not (akBottom in A)) then
      begin
        R.Bottom := R.Bottom + (FBoundsRect.Height - FAnchorRect.Height);
      end;
    end;
    if (akRight in A) then
    begin
      R.Right := R.Right + (FBoundsRect.Width - FAnchorRect.Width);
    end;
    if (akBottom in A) then
    begin
      R.Bottom := R.Bottom + (FBoundsRect.Height - FAnchorRect.Height);
    end;
    C.SetBounds(R.Left, R.Top, R.Width + 1, R.Height + 1);
  end;
end;

procedure TDXControl.SetAlign(const Value: TDXAlign);
begin
  if (FAlign <> Value) then
  begin
    FAlign := Value;
    SetAnchors(AnchorAlign[FAlign]);
    RequestAlign;
  end;
end;

procedure TDXControl.SetAlignWithMargins(const Value: Boolean);
begin
  if (FAlignWithMargins <> Value) then
  begin
    FAlignWithMargins := Value;
    RequestAlign;
  end;
end;

procedure TDXControl.SetAlphaBlend(const Value: Byte);
begin
  if (Value <> FAlphaBlend) then
  begin
    FAlphaBlend := Value;
    if (ieAlphaBlendChanged in FInvalidateEvents) then
    begin
      Invalidate;
    end;
  end;
end;

procedure TDXControl.SetAnchors(const Value: TDXAnchors);
var
  OldAnchors: TDXAnchors;
begin
  if (FAnchors <> Value) then
  begin
    OldAnchors := FAnchors;
    FAnchors := Value;
    if (OldAnchors <> [akLeft, akTop]) and (FAnchors = [akLeft, akTop]) and
      ((FExplicitLeft <> Left) or (FExplicitTop <> Top) or
      (FExplicitWidth <> Width) or(FExplicitHeight <> Height)) then
    begin
      SetBounds(FExplicitLeft, FExplicitTop, FExplicitWidth, FExplicitHeight);
    end;
  end;
end;

procedure TDXControl.SetAutoSize(const Value: Boolean);
begin
  if (FAutoSize <> Value) then
  begin
    FAutoSize := Value;
    SetBounds(FLeft, FTop, FWidth, FHeight);
  end;
end;

procedure TDXControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  OldWidth, OldHeight: Integer;
  Message: TCMControlBoundsChanged;
begin
  if CheckNewSize(AWidth, AHeight) and ((ALeft <> FLeft) or (ATop <> FTop) or
    (AWidth <> FWidth) or (AHeight <> FHeight)) then
  begin
    InvalidateParentRect(FBoundsRect);
    FAnchorRect := FBoundsRect;
    OldWidth := FWidth;
    OldHeight := FHeight;
    FLeft := ALeft;
    FTop := ATop;
    FWidth := AWidth;
    FHeight := AHeight;
    Message.BoundsRectOld := FBoundsRect;
    FBoundsRect := Rect(FLeft, FTop, FLeft + FWidth - 1, FTop + FHeight - 1);
    Message.BoundsRectNew := FBoundsRect;
    FClientRect := CalculateClientRect(FBoundsRect);
    if ((AWidth <> OldWidth) or (AHeight <> OldHeight)) and (FWidth > 0) and (FHeight > 0) then
    begin
      FSurface.Resize(FWidth, FHeight);
      Invalidate;
    end;
    UpdateAbsoluteRects;
    Message.MessageId := CM_CONTROL_BOUNDS_CHANGED;
    Self.Dispatch(Message);
    if (FAnchors = [akLeft, akTop]) then
    begin
      FExplicitLeft := FLeft;
      FExplicitTop := FTop;
      FExplicitWidth := FWidth;
      FExplicitHeight := FHeight;
    end;
    if Assigned(FOnResize) then FOnResize(Self);
    if (FAlign <> alNone) and (not FAligning) then RequestAlign;
    if ((FWidth <> OldWidth) or (FHeight <> OldHeight)) and (FWidth > 0) and (FHeight > 0) then
    begin
      ResizeAnchoredControls;
    end;
  end;
end;

procedure TDXControl.SetConstraints(const Value: TDXSizeConstraints);
begin
  FConstraints.Assign(Value);
end;

procedure TDXControl.SetEnabled(const Value: Boolean);
var
  Message: TCMControlEnabledChanged;
begin
  if (Value <> FEnabled) then
  begin
    FEnabled := Value;
    UpdateAbsoluteEnabled;
    Message.MessageId := CM_CONTROL_ENABLED_CHANGED;
    Self.Dispatch(Message);
  end;
end;

procedure TDXControl.SetHeight(const Value: Integer);
begin
  SetBounds(FLeft, FTop, FWidth, Value);
end;

procedure TDXControl.SetLeft(const Value: Integer);
begin
  SetBounds(Value, FTop, FWidth, FHeight);
end;

procedure TDXControl.SetMargins(const Value: TDXMargins);
begin
  if (FMargins <> Value) then
  begin
    FMargins.Assign(Value);
  end;
end;

procedure TDXControl.SetPadding(const Value: TDXPadding);
begin
  if (FPadding <> Value) then
  begin
    FPadding.Assign(Value);
  end;
end;

procedure TDXControl.SetParent(const Value: TDXControl);
begin
  Value.InsertControl(Self);
end;

procedure TDXControl.SetTop(const Value: Integer);
begin
  SetBounds(FLeft, Value, FWidth, FHeight);
end;

procedure TDXControl.SetVisible(const Value: Boolean);
var
  Message: TCMControlVisibleChanged;
begin
  if (Value <> FVisible) then
  begin
    FVisible := Value;
    UpdateAbsoluteVisible;
    Message.MessageId := CM_CONTROL_VISIBLE_CHANGED;
    Self.Dispatch(Message);
    Invalidate;
    RequestAlign;
  end;
end;

procedure TDXControl.SetWidth(const Value: Integer);
begin
  SetBounds(FLeft, FTop, Value, FHeight);
end;

procedure TDXControl.Show;
begin
  SetVisible(true);
end;

procedure TDXControl.UpdateAbsoluteEnabled;
var
  Control: TDXControl;
begin
  FAbsoluteEnabled := FEnabled;
  if Assigned(FParent) then
  begin
    FAbsoluteEnabled := FParent.AbsoluteEnabled and FEnabled;
  end;
  for Control in FControls do
  begin
    Control.UpdateAbsoluteEnabled;
  end;
end;

procedure TDXControl.UpdateAbsoluteRects;
var
  Control: TDXControl;
begin
  FAbsoluteBoundsRect := FBoundsRect;
  if Assigned(FParent) then
  begin
    Inc(FAbsoluteBoundsRect.Left, FParent.AbsoluteClientRect.Left);
    Inc(FAbsoluteBoundsRect.Top, FParent.AbsoluteClientRect.Top);
    Inc(FAbsoluteBoundsRect.Right, FParent.AbsoluteClientRect.Left);
    Inc(FAbsoluteBoundsRect.Bottom, FParent.AbsoluteClientRect.Top);
  end;
  FAbsoluteClientRect := CalculateClientRect(FAbsoluteBoundsRect);
  FRenderBoundsRect := Rect(0, 0, Width - 1, Height - 1);
  FRenderClientRect := CalculateClientRect(FRenderBoundsRect);
  FFlipRect := BoundsRect;
  if Assigned(FParent) then
  begin
    FFlipRect := FParent.CalculateClientRect(FFlipRect);
  end;
  for Control in FControls do
  begin
    Control.UpdateAbsoluteRects;
  end;
end;

procedure TDXControl.UpdateAbsoluteVisible;
var
  Control: TDXControl;
begin
  FAbsoluteVisible := FVisible;
  if Assigned(FParent) then
  begin
    FAbsoluteVisible := FParent.AbsoluteVisible and FVisible;
  end;
  for Control in FControls do
  begin
    Control.UpdateAbsoluteVisible;
  end;
end;

procedure TDXControl.ValidateContainer(AComponent: TComponent);
begin
  if (Supports(Self, IDXWindow)) then
  begin
    // INFO: Exception schmeißen, wenn versucht wird ein Fenster in ein anderes Fenster
    //       einzufügen
    //       [ TComponent.InsertComponent(TDXTopLevelControl) ]
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidContainer, [AComponent.ClassName]);
  end;
  inherited;
end;

procedure TDXControl.ValidateInsert(AComponent: TComponent);
begin
  if (not (csAcceptChildControls in FControlStyle)) then
  begin
    // INFO: Exception schmeißen, wenn versucht wird die aktuelle Instanz als Parent für ein
    //       beliebiges Child Control zu verwenden
    //       [ TDXControl.InsertComponent(TDXControl) ]
    raise EDXInvalidArgumentException.CreateResFmt(@SInvalidInsert, [AComponent.ClassName]);
  end;
  inherited;
end;

end.
