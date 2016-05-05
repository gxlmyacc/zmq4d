unit uServerThread;

interface

uses
  SysUtils,
  Classes;

type
  TServerThread = class(TThread)
  private
    FPort: Integer;
    FRetrunValue: Integer;
    FMsg: WideString;
  protected
    procedure DoSynchronizeS;
    procedure DoSynchronizeI;
    procedure DoSynchronizeR;
    procedure DoSynchronizeE;
    procedure Execute; override;
  public
    constructor Create(aCreateSuspended: Boolean; const aPort: Integer = 5560); overload;
    property Port: Integer read FPort write FPort;
  end;

implementation

uses
  fmServer, ZmqIntf;

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
  Location: string;
begin
  Synchronize(DoSynchronizeS);

  TimeOut := 50;
  Context := Zmq.CreateContext(1);

  //  Socket to talk to clients

  Location := 'tcp://localhost:' + IntToStr(FPort);

  Responder := Context.Socket(stResponse);
  try
    Responder.SetSndTimeout(TimeOut);
    FRetrunValue := Responder.ConnectEx(Location);
    Synchronize(DoSynchronizeI);

    while not Terminated do
    begin
      //  Wait for next request from client
      Responder.RecvString(Msg);

      if Msg <> '' then
      begin
        FMsg := Msg;
        Synchronize(DoSynchronizeR);

        //  Do some 'work'
        Sleep (500);

        //  Send reply back to client
        Responder.SendString('World');
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

procedure TServerThread.DoSynchronizeI;
begin
  frmServer.Memo1.Lines.Add('Return value: ' + IntToStr(FRetrunValue));
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
