unit CheckSign.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,

  CheckSign.CodeSignReader;

type

{ TMainForm }

  TMainForm = class(TForm)
    ReadButton: TButton;
    OpenDialog: TOpenDialog;
    SignedCheckBox: TCheckBox;
    SignedFromTextbox: TEdit;
    procedure ReadButtonClick(Sender: TObject);
  private
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

{ TMainForm }

procedure TMainForm.ReadButtonClick(Sender: TObject);
var
  LReader: TCodeSignReader;
begin
  if OpenDialog.Execute then
  begin
    LReader := TCodeSignReader.Create(OpenDialog.FileName);
    try
      SignedCheckBox.Checked := LReader.IsSigned;
      SignedFromTextbox.Text := LReader.CompanyName;
    finally
      LReader.Free;
    end;
  end;
end;

end.
