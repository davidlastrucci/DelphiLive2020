program CheckSign;

uses
  Vcl.Forms,
  CheckSign.MainForm in 'CheckSign.MainForm.pas' {MainForm},
  CheckSign.CodeSignReader in 'CheckSign.CodeSignReader.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
