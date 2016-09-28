library Zmq4D;

{$R 'MyRes.res' 'MyRes.rc'}

uses
  ShareFastMM,
  {$IF CompilerVersion <= 15.0 }
  //Fastcode,
  //FastMove,
  {$IFEND}
  ZmqApiImpl in 'ZmqApiImpl.pas',
  f_DebugIntf in 'f_DebugIntf.pas',
  ZmqIntf in '..\Public\ZmqIntf.pas',
  ZmqImpl in 'ZmqImpl.pas',
  MemLibrary in 'MemLibrary.pas';

{$R *.res}

begin

end.
