//
//  Task sink
//  Binds PULL socket to tcp://localhost:5558
//  Collects results from workers via that socket
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test6_sink;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  ZmqIntf;

var
  Receiver: PZMQSocket;
  Msg: WideString;
  I: Integer;
  StartTime: Cardinal;
  StopTime: Cardinal;

begin
  //  Socket to receive messages on
  Receiver := ZMQ.Context.Socket(stPull);
  Receiver.Bind('tcp://*:5558');

  //  Wait for start of batch
  Receiver.RecvString(Msg);

  //  Start our clock now
  StartTime := GetTickCount;

  //  Process 100 confirmations
  for I := 1 to 100 do
  begin
    Receiver.RecvString(Msg);

    if (I mod 10) = 0 then
      Write(':')
    else
      Write('.');
  end;
  StopTime := GetTickCount;
  Writeln;

  //  Calculate and report duration of batch
  Writeln(Format('Total elapsed time: %d msec', [StopTime - StartTime]));

  Receiver.Free;
end.
