unit DXGUIGraphics;

interface

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI, Winapi.ActiveX;

function GDIPCreateBitmapFromFile(const Filename: String): TGPBitmap;
function GDIPCreateBitmapFromResource(hInstance: HINST; ResName, ResType: PChar): TGPBitmap;
procedure GDIPCopyBitmapData(Bitmap: TGPBitmap; var Data: Pointer; var DataLength: DWord);

implementation

uses
  DXGUITypes, DXGUIExceptions;

function GDIPCreateBitmapFromFile(const Filename: String): TGPBitmap;
begin
  Result := TGPBitmap.Create(Filename);
  if (Result.GetLastStatus <> Ok) then
  begin
    raise EDXGUIFrameworkException.Create('Could not load graphic.');
  end;
end;

function GDIPCreateBitmapFromResource(hInstance: HINST; ResName, ResType: PChar): TGPBitmap;
var
  hResInfo,
  hResGlobal,
  hMem: THandle;
  dwResSize: DWord;
  ResData,
  Data: Pointer;
  Stream: IStream;
begin
  Result := nil;
  hResInfo := FindResource(hInstance, ResName, ResType);
  if (hResInfo = 0) then Exit;
  hResGlobal := LoadResource(hInstance, hResInfo);
  if (hResGlobal = 0) then Exit;
  hMem := 0;
  try
    ResData := LockResource(hResGlobal);
    if (not Assigned(ResData)) then Exit;
    dwResSize := SizeofResource(hInstance, hResInfo);
    if (dwResSize = 0) then Exit;
    hMem := GlobalAlloc(GHND or GMEM_NODISCARD, dwResSize);
    if (hMem = 0) then Exit;
    Data := GlobalLock(hMem);
    if (not Assigned(Data)) then Exit;
    CopyMemory(Data, ResData, dwResSize);
    GlobalUnlock(hMem);
    Stream := nil;
    if FAILED(CreateStreamOnHGlobal(hMem, true, Stream)) then
    begin
      raise EDXGUIFrameworkException.Create('Could not create stream from gobal.');
    end;
    Result := TGPBitmap.Create(Stream);
    if (Result.GetLastStatus <> Ok) then
    begin
      raise EDXGUIFrameworkException.Create('Could not load graphic.');
    end;
  finally
    if (hMem <> 0) then GlobalFree(hMem);
    if (hResGlobal <> 0) then FreeResource(hResGlobal);
  end;
end;

procedure GDIPCopyBitmapData(Bitmap: TGPBitmap; var Data: Pointer; var DataLength: DWord);
var
  R: TGPRect;
  BitData: BitmapData;
  H: DWord;
begin
  R.X := 0;
  R.Y := 0;
  R.Width := Bitmap.GetWidth;
  R.Height := Bitmap.GetHeight;
  if (Bitmap.LockBits(R, ImageLockModeRead, PixelFormat32bppARGB, BitData) <> Ok) then
  begin
    raise EDXGUIFrameworkException.Create('Could not lock bitmap data.');
  end else try
    H := BitData.Height;
    // TODO: Bei negativer Sprite liegt ein bottom-up Bitmap vor
    {$WARNINGS OFF}
    DataLength := H * BitData.Stride;
    GetMem(Data, DataLength);
    CopyMemory(Data, BitData.Scan0, H * BitData.Stride);
    {$WARNINGS ON}
  finally
    {$IFDEF WIN64}
      {$MESSAGE WARN 'FIXEN: UnlockBits überschreibt SELF Paramater unter 64 Bit'}
    {$ELSE}
    if (Bitmap.UnlockBits(BitData) <> Ok) then
    begin
      raise EDXGUIFrameworkException.Create('Could not unlock bitmap data.');
    end;
    {$ENDIF}
  end;
end;

end.
