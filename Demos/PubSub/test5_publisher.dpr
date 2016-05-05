//
//  Pubsub envelope publisher
//  Note that the zhelper.pas file also provides s_sendmore
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test5_publisher;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Publisher: PZMQSocket;
  Msg: IZMQMsg;
  Counter: Integer;
begin
  Counter := 0;

  //  Socket to publish from
  Publisher := ZMQ.Context.Socket(stPublish);
  Publisher.Bind('tcp://*:5563');

  // Add a pause, in order to allow subscribers time to establish connection with the publisher
  // otherwise early messages will be lost before subscribers have a chance to receive them.
  Sleep(1000);

  while True do
  begin
    Inc(Counter);
    Msg := ZMQ.CreateMsg;
    Msg.AddStr('A');
    Msg.AddStr('Only subscribers of ''A'' will see this. #' + IntToStr(Counter));
    Publisher.SendMsg(Msg);
    
    Inc(Counter);
    
    Msg := ZMQ.CreateMsg;
    Msg.AddStr('B');
    Msg.AddStr('If you subscribe to ''B'' you will see this. #' + IntToStr(Counter));
    Publisher.SendMsg(Msg);

    Sleep(100);
  end;

  //  We never get here but if we did, this would be how we end
  Publisher.Free;
end.
