unit SignApp.MainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  System.IOUtils,
  System.IniFiles,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.CheckLst,
  Vcl.Buttons,
  Vcl.ComCtrls;

type

{ TMainForm }

  TMainForm = class(TForm)
    FolderLabel: TLabel;
    FolderTextbox: TEdit;
    FolderButton: TSpeedButton;
    FolderOpenDialog: TFileOpenDialog;
    ApplicationsLabel: TLabel;
    ApplicationsListbox: TCheckListBox;
    SignToolLabel: TLabel;
    SignToolTextbox: TEdit;
    SignToolButton: TSpeedButton;
    SignToolOpenDialog: TFileOpenDialog;
    CertificateLabel: TLabel;
    CertificateTextbox: TEdit;
    CertificateButton: TSpeedButton;
    CertificateOpenDialog: TFileOpenDialog;
    PasswordLabel: TLabel;
    PasswordTextbox: TEdit;
    SignTypeLabel: TLabel;
    SignTypeCombobox: TComboBox;
    TimestampLabel: TLabel;
    TimeStampTextbox: TEdit;
    SignButton: TButton;
    procedure FolderButtonClick(Sender: TObject);
    procedure CertificateButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SignButtonClick(Sender: TObject);
    procedure SignToolButtonClick(Sender: TObject);
  strict private
    FIniFile: TIniFile;

    function IsApplication(const AExtension: String): Boolean;
    procedure SelectApplications(const AFolder: String);
    function GetSignCommand(
      const AFormat, ASignType, AApplication: String): String;
    procedure MakeSignCommands(const ACommands: TStrings);
    procedure ExecuteSignCommands(const ACommands: TStrings);
    procedure SignApplications;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FIniFile := TIniFile.Create(
    TPath.ChangeExtension(Application.ExeName, '.ini'));

  FolderTextbox.Text := FIniFile.ReadString('SignApp', 'Folder', '');
  SignToolTextbox.Text := FIniFile.ReadString('SignApp', 'SignTool', '');
  CertificateTextbox.Text := FIniFile.ReadString('SignApp', 'Certificate', '');
  PasswordTextbox.Text := FIniFile.ReadString('SignApp', 'Password', '');
  SignTypeCombobox.ItemIndex := StrToIntDef(
    FIniFile.ReadString('SignApp', 'SignType', ''), 2);
  TimeStampTextbox.Text := FIniFile.ReadString('SignApp', 'TimeStamp', '');

  if FolderTextbox.Text <> '' then
    SelectApplications(FolderTextbox.Text);
end;

function TMainForm.IsApplication(const AExtension: String): Boolean;
begin
  result := AExtension.Equals('.exe') or
    AExtension.Equals('.dll') or
    AExtension.Equals('.bpl');
end;

procedure TMainForm.SelectApplications(const AFolder: String);
var
  LFile: String;
begin
  ApplicationsListbox.Items.Clear;
  if TDirectory.Exists(AFolder) then
  begin
    for LFile in TDirectory.GetFiles(AFolder) do
      if IsApplication(TPath.GetExtension(LFile).ToLower()) then
        ApplicationsListbox.Items.Add(TPath.GetFileName(LFile));
    ApplicationsListbox.CheckAll(TCheckBoxState.cbChecked);
  end;
end;

procedure TMainForm.FolderButtonClick(Sender: TObject);
begin
  FolderOpenDialog.DefaultFolder := FolderTextbox.Text;
  if FolderOpenDialog.Execute then
  begin
    FolderTextbox.Text := FolderOpenDialog.FileName;
    SelectApplications(FolderTextbox.Text);
  end;
end;

procedure TMainForm.SignToolButtonClick(Sender: TObject);
begin
  SignToolOpenDialog.FileName := SignToolTextbox.Text;
  if SignToolOpenDialog.Execute then
    SignToolTextbox.Text := SignToolOpenDialog.FileName;
end;

procedure TMainForm.CertificateButtonClick(Sender: TObject);
begin
  CertificateOpenDialog.FileName := CertificateTextbox.Text;
  if CertificateOpenDialog.Execute then
    CertificateTextbox.Text := CertificateOpenDialog.FileName;
end;

procedure TMainForm.SignButtonClick(Sender: TObject);
begin
  Screen.Cursor := crHourglass;
  try
    FIniFile.WriteString('SignApp', 'Folder', FolderTextbox.Text);
    FIniFile.WriteString('SignApp', 'SignTool', SignToolTextbox.Text);
    FIniFile.WriteString('SignApp', 'Certificate', CertificateTextbox.Text);
    FIniFile.WriteString('SignApp', 'Password', PasswordTextbox.Text);
    FIniFile.WriteString(
      'SignApp', 'SignType', SignTypeCombobox.ItemIndex.ToString());
    FIniFile.WriteString('SignApp', 'TimeStamp', TimeStampTextbox.Text);

    SignApplications;
  finally
    Screen.Cursor := crDefault;
  end;
  MessageDlg('Operazione di firma completata.', mtInformation, [mbOk], 0);
end;

function TMainForm.GetSignCommand(
  const AFormat, ASignType, AApplication: String): String;
begin
  result := Format(AFormat, [
    SignToolTextbox.Text,
    ASignType,
    CertificateTextbox.Text,
    PasswordTextbox.Text,
    TimeStampTextbox.Text,
    TPath.Combine(FolderTextbox.Text, AApplication)]);
end;

procedure TMainForm.MakeSignCommands(const ACommands: TStrings);
const
  Command: String = '"%0:s" sign /fd %1:s /f "%2:s" /p %3:s /t %4:s "%5:s"';
  CommandAs: String = '"%0:s" sign /fd %1:s /f "%2:s" /p %3:s /tr %4:s /as "%5:s"';
var
  LIndex: Integer;
begin
  for LIndex := 0 to ApplicationsListbox.Items.Count - 1 do
    if ApplicationsListbox.Checked[LIndex] then
    begin
      case SignTypeCombobox.ItemIndex of
        0:
          ACommands.Add(GetSignCommand(
            Command, 'sha1', ApplicationsListbox.Items[LIndex]));
        1:
          ACommands.Add(GetSignCommand(
            Command, 'sha256', ApplicationsListbox.Items[LIndex]));
        2:
        begin
          ACommands.Add(GetSignCommand(
            Command, 'sha1', ApplicationsListbox.Items[LIndex]));
          ACommands.Add(GetSignCommand(
            CommandAs, 'sha256', ApplicationsListbox.Items[LIndex]));
        end;

        else
          raise Exception.Create('Tipo di firma non valido.');
      end;

    end;
end;

procedure TMainForm.ExecuteSignCommands(const ACommands: TStrings);
var
  LCommand: String;
  LCommandLine: array[0..2048] of char;
  LStartupInfo: TStartupInfo;
  LProcessInformation: TProcessInformation;
  LResult: Boolean;
  LExitCode: DWORD;
begin
  for LCommand in ACommands do
  begin
    StrPCopy(LCommandLine, LCommand);

    GetStartupInfo(LStartupInfo);
    LStartupInfo.wShowWindow := SW_HIDE;
    LStartupInfo.dwFlags := LStartupInfo.dwFlags or STARTF_FORCEOFFFEEDBACK;

    LResult := CreateProcess(
      nil,
      LCommandLine,
      nil,
      nil,
      False,
      0,
      nil,
      nil,
      LStartupInfo,
      LProcessInformation);

    if LResult then
    begin
      LExitCode := STILL_ACTIVE;
      WaitForSingleObject(LProcessInformation.hProcess, 1000);
      while GetExitCodeProcess(LProcessInformation.hProcess, LExitCode)  do
      begin
        Application.ProcessMessages;
        if LExitCode <> STILL_ACTIVE then
          break;
        WaitForSingleObject(LProcessInformation.hProcess, 1000);
      end;
    end;
  end;
end;

procedure TMainForm.SignApplications;
var
  LCommands: TStrings;
begin
  LCommands := TStringList.Create;
  try
    MakeSignCommands(LCommands);
    ExecuteSignCommands(LCommands);
  finally
    LCommands.Free;
  end;
end;

end.
