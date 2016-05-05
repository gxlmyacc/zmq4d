unit PollTestCase;
interface

uses
  TestFramework, Classes, Windows, ZmqIntf;

type

  TPollTestCase = class(TTestCase)
  private
    context: IZMQContext;
    poller: IZMQPoller;
    procedure PollEvent(const socket: PZMQSocket; const events: TZMQPollEvents );
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure PollRegister;
  end;

implementation

var
  ehandle: THandle;
  zmqPollItem: ^TZMQPollItem;

procedure TPollTestCase.PollEvent(const socket: PZMQSocket; const events: TZMQPollEvents);
begin
  zmqPollItem^.socket := socket;
  zmqPollItem^.events := events;
  SetEvent( ehandle );
end;

{ TPollTestCase }

procedure TPollTestCase.SetUp;
begin
  inherited;
  context := ZMQ.CreateContext;
  poller := ZMQ.CreatePoller( false, context );
  poller.onEvent := PollEvent;
end;

procedure TPollTestCase.TearDown;
begin
  inherited;
  poller := nil;
  context := nil;
end;

procedure TPollTestCase.PollRegister;
var
  sb,sc: PZMQSocket;
  s: WideString;
begin
  New( zmqPollItem );
  ehandle := CreateEvent( nil, true, false, nil );

  sb := context.Socket( stPair );
  sb.bind( 'inproc://pair' );
  sc := context.Socket( stPair );
  sc.connect( 'inproc://pair' );

  poller.Register( sb, [pePollIn], true );

  sc.SendString('Hello');

  WaitForSingleObject( ehandle, INFINITE );
  ResetEvent( ehandle );

  Check( zmqPollItem.socket = sb, 'wrong socket' );
  Check( zmqPollItem.events = [pePollIn], 'wrong event' );

  zmqPollItem.socket.RecvString( s );
  CheckEquals( 'Hello', s, 'wrong message received' );

  CloseHandle( ehandle );
  Dispose( zmqPollItem );
end;

initialization
  RegisterTest(TPollTestCase.Suite);

end.
