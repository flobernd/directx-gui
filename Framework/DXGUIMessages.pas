unit DXGUIMessages;

interface

uses
  Winapi.Windows;

function MAKEPOINTS(dwValue: DWord): TPoint; inline;
function GET_X_LPARAM(lParam: LPARAM): SmallInt; inline;
function GET_Y_LPARAM(lParam: LPARAM): SmallInt; inline;
function GET_WHEEL_DELTA_WPARAM(wParam: WPARAM): SmallInt; inline;
function GET_KEYSTATE_WPARAM(wParam: WPARAM): Word; inline;

implementation

function MAKEPOINTS(dwValue: DWord): TPoint;
begin
  Result.X := SmallInt(dwValue and $0000FFFF);
  Result.Y := SmallInt(dwValue shr 16);
end;

function GET_X_LPARAM(lParam: LPARAM): SmallInt;
begin
  Result := SmallInt(lParam and $0000FFFF);
end;

function GET_Y_LPARAM(lParam: LPARAM): SmallInt;
begin
  Result := SmallInt(lParam shr 16);
end;

function GET_WHEEL_DELTA_WPARAM(wParam: WPARAM): SmallInt;
begin
  Result := SmallInt(wParam shr 16);
end;

function GET_KEYSTATE_WPARAM(wParam: WPARAM): Word;
begin
  Result := wParam and $0000FFFF;
end;

end.
