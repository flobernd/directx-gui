unit DXGUIRenderInterface;

interface

uses
  Winapi.Windows, Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.ActiveX, System.SysUtils, System.Classes,
  Generics.Collections, DXGUITypes, DXGUIExceptions;

// ============================================================================================== //
{ Interface }

type
  EDXRendererException = class(EDXGUIFrameworkException);

type
  TDXRenderInterface = class;

  TDXRenderInterfaceObject = class(TPersistent)
  private
    FRenderInterface: TDXRenderInterface;
  public
    constructor Create(RenderInterface: TDXRenderInterface);
    destructor Destroy; override;
  public
    property RenderInterface: TDXRenderInterface read FRenderInterface;
  end;

  TDXRenderer = class;
  TDXTexture = class;
  TDXSurface = class;

  TDXRenderInterface = class(TObject)
  private
    FObjects: TList<TDXRenderInterfaceObject>;
    FRenderer: TDXRenderer;
  private
    function GetObject(Index: Integer): TDXRenderInterfaceObject;
    function GetObjectCount: Integer;
  private
    procedure InsertObject(AObject: TDXRenderInterfaceObject);
    procedure RemoveObject(AObject: TDXRenderInterfaceObject);
  protected
    function CreateRenderer: TDXRenderer; virtual; abstract;
  protected
    procedure DispatchObjectMessage(AObject: TDXRenderInterfaceObject; var Message);
    procedure BroadcastObjectMessage(var Message);
  public
    procedure AfterConstruction; override;
  public
    function CreateTexture: TDXTexture; overload; virtual; abstract;
    function CreateTexture(AWidth, AHeight: DWord): TDXTexture; overload;
    function CreateTexture(hInstance: HINST; ResName, ResType: PChar): TDXTexture; overload;
    function CreateTexture(const Filename: String): TDXTexture; overload;
    function CreateSurface: TDXSurface; overload; virtual; abstract;
    function CreateSurface(AWidth, AHeight: DWord): TDXSurface; overload;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Objects[Index: Integer]: TDXRenderInterfaceObject read GetObject;
    property ObjectCount: Integer read GetObjectCount;
    property Renderer: TDXRenderer read FRenderer;
  end;

  TDXRenderer = class(TDXRenderInterfaceObject)
  protected
    function GetActiveSurface: TDXSurface; virtual; abstract;
  protected
    procedure SetActiveSurface(Surface: TDXSurface); virtual; abstract;
  protected
    procedure InternalDrawTexture(Texture: TDXTexture; SourceRect, TargetRect: TRect;
      Diffuse: TDXColor); virtual; abstract;
  protected
    constructor Create(RenderInterface: TDXRenderInterface);
  public
    function GetEffectSurface(Pass: Cardinal): TDXSurface; virtual; abstract;
  public
    procedure BeginSequence; virtual; abstract;
    procedure EndSequence; virtual; abstract;
    procedure Clear; virtual; abstract;
  public
    { Shape Drawing }
    procedure DrawPrimitive(const Verticies; NumPrimitives: DWord;
      PrimType: TDXPrimitiveType); virtual; abstract;
    procedure DrawShape(X, Y, Radius: DWord; Edges: DWord; Color: TDXColor;
      const RotDeg: Single = 0; const SegmentDeg: Single = 360); virtual; abstract;
    procedure DrawRect(R: TRect; Color: TDXColor); overload; virtual; abstract;
    procedure DrawRect(X, Y, Width, Height: DWord; Color: TDXColor); overload;
    procedure FillRect(R: TRect; Color: TDXColor); overload;
    procedure FillRect(X, Y, Width, Height: DWord; Color: TDXColor); overload;
    procedure DrawLine(P1, P2: TPoint; Color: TDXColor); overload; virtual; abstract;
    procedure DrawLine(X1, Y1, X2, Y2: DWord; Color: TDXColor); overload;
    { Texture Drawing }
    procedure TextureDrawBegin; virtual; abstract;
    procedure TextureDrawEnd; virtual; abstract;
    procedure TextureDrawFlush; virtual; abstract;
    procedure DrawTexture(Texture: TDXTexture; SourceRect, TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    procedure DrawTexture(Texture: TDXTexture; SourceRect: TRect; TargetX, TargetY: DWord;
      const Diffuse: TDXColor = clWhite); overload;
    procedure DrawTexture(Texture: TDXTexture; TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    procedure DrawTexture(Texture: TDXTexture; TargetX, TargetY: DWord;
      const Diffuse: TDXColor = clWhite); overload;
    { Centered Drawing }
    procedure DrawTextureCentered(Texture: TDXTexture; SourceRect, TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    procedure DrawTextureCentered(Texture: TDXTexture; TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    { Stretched Drawing }
    procedure DrawTextureStretched(Texture: TDXTexture; SourceRect, TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    procedure DrawTextureStretched(Texture: TDXTexture; TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    { Clipping }
    procedure NextClippingLayer; virtual; abstract;
    procedure PrevClippingLayer; virtual; abstract;
  protected
    function GetCurrentClippingLayer: Cardinal; virtual; abstract;
    procedure SetCurrentClippingLayer(Layer: Cardinal); virtual; abstract;
    function IsClippingEnabled: Boolean; virtual; abstract;
    procedure SetClippingEnabled(Enabled: Boolean); virtual; abstract;
    function IsClippingWriteEnabled: Boolean; virtual; abstract;
    procedure SetClippingWriteEnabled(Enabled: Boolean); virtual; abstract;
    procedure ClearClipping; virtual; abstract;
  public
    property ActiveSurface: TDXSurface read GetActiveSurface write SetActiveSurface;
    property CurrentClippingSurface: Cardinal read GetCurrentClippingLayer
      write SetCurrentClippingLayer;
    property ClippingEnabled: Boolean read IsClippingEnabled write SetClippingEnabled;
    property ClippingWriteEnabled: Boolean read IsClippingWriteEnabled
      write SetClippingWriteEnabled;
  end;

  TDXLockedRect = record
    Pitch: Integer;
    Data: PDXImageData;
  end;

  TDXTexture = class(TDXRenderInterfaceObject)
  protected
    FWidth: DWord;
    FHeight: DWord;
  protected
    constructor Create(RenderInterface: TDXRenderInterface);
  public
    procedure LoadFromBitmap(Bitmap: TGPBitmap);
    procedure LoadFromFile(const Filename: String);
    procedure LoadFromResource(hInstance: HINST; ResName: PChar; ResType: PChar);
  public
    procedure Resize(AWidth, AHeight: DWord; const DiscardData: Boolean = false); virtual; abstract;
  public
    function LockRect(R: TRect;
      const ReadOnly: Boolean = false): TDXLockedRect; overload; virtual; abstract;
    function LockRect(const ReadOnly: Boolean = false): TDXLockedRect; overload;
    procedure UnlockRect; virtual; abstract;
    procedure ReadImageData(R: TRect; Data: PDXImageData); overload;
    procedure ReadImageData(Data: PDXImageData); overload;
    procedure WriteImageData(R: TRect; Data: PDXImageData; DataWidth, DataHeight: DWord); overload;  // TODO: DataWidth und DataHeight Parameter evtl. entfernen
    procedure WriteImageData(Data: PDXImageData; DataWidth, DataHeight: DWord); overload;
  public
    property Width: DWord read FWidth;
    property Height: DWord read FHeight;
  end;

  TDXSurface = class(TDXRenderInterfaceObject)
  protected
    FWidth: DWord;
    FHeight: DWord;
  protected
    constructor Create(RenderInterface: TDXRenderInterface);
  public
    procedure Resize(AWidth, AHeight: DWord); virtual; abstract;
  public
    { General Flipping }
    procedure Flip(SourceRect, TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload; virtual; abstract;
    procedure Flip(SourceRect: TRect; TargetX, TargetY: DWord;
      const Diffuse: TDXColor = clWhite); overload;
    procedure Flip(TargetRect: TRect; const Diffuse: TDXColor = clWhite); overload;
    procedure Flip(TargetX, TargetY: DWord; const Diffuse: TDXColor = clWhite); overload;
    { Centered Flipping }
    procedure FlipCentered(SourceRect, TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    procedure FlipCentered(TargetRect: TRect; const Diffuse: TDXColor = clWhite); overload;
    { Stretched Flipping }
    procedure FlipStretched(SourceRect, TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    procedure FlipStretched(TargetRect: TRect; const Diffuse: TDXColor = clWhite); overload;
  public
    property Width: DWord read FWidth;
    property Height: DWord read FHeight;
  end;

implementation

uses
  System.Types, DXGUIGraphics;

{ TDXRenderInterfaceObject }

constructor TDXRenderInterfaceObject.Create(RenderInterface: TDXRenderInterface);
begin
  inherited Create;
  FRenderInterface := RenderInterface;
  FRenderInterface.InsertObject(Self);
end;

destructor TDXRenderInterfaceObject.Destroy;
begin
  FRenderInterface.RemoveObject(Self);
  inherited;
end;

{ TDXRenderInterface }

procedure TDXRenderInterface.AfterConstruction;
begin
  inherited;
  FRenderer := CreateRenderer;
end;

procedure TDXRenderInterface.BroadcastObjectMessage(var Message);
var
  I: Integer;
begin
  for I := 0 to FObjects.Count - 1 do
  begin
    DispatchObjectMessage(FObjects[I], Message);
  end;
end;

constructor TDXRenderInterface.Create;
begin
  inherited Create;
  FObjects := TList<TDXRenderInterfaceObject>.Create;
end;

function TDXRenderInterface.CreateSurface(AWidth, AHeight: DWord): TDXSurface;
begin
  Result := CreateSurface;
  Result.Resize(AWidth, AHeight);
end;

function TDXRenderInterface.CreateTexture(AWidth, AHeight: DWord): TDXTexture;
begin
  Result := CreateTexture;
  Result.Resize(AWidth, AHeight);
end;

function TDXRenderInterface.CreateTexture(const Filename: String): TDXTexture;
begin
  Result := CreateTexture;
  Result.LoadFromFile(Filename);
end;

function TDXRenderInterface.CreateTexture(hInstance: HINST; ResName, ResType: PChar): TDXTexture;
begin
  Result := CreateTexture;
  Result.LoadFromResource(hInstance, ResName, ResType);
end;

destructor TDXRenderInterface.Destroy;
begin
  FObjects.Free;
  if Assigned(FRenderer) then
  begin
    FRenderer.Free;
  end;
  inherited;
end;

procedure TDXRenderInterface.DispatchObjectMessage(AObject: TDXRenderInterfaceObject;
  var Message);
begin
  AObject.Dispatch(Message);
end;

function TDXRenderInterface.GetObject(Index: Integer): TDXRenderInterfaceObject;
begin
  Result := FObjects[Index];
end;

function TDXRenderInterface.GetObjectCount: Integer;
begin
  Result := FObjects.Count;
end;

procedure TDXRenderInterface.InsertObject(AObject: TDXRenderInterfaceObject);
begin
  FObjects.Add(AObject);
end;

procedure TDXRenderInterface.RemoveObject(AObject: TDXRenderInterfaceObject);
begin
  FObjects.Remove(AObject);
end;

{ TDXRenderer }

constructor TDXRenderer.Create(RenderInterface: TDXRenderInterface);
begin
  inherited Create(RenderInterface);

end;

procedure TDXRenderer.DrawLine(X1, Y1, X2, Y2: DWord; Color: TDXColor);
begin
  DrawLine(Point(X1, Y1), Point(X2, Y2), Color);
end;

procedure TDXRenderer.DrawRect(X, Y, Width, Height: DWord; Color: TDXColor);
begin
  DrawRect(Rect(X, Y, X + Width, Y + Height), Color);
end;

procedure TDXRenderer.DrawTexture(Texture: TDXTexture; TargetRect: TRect; const Diffuse: TDXColor);
begin
  DrawTexture(Texture, Rect(0, 0, Texture.Width, Texture.Height), TargetRect, Diffuse);
end;

procedure TDXRenderer.DrawTexture(Texture: TDXTexture; SourceRect: TRect; TargetX, TargetY: DWord;
  const Diffuse: TDXColor);
begin
  {$WARNINGS OFF}
  DrawTexture(Texture, SourceRect, Rect(TargetX, TargetY, TargetX + SourceRect.Width,
    TargetY + SourceRect.Height), Diffuse);
  {$WARNINGS ON}
end;

procedure TDXRenderer.DrawTexture(Texture: TDXTexture; TargetX, TargetY: DWord;
  const Diffuse: TDXColor);
begin
  DrawTexture(Texture, Rect(0, 0, Texture.Width, Texture.Height), Rect(TargetX, TargetY,
    TargetX + Texture.Width, TargetY + Texture.Height), Diffuse);
end;

procedure TDXRenderer.DrawTexture(Texture: TDXTexture; SourceRect, TargetRect: TRect;
  const Diffuse: TDXColor);
begin
  TextureDrawBegin;
  InternalDrawTexture(Texture, SourceRect, TargetRect, Diffuse);
  TextureDrawEnd;
end;

procedure TDXRenderer.DrawTextureCentered(Texture: TDXTexture; TargetRect: TRect;
  const Diffuse: TDXColor);
begin
  DrawTextureCentered(Texture, Rect(0, 0, Texture.Width, Texture.Height), TargetRect, Diffuse);
end;

procedure TDXRenderer.DrawTextureCentered(Texture: TDXTexture; SourceRect, TargetRect: TRect;
  const Diffuse: TDXColor);
var
  R: TRect;
begin
  R.Left := TargetRect.Left + Round((TargetRect.Width  / 2) - (SourceRect.Width  / 2));
  R.Top  := TargetRect.Top  + Round((TargetRect.Height / 2) - (SourceRect.Height / 2));
  R.Width := SourceRect.Width;
  R.Height := SourceRect.Height;
  DrawTexture(Texture, SourceRect, R, Diffuse);
end;

procedure TDXRenderer.DrawTextureStretched(Texture: TDXTexture; SourceRect, TargetRect: TRect;
  const Diffuse: TDXColor);
begin
  DrawTexture(Texture, SourceRect, TargetRect, Diffuse);
end;

procedure TDXRenderer.DrawTextureStretched(Texture: TDXTexture; TargetRect: TRect;
  const Diffuse: TDXColor);
begin
  DrawTexture(Texture, Rect(0, 0, Texture.Width, Texture.Height), TargetRect, Diffuse);
end;

procedure TDXRenderer.FillRect(X, Y, Width, Height: DWord; Color: TDXColor);
begin
  FillRect(Rect(X, Y, X + Width, Y + Height), Color);
end;

procedure TDXRenderer.FillRect(R: TRect; Color: TDXColor);
var
  Verticies: array[0..3] of TDXVertex;
  I: Integer;
begin
  Verticies[0].X := R.Left;
  Verticies[0].Y := R.Top;
  Verticies[1].X := R.Right;
  Verticies[1].Y := R.Top;
  Verticies[2].X := R.Left;
  Verticies[2].Y := R.Bottom;
  Verticies[3].X := R.Right;
  Verticies[3].Y := R.Bottom;
  for I := Low(Verticies) to High(Verticies) do
  begin
    Verticies[i].Z := 0;
    Verticies[i].R := 0;
    Verticies[i].Diff := Color;
  end;
  DrawPrimitive(Verticies, 2, ptTriangleStrip);
end;

{ TDXTexture }

constructor TDXTexture.Create(RenderInterface: TDXRenderInterface);
begin
  inherited Create(RenderInterface);

end;

procedure TDXTexture.LoadFromBitmap(Bitmap: TGPBitmap);
var
  Data: Pointer;
  DataLength: DWord;
begin
  GDIPCopyBitmapData(Bitmap, Data, DataLength);
  try
    Resize(Bitmap.GetWidth, Bitmap.GetHeight, true);
    WriteImageData(Data, FWidth, FHeight);
  finally
    FreeMem(Data);
  end;
end;

procedure TDXTexture.LoadFromFile(const Filename: String);
var
  Bitmap: TGPBitmap;
begin
  Bitmap := GDIPCreateBitmapFromFile(Filename);
  try
    LoadFromBitmap(Bitmap);
  finally
    Bitmap.Free;
  end;
end;

procedure TDXTexture.LoadFromResource(hInstance: HINST; ResName, ResType: PChar);
var
  Bitmap: TGPBitmap;
begin
  Bitmap := GDIPCreateBitmapFromResource(hInstance, ResName, ResType);
  try
    LoadFromBitmap(Bitmap);
  finally
    Bitmap.Free;
  end;
end;

function TDXTexture.LockRect(const ReadOnly: Boolean): TDXLockedRect;
begin
  Result := LockRect(Rect(0, 0, FWidth, FHeight), ReadOnly);
end;

procedure TDXTexture.ReadImageData(Data: PDXImageData);
begin
  ReadImageData(Rect(0, 0, FWidth, FHeight), Data);
end;

procedure TDXTexture.ReadImageData(R: TRect; Data: PDXImageData);
var
  LockedRect: TDXLockedRect;
  I: Integer;
begin
  {$WARNINGS OFF}
  if (R.Right > FWidth) or (R.Bottom > FHeight) then
  {$WARNINGS ON}
  begin
    raise EDXInvalidArgumentException.Create('Fehlermeldung');
  end;
  LockedRect := LockRect(R, true);
  try
    for I := 0 to R.Height - 1 do
    begin
      {$WARNINGS OFF}
      CopyMemory(Pointer(NativeUInt(Data) + I * R.Width * SizeOf(TDXPixel)),
        Pointer(NativeUInt(LockedRect.Data) + I * LockedRect.Pitch),
        R.Width * SizeOf(TDXPixel));
      {$WARNINGS ON}
    end;
  finally
    UnlockRect;
  end;
end;

procedure TDXTexture.WriteImageData(R: TRect; Data: PDXImageData; DataWidth, DataHeight: DWord);
var
  LockedRect: TDXLockedRect;
  I: Integer;
begin
  {$WARNINGS OFF}
  if (R.Right > FWidth) or (R.Bottom > FHeight) then
  begin
    raise EDXInvalidArgumentException.Create('Fehlermeldung');
  end;
  if (DataWidth > R.Width) or (DataHeight > R.Height) then
  begin
    raise EDXInvalidArgumentException.Create('Fehlermeldung');
  end;
  {$WARNINGS ON}
  LockedRect := LockRect(R);
  try
    for I := 0 to DataHeight - 1 do
    begin
      {$WARNINGS OFF}
      CopyMemory(Pointer(NativeUInt(LockedRect.Data) + I * LockedRect.Pitch),
        Pointer(NativeUInt(Data) + I * DataWidth * SizeOf(TDXPixel)),
        DataWidth * SizeOf(TDXPixel));
      {$WARNINGS ON}
    end;
  finally
    UnlockRect;
  end;
end;

procedure TDXTexture.WriteImageData(Data: PDXImageData; DataWidth, DataHeight: DWord);
begin
  WriteImageData(Rect(0, 0, FWidth, FHeight), Data, DataWidth, DataHeight);
end;

{ TDXSurface }

constructor TDXSurface.Create(RenderInterface: TDXRenderInterface);
begin
  inherited Create(RenderInterface);

end;

procedure TDXSurface.Flip(SourceRect: TRect; TargetX, TargetY: DWord; const Diffuse: TDXColor);
begin
  {$WARNINGS OFF}
  Flip(SourceRect,
    Rect(TargetX, TargetY, TargetX + SourceRect.Width, TargetY + SourceRect.Height), Diffuse);
  {$WARNINGS ON}
end;

procedure TDXSurface.Flip(TargetX, TargetY: DWord; const Diffuse: TDXColor);
begin
  Flip(Rect(0, 0, FWidth, FHeight),
    Rect(TargetX, TargetY, TargetX + FWidth, TargetY + FHeight), Diffuse);
end;

procedure TDXSurface.Flip(TargetRect: TRect; const Diffuse: TDXColor);
begin
  Flip(Rect(0, 0, FWidth, FHeight), TargetRect, Diffuse);
end;

procedure TDXSurface.FlipCentered(SourceRect, TargetRect: TRect; const Diffuse: TDXColor);
var
  R: TRect;
begin
  R.Left := TargetRect.Left + Round((TargetRect.Width  / 2) - (SourceRect.Width  / 2));
  R.Top  := TargetRect.Top  + Round((TargetRect.Height / 2) - (SourceRect.Height / 2));
  R.Width := SourceRect.Width;
  R.Height := SourceRect.Height;
  Flip(SourceRect, R, Diffuse);
end;

procedure TDXSurface.FlipCentered(TargetRect: TRect; const Diffuse: TDXColor);
begin
  FlipCentered(Rect(0, 0, FWidth, FHeight), TargetRect, Diffuse);
end;

procedure TDXSurface.FlipStretched(TargetRect: TRect; const Diffuse: TDXColor);
begin
  Flip(Rect(0, 0, FWidth, FHeight), TargetRect, Diffuse);
end;

procedure TDXSurface.FlipStretched(SourceRect, TargetRect: TRect; const Diffuse: TDXColor);
begin
  Flip(SourceRect, TargetRect, Diffuse);
end;

end.
