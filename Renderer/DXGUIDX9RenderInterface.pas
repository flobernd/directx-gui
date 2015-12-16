unit DXGUIDX9RenderInterface;

interface

uses
  System.Math, Winapi.Windows, Winapi.Messages, Winapi.Direct3D9, DXGUITypes, DXGUIRenderInterface,
  D3DX9, D3DX10;

// ============================================================================================== //
// Interface

{ TODO : Implement Reset correctly, mind that the main surface may be resized }

const
  CM_RENDER_DX9              = WM_USER       + $8339;
  CM_RENDER_DX9_DEVICE_LOST  = CM_RENDER_DX9 + $0001;
  CM_RENDER_DX9_DEVICE_RESET = CM_RENDER_DX9 + $0002;

type
  TCMRenderDX9SimpleMessage = record
    MessageId: Cardinal;
  end;

  TCMRenderDX9DeviceLost  = TCMRenderDX9SimpleMessage;
  TCMRenderDX9DeviceReset = record
    MessageId: Cardinal;
    PresentParameters: TD3DPresentParameters;
  end;

type
  TDXDX9Surface = class;

  TDXDX9RenderInterface = class(TDXRenderInterface)
  private
    FDevice: IDirect3DDevice9;
  protected
    function CreateRenderer: TDXRenderer; override;
  public
    procedure PerformDeviceLost;
    procedure PerformDeviceReset(PresentParameters: TD3DPresentParameters);
  public
    function CreateTexture: TDXTexture; overload; override;
    function CreateSurface: TDXSurface; overload; override;
  public
    constructor Create(const Device: IDirect3DDevice9);
    destructor Destroy; override;
  public
    property Device: IDirect3DDevice9 read FDevice;
  end;

  TDXDX9Renderer = class(TDXRenderer)
  private
    FDX9RenderInterface: TDXDX9RenderInterface;
    FDevice: IDirect3DDevice9;
    FMainSurface: TDXDX9Surface;        // off-screen main surface
    FScreenSurface: IDirect3DSurface9;  // DirectX main surface
    FCurrentSurface: TDXSurface;        // currently active surface
    FDefaultStateBlock: IDirect3DStateBlock9;
    FSavedStateBlock: IDirect3DStateBlock9;
    FTextureStateBlock: IDirect3DStateBlock9;
    FEffectSurface1: TDXSurface;
    FEffectSurface2: TDXSurface;
    FClippingSurface: IDirect3DSurface9;
    FOriginalClippingSurface: IDirect3DSurface9;
  private
    procedure InitDefaultStateBlock;
    procedure Flip;
  protected
    procedure CMRenderDX9DeviceReset(var Message: TCMRenderDX9DeviceReset);
      message CM_RENDER_DX9_DEVICE_RESET;
  protected
    procedure InternalDrawTexture(Texture: TDXTexture; SourceRect, TargetRect: TRect;
      Diffuse: TDXColor); override;
  protected
    function GetActiveSurface: TDXSurface; override;
  protected
    procedure SetActiveSurface(Surface: TDXSurface); override;
  protected
    constructor Create(RenderInterface: TDXDX9RenderInterface);
  public
    function GetEffectSurface(Pass: Cardinal): TDXSurface; override;
  public
    procedure BeginSequence; override;
    procedure EndSequence; override;
    procedure Clear; override;
  public
    { Shape Drawing }
    procedure DrawPrimitive(const Verticies; NumPrimitives: DWord;
      PrimType: TDXPrimitiveType); override;
    procedure DrawShape(X, Y, Radius: DWord; Edges: DWord; Color: TDXColor;
      const RotDeg: Single = 0; const SegmentDeg: Single = 360); override;
    procedure DrawRect(R: TRect; Color: TDXColor); override;
    procedure DrawLine(P1, P2: TPoint; Color: TDXColor); override;
    { Texture Drawing }
    procedure TextureDrawBegin; override;
    procedure TextureDrawEnd; override;
    procedure TextureDrawFlush; override;
    { Clipping }
    procedure NextClippingLayer; override;
    procedure PrevClippingLayer; override;
    function GetCurrentClippingLayer: Cardinal; override;
    procedure SetCurrentClippingLayer(Layer: Cardinal); override;
    function IsClippingEnabled: Boolean; override;
    procedure SetClippingEnabled(Enabled: Boolean); override;
    function IsClippingWriteEnabled: Boolean; override;
    procedure SetClippingWriteEnabled(Enabled: Boolean); override;
    procedure ClearClipping; override;
  public
    destructor Destroy; override;
  end;

  TDXDX9Texture = class(TDXTexture)
  private
    FDX9RenderInterface: TDXDX9RenderInterface;
    FTexture: IDirect3DTexture9;
  private
    procedure InitTexture(AWidth, AHeight: DWord);
  protected
    constructor Create(RenderInterface: TDXDX9RenderInterface);
  public
    procedure Resize(AWidth, AHeight: DWord; const DiscardData: Boolean = false); override;
  public
    function LockRect(R: TRect; const ReadOnly: Boolean = false): TDXLockedRect; override;
    procedure UnlockRect; override;
  end;

  TDXDX9Surface = class(TDXSurface)
  private
    FDX9RenderInterface: TDXDX9RenderInterface;
    FTexture: IDirect3DTexture9;
    FSurfaceLevel: IDirect3DSurface9;
    FStoredStateBlock: IDirect3DStateBlock9;
  private
    procedure InitSurface(AWidth, AHeight: DWord);
  protected
    procedure CMRenderDX9DeviceLost(var Message: TCMRenderDX9DeviceLost);
      message CM_RENDER_DX9_DEVICE_LOST;
    procedure CMRenderDX9DeviceReset(var Message: TCMRenderDX9DeviceReset);
      message CM_RENDER_DX9_DEVICE_RESET;
  protected
    constructor Create(RenderInterface: TDXDX9RenderInterface);
  public
    procedure Resize(AWidth, AHeight: DWord); override;
  public
    procedure Flip(SourceRect, TargetRect: TRect; const Diffuse: TDXColor = clWhite); override;
  end;

implementation

uses
  System.Classes, DXGUIExceptions;

type
  TTextureVertex = packed record
    X, Y, Z, RHW: Single;
    Diff: TDXColor;
    U, V: Single;
  end;

{ TDXDX9RenderInterface }

constructor TDXDX9RenderInterface.Create(const Device: IDirect3DDevice9);
begin
  inherited Create;
  FDevice := Device;
end;

function TDXDX9RenderInterface.CreateRenderer: TDXRenderer;
begin
  Result := TDXDX9Renderer.Create(Self);
end;

function TDXDX9RenderInterface.CreateSurface: TDXSurface;
begin
  Result := TDXDX9Surface.Create(Self);
end;

function TDXDX9RenderInterface.CreateTexture: TDXTexture;
begin
  Result := TDXDX9Texture.Create(Self);
end;

destructor TDXDX9RenderInterface.Destroy;
begin

  inherited;
end;

procedure TDXDX9RenderInterface.PerformDeviceLost;
var
  Msg: TCMRenderDX9DeviceLost;
begin
  Msg.MessageId := CM_RENDER_DX9_DEVICE_LOST;
  BroadcastObjectMessage(Msg);
end;

procedure TDXDX9RenderInterface.PerformDeviceReset(PresentParameters: TD3DPresentParameters);
var
  Msg: TCMRenderDX9DeviceReset;
begin
  Msg.MessageId := CM_RENDER_DX9_DEVICE_RESET;
  Msg.PresentParameters := PresentParameters;
  BroadcastObjectMessage(Msg);
end;

{ TDXDX9Renderer }

{$REGION 'Default Values Lookup Tables'}
type
  TRenderStateValue = record
    Flag: D3DRENDERSTATETYPE;
    Value: DWord;
  end;
  TSamplerStageValue = record
    Flag: D3DSAMPLERSTATETYPE;
    Value: DWord;
  end;
  TTextureStageStateValue = record
    Flag: D3DTEXTURESTAGESTATETYPE;
    Value: DWord;
  end;

const
  RenderStateTable: array[0..102] of TRenderStateValue =
  (
    (Flag: D3DRS_ZENABLE;                    Value: 1                               ),
    (Flag: D3DRS_FILLMODE;                   Value: D3DFILL_SOLID                   ),
    (Flag: D3DRS_SHADEMODE;                  Value: D3DSHADE_GOURAUD                ),
    (Flag: D3DRS_ZWRITEENABLE;               Value: 1                               ),
    (Flag: D3DRS_ALPHATESTENABLE;            Value: 0                               ),
    (Flag: D3DRS_LASTPIXEL;                  Value: 0                               ),   //?
    (Flag: D3DRS_SRCBLEND;                   Value: D3DBLEND_ONE                    ),
    (Flag: D3DRS_DESTBLEND;                  Value: D3DBLEND_ZERO                   ),
    (Flag: D3DRS_CULLMODE;                   Value: D3DCULL_CCW                     ),
    (Flag: D3DRS_ZFUNC;                      Value: D3DCMP_LESSEQUAL                ),
    (Flag: D3DRS_ALPHAREF;                   Value: 0                               ),
    (Flag: D3DRS_ALPHAFUNC;                  Value: D3DCMP_ALWAYS                   ),
    (Flag: D3DRS_DITHERENABLE;               Value: 0                               ),
    (Flag: D3DRS_ALPHABLENDENABLE;           Value: 0                               ),
    (Flag: D3DRS_FOGENABLE;                  Value: 0                               ),
    (Flag: D3DRS_SPECULARENABLE;             Value: 0                               ),
    (Flag: D3DRS_FOGCOLOR;                   Value: 0                               ),
    (Flag: D3DRS_FOGTABLEMODE;               Value: D3DFOG_NONE                     ),
    (Flag: D3DRS_FOGSTART;                   Value: 0                               ),
    (Flag: D3DRS_FOGEND;                     Value: 0                               ),
    (Flag: D3DRS_FOGDENSITY;                 Value: $3F800000                       ),
    (Flag: D3DRS_RANGEFOGENABLE;             Value: 0                               ),
    (Flag: D3DRS_STENCILENABLE;              Value: 0                               ),
    (Flag: D3DRS_STENCILFAIL;                Value: D3DSTENCILOP_KEEP               ),
    (Flag: D3DRS_STENCILZFAIL;               Value: D3DSTENCILOP_KEEP               ),
    (Flag: D3DRS_STENCILPASS;                Value: D3DSTENCILOP_KEEP               ),
    (Flag: D3DRS_STENCILFUNC;                Value: D3DCMP_ALWAYS                   ),
    (Flag: D3DRS_STENCILREF;                 Value: 0                               ),
    (Flag: D3DRS_STENCILMASK;                Value: $FFFFFFFF                       ),
    (Flag: D3DRS_STENCILWRITEMASK;           Value: $FFFFFFFF                       ),
    (Flag: D3DRS_TEXTUREFACTOR;              Value: $FFFFFFFF                       ),
    (Flag: D3DRS_WRAP0;                      Value: 0                               ),
    (Flag: D3DRS_WRAP1;                      Value: 0                               ),
    (Flag: D3DRS_WRAP2;                      Value: 0                               ),
    (Flag: D3DRS_WRAP3;                      Value: 0                               ),
    (Flag: D3DRS_WRAP4;                      Value: 0                               ),
    (Flag: D3DRS_WRAP5;                      Value: 0                               ),
    (Flag: D3DRS_WRAP6;                      Value: 0                               ),
    (Flag: D3DRS_WRAP7;                      Value: 0                               ),
    (Flag: D3DRS_CLIPPING;                   Value: 1                               ),
    (Flag: D3DRS_LIGHTING;                   Value: 1                               ),
    (Flag: D3DRS_AMBIENT;                    Value: 0                               ),
    (Flag: D3DRS_FOGVERTEXMODE;              Value: D3DFOG_NONE                     ),
    (Flag: D3DRS_COLORVERTEX;                Value: 1                               ),
    (Flag: D3DRS_LOCALVIEWER;                Value: 1                               ),
    (Flag: D3DRS_NORMALIZENORMALS;           Value: 0                               ),
    (Flag: D3DRS_DIFFUSEMATERIALSOURCE;      Value: D3DMCS_COLOR1                   ),
    (Flag: D3DRS_SPECULARMATERIALSOURCE;     Value: D3DMCS_COLOR2                   ),
    (Flag: D3DRS_AMBIENTMATERIALSOURCE;      Value: D3DMCS_MATERIAL                 ),
    (Flag: D3DRS_EMISSIVEMATERIALSOURCE;     Value: D3DMCS_MATERIAL                 ),
    (Flag: D3DRS_VERTEXBLEND;                Value: D3DVBF_DISABLE                  ),
    (Flag: D3DRS_CLIPPLANEENABLE;            Value: 0                               ),
    (Flag: D3DRS_POINTSIZE;                  Value: $3F800000                       ),
    (Flag: D3DRS_POINTSIZE_MIN;              Value: $3F800000                       ),
    (Flag: D3DRS_POINTSPRITEENABLE;          Value: 0                               ),
    (Flag: D3DRS_POINTSCALEENABLE;           Value: 0                               ),
    (Flag: D3DRS_POINTSCALE_A;               Value: $3F800000                       ),
    (Flag: D3DRS_POINTSCALE_B;               Value: 0                               ),
    (Flag: D3DRS_POINTSCALE_C;               Value: 0                               ),
    (Flag: D3DRS_MULTISAMPLEANTIALIAS;       Value: 1                               ),
    (Flag: D3DRS_MULTISAMPLEMASK;            Value: $FFFFFFFF                       ),
    (Flag: D3DRS_PATCHEDGESTYLE;             Value: DWord(D3DPATCHEDGE_DISCRETE)    ),
    (Flag: D3DRS_DEBUGMONITORTOKEN;          Value: D3DDMT_ENABLE                   ),
    (Flag: D3DRS_POINTSIZE_MAX;              Value: $42800000                       ),
    (Flag: D3DRS_INDEXEDVERTEXBLENDENABLE;   Value: 0                               ),
    (Flag: D3DRS_COLORWRITEENABLE;           Value: $0000000F                       ),
    (Flag: D3DRS_TWEENFACTOR;                Value: $3F800000                       ),
    (Flag: D3DRS_BLENDOP;                    Value: D3DBLENDOP_ADD                  ),
    (Flag: D3DRS_POSITIONDEGREE;             Value: DWord(D3DDEGREE_CUBIC)          ),
    (Flag: D3DRS_NORMALDEGREE;               Value: DWord(D3DDEGREE_LINEAR)         ),
    (Flag: D3DRS_SCISSORTESTENABLE;          Value: 0                               ),
    (Flag: D3DRS_SLOPESCALEDEPTHBIAS;        Value: 0                               ),
    (Flag: D3DRS_ANTIALIASEDLINEENABLE;      Value: 0                               ),
    (Flag: D3DRS_MINTESSELLATIONLEVEL;       Value: $3F800000                       ),
    (Flag: D3DRS_MAXTESSELLATIONLEVEL;       Value: $3F800000                       ),
    (Flag: D3DRS_ADAPTIVETESS_X;             Value: 0                               ),
    (Flag: D3DRS_ADAPTIVETESS_Y;             Value: 0                               ),
    (Flag: D3DRS_ADAPTIVETESS_Z;             Value: $3F800000                       ),
    (Flag: D3DRS_ADAPTIVETESS_W;             Value: $42800000                       ),
    (Flag: D3DRS_ENABLEADAPTIVETESSELLATION; Value: 0                               ),
    (Flag: D3DRS_TWOSIDEDSTENCILMODE;        Value: 0                               ),
    (Flag: D3DRS_CCW_STENCILFAIL;            Value: D3DSTENCILOP_KEEP               ),
    (Flag: D3DRS_CCW_STENCILZFAIL;           Value: D3DSTENCILOP_KEEP               ),
    (Flag: D3DRS_CCW_STENCILPASS;            Value: D3DSTENCILOP_KEEP               ),
    (Flag: D3DRS_CCW_STENCILFUNC;            Value: D3DCMP_ALWAYS                   ),
    (Flag: D3DRS_COLORWRITEENABLE1;          Value: $0000000F                       ),
    (Flag: D3DRS_COLORWRITEENABLE2;          Value: $0000000F                       ),
    (Flag: D3DRS_COLORWRITEENABLE3;          Value: $0000000F                       ),
    (Flag: D3DRS_BLENDFACTOR;                Value: $FFFFFFFF                       ),
    (Flag: D3DRS_SRGBWRITEENABLE;            Value: 0                               ),
    (Flag: D3DRS_DEPTHBIAS;                  Value: 0                               ),
    (Flag: D3DRS_WRAP8;                      Value: 0                               ),
    (Flag: D3DRS_WRAP9;                      Value: 0                               ),
    (Flag: D3DRS_WRAP10;                     Value: 0                               ),
    (Flag: D3DRS_WRAP11;                     Value: 0                               ),
    (Flag: D3DRS_WRAP12;                     Value: 0                               ),
    (Flag: D3DRS_WRAP13;                     Value: 0                               ),
    (Flag: D3DRS_WRAP14;                     Value: 0                               ),
    (Flag: D3DRS_WRAP15;                     Value: 0                               ),
    (Flag: D3DRS_SEPARATEALPHABLENDENABLE;   Value: 0                               ),
    (Flag: D3DRS_SRCBLENDALPHA;              Value: D3DBLEND_ONE                    ),
    (Flag: D3DRS_DESTBLENDALPHA;             Value: D3DBLEND_ZERO                   ),
    (Flag: D3DRS_BLENDOPALPHA;               Value: D3DBLENDOP_ADD                  )
  );
  SamplerStageTable: array[0..12] of TSamplerStageValue =
  (
    (Flag: D3DSAMP_ADDRESSU;               Value: D3DTADDRESS_WRAP                  ),
    (Flag: D3DSAMP_ADDRESSV;               Value: D3DTADDRESS_WRAP                  ),
    (Flag: D3DSAMP_ADDRESSW;               Value: D3DTADDRESS_WRAP                  ),
    (Flag: D3DSAMP_BORDERCOLOR;            Value: 0                                 ),
    (Flag: D3DSAMP_MAGFILTER;              Value: D3DTEXF_POINT                     ),
    (Flag: D3DSAMP_MINFILTER;              Value: D3DTEXF_POINT                     ),
    (Flag: D3DSAMP_MIPFILTER;              Value: D3DTEXF_NONE                      ),
    (Flag: D3DSAMP_MIPMAPLODBIAS;          Value: 0                                 ),
    (Flag: D3DSAMP_MAXMIPLEVEL;            Value: 0                                 ),
    (Flag: D3DSAMP_MAXANISOTROPY;          Value: 1                                 ),
    (Flag: D3DSAMP_SRGBTEXTURE;            Value: 0                                 ),
    (Flag: D3DSAMP_ELEMENTINDEX;           Value: 0                                 ),
    (Flag: D3DSAMP_DMAPOFFSET;             Value: 0                                 )
  );
  TextureStage1StateTable: array[0..17] of TTextureStageStateValue =
  (
    (Flag: D3DTSS_COLOROP;                 Value: D3DTOP_MODULATE                   ),
    (Flag: D3DTSS_COLORARG1;               Value: D3DTA_TEXTURE                     ),
    (Flag: D3DTSS_COLORARG2;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_ALPHAOP;                 Value: D3DTOP_SELECTARG1                 ),
    (Flag: D3DTSS_ALPHAARG1;               Value: D3DTA_TEXTURE                     ),
    (Flag: D3DTSS_ALPHAARG2;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_BUMPENVMAT00;            Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVMAT01;            Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVMAT10;            Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVMAT11;            Value: 0                                 ),
    (Flag: D3DTSS_TEXCOORDINDEX;           Value: D3DTSS_TCI_PASSTHRU { ??? }       ),
    (Flag: D3DTSS_BUMPENVLSCALE;           Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVLOFFSET;          Value: 0                                 ),
    (Flag: D3DTSS_TEXTURETRANSFORMFLAGS;   Value: D3DTTFF_DISABLE                   ),
    (Flag: D3DTSS_COLORARG0;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_ALPHAARG0;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_RESULTARG;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_CONSTANT;                Value: 0 { ??? }                         )
  );
  TextureStageNStateTable: array[0..17] of TTextureStageStateValue =
  (
    (Flag: D3DTSS_COLOROP;                 Value: D3DTOP_DISABLE                    ),
    (Flag: D3DTSS_COLORARG1;               Value: D3DTA_TEXTURE                     ),
    (Flag: D3DTSS_COLORARG2;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_ALPHAOP;                 Value: D3DTOP_DISABLE                    ),
    (Flag: D3DTSS_ALPHAARG1;               Value: D3DTA_TEXTURE                     ),
    (Flag: D3DTSS_ALPHAARG2;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_BUMPENVMAT00;            Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVMAT01;            Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVMAT10;            Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVMAT11;            Value: 0                                 ),
    (Flag: D3DTSS_TEXCOORDINDEX;           Value: D3DTSS_TCI_PASSTHRU { ??? }       ),
    (Flag: D3DTSS_BUMPENVLSCALE;           Value: 0                                 ),
    (Flag: D3DTSS_BUMPENVLOFFSET;          Value: 0                                 ),
    (Flag: D3DTSS_TEXTURETRANSFORMFLAGS;   Value: D3DTTFF_DISABLE                   ),
    (Flag: D3DTSS_COLORARG0;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_ALPHAARG0;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_RESULTARG;               Value: D3DTA_CURRENT                     ),
    (Flag: D3DTSS_CONSTANT;                Value: 0 { ??? }                         )
  );
{$ENDREGION}

procedure TDXDX9Renderer.BeginSequence;
begin
  FSavedStateBlock.Capture;
  FDefaultStateBlock.Apply;
  FDevice.SetRenderState(D3DRS_ALPHABLENDENABLE,  1);
  FDevice.SetRenderState(D3DRS_BLENDOP,           D3DBLENDOP_ADD);
  FDevice.SetRenderState(D3DRS_SRCBLEND,          D3DBLEND_SRCALPHA);
  FDevice.SetRenderState(D3DRS_DESTBLEND,         D3DBLEND_INVSRCALPHA);
  FDevice.SetRenderState(D3DRS_DITHERENABLE,      1);
  FDevice.SetRenderState(D3DRS_LIGHTING,          0);
  { TODO : Alter this when implementing stencil }
  FDevice.SetRenderState(D3DRS_STENCILENABLE,     1);
  FDevice.SetRenderState(D3DRS_STENCILREF,        0);
  FDevice.SetRenderState(D3DRS_STENCILFUNC,       D3DCMP_EQUAL);
  if FAILED(FDevice.GetRenderTarget(0, FScreenSurface)) then
  begin
    raise EDXRendererException.Create('Unable to query render target.');
  end;
  if FDevice.GetDepthStencilSurface(FOriginalClippingSurface) = D3DERR_NOTFOUND then
  begin
    FOriginalClippingSurface := nil;
  end;
  if FAILED(FDevice.SetDepthStencilSurface(FClippingSurface)) then
  begin
    raise EDXRendererException.Create('Could not alter clipping surface');
  end;
  ActiveSurface := FMainSurface;
  Clear; // TODO: ?
  FDevice.SetFVF(D3DFVF_XYZRHW or D3DFVF_DIFFUSE);
end;

procedure TDXDX9Renderer.Clear;
begin
  FDevice.Clear(0, nil, D3DCLEAR_TARGET or D3DCLEAR_STENCIL or D3DCLEAR_ZBUFFER, 0, 0, 0);
end;

procedure TDXDX9Renderer.ClearClipping;
begin
  FDevice.Clear(0, nil, D3DCLEAR_STENCIL, 0, 0, 0);
end;

procedure TDXDX9Renderer.CMRenderDX9DeviceReset(var Message: TCMRenderDX9DeviceReset);
var
  W, H: DWord;
begin
  W := Message.PresentParameters.BackBufferWidth;
  H := Message.PresentParameters.BackBufferHeight;
  if (FMainSurface.Width <> W) or (FMainSurface.Height <> H) then
  begin
    FMainSurface.Resize(W, H);
    FEffectSurface1.Resize(W, H);
    FEffectSurface2.Resize(W, H);
  end;
end;

constructor TDXDX9Renderer.Create(RenderInterface: TDXDX9RenderInterface);
var
  ScreenSurface: IDirect3DSurface9;
  SurfaceDesc: D3DSURFACE_DESC;
begin
  inherited Create(RenderInterface);
  FDX9RenderInterface := RenderInterface;
  FDevice := FDX9RenderInterface.Device;
  if FAILED(FDevice.GetRenderTarget(0, ScreenSurface)) or
    FAILED(ScreenSurface.GetDesc(SurfaceDesc)) then
  begin
    raise EDXRendererException.Create('Could not retrieve main surface information.');
  end;
  FMainSurface    := TDXDX9Surface.Create(RenderInterface);
  FEffectSurface1 := TDXDX9Surface.Create(RenderInterface);
  FEffectSurface2 := TDXDX9Surface.Create(RenderInterface);
  FMainSurface.Resize(SurfaceDesc.Width, SurfaceDesc.Height);
  FEffectSurface1.Resize(SurfaceDesc.Width, SurfaceDesc.Height);
  FEffectSurface2.Resize(SurfaceDesc.Width, SurfaceDesc.Height);
  if FAILED(FDevice.CreateStateBlock(D3DSBT_ALL, FDefaultStateBlock)) or
    FAILED(FDevice.CreateStateBlock(D3DSBT_ALL, FSavedStateBlock)) or
    FAILED(FDevice.CreateStateBlock(D3DSBT_ALL, FTextureStateBlock)) then
  begin
    raise EDXRendererException.Create('Could not create state blocks');
  end;
  if FAILED(FDevice.CreateDepthStencilSurface(
    SurfaceDesc.Width, SurfaceDesc.Height,
    D3DFMT_D24S8,
    D3DMULTISAMPLE_NONE, 0,
    FALSE,
    FClippingSurface,
    nil
    )) then
  begin
    raise EDXRendererException.Create('Could not create clipping surface');
  end;
  FSavedStateBlock.Capture;
  InitDefaultStateBlock;
  FSavedStateBlock.Apply;
end;

destructor TDXDX9Renderer.Destroy;
begin
  FMainSurface.Free;
  FEffectSurface1.Free;
  FEffectSurface2.Free;
  inherited;
end;

procedure TDXDX9Renderer.DrawLine(P1, P2: TPoint; Color: TDXColor);
var
  Verticies: array[0..1] of TDXVertex;
  I: Integer;
begin
  for I := Low(Verticies) to High(Verticies) do
  begin
    Verticies[I].Diff := Color;
    Verticies[I].Z := 0;
    Verticies[I].R := 0;
  end;
  Verticies[0].X := P1.X;
  Verticies[0].Y := P1.Y;
  Verticies[1].X := P2.X;
  Verticies[1].Y := P2.Y;
  if FAILED(FDevice.DrawPrimitiveUp(D3DPT_LINESTRIP, 1, Verticies, SizeOf(TDXVertex))) then
  begin
    raise EDXRendererException.Create('Could not draw verticies.');
  end;
end;

procedure TDXDX9Renderer.DrawPrimitive(const Verticies; NumPrimitives: DWord;
  PrimType: TDXPrimitiveType);
var
  D3DPrimType: D3DPRIMITIVETYPE;
begin
  inherited;
  D3DPrimType := D3DPT_POINTLIST;
  case PrimType of
    ptLineList     : D3DPrimType := D3DPT_LINELIST;
    ptLineStrip    : D3DPrimType := D3DPT_LINESTRIP;
    ptTriangleList : D3DPrimType := D3DPT_TRIANGLELIST;
    ptTriangleStrip: D3DPrimType := D3DPT_TRIANGLESTRIP;
    ptTriangleFan  : D3DPrimType := D3DPT_TRIANGLEFAN;
  end;
  FDevice.DrawPrimitiveUP(D3DPrimType, NumPrimitives, Verticies, SizeOf(TDXVertex));
end;

procedure TDXDX9Renderer.DrawRect(R: TRect; Color: TDXColor);
var
  Verticies: array[0..4] of TDXVertex;
  I: Integer;
begin
  for I := Low(Verticies) to High(Verticies) do
  begin
    Verticies[I].Diff := Color;
    Verticies[I].Z := 0;
    Verticies[I].R := 0;
  end;
  Verticies[0].X := R.Left;
  Verticies[0].Y := R.Top;
  Verticies[1].X := R.Right - 1;
  Verticies[1].Y := R.Top;
  Verticies[2].X := R.Right - 1;
  Verticies[2].Y := R.Bottom - 1;
  Verticies[3].X := R.Left;
  Verticies[3].Y := R.Bottom - 1;
  Verticies[4].X := R.Left;
  Verticies[4].Y := R.Top;
  if FAILED(FDevice.DrawPrimitiveUp(D3DPT_LINESTRIP, 4, Verticies, SizeOf(TDXVertex))) then
  begin
    raise EDXRendererException.Create('Could not draw verticies.');
  end;
end;

procedure TDXDX9Renderer.DrawShape(X, Y, Radius, Edges: DWord; Color: TDXColor; const RotDeg,
  SegmentDeg: Single);
var
  Fract, Integral, Angle, RotRad, Theta: Single;
  Loops, NumVerticies: Integer;
  Verticies: Array of TDXVertex;
  I: Integer;
begin
  if (SegmentDeg = 0) then Exit;
  // Calculate how many edges will be actually drawn (depending on SegmentDeg)
  // and split result into fractional and integral parts
  Integral  := Edges / (360 / SegmentDeg);
  Fract     := Frac(Integral);
  Integral  := Int(Integral);
  Loops     := Floor(Integral) + 2;
  // Result odd? We'll need an additional loop for the partial rendered
  // triangle
  if (Fract <> 0) then
  begin
    Inc(Loops);
  end;
  // Is there anything to draw? If not, return
  if (Loops <= 0) or (Radius = 0) then
  begin
    Exit;
  end;
  // Allocate memory and pre-calculate angle
  NumVerticies  := Edges + 2;
  Angle         := -2 * Pi / Edges;
  RotRad        := DegToRad(RotDeg);
  SetLength(Verticies, NumVerticies);
  // Midpoint
  Verticies[0].X    := X;
  Verticies[0].Y    := Y;
  Verticies[0].Z    := 0;
  Verticies[0].R    := 1;
  Verticies[0].Diff := Color;
  // Generate other edges
  for I := 1 to Loops do
  begin
    // Last loop? Draw last triangle only partial, if there is any rest
    if (I = Loops - 1) and (Fract <> 0) then
    begin
      Theta := (I - (1 - Fract) - 1) * Angle;
    end else
    begin
      Theta := (I - 1) * Angle;
    end;
    // Add rotation
    Theta := Theta + RotRad;
    Verticies[I].X    := X + Radius * Cos(Theta);
    Verticies[I].Y    := Y - Radius * Sin(Theta);
    Verticies[I].Z    := 0;
    Verticies[I].R    := 1;
    Verticies[I].Diff := Color;
  end;
  // Draw polygons
  FDevice.DrawPrimitiveUP(D3DPT_TRIANGLEFAN, Loops - 2, Verticies[0], SizeOf(TDXVertex));
end;

procedure TDXDX9Renderer.EndSequence;
begin
  if FAILED(FDevice.SetRenderTarget(0, FScreenSurface)) then
  begin
    raise EDXRendererException.Create('Unable to restore original surface.');
  end;
  if Assigned(FOriginalClippingSurface) then
  begin
      if FAILED(FDevice.SetDepthStencilSurface(FOriginalClippingSurface)) then
      begin
        raise EDXRendererException.Create('Could not restore original clipping surface');
      end;
      FOriginalClippingSurface := nil;
  end;
  FCurrentSurface := nil;
  FSavedStateBlock.Apply;
  Flip;
end;

procedure TDXDX9Renderer.Flip;
begin
  FMainSurface.Flip(0, 0);
end;

function TDXDX9Renderer.GetActiveSurface: TDXSurface;
begin
  Result := FCurrentSurface;
end;

function TDXDX9Renderer.GetCurrentClippingLayer: Cardinal;
var
  Ref: Cardinal;
begin
  FDevice.GetRenderState(D3DRS_STENCILREF, Ref);
  Result := Ref;
end;

function TDXDX9Renderer.GetEffectSurface(Pass: Cardinal): TDXSurface;
begin
  if (Pass mod 2) = 0 then
  begin
    Result := FEffectSurface1;
  end else
  begin
    Result := FEffectSurface2;
  end;
end;

procedure TDXDX9Renderer.InitDefaultStateBlock;
var
  CurRenderStateValue: TRenderStateValue;
  CurSamplerStageValue: TSamplerStageValue;
  CurTextureStageStateValue: TTextureStageStateValue;
  I: Integer;
begin
  for CurRenderStateValue in RenderStateTable do
  begin
    FDevice.SetRenderState(CurRenderStateValue.Flag, CurRenderStateValue.Value);
  end;
  for I := 0 to 3 do
  begin
    for CurSamplerStageValue in SamplerStageTable do
    begin
      FDevice.SetSamplerState(I, CurSamplerStageValue.Flag, CurSamplerStageValue.Value);
    end;
  end;
  for CurTextureStageStateValue in TextureStage1StateTable do
  begin
    FDevice.SetTextureStageState(0,
      CurTextureStageStateValue.Flag, CurTextureStageStateValue.Value);
  end;
  for I := 1 to 7 do
  begin
    for CurTextureStageStateValue in TextureStageNStateTable do
    begin
      FDevice.SetTextureStageState(I,
        CurTextureStageStateValue.Flag, CurTextureStageStateValue.Value);
    end;
  end;
  FDevice.SetPixelShader(nil);
  FDevice.SetVertexShader(nil);
  FDevice.SetTexture(0, nil);
  FDefaultStateBlock.Capture;
end;

procedure TDXDX9Renderer.InternalDrawTexture(Texture: TDXTexture; SourceRect, TargetRect: TRect;
  Diffuse: TDXColor);
var
  TextureCoordinates: array[0..3] of Double;
  Verticies: array[0..3] of TTextureVertex;
  I: Integer;
  Device: IDirect3DDevice9;
begin
  if (not Assigned(Texture)) then
  begin
    raise EDXInvalidArgumentException.Create('Texture is empty.');
  end;

  if (SourceRect.Left = 0) then SourceRect.Right  := SourceRect.Right  - 1;
  if (SourceRect.Top  = 0) then SourceRect.Bottom := SourceRect.Bottom - 1;

  TextureCoordinates[0] := (SourceRect.Left + 1) / (Texture.Width + 1);
  TextureCoordinates[1] := (SourceRect.Top + 1) / (Texture.Height + 1);
  TextureCoordinates[2] := (SourceRect.Right + 1) / (Texture.Width + 1);
  TextureCoordinates[3] := (SourceRect.Bottom + 1) / (Texture.Height + 1);
  Verticies[0].X := TargetRect.Left;
  Verticies[0].Y := TargetRect.Top;
  Verticies[0].U := TextureCoordinates[0];
  Verticies[0].V := TextureCoordinates[1];
  Verticies[1].X := TargetRect.Right - 1;
  Verticies[1].Y := TargetRect.Top;
  Verticies[1].U := TextureCoordinates[2];
  Verticies[1].V := TextureCoordinates[1];
  Verticies[2].X := TargetRect.Left;
  Verticies[2].Y := TargetRect.Bottom - 1;
  Verticies[2].U := TextureCoordinates[0];
  Verticies[2].V := TextureCoordinates[3];
  Verticies[3].X := TargetRect.Right - 1;
  Verticies[3].Y := TargetRect.Bottom - 1;
  Verticies[3].U := TextureCoordinates[2];
  Verticies[3].V := TextureCoordinates[3];
  for I := Low(Verticies) to High(Verticies) do
  begin
    Verticies[I].Z := 0.;
    Verticies[I].RHW := 1.;
    Verticies[I].Diff := Diffuse;
  end;
  Device := FDX9RenderInterface.Device;

  Device.SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_BORDER);
  Device.SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_BORDER);
  Device.SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_NONE);
  Device.SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_NONE);
  Device.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_NONE);

  Device.SetTexture     (0, TDXDX9Texture(Texture).FTexture); // TODO: ggfls. Textur nicht neu setzen, wenn noch aktuell
  Device.SetFVF         (D3DFVF_XYZRHW or D3DFVF_TEX1 or D3DFVF_DIFFUSE);
  Device.SetRenderState (D3DRS_ALPHABLENDENABLE,          1                   );
  Device.SetRenderState (D3DRS_BLENDOP,                   D3DBLENDOP_ADD      );
  Device.SetRenderState (D3DRS_SEPARATEALPHABLENDENABLE,  1                   );
  Device.SetRenderState (D3DRS_SRCBLEND,                  D3DBLEND_SRCALPHA   );
  Device.SetRenderState (D3DRS_DESTBLEND,                 D3DBLEND_INVSRCALPHA);
  Device.SetRenderState (D3DRS_SRCBLENDALPHA,             D3DBLEND_ONE        );
  Device.SetRenderState (D3DRS_DESTBLENDALPHA,            D3DBLEND_ONE        );
  Device.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
  Device.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Device.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
  Device.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TEXTURE);
  Device.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
  Device.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TEXTURE);
  Device.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Verticies, SizeOf(TTextureVertex));
end;

function TDXDX9Renderer.IsClippingEnabled: Boolean;
var
  Enabled: Cardinal;
begin
  FDevice.GetRenderState(D3DRS_STENCILENABLE, Enabled);
  Result := Enabled <> 0;
end;

function TDXDX9Renderer.IsClippingWriteEnabled: Boolean;
var
  StencilFunc: Cardinal;
begin
  FDevice.GetRenderState(D3DRS_STENCILFUNC, StencilFunc);
  Result := StencilFunc = D3DCMP_ALWAYS;
end;

procedure TDXDX9Renderer.NextClippingLayer;
begin
  FDevice.SetRenderState(D3DRS_STENCILREF, GetCurrentClippingLayer + 1);
end;

procedure TDXDX9Renderer.PrevClippingLayer;
begin
  FDevice.SetRenderState(D3DRS_STENCILREF, GetCurrentClippingLayer - 1);
end;

procedure TDXDX9Renderer.SetActiveSurface(Surface: TDXSurface);
var
  SurfaceLevel: IDirect3DSurface9;
begin
  if FAILED(TDXDX9Surface(Surface).FTexture.GetSurfaceLevel(0, SurfaceLevel)) then
  begin
    raise EDXRendererException.Create('Could not retrieve surface level of texture');
  end;
  if FAILED(FDevice.SetRenderTarget(0, SurfaceLevel)) then
  begin
    raise EDXRendererException.Create('Could not switch render target');
  end;
  FCurrentSurface := Surface;
end;

procedure TDXDX9Renderer.SetClippingEnabled(Enabled: Boolean);
begin
  FDevice.SetRenderState(D3DRS_STENCILENABLE, Cardinal(Enabled));
end;

procedure TDXDX9Renderer.SetClippingWriteEnabled(Enabled: Boolean);
begin
  if Enabled then
  begin
    FDevice.SetRenderState(D3DRS_STENCILFUNC, D3DCMP_ALWAYS);
    FDevice.SetRenderState(D3DRS_STENCILPASS, D3DSTENCILOP_REPLACE); // D3DSTENCILOP_INCRSAT
    FDevice.SetRenderState(D3DRS_COLORWRITEENABLE, 0);
  end
  else begin
    FDevice.SetRenderState(D3DRS_STENCILFUNC, D3DCMP_EQUAL);
    FDevice.SetRenderState(D3DRS_STENCILPASS, D3DSTENCILOP_KEEP);
    FDevice.SetRenderState(
      D3DRS_COLORWRITEENABLE,
      D3DCOLORWRITEENABLE_RED
      or D3DCOLORWRITEENABLE_GREEN
      or D3DCOLORWRITEENABLE_BLUE
      or D3DCOLORWRITEENABLE_ALPHA
    );
  end;
end;

procedure TDXDX9Renderer.SetCurrentClippingLayer(Layer: Cardinal);
begin
  FDevice.SetRenderState(D3DRS_STENCILREF, Layer);
end;

procedure TDXDX9Renderer.TextureDrawBegin;
begin
  FTextureStateBlock.Capture;
end;

procedure TDXDX9Renderer.TextureDrawEnd;
begin
  FTextureStateBlock.Apply;
end;

procedure TDXDX9Renderer.TextureDrawFlush;
begin
  // TODO:
end;

{ TDXDX9Texture }

constructor TDXDX9Texture.Create(RenderInterface: TDXDX9RenderInterface);
begin
  inherited Create(RenderInterface);
  FDX9RenderInterface := RenderInterface;
end;

procedure TDXDX9Texture.InitTexture(AWidth, AHeight: DWord);
begin
  if FAILED(FDX9RenderInterface.Device.CreateTexture(AWidth, AHeight, 1, 0,
    D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, FTexture, nil)) then
  begin
    raise EDXRendererException.Create('Could not create texture.');
  end;
end;

function TDXDX9Texture.LockRect(R: TRect; const ReadOnly: Boolean): TDXLockedRect;
var
  LR: TD3DLockedRect;
  Flags: DWord;
begin
  if (not Assigned(FTexture)) then
  begin
    raise EDXRendererException.Create('The texture is not initialized.');
  end;
  Flags := 0;
  if (ReadOnly) then Flags := D3DLOCK_READONLY;
  if FAILED(FTexture.LockRect(0, LR, @R, Flags)) then
  begin
    raise EDXRendererException.Create('Could not lock texture rect.');
  end;
  Result.Pitch := LR.Pitch;
  Result.Data := LR.pBits;
end;

procedure TDXDX9Texture.Resize(AWidth, AHeight: DWord; const DiscardData: Boolean);
var
  DataBackup: Pointer;
  MinWidth, MinHeight: DWord;
begin
  if (AWidth = FWidth) and (AHeight = FHeight) then Exit;
  if (AWidth = 0) or (AHeight = 0) then
  begin
    raise EDXInvalidArgumentException.Create('Invalid texture size.');
  end;
  if (Assigned(FTexture) and (FWidth > 0) and (FHeight > 0) and (not DiscardData)) then
  begin
    MinWidth := AWidth;
    MinHeight := AHeight;
    if (MinWidth > FWidth) then MinWidth := FWidth;
    if (MinHeight > FHeight) then MinHeight := FHeight;
    GetMem(DataBackup, MinWidth * MinHeight * SizeOf(TDXPixel));
    try
      ReadImageData(Rect(0, 0, MinWidth, MinHeight), DataBackup);
      InitTexture(AWidth, AHeight);
      WriteImageData(Rect(0, 0, MinWidth, MinHeight), DataBackup, MinWidth, MinHeight);
    finally
      FreeMem(DataBackup);
    end;
  end else
  begin
    InitTexture(AWidth, AHeight);
  end;
  FWidth := AWidth;
  FHeight := AHeight;
end;

procedure TDXDX9Texture.UnlockRect;
begin
  if (not Assigned(FTexture)) then
  begin
    raise EDXRendererException.Create('The texture is not initialized.');
  end;
  if FAILED(FTexture.UnlockRect(0)) then
  begin
    raise EDXRendererException.Create('Could not unlock texture rect.');
  end;
end;

{ TDXDX9Surface }

procedure TDXDX9Surface.CMRenderDX9DeviceLost(var Message: TCMRenderDX9DeviceLost);
begin
  // TODO: Copy Surface Content to Buffer
end;

procedure TDXDX9Surface.CMRenderDX9DeviceReset(var Message: TCMRenderDX9DeviceReset);
begin
  // TODO: Recreate Surface and restore Content from local Buffer
end;

constructor TDXDX9Surface.Create(RenderInterface: TDXDX9RenderInterface);
begin
  inherited Create(RenderInterface);
  FDX9RenderInterface := RenderInterface;
  if FAILED(FDX9RenderInterface.Device.CreateStateBlock(D3DSBT_ALL, FStoredStateBlock)) then
  begin
    raise EDXRendererException.Create('Could not create state block.');
  end;
end;

procedure TDXDX9Surface.Flip(SourceRect, TargetRect: TRect; const Diffuse: TDXColor);
var
  TextureCoordinates: array[0..3] of Double;
  Verticies: array[0..3] of TTextureVertex;
  I: Integer;
  Device: IDirect3DDevice9;
begin
  if (not Assigned(FTexture)) then
  begin
    raise EDXRendererException.Create('The surface is not initialized.');
  end;
  // TODO: Testen mit eingeschränktem SourceRect
  if (SourceRect.Left = 0) then SourceRect.Right  := SourceRect.Right  - 1;
  if (SourceRect.Top  = 0) then SourceRect.Bottom := SourceRect.Bottom - 1;
  FStoredStateBlock.Capture;
  TextureCoordinates[0] := (SourceRect.Left   + 1) / (FWidth  + 1);
  TextureCoordinates[1] := (SourceRect.Top    + 1) / (FHeight + 1);
  TextureCoordinates[2] := (SourceRect.Right  + 1) / (FWidth  + 1);
  TextureCoordinates[3] := (SourceRect.Bottom + 1) / (FHeight + 1);
  Verticies[0].X := TargetRect.Left;
  Verticies[0].Y := TargetRect.Top;
  Verticies[0].U := TextureCoordinates[0];
  Verticies[0].V := TextureCoordinates[1];
  Verticies[1].X := TargetRect.Right - 1;
  Verticies[1].Y := TargetRect.Top;
  Verticies[1].U := TextureCoordinates[2];
  Verticies[1].V := TextureCoordinates[1];
  Verticies[2].X := TargetRect.Left;
  Verticies[2].Y := TargetRect.Bottom - 1;
  Verticies[2].U := TextureCoordinates[0];
  Verticies[2].V := TextureCoordinates[3];
  Verticies[3].X := TargetRect.Right - 1;
  Verticies[3].Y := TargetRect.Bottom - 1;
  Verticies[3].U := TextureCoordinates[2];
  Verticies[3].V := TextureCoordinates[3];
  for I := Low(Verticies) to High(Verticies) do
  begin
    Verticies[I].Z := 0.;
    Verticies[I].RHW := 1.;
    Verticies[I].Diff := Diffuse;
  end;
  Device := FDX9RenderInterface.Device;

  Device.SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_BORDER);
  Device.SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_BORDER);
  Device.SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_NONE);
  Device.SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_NONE);
  Device.SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_NONE);

  Device.SetTexture     (0, FTexture); // TODO: ggfls. Textur nicht neu setzen, wenn noch aktuell
  Device.SetFVF         (D3DFVF_XYZRHW or D3DFVF_TEX1 or D3DFVF_DIFFUSE);
  Device.SetRenderState (D3DRS_ALPHABLENDENABLE,          1                   );
  Device.SetRenderState (D3DRS_BLENDOP,                   D3DBLENDOP_ADD      );
  Device.SetRenderState (D3DRS_SEPARATEALPHABLENDENABLE,  1                   );
  Device.SetRenderState (D3DRS_SRCBLEND,                  D3DBLEND_SRCALPHA   );
  Device.SetRenderState (D3DRS_DESTBLEND,                 D3DBLEND_INVSRCALPHA);
  Device.SetRenderState (D3DRS_SRCBLENDALPHA,             D3DBLEND_ONE        );
  Device.SetRenderState (D3DRS_DESTBLENDALPHA,            D3DBLEND_ONE        );
  Device.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
  Device.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
  Device.SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_DIFFUSE);
  Device.SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TEXTURE);
  Device.SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_DIFFUSE);
  Device.SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TEXTURE);
  Device.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, Verticies, SizeOf(TTextureVertex));
  FStoredStateBlock.Apply;
end;

procedure TDXDX9Surface.InitSurface(AWidth, AHeight: DWord);
begin
  if FAILED(FDX9RenderInterface.Device.CreateTexture(AWidth, AHeight, 1, D3DUSAGE_RENDERTARGET,
    D3DFMT_A8R8G8B8, D3DPOOL_DEFAULT, FTexture, nil)) then
  begin
    raise EDXRendererException.Create('Could not create texture.');
  end;
  if FAILED(FTexture.GetSurfaceLevel(0, FSurfaceLevel)) then
  begin
    raise EDXRendererException.Create('Could not acquire surface level of texture.');
  end;
end;

procedure TDXDX9Surface.Resize(AWidth, AHeight: DWord);
begin
  if (AWidth = FWidth) and (AHeight = FHeight) then Exit;
  if (AWidth = 0) or (AHeight = 0) then
  begin
    raise EDXInvalidArgumentException.Create('Invalid surface size.');
  end;
  InitSurface(AWidth, AHeight);
  FWidth := AWidth;
  FHeight := AHeight;
end;

end.
