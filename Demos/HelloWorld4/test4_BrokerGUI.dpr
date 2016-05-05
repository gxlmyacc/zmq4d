program test4_BrokerGUI;

uses
  Forms,
  fmBroker in 'fmBroker.pas' {frmBroker},
  uBrokerThread in 'uBrokerThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmBroker, frmBroker);
  Application.Run;
end.
