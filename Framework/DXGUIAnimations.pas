unit DXGUIAnimations;

interface

uses
  Winapi.Windows, DXGUITypes, DXGUIFramework;

// ============================================================================================== //
{ Interface }

type
  IDXEasingCurve = interface['{CD802EA3-109F-41B8-B1DF-8C5C1D87CA1B}']
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single;
  end;

  TDXCustomEasingCurve = class(TInterfacedObject, IDXEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; virtual; abstract;
  end;

  TDXCustomAnimation = class(TObject)
  private
    FStartTimestamp: Int64;
    FDuration: DWord;
    FEasingCurve: IDXEasingCurve;
    FRunning: Boolean;
    FTimePassed: DWord;
    FCurrentEasingValue: Single;
  private
    function CurrentTimestamp: Int64;
  protected
    procedure UpdateAnimation(EasingValue: Single); virtual; abstract;
  public
    procedure Start(Duration: DWord; const EasingCurve: IDXEasingCurve = nil);
    procedure Update;
    procedure Cancel;
    procedure Reset;
  public
    destructor Destroy; override;
  public
    property Duration: DWord read FDuration default 200;
    property EasingCurve: IDXEasingCurve read FEasingCurve;
    property Running: Boolean read FRunning;
    property TimePassed: DWord read FTimePassed;
    property CurrentEasingValue: Single read FCurrentEasingValue;
  end;

  TDXLinearEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInQuadEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXOutQuadEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInOutQuadEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInCubicEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXOutCubicEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInOutCubicEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInQuartEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXOutQuartEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInOutQuartEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInQuintEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXOutQuintEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInOutQuintEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXInOutElasticEasingCurve = class(TDXCustomEasingCurve)
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  end;

  TDXBezierPointList = array of Double;

  TDXBezierEasingCurve = class(TDXCustomEasingCurve)
  private
    FPoints: TDXBezierPointList;
    FBezierCurve: TDXBezierPointList;
  private
    function Factorial(N: Integer): Double;
    function Ni(N, I: Integer): Double;
    function Bernstein(N, I: Integer; T: Double): Double;
  private
    procedure Bezier2D(const InputPoints: TDXBezierPointList; var OutputPoints: TDXBezierPointList);
  protected
    function CalculateEasingCurve(TimePassed, Duration: DWord): Single; override;
  public
    constructor Create(const Points: TDXBezierPointList);
    destructor Destroy; override;
  end;

  TDXSimpleAnimation = class(TDXCustomAnimation)
  protected
    procedure UpdateAnimation(EasingValue: Single); override;
  end;

  TDXFadeAnimation = class(TDXCustomAnimation)
  private
    FControl: TDXControl;
    FAlphaBlendStart: Byte;
    FAlphaBlendEnd: Byte;
  protected
    procedure UpdateAnimation(EasingValue: Single); override;
  public
    procedure Start(Duration: DWord; EasingCurve: IDXEasingCurve;
      Control: TDXControl; AlphaBlendStart, AlphaBlendEnd: Byte);
  end;

  TDXColorAnimation = class(TDXCustomAnimation)
  private
    FCurrentColor: TDXColor;
    FSA, FSR, FSG, FSB: Byte;
    FFA, FFR, FFG, FFB: Byte;
  protected
    procedure UpdateAnimation(EasingValue: Single); override;
  public
    procedure Start(Duration: DWord; EasingCurve: IDXEasingCurve; StartColor, FinalColor: TDXColor);
  public
    property CurrentColor: TDXColor read FCurrentColor;
  end;

implementation

uses
  System.Math, DXGUIExceptions;

// ============================================================================================== //
{ TDXCustomAnimation }

procedure TDXCustomAnimation.Cancel;
begin
  FRunning := false;
  FTimePassed := 0;
end;

function TDXCustomAnimation.CurrentTimestamp: Int64;
var
  Timestamp, Frequency: Int64;
begin
  if (not QueryPerformanceFrequency(Frequency)) or (not QueryPerformanceCounter(Timestamp)) then
  begin
    Result := GetTickCount;
  end else
  begin
    Result := Round(Timestamp * 1000 / Frequency);
  end;
end;

destructor TDXCustomAnimation.Destroy;
begin
  FEasingCurve := nil;
  inherited;
end;

procedure TDXCustomAnimation.Reset;
begin
  UpdateAnimation(0);
  FRunning := false;
end;

procedure TDXCustomAnimation.Start(Duration: DWord; const EasingCurve: IDXEasingCurve);
begin
  if (FRunning) then Exit;
  FDuration := Duration;
  FEasingCurve := EasingCurve;
  if (not Assigned(FEasingCurve)) then
  begin
    FEasingCurve := TDXLinearEasingCurve.Create;
  end;
  FStartTimestamp := CurrentTimestamp;
  FTimePassed := 0;
  FRunning := true;
  Update;
end;

procedure TDXCustomAnimation.Update;
begin
  if (not FRunning) then Exit;
  FTimePassed := CurrentTimestamp - FStartTimestamp;
  if (FTimePassed >= FDuration) then
  begin
    FTimePassed := FDuration;
    FRunning := false;
  end;
  FCurrentEasingValue := EasingCurve.CalculateEasingCurve(FTimePassed, FDuration);
  UpdateAnimation(FCurrentEasingValue);
end;

// ============================================================================================== //
{ TDXLinearEasingCurve }

function TDXLinearEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
begin
  Result := TimePassed / Duration;
end;

// ============================================================================================== //
{ TDXBezierEasingCurve }

const
  FACTORIAL_LOOKUP: array[0..32] of Double = (
    1.0,
    1.0,
    2.0,
    6.0,
    24.0,
    120.0,
    720.0,
    5040.0,
    40320.0,
    362880.0,
    3628800.0,
    39916800.0,
    479001600.0,
    6227020800.0,
    87178291200.0,
    1307674368000.0,
    20922789888000.0,
    355687428096000.0,
    6402373705728000.0,
    121645100408832000.0,
    2432902008176640000.0,
    51090942171709440000.0,
    1124000727777607680000.0,
    25852016738884976640000.0,
    620448401733239439360000.0,
    15511210043330985984000000.0,
    403291461126605635584000000.0,
    10888869450418352160768000000.0,
    304888344611713860501504000000.0,
    8841761993739701954543616000000.0,
    265252859812191058636308480000000.0,
    8222838654177922817725562880000000.0,
    263130836933693530167218012160000000.0
  );

function TDXBezierEasingCurve.Bernstein(N, I: Integer; T: Double): Double;
var
  TI, TNI: Double;
begin
  if (T = 0) and (I = 0) then
  begin
    TI := 1;
  end else
  begin
    TI := Power(T, I);
  end;
  if (N = I) and (T = 1) then
  begin
    TNI := 1;
  end else
  begin
    TNI := Power(1 - T, N - I);
  end;
  Result := NI(N, I) * TI * TNI;
end;

procedure TDXBezierEasingCurve.Bezier2D(const InputPoints: TDXBezierPointList;
  var OutputPoints: TDXBezierPointList);
var
  T, Step, Basis: Double;
  I, J: Integer;
begin
  T := 0;
  Step := 1 / (Length(OutputPoints) - 1);
  for I := 0 to Length(OutputPoints) - 1 do
  begin
    if ((1 - T) < 5e-6) then T := 1;
    OutputPoints[I] := 0;
    for J := 0 to Length(InputPoints) - 1 do
    begin
      Basis := Bernstein(Length(InputPoints) - 1, J, T);
      OutputPoints[I] := OutputPoints[I] + Basis * InputPoints[J];
    end;
    T := T + Step;
  end;
end;

function TDXBezierEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
begin
  Result := 0;
  {$WARNINGS OFF}
  if (Length(FBezierCurve) <> Duration) then
  {$WARNINGS ON}
  begin
    SetLength(FBezierCurve, Duration);
    Bezier2D(FPoints, FBezierCurve);
  end;
  if (TimePassed <= Duration) then
  begin
    Result := FBezierCurve[TimePassed - 1];
  end;
end;

constructor TDXBezierEasingCurve.Create(const Points: TDXBezierPointList);
begin
  inherited Create;
  FPoints := Points;
end;

destructor TDXBezierEasingCurve.Destroy;
begin

  inherited;
end;

function TDXBezierEasingCurve.Factorial(N: Integer): Double;
begin
  if (N < 0) or (N > 32) then
  begin
    raise EDXInvalidArgumentException.Create('Factorial base value out of bounds (0..32).');
  end;
  Result := FACTORIAL_LOOKUP[n];
end;

function TDXBezierEasingCurve.Ni(N, I: Integer): Double;
begin
  Result := Factorial(N) / (Factorial(I) * Factorial(N - I));
end;

// ============================================================================================== //
{ TDXSimpleAnimation }

procedure TDXSimpleAnimation.UpdateAnimation(EasingValue: Single);
begin

end;

// ============================================================================================== //
{ TDXFadeAnimation }

procedure TDXFadeAnimation.Start(Duration: DWord; EasingCurve: IDXEasingCurve;
  Control: TDXControl; AlphaBlendStart, AlphaBlendEnd: Byte);
begin
  FControl := Control;
  FAlphaBlendStart := AlphaBlendStart;
  FAlphaBlendEnd := AlphaBlendEnd;
  inherited Start(Duration, EasingCurve);
end;

procedure TDXFadeAnimation.UpdateAnimation(EasingValue: Single);
begin
  FControl.AlphaBlend := FAlphaBlendStart +
    Round(EasingValue * (FAlphaBlendEnd - FAlphaBlendStart));
end;

// ============================================================================================== //
{ TDXColorAnimation }

procedure TDXColorAnimation.Start(Duration: DWord; EasingCurve: IDXEasingCurve;
  StartColor, FinalColor: TDXColor);
begin
  DXCOLOR_DECODE_ARGB(StartColor, FSA, FSR, FSG, FSB);
  DXCOLOR_DECODE_ARGB(FinalColor, FFA, FFR, FFG, FFB);
  inherited Start(Duration, EasingCurve);
end;

procedure TDXColorAnimation.UpdateAnimation(EasingValue: Single);
begin
  FCurrentColor := DXCOLOR_ARGB(
    Round(EasingValue * FFA + (1 - EasingValue) * FSA),
    Round(EasingValue * FFR + (1 - EasingValue) * FSR),
    Round(EasingValue * FFG + (1 - EasingValue) * FSG),
    Round(EasingValue * FFB + (1 - EasingValue) * FSB)
  );
end;

// ============================================================================================== //

{ TDXInQuadEasingCurve }

function TDXInQuadEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / Duration;
  Result := P * P;
end;

{ TDXOutQuadEasingCurve }

function TDXOutQuadEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / Duration;
  Result := - (P) * (P - 2);
end;

{ TDXInOutQuadEasingCurve }

function TDXInOutQuadEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / (Duration / 2);
  if (P < 1) then
  begin
    Result := 1 / 2 * P * P;
  end else
  begin
    Result := - 1 / 2 * ((P - 1) * (P - 3) - 1);
  end;
end;

{ TDXInCubicEasingCurve }

function TDXInCubicEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / Duration;
  Result := P * P * P;
end;

{ TDXOutCubicEasingCurve }

function TDXOutCubicEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / (Duration - 1);
  Result := P * P * P + 1;
end;

{ TDXInOutCubicEasingCurve }

function TDXInOutCubicEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / (Duration / 2);
  if (P < 1) then
  begin
    Result := 1 / (2 * P * P * P);
  end else
  begin
    P := P - 2;
    Result := 1 / 2 * (P * P * P + 2);
  end;
end;

{ TDXInQuartEasingCurve }

function TDXInQuartEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / Duration;
  Result := P * P * P * P;
end;

{ TDXOutQuartEasingCurve }

function TDXOutQuartEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / (Duration - 1);
  Result := - (P * P * P * P) - 1;
end;

{ TDXInOutQuartEasingCurve }

function TDXInOutQuartEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / (Duration / 2);
  if (P < 1) then
  begin
    Result := 1 / (2 * P * P * P * P);
  end else
  begin
    P := P - 2;
    Result := - 1 / 2 * (P * P * P * P - 2);
  end;
end;

{ TDXInQuintEasingCurve }

function TDXInQuintEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / Duration;
  Result := P * P * P * P * P;
end;

{ TDXOutQuintEasingCurve }

function TDXOutQuintEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := (TimePassed / Duration) - 1;
  Result := P * P * P * P * P + 1;
end;

{ TDXInOutQuintEasingCurve }

function TDXInOutQuintEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  P: Double;
begin
  P := TimePassed / (Duration / 2);
  if (P < 1) then
  begin
    Result := 1 / 2 * P * P * P * P * P;
  end else
  begin
    P := P - 2;
    Result := 1 / 2 * (P * P * P * P * P + 2);
  end;
end;

{ TDXInOutElasticEasingCurve }

function TDXInOutElasticEasingCurve.CalculateEasingCurve(TimePassed, Duration: DWord): Single;
var
  S, P, A, X: Double;
begin
  S := 1.70158;
  P := 0;
  A := 1;
  if (TimePassed = 0) then Exit(0);
  X := TimePassed / (Duration / 2);
  if (X = 2) then Exit(1);
  if (P = 0) then P := Duration * (0.3 * 1.5);
  if (A < Abs(1)) then
  begin
    A := 1;
    S := P / 4;
  end else
  begin
    S := P / (2 * PI) * ArcSin (1 / A);
  end;
  if (TimePassed < 1) then
  begin
    Exit(- 0.5 * (A * Power(2, 10 * TimePassed)) * Sin(((TimePassed - 1) * Duration - S) * (2 * PI) / P));
  end;
  Result := A * Power(2, - 10 * TimePassed) * Sin(((TimePassed - 1) * Duration - S) * (2 * PI) / P) + 1;
end;

end.
