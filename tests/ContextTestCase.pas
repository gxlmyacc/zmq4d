unit ContextTestCase;

interface

uses
  TestFramework, Classes, Windows, ZmqIntf;

type

  TContextTestCase = class(TTestCase)
  private
    context: IZMQContext;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ContextTerminate;
    procedure ContextDefaults;
    procedure SetIOThreads;
    procedure SetMaxSockets;
    procedure CreateReqSocket;
    procedure lazyPirateBugTest;
  end;

implementation

uses
  SysUtils;

{ TContextTestCase }

procedure TContextTestCase.ContextTerminate;
var
  st: TZMQSocketType;
  FZMQsocket: PZMQSocket;
begin
  for st := Low( TZMQSocketType ) to High( TZMQSocketType ) do
  begin
    if context = nil then
      context := ZMQ.CreateContext;
    FZMQSocket := context.Socket( st );
    try
      FZMQSocket.bind('tcp://127.0.0.1:5555');
      context.Linger := 10;     
      //CheckEquals( True, FZMQSocket.Terminated, 'Socket has not terminated! socket type: ' + IntToStr( Ord( st ) ) );
    finally
      FZMQsocket.Free;
      context := nil;
    end;
  end;
end;

procedure TContextTestCase.CreateReqSocket;
var
  s: PZMQSocket;
  p: IZMQPoller;
begin
  s := context.Socket( stRequest );
  try
    p := ZMQ.CreatePoller( true );
    s.connect( 'tcp://127.0.0.1:5555' );
    s.SendString('hhhh');
    p.Register( s , [pepollin] );
    p.poll(1000);
    p := nil;

    s.SetLinger(0);
  finally
    s.Free;
  end;
  context := nil;
end;

procedure TContextTestCase.lazyPirateBugTest;
var
  sclient,
  sserver: PZMQSocket;
begin
  sserver := context.Socket( stResponse );
  try
    sserver.bind( 'tcp://*:5555' );

    sclient := context.Socket( stRequest );
    try
      sclient.connect( 'tcp://localhost:5555' );
      sclient.SendString('request1');
      sleep(500);
    finally
      sclient.Free;
    end;  

    sclient := context.Socket( stRequest );
    try
      sclient.connect( 'tcp://localhost:5555' );
      sclient.SendString('request1');
      sleep(500);
    finally
      sclient.Free;
    end;
  finally
    sserver.Free;
    sleep(500);
  end;
  context := nil;
end;

procedure TContextTestCase.SetUp;
begin
  context := ZMQ.CreateContext;
end;

procedure TContextTestCase.TearDown;
begin
  context := nil;
end;

procedure TContextTestCase.ContextDefaults;
begin
  CheckEquals( ZMQ_IO_THREADS_DFLT, context.IOThreads );
  CheckEquals( ZMQ_MAX_SOCKETS_DFLT, context.MaxSockets );
end;

procedure TContextTestCase.SetIOThreads;
begin
  CheckEquals( ZMQ_IO_THREADS_DFLT, context.IOThreads );
  context.IOThreads := 0;
  CheckEquals( 0, context.IOThreads );
  context.IOThreads := 2;
  CheckEquals( 2, context.IOThreads );
end;

procedure TContextTestCase.SetMaxSockets;
begin
  CheckEquals( ZMQ_MAX_SOCKETS_DFLT, context.MaxSockets );
  context.MaxSockets := 16;
  CheckEquals( 16, context.MaxSockets );
end;


initialization
  RegisterTest(TContextTestCase.Suite);

end.
