unit formMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ImgList, Vcl.StdCtrls, Vcl.ExtCtrls, Winapi.Direct3D9,
  Winapi.D3DX9, Winapi.DXTypes, Vcl.ComCtrls, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxEdit, cxInplaceContainer, cxVGrid, cxOI, cxClasses,
  dxSkinsForm, dxSkinSeven, dxSkinsCore, DXGUIFramework, DXGUIDX9RenderInterface, DXGUIWindow,
  DXGUIButton, DXGUIImageList, DXGUIPanel, DXGUIRenderInterface, DXGUICheckBox, DXGUIRadioButton,
  DXGUIProgressBar, DXGUITrackBar, DXGUITypes, DXGUILabel, Vcl.AppEvnts, DXGUIPageControl,
  dxRibbonSkins, dxSkinsdxRibbonPainter, dxSkinsdxBarPainter, dxBar, dxRibbon, dxStatusBar,
  dxRibbonStatusBar, dxRibbonForm, untFormDesigner, dxSkinBlueprint, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinHighContrast, dxSkinOffice2013White, dxSkinSevenClassic,
  dxSkinSharpPlus, dxSkinTheAsphaltWorld, dxSkinVS2010, dxSkinWhiteprint, dxSkinBlue,
  dxRibbonCustomizationForm, System.ImageList;

type
  TfrmMain = class(TdxRibbonForm)
    Inspector: TcxRTTIInspector;
    tmrRender: TTimer;
    dxSkinController: TdxSkinController;
    ApplicationEvents: TApplicationEvents;
    dxRibbonTab1: TdxRibbonTab;
    dxRibbon: TdxRibbon;
    dxBarManager: TdxBarManager;
    dxRibbonStatusBar: TdxRibbonStatusBar;
    dxBarManagerBar1: TdxBar;
    lbDrawFocusRect: TdxBarLargeButton;
    imgIcons16: TcxImageList;
    imgIcons32: TcxImageList;
    dxBarManagerBar2: TdxBar;
    lbDrawDragPoints: TdxBarLargeButton;
    procedure ApplicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure lbDrawFocusRectClick(Sender: TObject);
    procedure lbDrawDragPointsClick(Sender: TObject);
    procedure tmrRenderTimer(Sender: TObject);
  private
    FDesigner: TDXFormDesigner;
    FBackground: TDXTexture;
  private
    procedure DesignerInitialized(Sender: TObject);
    procedure DesignerSelectedControlChanged(Sender: TObject);
    procedure DesignerBeforePaint(Sender: TObject);
  private
    PB1: TDXProgressBar;
    procedure TrackBarChanged(Sender: TObject);
  public
    { Public-Deklarationen }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses DXGUIStatusBar;

procedure TfrmMain.DesignerBeforePaint(Sender: TObject);
var
  Renderer: TDXRenderer;
begin
  FDesigner.RenderInterface.Renderer.DrawTextureCentered(FBackground, FDesigner.ClientRect);
  Renderer := FDesigner.RenderInterface.Renderer;

  Renderer.BeginSequence;
  Renderer.ClippingWriteEnabled := true;
  Renderer.ClippingEnabled := true;
  Renderer.NextClippingLayer;
  Renderer.FillRect(125, 125, 50, 50, $ffffffff);
  Renderer.PrevClippingLayer;
  Renderer.ClippingWriteEnabled := False;
  Renderer.FillRect(100, 100, 100, 100, $ffff0000);
  Renderer.EndSequence;
//  Renderer.FillRect();
end;

procedure TfrmMain.DesignerInitialized(Sender: TObject);
var
  Icons: TDXImageList;
  Wnd1, Wnd2: TDXWindow;
  Btn1, Btn2, Btn3, Btn4: TDXButton;
  Pnl1: TDXPanel;

  CB1: TDXCheckBox;
  RB1, RB2, RB3: TDXRadioButton;


  LBL1: TDXLabel;

  TB1, TB2: TDXTrackBar;
  PC: TDXPageControl;
  TS1, TS2, TS3: TDXTabSheet;
  SB: TDXStatusBar;
begin
  FBackground := FDesigner.RenderInterface.CreateTexture(hInstance, 'BACKGROUND', RT_RCDATA);

  Wnd2 := TDXWindow.Create(FDesigner.GUIManager);
  Wnd2.Left := 20;
  Wnd2.Top := 20;
  Wnd2.Width := 400;
  Wnd2.Height := 250;
  Wnd2.Name := 'Window2';

  CB1 := TDXCheckBox.Create(FDesigner.GUIManager, Wnd2);
  CB1.Parent := Wnd2;
  CB1.Left := 20;
  CB1.Top := 20;
  CB1.Name := 'CheckBox1';

  RB1 := TDXRadioButton.Create(FDesigner.GUIManager, Wnd2);
  RB1.Parent := Wnd2;
  RB1.Left := 20;
  RB1.Top := 50;
  RB1.Name := 'RadioButton1';

  RB2 := TDXRadioButton.Create(FDesigner.GUIManager, Wnd2);
  RB2.Parent := Wnd2;
  RB2.Left := 20;
  RB2.Top := 80;
  RB2.Name := 'RadioButton2';

  RB3 := TDXRadioButton.Create(FDesigner.GUIManager, Wnd2);
  RB3.Parent := Wnd2;
  RB3.Left := 20;
  RB3.Top := 110;
  RB3.Name := 'RadioButton3';

  Wnd1 := TDXWindow.Create(FDesigner.GUIManager);
  Wnd1.Left := 50;
  Wnd1.Top := 50;
  Wnd1.Width := 700;
  Wnd1.Height := 520;
  Wnd1.Name := 'Window1';

  Icons := TDXImageList.Create(FDesigner.GUIManager, Wnd1);
  Icons.Width := 16;
  Icons.Height := 16;
  Icons.Add(hInstance, 'ICON', RT_RCDATA);
  Icons.Add(hInstance, 'LOAD', RT_RCDATA);
  Icons.Add(hInstance, 'SAVE', RT_RCDATA);
  Icons.Add(hInstance, 'CLOSE', RT_RCDATA);
  // Icons.Delete(0);
  Wnd1.Icons := Icons;
  Wnd1.IconIndex := 0;
  Wnd2.Icons := Icons;
  Wnd2.IconIndex := 0;


  Btn1 := TDXButton.Create(FDesigner.GUIManager, Wnd1);
  Btn1.Parent := Wnd1;
  Btn1.Left := 20;
  Btn1.Top := 20;
  Btn1.Width := 120;
  Btn1.Height := 27;
  Btn1.Name := 'Button1';
  Btn1.Images := Icons;
  Btn1.ImageIndex := 1;

  PB1 := TDXProgressBar.Create(FDesigner.GUIManager, Wnd1);
  PB1.Parent := Wnd1;
  PB1.Left := 160;
  PB1.Top := 20;
  PB1.Name := 'ProgressBar1';
  PB1.Position := 80;
  //PB1.Color := $FF007FFF;

  TB1 := TDXTrackBar.Create(FDesigner.GUIManager, Wnd1);
  TB1.Parent := Wnd1;
  TB1.Left := 20;
  TB1.Top := 60;
  TB1.Width := 300;
  TB1.Height := 41;
  TB1.Name := 'TrackBar1';
  TB1.Min := 0;
  TB1.Max := 100;
  TB1.Position := 80;
  TB1.Frequency := 5;
  TB1.OnChanged := TrackBarChanged;

  TB2 := TDXTrackBar.Create(FDesigner.GUIManager, Wnd1);
  TB2.Parent := Wnd1;
  TB2.Left := 590;
  TB2.Top := 60;
  TB2.Width := 41;
  TB2.Height := 300;
  TB2.Name := 'TrackBar2';
  TB2.Position := 3;
  TB2.Orientation := trVertical;

  Pnl1 := TDXPanel.Create(FDesigner.GUIManager, Wnd1);
  Pnl1.Parent := Wnd1;
  Pnl1.Top := 20;
  Pnl1.Left := 340;
  Pnl1.Width := 230;
  Pnl1.Height := 130;

  Btn2 := TDXButton.Create(FDesigner.GUIManager, Pnl1);
  Btn2.Parent := Pnl1;
  Btn2.Left := 20;
  Btn2.Top := 20;
  Btn2.Width := 120;
  Btn2.Height := 26;
  Btn2.Name := 'Button2';
  Btn2.Images := Icons;
  Btn2.ImageIndex := 2;

  LBL1 := TDXLabel.Create(FDesigner.GUIManager, Wnd1);
  LBL1.Parent := Wnd1;
  LBL1.Caption := 'TDXLabel';
  LBL1.Left := 20;
  LBL1.Top := 150;
  LBL1.Color := DXCOLOR_ARGB($ff, $ff, $00, $00);

  PC := TDXPageControl.Create(FDesigner.GUIManager, Wnd1);
  PC.Parent := Wnd1;
  PC.Top := 190;
  PC.Left := 20;
  PC.Width := 500;
  PC.Height := 250;
  PC.Animated := true;
  PC.Images := Icons;

  TS1 := TDXTabSheet.Create(FDesigner.GUIManager, PC);
  TS1.Parent := PC;
  TS1.ImageIndex := 0;
  TS2 := TDXTabSheet.Create(FDesigner.GUIManager, PC);
  TS2.Parent := PC;
  TS2.ImageIndex := 2;
  TS3 := TDXTabSheet.Create(FDesigner.GUIManager, PC);
  TS3.Parent := PC;

  Btn3 := TDXButton.Create(FDesigner.GUIManager, TS1);
  Btn3.Parent := TS1;
  Btn3.Left := 20;
  Btn3.Top := 20;
  Btn3.Width := 120;
  Btn3.Height := 26;
  Btn3.Name := 'Button3';
  Btn3.Images := Icons;
  Btn3.ImageIndex := 2;

  Btn4 := TDXButton.Create(FDesigner.GUIManager, TS2);
  Btn4.Parent := TS2;
  Btn4.Left := 120;
  Btn4.Top := 120;
  Btn4.Width := 120;
  Btn4.Height := 26;
  Btn4.Name := 'Button4';
  Btn4.Images := Icons;
  Btn4.ImageIndex := 0;

  PC.ActivePage := TS2;

  SB := TDXStatusBar.Create(FDesigner.GUIManager, Wnd1);
  SB.Parent := Wnd1;

  FDesigner.GUIManager.ActivateWindow(Wnd1);
  FDesigner.SelectControl(Wnd1);
end;

procedure TfrmMain.DesignerSelectedControlChanged(Sender: TObject);
begin
  Inspector.InspectedObject := FDesigner.SelectedControl;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDesigner := TDXFormDesigner.Create(Self);
  FDesigner.Parent := Self;
  FDesigner.Align := Vcl.Controls.alClient;
  FDesigner.OnInitialized := DesignerInitialized;
  FDesigner.OnSelectedControlChanged := DesignerSelectedControlChanged;
  FDesigner.OnBeforePaint := DesignerBeforePaint;
  FDesigner.DrawFocusRect := true;
  FDesigner.DrawDragPoints := true;
end;

procedure TfrmMain.lbDrawDragPointsClick(Sender: TObject);
begin
  FDesigner.DrawDragPoints := lbDrawDragPoints.Down;
end;

procedure TfrmMain.lbDrawFocusRectClick(Sender: TObject);
begin
  FDesigner.DrawFocusRect := lbDrawFocusRect.Down;
end;

procedure TfrmMain.tmrRenderTimer(Sender: TObject);
begin
  if FDesigner.NeedsRepaint then
  begin
    InvalidateRect(FDesigner.Handle, nil, false);
  end;
end;

procedure TfrmMain.TrackBarChanged(Sender: TObject);
begin
  PB1.Position := TDXTrackBar(Sender).Position;
end;

procedure TfrmMain.ApplicationEventsMessage(var Msg: tagMSG; var Handled: Boolean);
begin
  // INFO: MouseWheel Messages an das Designer Panel weiterleiten
  if (Msg.hwnd <> FDesigner.Handle) and (Msg.message = WM_MOUSEWHEEL) then
  begin
    PostMessage(FDesigner.Handle, Msg.message, Msg.wParam, Msg.lParam);
  end;
end;

end.
