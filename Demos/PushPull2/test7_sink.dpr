//
//  Task sink - Design 2
//  Binds PULL socket to tcp://localhost:5558
//  Collects results from workers via that socket
//
//  Adds pub-sub flow to send kill signal to workers when
//  all tasks are complete.
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test7_sink;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  ZmqIntf;

var
  Receiver: PZMQSocket;
  Controller: PZMQSocket;
  Msg: WideString;
  I: Integer;
  StartTime: Cardinal;
  StopTime: Cardinal;

begin
  //  Socket to receive messages on
  Receiver := ZMQ.Context.Socket(stPull);
  Receiver.Bind('tcp://*:5558');
  
  //  Socket for worker control
  Controller := ZMQ.Context.Socket(stPublish);
  Controller.Bind('tcp://*:5559');

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

  //  Send kill signal to workers
  Controller.SendString('KILL');

  //  Finished
  sleep (100); //  Give 0MQ time to deliver

  Receiver.Free;
  Controller.Free;
end.
