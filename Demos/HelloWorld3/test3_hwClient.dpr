program test3_hwClient;

uses
  Forms,
  fmClient in 'fmClient.pas' {frmClient};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmClient, frmClient);
  Application.Run;
end.
