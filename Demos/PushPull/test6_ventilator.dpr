//
//  Task ventilator
//  Binds PUSH socket to tcp://localhost:5557
//  Sends batch of tasks to workers via that socket
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test6_ventilator;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Sender: PZMQSocket;
  Sink: PZMQSocket;
  I: Integer;
  TotalMSec: Integer;
  WorkLoad: Integer;

begin
  //  Socket to send messages on
  Sender := ZMQ.Context.Socket(stPush);
  Sender.Bind('tcp://*:5557');

  //  Socket to send start of batch message on
  Sink := ZMQ.Context.Socket(stPush);
  Sink.Connect('tcp://localhost:5558');

  Writeln('Press Enter when the workers are ready: ');
  Readln;
  Writeln('Sending tasks to workers?');

  //  The first message is '0' and signals start of batch
  Sink.SendString('0');

  //  Initialize random number generator
  Randomize;

  //  Send 100 tasks
  TotalMSec := 0;
  for I := 1 to 100 do
  begin
    WorkLoad := Random(100) + 1;
    Inc(TotalMSec, WorkLoad);
    Sender.SendString(IntToStr(WorkLoad));
  end;

  Writeln(Format('Total expected cost: %d msec.', [TotalMSec]));
  Sleep(100);

  Sink.Free;
  Sender.Free;
end.
