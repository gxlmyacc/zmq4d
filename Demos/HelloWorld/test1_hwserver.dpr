{

  Hello World server in Delphi
  Binds REP socket to tcp://*:5555
  Expects "Hello" from client, replies with "World"

  Translated from the original C code from the ZeroMQ Guide.

}
program test1_hwserver;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Responder: PZMQSocket;
  sMsg: WideString;
begin
  //  Socket to talk to clients
  Responder := ZMQ.Context.Socket(stResponse);
  Responder.Bind('tcp://*:5555');

  while True do
  begin
    //  Wait for next Request from client
    Responder.RecvString(sMsg);
    Writeln('Received: ' + sMsg);

    //  Do some 'work'
    Sleep (1);

    //  Send Reply back to client
    Responder.SendString('World');
  end;
end.
