program test3_hwServer;

uses
  Forms,
  fmServer in 'fmServer.pas' {frmServer},
  uServerThread in 'uServerThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmServer, frmServer);
  Application.Run;
end.
