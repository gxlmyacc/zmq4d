unit uServerThread;

interface

uses
  SysUtils,
  Classes;

type
  TServerThread = class(TThread)
  private
    FPort: Integer;
    FMsg: WideString;
  protected
    procedure DoSynchronizeS;
    procedure DoSynchronizeR;
    procedure DoSynchronizeE;
    procedure Execute; override;
  public
    constructor Create(aCreateSuspended: Boolean; const aPort: Integer = 5555); overload;
    property Port: Integer read FPort write FPort;
  end;

implementation

uses
  fmServer,
  ZmqIntf;

{ TServerThread }

constructor TServerThread.Create(aCreateSuspended: Boolean; const aPort: Integer);
begin
  FPort := aPort;
  FreeOnTerminate := True;
  inherited Create(aCreateSuspended);
end;

procedure TServerThread.Execute;
var
  Context: IZMQContext;
  Responder: PZMQSocket;
  Msg: WideString;
  TimeOut: Integer;
  Location: WideString;
begin
  Synchronize(DoSynchronizeS);

  TimeOut := 50;
  Context := Zmq.CreateContext();

  //  Socket to talk to clients

  Location := 'tcp://*:' + IntToStr(FPort);

  Responder := Context.Socket(stResponse);
  try
    Responder.SetRcvTimeout(TimeOut);
    Responder.Bind(Location);

    while not Terminated do
    begin
      //  Wait for next request from client
      responder.RecvString(Msg);

      if Msg <> '' then
      begin
        FMsg := Msg;
        Synchronize(DoSynchronizeR);

        //  Do some 'work'
        Sleep (300);

        //  Send reply back to client
        responder.SendString('World');
      end;
    end;
  finally
    //  Close connection
    Responder.Free;
    Context := nil;
    Synchronize(DoSynchronizeE);
  end;
end;

procedure TServerThread.DoSynchronizeS;
begin
  frmServer.Memo1.Lines.Add('Server started.');
end;

procedure TServerThread.DoSynchronizeR;
begin
  frmServer.Memo1.Lines.Add('Received: ' + FMsg);
end;

procedure TServerThread.DoSynchronizeE;
begin
  frmServer.Memo1.Lines.Add('Server stopped.');
end;


end.
