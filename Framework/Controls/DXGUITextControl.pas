unit DXGUITextControl;

interface

uses
  Winapi.Messages, DXGUIFramework, DXGUITypes, DXGUIFont;

const
  CM_TEXTCONTROL                 = WM_USER        + $2749;
  CM_TEXTCONTROL_FONT_CHANGED    = CM_TEXTCONTROL + $0001;
  CM_TEXTCONTROL_CAPTION_CHANGED = CM_TEXTCONTROL + $0002;

type
  TCMTextControlFontChanged = TCMSimpleMessage;
  TCMTextControlCaptionChanged = TCMSimpleMessage;

type
  TDXCaption = type String;

  TDXCustomTextControl = class(TDXControl)
  private
    FFont: TDXFont;
    FParentFontInstance: TDXFont;
    FParentFontChanging: Boolean;
    FCaption: TDXCaption;
    FParentFont: Boolean;
  private
    procedure SetCaption(const Value: TDXCaption);
    procedure SetParentFont(const Value: Boolean);
  private
    function FindParentFont: TDXFont;
    procedure UpdateParentFont(Font: TDXFont);
  protected
    procedure CMChangeNotification(var Message: TCMChangeNotification); override;
    procedure CMControlParentChanged(var Message: TCMControlParentChanged);
      message CM_CONTROL_PARENT_CHANGED;
    procedure CMFontChanged(var Message: TCMTextControlFontChanged);
      message CM_TEXTCONTROL_FONT_CHANGED;
    procedure CMCaptionChanged(var Message: TCMTextControlCaptionChanged);
      message CM_TEXTCONTROL_CAPTION_CHANGED;
  protected
    property Font: TDXFont read FFont;
    property Caption: TDXCaption read FCaption write SetCaption;
    property ParentFont: Boolean read FParentFont write SetParentFont default true;
  public
    constructor Create(Manager: TDXGUIManager; AOwner: TDXComponent);
    destructor Destroy; override;
  end;

implementation

{ TDXCustomTextControl }

procedure TDXCustomTextControl.CMCaptionChanged(var Message: TCMTextControlCaptionChanged);
begin

end;

procedure TDXCustomTextControl.CMChangeNotification(var Message: TCMChangeNotification);
var
  MessageFont: TCMTextControlFontChanged;
begin
  inherited;
  if (Message.Sender is TDXFont) then
  begin
    if (Message.Sender = FFont) then
    begin
      if (not FParentFontChanging) then SetParentFont(false);
    end else
    begin
      FParentFontChanging := true;
      FFont.Assign(FParentFontInstance);
      FParentFontChanging := false;
    end;
    MessageFont.MessageId := CM_TEXTCONTROL_FONT_CHANGED;
    Self.Dispatch(MessageFont);
  end;
end;

procedure TDXCustomTextControl.CMFontChanged(var Message: TCMTextControlFontChanged);
begin

end;

procedure TDXCustomTextControl.CMControlParentChanged(var Message: TCMControlParentChanged);
begin
  inherited;
  if (FParentFont) then
  begin
    UpdateParentFont(FindParentFont);
  end else
  begin
    UpdateParentFont(nil);
  end;
end;

constructor TDXCustomTextControl.Create(Manager: TDXGUIManager; AOwner: TDXComponent);
begin
  inherited Create(Manager, AOwner);
  FFont := TDXFont.Create(Manager);
  FFont.InsertChangeObserver(Self);
  FCaption := ClassName;
  FParentFont := true;
end;

destructor TDXCustomTextControl.Destroy;
begin
  FFont.Free;
  if Assigned(FParentFontInstance) then
  begin
    FParentFontInstance.RemoveChangeObserver(Self);
  end;
  inherited;
end;

function TDXCustomTextControl.FindParentFont: TDXFont;
var
  C: TDXControl;
begin
  Result := nil;
  C := Self.Parent;
  while Assigned(C) do
  begin
    if (C is TDXCustomTextControl) and
      ((not TDXCustomTextControl(C).ParentFont) or (not Assigned(C.Parent))) then
    begin
      Result := TDXCustomTextControl(C).Font;
      Break;
    end;
    C := C.Parent;
  end;
end;

procedure TDXCustomTextControl.UpdateParentFont(Font: TDXFont);
var
  I: Integer;
begin
  if (Assigned(FParentFontInstance)) and (not FParentFont) then
  begin
    FParentFontInstance.RemoveChangeObserver(Self);
    FParentFontInstance := nil;
  end;
  if (FParentFont) then
  begin
    if Assigned(Font) and (FParentFontInstance <> Font) then
    begin
      FParentFontInstance := Font;
      FParentFontInstance.InsertChangeObserver(Self);
      FParentFontChanging := true;
      FFont.Assign(FParentFontInstance);
      FParentFontChanging := false;
    end;
  end;
  if (not Assigned(Font)) then Font := FFont;
  for I := 0 to ControlCount - 1 do
  begin
    if (Controls[I] is TDXCustomTextControl) and
      (TDXCustomTextControl(Controls[I]).ParentFont) then
    begin
      TDXCustomTextControl(Controls[I]).UpdateParentFont(Font);
    end;
  end;
end;

procedure TDXCustomTextControl.SetCaption(const Value: TDXCaption);
var
  Message: TCMTextControlCaptionChanged;
begin
  if (FCaption <> Value) then
  begin
    FCaption := Value;
    Message.MessageId := CM_TEXTCONTROL_CAPTION_CHANGED;
    Self.Dispatch(Message);
  end;
end;

procedure TDXCustomTextControl.SetParentFont(const Value: Boolean);
begin
  if (FParentFont <> Value) then
  begin
    FParentFont := Value;
    if Value then
    begin
      UpdateParentFont(FindParentFont);
    end else
    begin
      UpdateParentFont(nil);
    end;
  end;
end;

end.
