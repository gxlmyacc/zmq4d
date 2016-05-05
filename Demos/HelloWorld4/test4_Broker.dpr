//
//  Simple message queuing broker
//  Same as request-reply broker but using QUEUE device
//
//  Translated from the original C code from the ZeroMQ Guide.
//
program test4_Broker;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ZmqIntf;

var
  FrontSocket: PZMQSocket;
  BackSocket: PZMQSocket;
  FrontEnd: WideString;
  BackEnd: WideString;

begin
  if ParamStr(1) = '' then
    FrontEnd := '5559'
  else
    FrontEnd := ParamStr(1);

  if ParamStr(2) = '' then
    BackEnd := '5560'
  else
    BackEnd := ParamStr(2);

  FrontEnd := 'tcp://127.0.0.1:' + FrontEnd;
  BackEnd := 'tcp://127.0.0.1:' + BackEnd;

  // Socket facing clients
  FrontSocket := ZMQ.Context.Socket(stRouter);
  FrontSocket.Bind(FrontEnd);

  // Socket facing services
  BackSocket := ZMQ.Context.Socket(stDealer);
  BackSocket.Bind(BackEnd);

  // Start built-in device
  ZMQ.Device(dQueue, FrontSocket, BackSocket);

  //  Close connection (we never get here).
  FrontSocket.Free;
  BackSocket.Free;
end.
