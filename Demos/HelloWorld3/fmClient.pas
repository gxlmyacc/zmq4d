unit fmClient;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmClient = class(TForm)
    btnDemo1: TButton;
    btnDemo2: TButton;
    Memo1: TMemo;
    edtName: TLabeledEdit;
    procedure btnDemo2Click(Sender: TObject);
    procedure btnDemo1Click(Sender: TObject);
  private
    procedure AddLine(const s: string);
  public
  end;

var
  frmClient: TfrmClient;

implementation

uses ZmqIntf;

{$R *.dfm}

procedure TfrmClient.AddLine(const s: string);
begin
  Memo1.Lines.Add(s);
  Application.ProcessMessages;
end;

procedure TfrmClient.btnDemo1Click(Sender: TObject);
var
  Context: IZMQContext;
  Requestor: PZMQSocket;
  I: Integer;
  Msg: WideString;
begin
  Context := Zmq.CreateContext();

  //  Socket to talk to server
  AddLine('Connecting to hello world server');
  Requestor := Context.Socket(stRequest);
  Requestor.Connect('tcp://localhost:5555');

  for I := 0 to 50 do
  begin
    Msg := Format('Hello %d from %s', [I, edtName.Text]);
    AddLine(Format('Sending... %s', [Msg]));
    Requestor.SendString(Msg);

    Requestor.RecvString(Msg);
    AddLine(Format('Received %d - %s', [I, Msg]));
  end;

  Requestor.Free;
end;

procedure TfrmClient.btnDemo2Click(Sender: TObject);
var
  Context: IZMQContext;
  Requestor: PZMQSocket;
  Msg: WideString;
  I: Integer;
begin
  Context := Zmq.CreateContext();

  //  Socket to talk to server
  AddLine('Connecting to hello world server');
  Requestor := Context.Socket(stRequest);
  Requestor.Connect('tcp://localhost:5555');
  Requestor.Connect('tcp://localhost:5556');

  for I := 0 to 50 do
  begin
    Msg := Format('Hello %d from %s', [I, edtName.Text]);
    AddLine(Format('Sending... %s', [Msg]));
    Requestor.SendString(Msg);

    Requestor.RecvString(Msg);
    AddLine(Format('Received %d - %s', [I, Msg]));
  end;
  Requestor.Free;
end;

end.
