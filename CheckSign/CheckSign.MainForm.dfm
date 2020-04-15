object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Check Sign'
  ClientHeight = 109
  ClientWidth = 382
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ReadButton: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Read'
    TabOrder = 0
    OnClick = ReadButtonClick
  end
  object SignedCheckBox: TCheckBox
    Left = 8
    Top = 39
    Width = 97
    Height = 17
    Caption = 'Firmata'
    TabOrder = 1
  end
  object SignedFromTextbox: TEdit
    Left = 8
    Top = 62
    Width = 345
    Height = 21
    TabOrder = 2
    TextHint = 'Firmata da'
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'exe'
    FileName = 'D:\Documenti\#Desktop\Certificati\Batch\OSItalia.FE.Firma.exe'
    Filter = 'Programma (*.exe)|*.exe|Tutti i file (*.*)|*.*'
    Title = 'Selezionare un programma'
    Left = 88
    Top = 8
  end
end
