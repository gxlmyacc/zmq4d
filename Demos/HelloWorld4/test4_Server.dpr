program test4_Server;

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
