unit CheckSign.CodesignReader;

interface

uses
  System.SysUtils,
  System.Classes;

type

{ TCodesignReader }

  TCodesignReader = class
  strict private
    FFileName: String;
    FIsSigned: Boolean;
    FCompanyName: String;

    function IsCodeSigned: Boolean;
    function CompanySigningCertificate: String;
  public
    constructor Create(const AFileName: String);

    procedure AfterConstruction; override;

    property IsSigned: Boolean read FIsSigned;
    property CompanyName: String read FCompanyName;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Forms;

const
  CERT_SECTION_TYPE_ANY = $FF;

function ImageEnumerateCertificates(
  FileHandle: THandle;
  TypeFilter: WORD;
  out CertificateCount: DWORD;
  Indicies: PDWORD;
  IndexCount: Integer): BOOL; stdcall; external 'Imagehlp.dll';

function ImageGetCertificateHeader(
  FileHandle: THandle;
  CertificateIndex: Integer;
  var CertificateHeader: TWinCertificate): BOOL; stdcall; external 'Imagehlp.dll';

function ImageGetCertificateData(
  FileHandle: THandle;
  CertificateIndex: Integer;
  Certificate: PWinCertificate;
  var RequiredLength: DWORD): BOOL; stdcall; external 'Imagehlp.dll';

const
  CERT_NAME_SIMPLE_DISPLAY_TYPE = 4;
  PKCS_7_ASN_ENCODING = $00010000;
  X509_ASN_ENCODING = $00000001;

type
  PCCERT_CONTEXT = type Pointer;
  HCRYPTPROV_LEGACY = type Pointer;
  PFN_CRYPT_GET_SIGNER_CERTIFICATE = type Pointer;

  CRYPT_VERIFY_MESSAGE_PARA = record
    cbSize: DWORD;
    dwMsgAndCertEncodingType: DWORD;
    hCryptProv: HCRYPTPROV_LEGACY;
    pfnGetSignerCertificate: PFN_CRYPT_GET_SIGNER_CERTIFICATE;
    pvGetArg: Pointer;
  end;

function CryptVerifyMessageSignature(
  const pVerifyPara: CRYPT_VERIFY_MESSAGE_PARA;
  dwSignerIndex: DWORD;
  pbSignedBlob: PByte;
  cbSignedBlob: DWORD;
  pbDecoded: PBYTE;
  pcbDecoded: PDWORD;
  ppSignerCert: PCCERT_CONTEXT): BOOL; stdcall; external 'Crypt32.dll';

function CertGetNameStringA(
  pCertContext: PCCERT_CONTEXT;
  dwType: DWORD;
  dwFlags: DWORD;
  pvTypePara: Pointer;
  pszNameString: PAnsiChar;
  cchNameString: DWORD): DWORD; stdcall; external 'Crypt32.dll';

function CertFreeCertificateContext(
  pCertContext: PCCERT_CONTEXT): BOOL; stdcall; external 'Crypt32.dll';

function CertCreateCertificateContext(
  dwCertEncodingType: DWORD;
  pbCertEncoded: PBYTE;
  cbCertEncoded: DWORD): PCCERT_CONTEXT; stdcall; external 'Crypt32.dll';

const
  WINTRUST_ACTION_GENERIC_VERIFY_V2: TGUID = '{00AAC56B-CD44-11d0-8CC2-00C04FC295EE}';
  WTD_CHOICE_FILE = 1;
  WTD_REVOKE_NONE = 0;
  WTD_UI_NONE = 2;

type
  PWinTrustFileInfo = ^TWinTrustFileInfo;
  TWinTrustFileInfo = record
    cbStruct: DWORD;
    pcwszFilePath: PWideChar;
    hFile: THandle;
    pgKnownSubject: PGUID;
  end;

  PWinTrustData = ^TWinTrustData;
  TWinTrustData = record
    cbStruct: DWORD;
    pPolicyCallbackData: Pointer;
    pSIPClientData: Pointer;
    dwUIChoice: DWORD;
    fdwRevocationChecks: DWORD;
    dwUnionChoice: DWORD;
    pFile: PWinTrustFileInfo;
    dwStateAction: DWORD;
    hWVTStateData: THandle;
    pwszURLReference: PWideChar;
    dwProvFlags: DWORD;
    dwUIContext: DWORD;
  end;

function WinVerifyTrust(
  hwnd: HWND;
  const ActionID: TGUID;
  ActionData: Pointer): Longint; stdcall; external wintrust;

{ TCodesignReader }

constructor TCodesignReader.Create(const AFileName: String);
begin
  inherited Create;
  FFileName := AFileName;
end;

procedure TCodesignReader.AfterConstruction;
begin
  inherited AfterConstruction;
  FIsSigned := IsCodeSigned;
  FCompanyName := String.Empty;
  if FIsSigned then
    FCompanyName := CompanySigningCertificate;
end;

function TCodesignReader.IsCodeSigned: Boolean;
var
  file_info: TWinTrustFileInfo;
  trust_data: TWinTrustData;
begin
  FillChar(file_info, SizeOf(file_info), 0);
  file_info.cbStruct := sizeof(file_info);
  file_info.pcwszFilePath := PWideChar(WideString(FFilename));
  FillChar(trust_data, SizeOf(trust_data), 0);
  trust_data.cbStruct := sizeof(trust_data);
  trust_data.dwUIChoice := WTD_UI_NONE;
  trust_data.fdwRevocationChecks := WTD_REVOKE_NONE;
  trust_data.dwUnionChoice := WTD_CHOICE_FILE;
  trust_data.pFile := @file_info;
  Result := WinVerifyTrust(
    INVALID_HANDLE_VALUE,
    WINTRUST_ACTION_GENERIC_VERIFY_V2,
    @trust_data) = ERROR_SUCCESS
end;

function TCodesignReader.CompanySigningCertificate: String;
var
  hExe: HMODULE;
  Cert: PWinCertificate;
  CertContext: PCCERT_CONTEXT;
  CertCount: DWORD;
  CertName: AnsiString;
  CertNameLen: DWORD;
  VerifyParams: CRYPT_VERIFY_MESSAGE_PARA;
begin
  Result := String.Empty;
  hExe := CreateFile(
    PChar(FFilename),
    GENERIC_READ,
    FILE_SHARE_READ,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS,
    0);
  if hExe = INVALID_HANDLE_VALUE then
      Exit;
  try
    if (not ImageEnumerateCertificates(
      hExe, CERT_SECTION_TYPE_ANY, CertCount, nil, 0)) or
      (CertCount <> 1) then
        Exit;
    GetMem(Cert, SizeOf(TWinCertificate) + 3);
    try
      Cert.dwLength := 0;
      Cert.wRevision := WIN_CERT_REVISION_1_0;
      if not ImageGetCertificateHeader(hExe, 0, Cert^) then
        Exit;

      ReallocMem(Cert, SizeOf(TWinCertificate) + Cert.dwLength);
      if not ImageGetCertificateData(hExe, 0, Cert, Cert.dwLength) then
        Exit;

      FillChar(VerifyParams, SizeOf(VerifyParams), 0);
      VerifyParams.cbSize := SizeOf(VerifyParams);
      VerifyParams.dwMsgAndCertEncodingType :=
        X509_ASN_ENCODING or PKCS_7_ASN_ENCODING;
      if not CryptVerifyMessageSignature(
        VerifyParams,
        0,
        @Cert.bCertificate,
        Cert.dwLength,
        nil,
        nil,
        @CertContext) then
          Exit;

      try
        CertNameLen := CertGetNameStringA(
        CertContext, CERT_NAME_SIMPLE_DISPLAY_TYPE, 0, nil, nil, 0);
        SetLength(CertName, CertNameLen - 1);
        CertGetNameStringA(
          CertContext,
          CERT_NAME_SIMPLE_DISPLAY_TYPE,
          0,
          nil,
          PAnsiChar(CertName),
          CertNameLen);
        result := String(CertName);
      finally
        CertFreeCertificateContext(CertContext)
      end;
    finally
      FreeMem(Cert);
    end;
  finally
    CloseHandle(hExe);
  end;
end;

end.

