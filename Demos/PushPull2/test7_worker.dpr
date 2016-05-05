//
//  Task worker - Design 2
//  Connects PULL socket to tcp://localhost:5557
//  Collects workloads from ventilator via that socket
//  Connects PUSH socket to tcp://localhost:5558
//  Sends results to sink via that socket
//
//  Adds pub-sub flow to receive and respond to kill signal
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test7_worker;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Receiver: PZMQSocket;
  Sender: PZMQSocket;
  Controller: PZMQSocket;
  Msg: WideString;
  Items: TZMQPollItemArray;

begin
  //  Socket to receive messages on
  Receiver := ZMQ.Context.Socket(stPull);
  Receiver.Connect('tcp://localhost:5557');

  //  Socket to send messages to
  Sender := ZMQ.Context.Socket(stPush);
  Sender.Connect('tcp://localhost:5558');

  //  Socket for control input
  Controller := ZMQ.Context.Socket(stSubscribe);
  Controller.Connect('tcp://localhost:5559');
  Controller.Subscribe('');

  //  Process messages from receiver and controller
  SetLength(Items, 2);
  Items[0].socket := Receiver;
  Items[0].events := [pePollIn];
  Items[0].revents := [];

  Items[1].socket := Controller;
  Items[1].events := [pePollIn];
  Items[1].revents := [];

  //  Process messages from both sockets
  while True do
  begin
    ZMQ.Poll(Items);

    if pePollIn in Items[0].revents then
    begin
      Receiver.RecvString(Msg);

      // Do the work
      Sleep(StrToInt(Msg));

      // Send result to sink
      Sender.SendString('');

      //  Simple progress indicator for the viewer
      Write('.');
    end;

    //  Any waiting controller command acts as 'KILL'
    if pePollIn in Items[1].revents then
      Break; // Exit loop
  end;

  Writeln;
  Writeln('Worker stopped.');

  // Finished.
  Receiver.Free;
  Sender.Free;
  Controller.Free;
end.
