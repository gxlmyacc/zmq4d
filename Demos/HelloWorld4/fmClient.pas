unit fmClient;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfrmClient = class(TForm)
    btnDemo1: TButton;
    Memo1: TMemo;
    edtName: TLabeledEdit;
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
  Requester: PZMQSocket;
  I: Integer;
  Msg: WideString;
begin
  Context := ZMQ.CreateContext;

  //  Socket to talk to server
  AddLine('Connecting to hello world server');
  Requester := Context.Socket(stRequest);
  Requester.Connect('tcp://localhost:5559');

  for I := 0 to 50 do
  begin
    Msg := Format('Hello %d from %s', [I, edtName.Text]);
    AddLine(Format('Sending... %s', [Msg]));
    Requester.SendString(Msg);

    Requester.RecvString(Msg);
    AddLine(Format('Received %d - %s', [I, Msg]));
  end;

  Requester.Free;
  Context := nil;
end;

end.
