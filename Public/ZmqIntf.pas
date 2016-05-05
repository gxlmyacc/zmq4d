unit ZmqIntf;

interface

uses
  SysUtils, Windows, ActiveX;

const
  ZMQEAGAIN            = 11;
  ZMQ_CHAR_SIZE        =  2;

(*  Default for new contexts                                                  *)

  ZMQ_IO_THREADS_DFLT  =  1;
  ZMQ_MAX_SOCKETS_DFLT = 1024;

const
  DLL_Zmq4D        = 'Zmq4D.dll';
  CLASSNAME_Zmq4D  = 'gxl.zmq4d.class';

  ZmqApi_FuncsCount       =  1;

  //function ZMQMananger: PIZMQMananger;
  FuncIdx_ZMQMananger     =  0;

type
  TZMQMonitorEvent = (
    meConnected,
    meConnectDelayed,
    meConnectRetried,
    meListening,
    meBindFailed,
    meAccepted,
    meAcceptFailed,
    meClosed,
    meCloseFailed,
    meDisconnected
  );
  TZMQMonitorEvents = set of TZMQMonitorEvent;

const
  cZMQMonitorEventsAll = [
    meConnected,
    meConnectDelayed,
    meConnectRetried,
    meListening,
    meBindFailed,
    meAccepted,
    meAcceptFailed,
    meClosed,
    meCloseFailed,
    meDisconnected
  ];

type
  IZMQFrame = interface;
  IZMQMsg = interface;
  IZMQContext = interface;

  TZMQSendFlag = (
    sfDontWait = 1,
    sfSndMore  = 2
  );
  TZMQSendFlags = set of TZMQSendFlag;

  TZMQRecvFlag = (
    rfDontWait = 1
  );
  TZMQRecvFlags = set of TZMQRecvFlag;

  TZMQMessageProperty = (
    mpMore   = 1
  );

  TZMQFreeProc = procedure(data, hint: Pointer) of object;

  IZMQFrame = interface
  ['{3F9FBFD0-234B-4FE3-AFFA-7BDD938D3078}']
    function GetHandle: Pointer;
    function GetI: Integer;
    function GetF: Single;
    function GetD: Double;
    function GetC: Currency;
    function GetDT: TDateTime;
    function GetH: WideString;
    function GetS: WideString;
    function GetProp(prop: TZMQMessageProperty): Integer;
    procedure SetI(const Value: Integer);
    procedure SetF(const Value: Single);
    procedure SetD(const Value: Double);
    procedure SetC(const Value: Currency);
    procedure SetDT(const Value: TDateTime);
    procedure SetH(const Value: WideString);
    procedure SetS(const Value: WideString);
    procedure SetProp(prop: TZMQMessageProperty; value: Integer);

    function Implementor: Pointer;

    procedure Rebuild; overload;
    procedure Rebuild(size: Cardinal); overload;
    procedure Rebuild(data: Pointer; size: Cardinal; ffn: TZMQFreeProc; hint: Pointer = nil); overload;
    procedure Move(const msg: IZMQFrame);
    procedure Copy(const msg: IZMQFrame);

    function Data: Pointer;
    function Size: Cardinal;
    function More: Boolean;

    function Dup: IZMQFrame;
    // convert the data into a readable string.
    function Dump: WideString;

    // copy the whole content of the stream to the message.
    procedure LoadFromStream(const strm: IStream);
    procedure SaveToStream(const strm: IStream);

    property Handle: Pointer read GetHandle;

    property S: WideString read GetS write SetS;
    property H: WideString read GetH write SetH;
    property I: Integer read GetI write SetI;
    property F: Single read GetF write SetF;
    property D: Double read GetD write SetD;
    property C: Currency read GetC write SetC;
    property DT: TDateTime read GetDT write SetDT;
    property Prop[prop: TZMQMessageProperty]: Integer read GetProp;
  end;

  // for multipart message
  IZMQMsg = interface
  ['{632CC740-F37A-4C75-A359-1ABBA3F09052}']
    function GetItem(indx: Integer): IZMQFrame;

    function Implementator: Pointer;

    // Push frame to the front of the message, i.e. before all other frames.
    // Message takes ownership of frame, will destroy it when message is sent.
    // Set the cursor to 0
    // Returns 0 on success, -1 on error.
    function Push(const msg: IZMQFrame): Integer;
    function PushStr(const str: WideString): Integer;
    function PushInt(const msg: Integer): Integer;

    // Remove first frame from message, if any. Returns frame, or NULL. Caller
    // now owns frame and must destroy it when finished with it.
    // Set the cursor to 0
    function Pop: IZMQFrame;
    function PopStr: WideString;
    function PopInt: Integer;
    // Add frame to the end of the message, i.e. after all other frames.
    // Message takes ownership of frame, will destroy it when message is sent.
    // Set the cursor to 0
    // Returns 0 on success
    function Add(const msg: IZMQFrame): Integer;
    function AddStr(const msg: WideString): Integer;
    function AddInt(const msg: Integer): Integer;

    // Push frame plus empty frame to front of message, before first frame.
    // Message takes ownership of frame, will destroy it when message is sent.
    procedure Wrap(const msg: IZMQFrame);
    // Pop frame off front of message, caller now owns frame
    // If next frame is empty, pops and destroys that empty frame.
    function Unwrap: IZMQFrame;

    // Set cursor to first frame in message. Returns frame, or NULL.
    function First: IZMQFrame;
    // Return the next frame. If there are no more frames, returns NULL. To move
    // to the first frame call zmsg_first(). Advances the cursor.
    function Next: IZMQFrame;
    // Return the last frame. If there are no frames, returns NULL.
    // Set the cursor to the last
    function Last: IZMQFrame;

    // Create copy of message, as new message object
    function Dup: IZMQMsg;
    // dumpt message
    function Dump: WideString;

    function  SaveAsHex: WideString;
    procedure LoadFromHex(const data: WideString);

    procedure Clear;
    // Remove specified frame from list, if present. Does not destroy frame.
    // Set the cursor to 0
    procedure Remove(const msg: IZMQFrame);

    // Return size of message, i.e. number of frames (0 or more).
    function Size: Integer;
    // Return size of message, i.e. number of frames (0 or more).
    function ContentSize: Integer;

    property Item[indx: Integer]: IZMQFrame read GetItem; default;
  end;

  TZMQSocketType = (
    stPair       = 0,
    stPublish    = 1,
    stSubscribe  = 2,
    stRequest    = 3,
    stResponse   = 4,
    stDealer     = 5,
    stRouter     = 6,
    stPull       = 7,
    stPush       = 8,
    stXPublish   = 9,
    stXSubscribe = 10
  );

  TZMQPollEvent = (
    pePollIn  = 1,
    pePollOut = 2,
    pePollErr = 4
  );
  TZMQPollEvents = set of TZMQPollEvent;

  TZMQKeepAlive = ( kaDefault, kaFalse, kaTrue );

  TZMQEvent = record
    event: TZMQMonitorEvent;
    addr: WideString;
    case TZMQMonitorEvent of
      meConnected,
      meListening,
      meAccepted,
      meClosed,
      meDisconnected: (
        fd: Integer;
      );
      meConnectDelayed,
      meBindFailed,
      meAcceptFailed,
      meCloseFailed: (
        err: Integer;
      );
      meConnectRetried: ( //connect_retried
        interval: Integer;
      );
  end;

  TZMQMonitorProc = procedure(const event: TZMQEvent) of object;

  PZMQMonitorRec = ^TZMQMonitorRec;
  TZMQMonitorRec = record
    terminated: Boolean;
    context: Pointer;
    addr: WideString;
    proc: TZMQMonitorProc;
  end;

  PZMQSocket  = ^TZMQSocketRec;
  TZMQSocketRec = record
    SocketType: function : TZMQSocketType of object;
    RcvMore: function : Boolean of object;
    RcvTimeout: function : Integer of object;
    SndTimeout: function : Integer of object;
    Affinity: function : UInt64 of object;
    Identity: function : WideString of object;
    Rate: function : Integer of object;
    RecoveryIVL: function : Integer of object;
    SndBuf: function : Integer of object;
    RcvBuf: function : Integer of object;
    Linger: function : Integer of object;
    ReconnectIVL: function : Integer of object;
    ReconnectIVLMax: function : Integer of object;
    Backlog: function : Integer of object;
    FD: function : Pointer of object;
    Events: function : TZMQPollEvents of object;
    HWM: function : Integer of object;
    SndHWM: function : Integer of object;
    RcvHWM: function : Integer of object;
    MaxMsgSize: function : Int64 of object;
    MulticastHops: function : Integer of object;
    IPv4Only: function : Boolean of object;
    LastEndpoint: function : WideString of object;
    KeepAlive: function : TZMQKeepAlive of object;
    KeepAliveIdle: function : Integer of object;
    KeepAliveCnt: function : Integer of object;
    KeepAliveIntvl: function : Integer of object;
    AcceptFilter: function (indx: Integer): WideString of object;
    Context: function : IZMQContext of object;
    Socket: function : Pointer of object;
    RaiseEAgain: function : Boolean of object;
    SetHWM: procedure (const Value: Integer) of object;
    SetRcvTimeout: procedure (const Value: Integer) of object;
    SetSndTimeout: procedure (const Value: Integer) of object;
    SetAffinity: procedure (const Value: UInt64) of object;
    SetIdentity: procedure (const Value: WideString) of object;
    SetRate: procedure (const Value: Integer) of object;
    SetRecoveryIvl: procedure (const Value: Integer) of object;
    SetSndBuf: procedure (const Value: Integer) of object;
    SetRcvBuf: procedure (const Value: Integer) of object;
    SetLinger: procedure (const Value: Integer) of object;
    SetReconnectIvl: procedure (const Value: Integer) of object;
    SetReconnectIvlMax: procedure (const Value: Integer) of object;
    SetBacklog: procedure (const Value: Integer) of object;
    SetSndHWM: procedure (const Value: Integer) of object;
    SetRcvHWM: procedure (const Value: Integer) of object;
    SetMaxMsgSize: procedure (const Value: Int64) of object;
    SetMulticastHops: procedure (const Value: Integer) of object;
    SetIPv4Only: procedure (const Value: Boolean) of object;
    SetKeepAlive: procedure (const Value: TZMQKeepAlive) of object;
    SetKeepAliveIdle: procedure (const Value: Integer) of object;
    SetKeepAliveCnt: procedure (const Value: Integer) of object;
    SetKeepAliveIntvl: procedure (const Value: Integer) of object;
    SetAcceptFilter: procedure (indx: Integer; const Value: WideString) of object;
    SetRouterMandatory: procedure (const Value: Boolean) of object;
    SetRaiseEAgain: procedure (const Value: Boolean) of object;

    Implementator: function : Pointer of object;

    Bind: procedure (const addr: WideString) of object;
    Unbind: procedure (const addr: WideString) of object;

    Connect: procedure (const addr: WideString) of object;
    ConnectEx: function (const addr: WideString): Integer of object;
    Disconnect: procedure (const addr: WideString) of object;
    Free: procedure  of object;

    Subscribe: procedure (const filter: WideString) of object;
    UnSubscribe: procedure (const filter: WideString) of object;

    AddAcceptFilter: procedure (const addr: WideString) of object;

    SendFrame: function (var msg: IZMQFrame; flags: TZMQSendFlags = []): Integer of object;
    SendStream: function (const strm: IStream; size: Integer; flags: TZMQSendFlags = []): Integer of object;
    SendString: function (const msg: WideString; flags: TZMQSendFlags = []): Integer of object;

    SendMsg: function (var msgs: IZMQMsg; dontwait: Boolean = false): Integer of object;
    SendStrings: function (const msg: array of WideString; dontwait: Boolean = false): Integer of object;
    SendBuffer: function (const Buffer; len: Cardinal; flags: TZMQSendFlags = []): Integer of object;

    RecvFrame: function (var msg: IZMQFrame; flags: TZMQRecvFlags = []): Integer of object;
    RecvStream: function (const strm: IStream; flags: TZMQRecvFlags = []): Integer of object;
    RecvString: function (var msg: WideString; flags: TZMQRecvFlags = []): Integer of object;

    RecvMsg: function (var msgs: IZMQMsg; flags: TZMQRecvFlags = []): Integer of object;
    RecvBuffer: function (var Buffer; len: Cardinal; flags: TZMQRecvFlags = []): Integer of object;

    RegisterMonitor: procedure (proc: TZMQMonitorProc; events: TZMQMonitorEvents = cZMQMonitorEventsAll) of object;
    UnregisterMonitor: procedure of object;
  end;

  IZMQContext = interface
  ['{21CB3BB5-4D6D-45F1-B1C7-3065616D7566}']
    function GetContextPtr: Pointer;
    function GetLinger: Integer;
    function GetTerminated: Boolean;
    function GetIOThreads: Integer;
    function GetMaxSockets: Integer;
    procedure SetLinger(const Value: Integer);
    procedure SetIOThreads(const Value: Integer);
    procedure SetMaxSockets(const Value: Integer);

    function Shadow: IZMQContext;
    function Socket(stype: TZMQSocketType): PZMQSocket;

    procedure Terminate;

    property ContextPtr: Pointer read GetContextPtr;
    //  < -1 means dont change linger when destroy
    property Linger: Integer read GetLinger write SetLinger;
    property Terminated: Boolean read GetTerminated;
    property IOThreads: Integer read GetIOThreads write SetIOThreads;
    property MaxSockets: Integer read GetMaxSockets write SetMaxSockets;
  end;

  TZMQFree = procedure(data, hint: Pointer);
  TNotifyEvent = procedure (Sender: TObject) of object;

  TZMQPollItem = record
    socket:  PZMQSocket;
    events:  TZMQPollEvents;
    revents: TZMQPollEvents;
  end;
  TZMQPollItemArray = array of TZMQPollItem;

  IZMQPoller = interface;

  TZMQPollEventProc = procedure(const socket: PZMQSocket; const event: TZMQPollEvents) of object;
  TZMQExceptionProc = procedure(const exc: Exception) of object;
  TZMQTimeOutProc = procedure(const poller: IZMQPoller) of object;

  IZMQPoller = interface
  ['{A8C3DC9E-651E-4CA6-AD31-1BC7771E611D}']
    function GetPollResult(const Index: Integer): TZMQPollItem;
    function GetPollNumber: Integer;
    function GetPollItem(const Index: Integer): TZMQPollItem;
    function GetFreeOnTerminate: Boolean;
    function GetHandle: THandle;
    function GetSuspended: Boolean;
    function GetThreadID: THandle;
    function GetOnTerminate: TNotifyEvent;
    function GetOnEvent: TZMQPollEventProc;
    function GetOnException: TZMQExceptionProc;
    function GetOnTimeOut: TZMQTimeOutProc;
    procedure SetPollNumber(const AValue: Integer);
    procedure SetFreeOnTerminate(const Value: Boolean);
    procedure SetOnTerminate(const Value: TNotifyEvent);
    procedure SetSuspended(const Value: Boolean);
    procedure SetOnEvent(const AValue: TZMQPollEventProc);
    procedure SetOnException(const AValue: TZMQExceptionProc);
    procedure SetOnTimeOut(const AValue: TZMQTimeOutProc);

    procedure Resume;
    procedure Suspend;
    procedure Terminate;
    function  WaitFor: LongWord;

    procedure Register(const socket: PZMQSocket; const events: TZMQPollEvents; bWait: Boolean = False);
    procedure Unregister(const socket: PZMQSocket; const events: TZMQPollEvents; bWait: Boolean = False);
    procedure SetPollNumberAndWait(const Value: Integer);

    function  Poll(timeout: Longint = -1; lPollNumber: Integer = -1): Integer;

    property PollResult[const Index: Integer]: TZMQPollItem read GetPollResult;
    property PollNumber: Integer read GetPollNumber write SetPollNumber;
    property PollItem[const Index: Integer]: TZMQPollItem read GetPollItem;
    property FreeOnTerminate: Boolean read GetFreeOnTerminate write SetFreeOnTerminate;
    property Handle: THandle read GetHandle;
    property Suspended: Boolean read GetSuspended write SetSuspended;
    property ThreadID: THandle read GetThreadID;
    property OnTerminate: TNotifyEvent read GetOnTerminate write SetOnTerminate;
    property OnEvent: TZMQPollEventProc read GetOnEvent write SetOnEvent;
    property OnException: TZMQExceptionProc read GetOnException write SetOnException;
    property OnTimeOut: TZMQTimeOutProc read GetOnTimeOut write SetOnTimeOut;
  end;

  // Thread related functions.
  TDetachedThreadMethod = procedure(Args: Pointer; const Context: IZMQContext) of object;
  TAttachedThreadMethod = procedure(Args: Pointer; const Context: IZMQContext; const Pipe: PZMQSocket) of object;

  TDetachedThreadProc = procedure(Args: Pointer; const Context: IZMQContext);
  TAttachedThreadProc = procedure(Args: Pointer; const Context: IZMQContext; const Pipe: PZMQSocket);

  TZMQThreadExecuteMethod = procedure (AThread: TObject) of object;

  IZMQThread = interface
  ['{935EF0DD-0334-4756-9CC7-CD05FB7BC0FD}']
    function GetPipe: PZMQSocket;
    function GetArgs: Pointer;
    function GetContext: IZMQContext;
    function GetFreeOnTerminate: Boolean;
    function GetHandle: THandle;
    function GetSuspended: Boolean;
    function GetThreadID: THandle;
    function GetOnExecute: TZMQThreadExecuteMethod;
    function GetOnTerminate: TNotifyEvent;
    procedure SetFreeOnTerminate(const AValue: Boolean);
    procedure SetSuspended(const AValue: Boolean);
    procedure SetOnExecute(const AValue: TZMQThreadExecuteMethod);
    procedure SetOnTerminate(const AValue: TNotifyEvent);

    procedure Resume;
    procedure Suspend;
    procedure Terminate;
    function WaitFor: LongWord;

    property Pipe: PZMQSocket read GetPipe;
    property Args: Pointer read GetArgs;
    property Context: IZMQContext read GetContext;
    property FreeOnTerminate: Boolean read GetFreeOnTerminate write SetFreeOnTerminate;
    property Handle: THandle read GetHandle;
    property Suspended: Boolean read GetSuspended write SetSuspended;
    property ThreadID: THandle read GetThreadID;
    property OnExecute: TZMQThreadExecuteMethod read GetOnExecute write SetOnExecute;
    property OnTerminate: TNotifyEvent read GetOnTerminate write SetOnTerminate;
  end;

  TZMQDevice = (dStreamer, dForwarder, dQueue);

  TZMQVersion = record
    major: Integer;
    minor: Integer;
    patch: Integer;
  end;

  PIZMQMananger = ^IZMQMananger;
  IZMQMananger = interface
  ['{B9484F11-C531-4527-BBFE-DB3A4F358444}']
    function  GetTerminated: Boolean;
    function  GetVersion: TZMQVersion;
    function  GetDriverFile: WideString;
    function  GetContext: IZMQContext;
    procedure SetTerminated(const Value: Boolean);
    procedure SetDriverFile(const Value: WideString);

    function  CreateFrame: IZMQFrame; overload;
    function  CreateFrame(size: Cardinal): IZMQFrame; overload;
    function  CreateFrame(data: Pointer; size: Cardinal; ffn: TZMQFreeProc; hint: Pointer = nil): IZMQFrame; overload;
    function  CreateMsg: IZMQMsg;
    function  CreateContext: IZMQContext;
    function  CreatePoller(aSync: Boolean = false; const aContext: IZMQContext = nil): IZMQPoller;
    function  CreateThread(lArgs: Pointer; const ctx: IZMQContext): IZMQThread;
    function  CreateAttached(lAttachedMeth: TAttachedThreadMethod; const ctx: IZMQContext; lArgs: Pointer): IZMQThread;
    function  CreateDetached(lDetachedMeth: TDetachedThreadMethod; lArgs: Pointer): IZMQThread;
    function  CreateAttachedProc(lAttachedProc: TAttachedThreadProc; const ctx: IZMQContext; lArgs: Pointer): IZMQThread;
    function  CreateDetachedProc(lDetachedProc: TDetachedThreadProc; lArgs: Pointer): IZMQThread;

    function  Poll(var pia: TZMQPollItemArray; timeout: Integer = -1): Integer; overload;
    function  Poll(var pia: TZMQPollItem; timeout: Integer = -1): Integer; overload;
    procedure Proxy(const frontend, backend, capture: PZMQSocket);
    procedure Device(device: TZMQDevice; const insocket, outsocket: PZMQSocket);

    procedure FreeAndNilSocket(var socket: PZMQSocket);
    function  StartStopWatch: Pointer;
    function  StopStopWatch(watch: Pointer): LongWord;
    procedure Sleep(const seconds: Integer);
    procedure Terminate;

    function  IsZMQException(AExcetpion: Exception): Boolean;

    property Version: TZMQVersion read GetVersion;
    property DriverFile: WideString read GetDriverFile write SetDriverFile;
    property Terminated: Boolean read GetTerminated write SetTerminated;
    property Context: IZMQContext read GetContext;
  end;

  PDynPointerArray = ^TDynPointerArray;
  TDynPointerArray = array of Pointer;

  PPZmqApi = ^PZmqApi;
  PZmqApi = ^TZmqApi;
  TZmqApi = record
    Flags: array[0..2] of AnsiChar;
    Instance: HMODULE;
    InitProc: procedure (const Api: PPointer; const Instance: HINST);
    FinalProc: procedure (const Api: PPointer; const Instance: HINST);
    FuncsCount: Integer;
    Funcs: TDynPointerArray;
  end;

function ZMQ: IZMQMananger;
function ZMQEnabled: Boolean;

{$IFNDEF Zmq4D}
function  LoadZMQ4D(const ADllPath: string = DLL_Zmq4D): Boolean;
procedure UnloadZMQ4D;
{$ENDIF}

implementation

{$IFDEF Zmq4D}
uses
  ZmqImpl;
{$ENDIF}

var
  varApi: PZmqApi = nil;
{$IFNDEF Zmq4D}
  varDLLHandle: THandle;
{$ENDIF}

function ZMQ: IZMQMananger;
type
  TZMQManangerProc = function : PIZMQMananger;
begin
  Result := TZMQManangerProc(varApi.Funcs[FuncIdx_ZMQMananger])^;
end;

function ZMQEnabled: Boolean;
begin
  Result := varApi <> nil;
end;

{$IFNDEF Zmq4D}
function  LoadZMQ4D(const ADllPath: string): Boolean;
var
  wc: TWndClassA;
begin
  Result := False;
  try
    if ZMQEnabled then
    begin
      Result := True;
      Exit;
    end;
    if GetClassInfoA(SysInit.HInstance, CLASSNAME_Zmq4D, wc) then
    begin
      varApi := PZmqApi(wc.lpfnWndProc);
      varApi.InitProc(@varApi, SysInit.HInstance);
      Result := True;
      Exit;
    end;
    if not FileExists(ADllPath) then
    begin
      OutputDebugString(PChar('[' + ADllPath + ']加载失败：['+ADllPath+']不存在！'));
      Exit;
    end;
    varDLLHandle := LoadLibrary(PChar(ADllPath));
    if varDLLHandle < 32 then
    begin
      OutputDebugString(PChar('[' + ADllPath + ']加载失败：'+ SysErrorMessage(GetLastError)));
      Exit;
    end;
    try
      if GetClassInfoA(SysInit.HInstance, CLASSNAME_Zmq4D, wc) then
      begin
        varApi := PZmqApi(wc.lpfnWndProc);
        varApi.InitProc(@varApi, SysInit.HInstance);
      end
      else
      begin
        OutputDebugString(PChar('[' + ADllPath + ']加载失败：未找到全局注册信息！'));
        Exit;
      end;
      Result := True;
    finally
      if not Result then
      begin
        FreeLibrary(varDLLHandle);
        varDLLHandle := 0;
      end;
    end;
  except
    on E: Exception do
      OutputDebugString(PChar('[LoadZMQ4D]'+E.Message));
  end;
end;

procedure UnloadZMQ4D;
begin
  try
    if varDLLHandle > 0 then
    begin
      if varApi <> nil then
      try
        varApi.FinalProc(@varApi, SysInit.HInstance);
      except
        on E: Exception do
          OutputDebugString(PChar('[UnloadZMQ4D]'+E.Message));
      end;
      varApi := nil;
      FreeLibrary(varDLLHandle);
      varDLLHandle := 0;
    end;
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('[UnloadZMQ4D]'+E.Message));
    end
  end;
end;
{$ENDIF}

initialization
{$IFDEF Zmq4D}
  varApi := @ZmqImpl.varApi;
{$ELSE}
  if FileExists(DLL_Zmq4D) then
    LoadZMQ4D();
{$ENDIF}

finalization
{$IFDEF Zmq4D}
{$ELSE}
  UnloadZMQ4D;
{$ENDIF}

end.
