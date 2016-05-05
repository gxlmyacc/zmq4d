object frmBroker: TfrmBroker
  Left = 348
  Top = 203
  Width = 335
  Height = 237
  Caption = 'REQ-REP Broker'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnStart: TButton
    Left = 104
    Top = 96
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 2
    OnClick = btnStartClick
  end
  object edtFrontEnd: TLabeledEdit
    Left = 16
    Top = 32
    Width = 75
    Height = 21
    EditLabel.Width = 47
    EditLabel.Height = 13
    EditLabel.Caption = 'Front End'
    TabOrder = 0
    Text = '5559'
  end
  object edtBackEnd: TLabeledEdit
    Left = 192
    Top = 32
    Width = 75
    Height = 21
    EditLabel.Width = 43
    EditLabel.Height = 13
    EditLabel.Caption = 'Back End'
    TabOrder = 1
    Text = '5560'
  end
end
