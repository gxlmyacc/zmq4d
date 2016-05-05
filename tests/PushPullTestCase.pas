unit PushPullTestCase;

interface

uses
    TestFramework, Classes, Windows, ZmqIntf;

const
  cBind = 'tcp://*:5555';
  cConnect = 'tcp://127.0.0.1:5555';
  
type

  TPushPullTestCase = class(TTestCase)
  private
    context: IZMQContext;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure SendString;
    procedure SendStringThread;
    procedure SendStringThreadFirstConnect;
  end;

implementation

uses
  Sysutils
  ;

var
  ehandle: THandle;

{ TPushPullTestCase }

procedure TPushPullTestCase.SetUp;
begin
  inherited;
  context := ZMQ.CreateContext;
end;

procedure TPushPullTestCase.TearDown;
begin
  inherited;
  context := nil;
end;

procedure TPushPullTestCase.SendString;
var
  sPush,sPull: PZMQSocket;
  s: WideString;
  rc: Integer;
begin
  sPush := context.Socket( stPush );
  try
    sPush.bind( cBind );
    sPull := context.Socket( stPull );
    try
      sPull.connect( cConnect );
      sPush.SendString( 'Hello' );
      rc := sPull.RecvString( s );
      CheckEquals( 5*ZMQ_CHAR_SIZE, rc, 'checking result' );
      CheckEquals( 'Hello', s, 'checking value' );
    finally
      sPull.Free;
    end;
  finally
    sPush.Free;
  end;
end;

procedure PushProc( lcontext: IZMQContext );
var
  sPush: PZMQSocket;
begin
  WaitForSingleObject( ehandle, INFINITE );
  sPush := lcontext.Socket( stPush );
  try
    sPush.bind( cBind );
    sPush.SendString( 'Hello' );
  finally
    sPush.Free;
  end;
end;

procedure TPushPullTestCase.SendStringThread;
var
  sPull: PZMQSocket;
  s: WideString;
  rc: Integer;
  tid: Cardinal;
begin
  SetEvent( ehandle );
  BeginThread( nil, 0, @pushProc, Pointer(context), 0, tid );

  sPull := context.Socket( stPull );
  try
    sPull.connect( cConnect );
    rc := sPull.RecvString( s );
    CheckEquals( 5*ZMQ_CHAR_SIZE, rc, 'checking result' );
    CheckEquals( 'Hello', s, 'checking value' );

  finally
    sPull.Free;
  end;

end;

// should work, because push blocks until a downstream node
// become available.
procedure TPushPullTestCase.SendStringThreadFirstConnect;
var
  sPull: PZMQSocket;
  s: WideString;
  rc: Integer;
  tid: Cardinal;
begin
  ResetEvent( ehandle );
  BeginThread( nil, 0, @pushProc, Pointer(context), 0, tid );

  sPull := context.Socket( stPull );
  try
    sPull.connect( cConnect );
    SetEvent( ehandle );
    rc := sPull.RecvString( s );
    CheckEquals( 5*ZMQ_CHAR_SIZE, rc, 'checking result' );
    CheckEquals( 'Hello', s, 'checking value' );

  finally
    sPull.Free;
  end;
end;

{
  try
    SetEvent( ehandle );
    WaitForSingleObject( ehandle, INFINITE );
  finally
  end;
}
initialization
  RegisterTest(TPushPullTestCase.Suite);
  ehandle := CreateEvent( nil, true, true, nil );

finalization
  CloseHandle( ehandle );

end.
