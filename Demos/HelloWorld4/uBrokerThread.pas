unit uBrokerThread;

interface

uses
  SysUtils,
  Classes;

type
  TBrokerThread = class(TThread)
  private
    FFrontEnd: Integer;
    FBackEnd: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(aCreateSuspended: Boolean; const aFront, aBack: Integer); overload;
    property FrontEnd: Integer read FFrontEnd write FFrontEnd;
    property BackEnd: Integer read FBackEnd write FBackEnd;
  end;

implementation

uses
  ZmqIntf;

{ TServerThread }

constructor TBrokerThread.Create(aCreateSuspended: Boolean; const aFront, aBack: Integer);
begin
  FFrontEnd := aFront;
  FBackEnd := aBack;
  FreeOnTerminate := True;
  inherited Create(aCreateSuspended);
end;

procedure TBrokerThread.Execute;
var
  FrontSocket: PZMQSocket;
  BackSocket: PZMQSocket;
  FrontLoc: WideString;
  BackLoc: WideString;
begin
  FrontLoc := 'tcp://*:' + IntToStr(FFrontEnd);
  BackLoc := 'tcp://*:' + IntToStr(FBackEnd);

  // Socket facing clients
  FrontSocket := Zmq.Context.Socket(stRouter);
  FrontSocket.Bind(FrontLoc);

  // Socket facing services
  BackSocket := Zmq.Context.Socket(stDealer);
  BackSocket.Bind(BackLoc);

  // Start built-in device
  ZMQ.Device(dQueue, FrontSocket, BackSocket);

  //  Close connection (we never get here).
  FrontSocket.Free;
  FrontSocket.Free;
end;

end.
