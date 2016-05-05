//
//  Task worker
//  Connects PULL socket to tcp://localhost:5557
//  Collects workloads from ventilator via that socket
//  Connects PUSH socket to tcp://localhost:5558
//  Sends results to sink via that socket
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test6_worker;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Receiver: PZMQSocket;
  Sender: PZMQSocket;
  Msg: WideString;

begin
  //  Socket to receive messages on
  Receiver := ZMQ.Context.Socket(stPull);
  Receiver.Connect('tcp://localhost:5557');

  //  Socket to send messages to
  Sender := ZMQ.Context.Socket(stPush);
  Sender.Connect('tcp://localhost:5558');

  //  Process tasks forever
  while True do
  begin
    Receiver.RecvString(Msg);

    //  Simple progress indicator for the viewer
    Writeln(Msg);

    // Do the work
    Sleep(StrToInt(Msg));

    // Send result to sink
    Sender.SendString('');
  end;

  Receiver.Free;
  Sender.Free;
end.
