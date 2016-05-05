//
//  Pubsub envelope subscriber
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test5_subscriber;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  Subscriber: PZMQSocket;
  Key: WideString;
  Topic: WideString;
  Msg: WideString;

begin
  Key := ParamStr(1);

  //  Socket to talk to server
  Writeln('Connecting to hello world server');
  Subscriber := ZMQ.Context.Socket(stSubscribe);
  Subscriber.Connect('tcp://localhost:5563');
  Subscriber.Subscribe(Key);

  while True do
  begin
    // Read the message topic.
    Subscriber.RecvString(Topic);
    // Read the content of the message.
    Subscriber.RecvString(Msg);

    Writeln(Format('%s - %s', [Topic, Msg]));
  end;

  Subscriber.Free;
end.
