program SignApp;

uses
  Vcl.Forms,
  SignApp.MainForm in 'SignApp.MainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
