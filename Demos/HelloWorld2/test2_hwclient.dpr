//
//  Hello World client in Delphi
//  Connects REQ socket to tcp://localhost:5555
//  Sends "Hello" to server, expects a reply with "World"
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test2_hwclient;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Requestor: PZMQSocket;
  Msg: WideString;
  I: Integer;

begin
  //  Socket to talk to server
  Writeln('Connecting to hello world server');
  Requestor := ZMQ.Context.Socket(stRequest);
  try
    Requestor.Connect('ipc://test');
  except
    on E: Exception do
    begin
      Writeln('error:'+e.message);
      Exit;
    end
  end;

  for I := 0 to 20 do
  begin
    Msg := Format('Hello %d from %s', [I, ParamStr(1)]);
    Writeln('Sending... ', Msg);
    Requestor.SendString(Msg);

    Requestor.RecvString(Msg);
    Writeln('Received ', I, Msg);
    Sleep(200);
  end;
end.
