program DirectXGUIEditor;

{$R 'Textures.res' 'Textures.rc'}

uses
  Vcl.Forms,
  formMain in 'Formulare\formMain.pas' {frmMain},
  DXGUIFramework in 'Framework\DXGUIFramework.pas',
  DXGUITypes in 'Framework\DXGUITypes.pas',
  DXGUIDX9RenderInterface in 'Renderer\DXGUIDX9RenderInterface.pas',
  DXGUIRenderInterface in 'Renderer\DXGUIRenderInterface.pas',
  DXGUIGraphics in 'Framework\DXGUIGraphics.pas',
  DXGUIExceptions in 'Framework\DXGUIExceptions.pas',
  DXGUIWindow in 'Framework\Controls\DXGUIWindow.pas',
  DXGUIButton in 'Framework\Controls\DXGUIButton.pas',
  DXGUITextControl in 'Framework\Controls\DXGUITextControl.pas',
  DXGUIImageList in 'Framework\Components\DXGUIImageList.pas',
  DXGUICheckBox in 'Framework\Controls\DXGUICheckBox.pas',
  DXGUIEdit in 'Framework\Controls\DXGUIEdit.pas',
  DXGUILabel in 'Framework\Controls\DXGUILabel.pas',
  DXGUIPageControl in 'Framework\Controls\DXGUIPageControl.pas',
  DXGUIPanel in 'Framework\Controls\DXGUIPanel.pas',
  DXGUIProgressBar in 'Framework\Controls\DXGUIProgressBar.pas',
  DXGUIRadioButton in 'Framework\Controls\DXGUIRadioButton.pas',
  DXGUITrackBar in 'Framework\Controls\DXGUITrackBar.pas',
  DXGUIAnimations in 'Framework\DXGUIAnimations.pas',
  DXGUIFont_new in 'Framework\DXGUIFont_new.pas',
  DXGUIMessages in 'Framework\DXGUIMessages.pas',
  untFormDesigner in 'untFormDesigner.pas',
  DXGUIFont in 'Framework\DXGUIFont.pas',
  DXGUIStatusBar in 'Framework\Controls\DXGUIStatusBar.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
