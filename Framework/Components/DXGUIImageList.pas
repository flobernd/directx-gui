unit DXGUIImageList;

interface

uses
  Winapi.Windows, Winapi.GDIPOBJ, DXGUIFramework, DXGUIRenderInterface, DXGUITypes;

// ============================================================================================== //
{ Interface }

type
  // TODO: Serialisieren und Deserialisieren implementieren
  TDXCustomImageList = class(TDXComponent)
  private
    FTexture: TDXTexture;
    FWidth: Integer;
    FHeight: Integer;
    FCount: Integer;
    FLineCapacity: Integer;
  private
    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
  private
    procedure InsertImage(Index: Integer; Bitmap: TGPBitmap);
    procedure DeleteImage(Index: Integer);
    procedure ResizeTexture(LineCapacity: DWord);
  public
    function Add(const Filename: String): Integer; overload;
    function Add(hInstance: HINST; ResName: PChar; ResType: PChar): Integer; overload;
    procedure Insert(Index: Integer; const Filename: String); overload;
    procedure Insert(Index: Integer; hInstance: HINST; ResName: PChar; ResType: PChar); overload;
    procedure Delete(Index: Integer);
    procedure Clear;
  public
    { General Drawing }
    procedure Draw(ImageIndex: Integer; TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    procedure Draw(ImageIndex: Integer; TargetX, TargetY: DWord;
      const Diffuse: TDXColor = clWhite); overload;
    { Centered Drawing }
    procedure DrawCentered(ImageIndex: Integer; TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
    { Stretched Drawing }
    procedure DrawStretched(ImageIndex: Integer; TargetRect: TRect;
      const Diffuse: TDXColor = clWhite); overload;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  public
    property Count: Integer read FCount;
  published
    property Width: Integer read FWidth write SetWidth default 16;
    property Height: Integer read FHeight write SetHeight default 16;
  end;

  TDXImageList = class(TDXCustomImageList)

  end;

implementation

uses
  System.Classes, DXGUIGraphics;

// ============================================================================================== //
{ TDXCustomImageList }

function TDXCustomImageList.Add(hInstance: HINST; ResName, ResType: PChar): Integer;
begin
  Result := FCount;
  InsertImage(Result, GDIPCreateBitmapFromResource(hInstance, ResName, ResType));
  SendChangeNotifications;
end;

function TDXCustomImageList.Add(const Filename: String): Integer;
begin
  Result := FCount;
  InsertImage(Result, GDIPCreateBitmapFromFile(Filename));
  SendChangeNotifications;
end;

procedure TDXCustomImageList.Clear;
begin
  FCount := 0;
  SendChangeNotifications;
end;

constructor TDXCustomImageList.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FTexture := Manager.RenderInterface.CreateTexture;
  FWidth := 16;
  FHeight := 16;
  FCount := 0;
  FLineCapacity := 0;
end;

procedure TDXCustomImageList.Delete(Index: Integer);
begin
  if (Index < FCount) then
  begin
    DeleteImage(Index);
    SendChangeNotifications;
  end;
end;

procedure TDXCustomImageList.DeleteImage(Index: Integer);
begin
(*var
  R: TRect;
  DataBackup: Pointer;
begin
  if (Index = FCount - 1) then
  begin
    Dec(FCount);
    FTexture.Resize(FCount * FWidth, FHeight);
  end else
  begin
    R := Rect(FWidth * (Index + 1), 0, FWidth * FCount, FHeight);
    GetMem(DataBackup, R.Width * SizeOf(TDXPixel));
    try
      FTexture.ReadImageData(R, DataBackup);
      Dec(FCount);
      FTexture.Resize(FCount * FWidth, FHeight);
      R.Left := R.Left - FWidth;
      R.Right := R.Right - FWidth;
      FTexture.WriteImageData(R, DataBackup, R.Width, R.Height);
    finally
      FreeMem(DataBackup);
    end;
  end; *)
end;

destructor TDXCustomImageList.Destroy;
begin
  FTexture.Free;
  inherited;
end;

procedure TDXCustomImageList.Draw(ImageIndex: Integer; TargetX, TargetY: DWord;
  const Diffuse: TDXColor);
begin
  if (ImageIndex < 0) or (ImageIndex >= FCount) then Exit;
  {$WARNINGS OFF}
  Manager.RenderInterface.Renderer.DrawTextureCentered(FTexture,
    Rect(ImageIndex * FWidth, 0, (ImageIndex + 1) * FWidth, FHeight),
    Rect(TargetX, TargetY, TargetX + FWidth, TargetY + FHeight), Diffuse);
  {$WARNINGS ON}
end;

procedure TDXCustomImageList.Draw(ImageIndex: Integer; TargetRect: TRect; const Diffuse: TDXColor);
begin
  if (ImageIndex < 0) or (ImageIndex >= FCount) then Exit;
  Manager.RenderInterface.Renderer.DrawTextureCentered(FTexture, Rect(ImageIndex * FWidth, 0,
    (ImageIndex + 1) * FWidth, FHeight), TargetRect, Diffuse);
end;

procedure TDXCustomImageList.DrawCentered(ImageIndex: Integer; TargetRect: TRect;
  const Diffuse: TDXColor);
begin
  if (ImageIndex < 0) or (ImageIndex >= FCount) then Exit;
  Manager.RenderInterface.Renderer.DrawTextureCentered(FTexture, Rect(ImageIndex * FWidth, 0,
    (ImageIndex + 1) * FWidth, FHeight), TargetRect, Diffuse);
end;

procedure TDXCustomImageList.DrawStretched(ImageIndex: Integer; TargetRect: TRect;
  const Diffuse: TDXColor);
begin
  if (ImageIndex < 0) or (ImageIndex >= FCount) then Exit;
  Manager.RenderInterface.Renderer.DrawTextureStretched(FTexture, Rect(ImageIndex * FWidth, 0,
    (ImageIndex + 1) * FWidth, FHeight), TargetRect, Diffuse);
end;

procedure TDXCustomImageList.Insert(Index: Integer; hInstance: HINST; ResName, ResType: PChar);
begin
  if (Index >= FCount) then Exit;
  InsertImage(Index, GDIPCreateBitmapFromResource(hInstance, ResName, ResType));
  SendChangeNotifications;
end;

procedure TDXCustomImageList.InsertImage(Index: Integer; Bitmap: TGPBitmap);
(*var
  BitmapData: Pointer;
  DataLength: DWord;
begin
  if (FCount + 1) > (FLineCapacity) then
  begin
    if (FLineCapacity = 0) then
    begin
      FLineCapacity := 1;
    end else
    begin
      FLineCapacity := FLineCapacity * 2;
    end;
    ResizeTexture(FLineCapacity);
  end;
  GDIPCopyBitmapData(Bitmap, BitmapData, DataLength);
  try
    if (Index = FCount) then
    begin

    end else
    begin

    end;
  finally
    FreeMem(BitmapData);
  end;  *)
var
  NeedResize: Boolean;
  Data, DataBackup: Pointer;
  DataLength: DWord;
  R: TRect;
begin
  // TODO: Resize Bitmap
  GDIPCopyBitmapData(Bitmap, Data, DataLength);
  try
    NeedResize := false;
    if ((FCount + 1) > FLineCapacity) then
    begin
      FLineCapacity := FLineCapacity * 2;
      if (FLineCapacity = 0) then FLineCapacity := 1;
      NeedResize := true;
    end;
    if (Index = FCount) then
    begin
      if NeedResize then FTexture.Resize(FLineCapacity * FWidth, FHeight);
      FTexture.WriteImageData(Rect(FWidth * Index, 0, FWidth * (Index + 1), FHeight), Data,
        Bitmap.GetWidth, Bitmap.GetHeight);
    end else
    begin
      R := Rect(FWidth * Index, 0, FWidth * FCount, FHeight);
      GetMem(DataBackup, R.Width * SizeOf(TDXPixel));
      try
        FTexture.ReadImageData(R, DataBackup);
        if NeedResize then FTexture.Resize(FLineCapacity * FWidth, FHeight, true);
        R.Left := R.Left + FWidth;
        R.Right := R.Right + FWidth;
        FTexture.WriteImageData(R, DataBackup, R.Width, R.Height);
      finally
        FreeMem(DataBackup);
      end;
      FTexture.WriteImageData(Rect(FWidth * Index, 0, FWidth * (Index + 1), FHeight), Data,
        Bitmap.GetWidth, Bitmap.GetHeight);
    end;
    Inc(FCount);
  finally
    FreeMem(Data);
  end;
end;

procedure TDXCustomImageList.ResizeTexture(LineCapacity: DWord);
begin

end;

procedure TDXCustomImageList.Insert(Index: Integer; const Filename: String);
begin
  if (Index >= FCount) then Exit;
  InsertImage(Index, GDIPCreateBitmapFromFile(Filename));
  SendChangeNotifications;
end;

procedure TDXCustomImageList.SetHeight(const Value: Integer);
begin
  if (Value <> FHeight) then
  begin
    Clear;
    FHeight := Value;
  end;
end;

procedure TDXCustomImageList.SetWidth(const Value: Integer);
begin
  if (Value <> FWidth) then
  begin
    Clear;
    FWidth := Value;
  end;
end;

initialization
  RegisterClass(TDXImageList);

end.
