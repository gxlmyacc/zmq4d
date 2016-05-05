unit ThreadTestCase;

interface

uses
  TestFramework, Classes, Windows, ZmqIntf;

type
  TMyZMQThread = class(TInterfacedObject)
  private
    FThread: IZMQThread;
    tvar: Boolean;
  protected
    procedure DoExecute(AThread: TObject);
  public
    constructor Create(lArgs: Pointer; const ctx: IZMQContext);
    destructor Destroy; override;

    property Thread: IZMQThread read FThread;
  end;

  TThreadTestCase = class( TTestCase )
  private
    context: IZMQContext;

    tvar: Boolean;
    tmpS: WideString;

  public
    myThr: TMyZMQThread;

    procedure SetUp; override;
    procedure TearDown; override;

    procedure DetachedTestMeth( args: Pointer; const context: IZMQContext );
    procedure AttachedTestMeth( args: Pointer; const context: IZMQContext; const pipe: PZMQSocket );

    procedure AttachedPipeTestMeth( args: Pointer; const context: IZMQContext; const pipe: PZMQSocket );

    procedure InheritedThreadTerminate( Sender: TObject );

  published
    procedure CreateAttachedTest;
    procedure CreateDetachedTest;

    procedure CreateInheritedAttachedTest;
    procedure CreateInheritedDetachedTest;


    procedure AttachedPipeTest;
  end;

implementation

uses
  Sysutils
  ;

var
  ehandle: THandle;

{ TMyZMQThread }

constructor TMyZMQThread.Create(lArgs: Pointer; const ctx: IZMQContext);
begin
  FThread := ZMQ.CreateThread(lArgs, ctx);
  FThread.OnExecute := DoExecute;
end;

destructor TMyZMQThread.Destroy;
begin
  FThread := nil;
  inherited;
end;

procedure TMyZMQThread.doExecute;
begin
  // custom code.
  tvar := true;
  SetEvent( ehandle );
end;

{ TThreadTestCase }

procedure TThreadTestCase.SetUp;
begin
  inherited;
  ehandle := CreateEvent( nil, true, false, nil );

  context := ZMQ.CreateContext;
  tvar := false;
end;

procedure TThreadTestCase.TearDown;
begin
  inherited;
  context := nil;
  CloseHandle( ehandle );
end;

procedure TThreadTestCase.AttachedTestMeth( args: Pointer; const context: IZMQContext; const pipe: PZMQSocket );
begin
  tvar := true;
  SetEvent( ehandle );
end;

procedure TThreadTestCase.CreateAttachedTest;
var
  thr: IZMQThread;
begin
  thr := ZMQ.CreateAttached( AttachedTestMeth, context, nil );
  thr.FreeOnTerminate := true;
  thr.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  CheckEquals( true, tvar, 'tvar didn''t set' );

end;

procedure TThreadTestCase.DetachedTestMeth( args: Pointer; const context: IZMQContext );
begin
  tvar := true;
  context.Socket( TZMQSocketType( Args^ ) );
  Dispose( args );
  SetEvent( ehandle );
end;

procedure TThreadTestCase.CreateDetachedTest;
var
  thr: IZMQThread;
  sockettype: ^TZMQSocketType;
begin
  New( sockettype );
  sockettype^ := stDealer;
  thr := ZMQ.CreateDetached( DetachedTestMeth, sockettype );
  thr.FreeOnTerminate := true;
  thr.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  CheckEquals( true, tvar, 'tvar didn''t set' );

end;

procedure TThreadTestCase.InheritedThreadTerminate( Sender: TObject );
begin
  // this executes in the main thread.
  tvar := myThr.tvar;
end;

procedure TThreadTestCase.CreateInheritedAttachedTest;
begin
  mythr := TMyZMQThread.Create( nil, context );
  mythr.Thread.OnTerminate := InheritedThreadTerminate;
  mythr.Thread.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  sleep(10);
  mythr.Free;
  CheckEquals( true, tvar, 'tvar didn''t set' );
end;

procedure TThreadTestCase.CreateInheritedDetachedTest;
begin
  mythr := TMyZMQThread.Create( nil, nil );
  mythr.Thread.OnTerminate := InheritedThreadTerminate;
  mythr.Thread.Resume;

  WaitForSingleObject( ehandle, INFINITE );
  mythr.Free;
  CheckEquals( true, tvar, 'tvar didn''t set' );

end;

procedure TThreadTestCase.AttachedPipeTestMeth(args: Pointer;
  const context: IZMQContext; const pipe: PZMQSocket );
begin
  pipe.RecvString( tmpS );
  SetEvent( ehandle );
end;

procedure TThreadTestCase.AttachedPipeTest;
var
  thr: IZMQThread;
begin
  thr := ZMQ.CreateAttached( AttachedPipeTestMeth, context, nil );
  thr.FreeOnTerminate := true;
  thr.Resume;

  thr.pipe.SendString( 'hello pipe' );

  WaitForSingleObject( ehandle, INFINITE );
  CheckEquals( 'hello pipe', tmpS, 'pipe error' );

end;

initialization
  RegisterTest(TThreadTestCase.Suite);

end.
