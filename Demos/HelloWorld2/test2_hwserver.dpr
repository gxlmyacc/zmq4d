//
//  Hello World server in Delphi
//  Binds REP socket to tcp://*:5555
//  Expects "Hello" from client, replies with "World"
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test2_hwserver;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Responder: PZMQSocket;
  Msg: WideString;

begin
  //  Socket to talk to clients
  Responder := ZMQ.Context.Socket(stResponse);
  Responder.Bind('ipc://test');

  while True do
  begin
    //  Wait for next request from client
    Responder.RecvString(Msg);
    Writeln('Received: ', Msg);

    //  Do some 'work'
    Sleep (1);

    //  Send reply back to client
    Responder.SendString('World');
  end;
end.
