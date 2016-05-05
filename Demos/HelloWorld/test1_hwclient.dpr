//
//  Hello World client in Delphi
//  Connects REQ socket to tcp://localhost:5555
//  Sends "Hello" to server, expect replies with "World"
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test1_hwclient;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Requestor: PZMQSocket;
  I: Integer;
  sMsg: WideString;
begin
  //  Socket to talk to server
  Writeln('Connecting to hello world server');
  Requestor := ZMQ.Context.Socket(stRequest);
  Requestor.Connect('tcp://localhost:5555');

  for I := 0 to 9 do
  begin
    sMsg := 'Hello' + IntToStr(I);
    Requestor.SendString(sMsg);
    Writeln(sMsg);

    Requestor.RecvString(sMsg);
    Writeln('Received: ' + sMsg);
  end;
end.
