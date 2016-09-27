unit ZmqImpl;

interface

uses
  SysUtils, Classes, Windows, ZmqIntf, ZmqApiImpl, ActiveX;

type
  EZMQException = class(Exception)
  private
    fErrorCode: Integer;
  public
    constructor Create; overload;
    constructor Create(aErrorCode: Integer); overload;
    property ErrorCode: Integer read fErrorCode;
  end;

  TZMQFrame = class;

  PZMQFreeHint = ^TZMQFreeHint;
  TZMQFreeHint = record
    frame: TZMQFrame;
    fn: TZMQFreeProc;
    hint: Pointer;
  end;

  TZMQInterfacedObject = class(TInterfacedObject)
  private
    FDestroying: Boolean;
  protected
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    procedure BeforeDestruction; override;
  end;

  TZMQFrame = class(TZMQInterfacedObject, IZMQFrame)
  private
    fMessage: zmq_msg_t;
    fFreeHint: TZMQFreeHint;
  private
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

    procedure CheckResult(rc: Integer);
  public
    constructor Create; overload;
    constructor Create(size: Cardinal); overload;
    constructor Create(data: Pointer; size: Cardinal; ffn: TZMQFreeProc; hint: Pointer = nil); overload;
    destructor Destroy; override;

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

  TZMQMsg = class(TZMQInterfacedObject, IZMQMsg)
  private
    fMsgs: IInterfaceList;
    fSize: Cardinal;
    fCursor: Integer;
  private
    function GetItem(indx: Integer): IZMQFrame;
  public
    constructor Create;
    destructor Destroy; override;

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

  TZMQContext = class;

  TZMQSocketImpl = class
  protected
    fData: TZMQSocketRec;
    fSocket: Pointer;
    fContext: TZMQContext;

    fRaiseEAgain: Boolean;
    fAcceptFilter: TStringList;
    fMonitorRec: PZMQMonitorRec;
    fMonitorThread: THandle;
  private
    procedure Close;
    procedure SetSockOpt(option: Integer; optval: Pointer; optvallen: Cardinal);
    procedure GetSockOpt(option: Integer; optval: Pointer; var optvallen: Cardinal);
    function Send(var msg: IZMQFrame; flags: Integer = 0): Integer; overload;
    function Recv(var msg: IZMQFrame; flags: Integer = 0): Integer; overload;

    function CheckResult(rc: Integer): Integer;
    function GetSockOptInt64(option: Integer): Int64;
    function GetSockOptInteger(option: Integer): Integer;
    procedure SetSockOptInt64(option: Integer; const Value: Int64);
    procedure SetSockOptInteger(option: Integer; const Value: Integer);
  protected
    function GetData: PZMQSocket;
    function GetSocketType: TZMQSocketType;
    function GetRcvMore: Boolean;
    function GetRcvTimeout: Integer;
    function GetSndTimeout: Integer;
    function GetAffinity: UInt64;
    function GetIdentity: WideString;
    function GetRate: Integer;
    function GetRecoveryIVL: Integer;
    function GetSndBuf: Integer;
    function GetRcvBuf: Integer;
    function GetLinger: Integer;
    function GetReconnectIVL: Integer;
    function GetReconnectIVLMax: Integer;
    function GetBacklog: Integer;
    function GetFD: Pointer;
    function GetEvents: TZMQPollEvents;
    function GetHWM: Integer;
    function GetSndHWM: Integer;
    function GetRcvHWM: Integer;
    function GetMaxMsgSize: Int64;
    function GetMulticastHops: Integer;
    function GetIPv4Only: Boolean;
    function GetLastEndpoint: WideString;
    function GetKeepAlive: TZMQKeepAlive;
    function GetKeepAliveIdle: Integer;
    function GetKeepAliveCnt: Integer;
    function GetKeepAliveIntvl: Integer;
    function GetAcceptFilter(indx: Integer): WideString;
    function GetContext: IZMQContext;
    function GetSocket: Pointer;
    function GetRaiseEAgain: Boolean;
    procedure SetHWM(const Value: Integer);
    procedure SetRcvTimeout(const Value: Integer);
    procedure SetSndTimeout(const Value: Integer);
    procedure SetAffinity(const Value: UInt64);
    procedure SetIdentity(const Value: WideString);
    procedure SetRate(const Value: Integer);
    procedure SetRecoveryIvl(const Value: Integer);
    procedure SetSndBuf(const Value: Integer);
    procedure SetRcvBuf(const Value: Integer);
    procedure SetLinger(const Value: Integer);
    procedure SetReconnectIvl(const Value: Integer);
    procedure SetReconnectIvlMax(const Value: Integer);
    procedure SetBacklog(const Value: Integer);
    procedure SetSndHWM(const Value: Integer);
    procedure SetRcvHWM(const Value: Integer);
    procedure SetMaxMsgSize(const Value: Int64);
    procedure SetMulticastHops(const Value: Integer);
    procedure SetIPv4Only(const Value: Boolean);
    procedure SetKeepAlive(const Value: TZMQKeepAlive);
    procedure SetKeepAliveIdle(const Value: Integer);
    procedure SetKeepAliveCnt(const Value: Integer);
    procedure SetKeepAliveIntvl(const Value: Integer);
    procedure SetAcceptFilter(indx: Integer; const Value: WideString);
    procedure SetRouterMandatory(const Value: Boolean);
    procedure SetRaiseEAgain(const Value: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    function Implementator: Pointer;

    procedure Bind(const addr: WideString);
    procedure Unbind(const addr: WideString);

    procedure Connect(const addr: WideString);
    function  ConnectEx(const addr: WideString): Integer;
    procedure Disconnect(const addr: WideString);
    procedure Free;

    procedure Subscribe(const filter: WideString);
    procedure UnSubscribe(const filter: WideString);

    procedure AddAcceptFilter(const addr: WideString);

    function Send(var msg: IZMQFrame; flags: TZMQSendFlags = []): Integer; overload;
    function Send(const strm: IStream; size: Integer; flags: TZMQSendFlags = []): Integer; overload;
    function Send(const msg: WideString; flags: TZMQSendFlags = []): Integer; overload;

    function Send(var msgs: IZMQMsg; dontwait: Boolean = false): Integer; overload;
    function Send(const msg: array of WideString; dontwait: Boolean = false): Integer; overload;
    function SendBuffer(const Buffer; len: Size_t; flags: TZMQSendFlags = []): Integer;

    function Recv(var msg: IZMQFrame; flags: TZMQRecvFlags = []): Integer; overload;
    function Recv(const strm: IStream; flags: TZMQRecvFlags = []): Integer; overload;
    function Recv(var msg: WideString; flags: TZMQRecvFlags = []): Integer; overload;

    function Recv(var msgs: IZMQMsg; flags: TZMQRecvFlags = []): Integer; overload;
    function RecvBuffer(var Buffer; len: size_t; flags: TZMQRecvFlags = []): Integer;
    
    procedure RegisterMonitor(proc: TZMQMonitorProc; events: TZMQMonitorEvents = cZMQMonitorEventsAll);
    procedure UnregisterMonitor;

    property Data: PZMQSocket read GetData;
    property SocketType: TZMQSocketType read GetSocketType;
    property RcvMore: Boolean read GetRcvMore;

    property SndHWM: Integer read GetSndHWM write SetSndHwm;
    property RcvHWM: Integer read GetRcvHWM write SetRcvHwm;
    property MaxMsgSize: Int64 read GetMaxMsgSize write SetMaxMsgSize;
    property MulticastHops: Integer read GetMulticastHops write SetMulticastHops;
    property IPv4Only: Boolean read GetIPv4Only write SetIPv4Only;
    property LastEndpoint: WideString read GetLastEndpoint;
    property KeepAlive: TZMQKeepAlive read GetKeepAlive write SetKeepAlive;
    property KeepAliveIdle: Integer read GetKeepAliveIdle write SetKeepAliveIdle;
    property KeepAliveCnt: Integer read GetKeepAliveCnt write SetKeepAliveCnt;
    property KeepAliveIntvl: Integer read GetKeepAliveIntvl write SetKeepAliveIntvl;
    property AcceptFilter[indx: Integer]: WideString read GetAcceptFilter write SetAcceptFilter;
    property RouterMandatory: Boolean write SetRouterMandatory;
    property HWM: Integer read GetHWM write SetHWM;
    property RcvTimeout: Integer read GetRcvTimeout write SetRcvTimeout;
    property SndTimeout: Integer read GetSndTimeout write SetSndTimeout;
    property Affinity: UInt64 read GetAffinity write SetAffinity;
    property Identity: WideString read GetIdentity write SetIdentity;
    property Rate: Integer read GetRate write SetRate;
    property RecoveryIvl: Integer read GetRecoveryIvl write SetRecoveryIvl;
    property SndBuf: Integer read GetSndBuf write SetSndBuf;
    property RcvBuf: Integer read GetRcvBuf write SetRcvBuf;
    property Linger: Integer read GetLinger write SetLinger;
    property ReconnectIvl: Integer read GetReconnectIvl write SetReconnectIvl;
    property ReconnectIvlMax: Integer read GetReconnectIvlMax write SetReconnectIvlMax;
    property Backlog: Integer read GetBacklog write SetBacklog;
    property FD: Pointer read GetFD;
    property Events: TZMQPollEvents read GetEvents;

    property Context: IZMQContext read GetContext;
    property SocketPtr: Pointer read GetSocket;
    property RaiseEAgain: Boolean read GetRaiseEAgain write SetRaiseEAgain;
  end;

  TZMQContext = class(TZMQInterfacedObject, IZMQContext)
  private
    fContext: Pointer;
    fSockets: TThreadList;
    fLinger: Integer;
  private
    function GetContextPtr: Pointer;
    function GetLinger: Integer;
    function GetTerminated: Boolean;
    function GetOption( option: Integer ): Integer;
    function GetIOThreads: Integer;
    function GetMaxSockets: Integer;
    procedure SetLinger(const Value: Integer);
    procedure SetOption(option, optval: Integer);
    procedure SetIOThreads(const Value: Integer);
    procedure SetMaxSockets(const Value: Integer);
  protected
    fTerminated: Boolean;
    fMainThread: Boolean;

    constructor CreateShadow(const Context: TZMQContext);

    procedure CheckResult(rc: Integer);
    procedure RemoveSocket(const socket: TZMQSocketImpl );
  public
    constructor Create;
    destructor Destroy; override;

    function  Shadow: IZMQContext;
    function  Socket(stype: TZMQSocketType): PZMQSocket;
    procedure Terminate;

    property ContextPtr: Pointer read GetContextPtr;
    //  < -1 means dont change linger when destroy
    property Linger: Integer read GetLinger write SetLinger;
    property Terminated: Boolean read GetTerminated;
    property IOThreads: Integer read GetIOThreads write SetIOThreads;
    property MaxSockets: Integer read GetMaxSockets write SetMaxSockets;
  end;

  TZMQPoller = class;
  
  TZMQPollerThread = class(TThread)
  private
    fOwner: TZMQPoller;
    fContext: IZMQContext;
    fPair: TZMQSocketImpl;
    fAddr: WideString;

    fPollItem: array of zmq_pollitem_t;
    fPollSocket: array of TZMQSocketImpl;
    fPollItemCapacity,
    fPollItemCount: Integer;

    fTimeOut: Integer;

    fPollNumber: Integer;

    fLock: TRTLCriticalSection;
    fSync: Boolean;

    fOnException: TZMQExceptionProc;
    fOnTimeOut: TZMQTimeOutProc;
    fOnEvent: TZMQPollEventProc;
  private
    function GetPollItem(const Index: Integer): TZMQPollItem;
    function GetPollResult(const Index: Integer): TZMQPollItem;
    procedure CheckResult(rc: Integer);
    procedure AddToPollItems(const socket: TZMQSocketImpl; events: TZMQPollEvents);
    procedure DelFromPollItems(const socket: TZMQSocketImpl; events: TZMQPollEvents; index: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(aOwner: TZMQPoller; aSync: Boolean = false; const aContext: IZMQContext = nil);
    destructor Destroy; override;

    procedure Register(const socket: PZMQSocket; events: TZMQPollEvents; bWait: Boolean = false);
    procedure Deregister(const socket: PZMQSocket; events: TZMQPollEvents; bWait: Boolean = false);
    procedure SetPollNumber(const Value: Integer; bWait: Boolean = false);
    function  Poll(timeout: Longint = -1; lPollNumber: Integer = -1): Integer;
    
    property PollResult[const Index: Integer]: TZMQPollItem read GetPollResult;
    property PollNumber: Integer read fPollNumber;
    property PollItem[const Index: Integer]: TZMQPollItem read GetPollItem;
    property OnEvent: TZMQPollEventProc read fOnEvent write fOnEvent;
    property OnException: TZMQExceptionProc read fOnException write fOnException;
    property OnTimeOut: TZMQTimeOutProc read fOnTimeOut write fOnTimeOut;
  end;

  TZMQPoller = class(TZMQInterfacedObject, IZMQPoller)
  private
    FThread: TZMQPollerThread;
  protected
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
  public
    constructor Create(aSync: Boolean = false; const aContext: IZMQContext = nil);
    destructor Destroy; override;

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

  TZMQInternalThread = class(TThread)
  private
    fPipe: TZMQSocketImpl;      //attached thread pipe
    thrPipe: TZMQSocketImpl;    // attached thread pipe in the new thread.
    fContext: IZMQContext;
    fArgs: Pointer;
    fDetachedMeth: TDetachedThreadMethod;
    fAttachedMeth: TAttachedThreadMethod;
    fDetachedProc: TDetachedThreadProc;
    fAttachedProc: TAttachedThreadProc;
    fOnExecute: TZMQThreadExecuteMethod;
  public
    constructor Create(lArgs: Pointer; const ctx: IZMQContext);
    constructor CreateAttached(lAttachedMeth: TAttachedThreadMethod; const ctx: IZMQContext; lArgs: Pointer);
    constructor CreateDetached(lDetachedMeth: TDetachedThreadMethod; lArgs: Pointer);
    constructor CreateAttachedProc(lAttachedProc: TAttachedThreadProc; const ctx: IZMQContext; lArgs: Pointer);
    constructor CreateDetachedProc(lDetachedProc: TDetachedThreadProc; lArgs: Pointer);
    destructor Destroy; override;
  protected
    procedure Execute; override;
    procedure DoExecute; virtual;
  public
    property Pipe: TZMQSocketImpl read fPipe;
    property Args: Pointer read fArgs;
    property Context: IZMQContext read fContext;
    property OnExecute: TZMQThreadExecuteMethod read fOnExecute write fOnExecute; 
  end;

  TZMQThread = class(TZMQInterfacedObject, IZMQThread)
  private
    FThread: TZMQInternalThread;
  protected
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
  public
    constructor Create(lArgs: Pointer; const ctx: IZMQContext);
    constructor CreateAttached(lAttachedMeth: TAttachedThreadMethod; const ctx: IZMQContext; lArgs: Pointer );
    constructor CreateDetached(lDetachedMeth: TDetachedThreadMethod; lArgs: Pointer );
    constructor CreateAttachedProc(lAttachedProc: TAttachedThreadProc; const ctx: IZMQContext; lArgs: Pointer );
    constructor CreateDetachedProc(lDetachedProc: TDetachedThreadProc; lArgs: Pointer );
    destructor Destroy; override;
    
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

  TZMQMananger = class(TInterfacedObject, IZMQMananger)
  private
    FContext: IZMQContext;
    FTerminated: Boolean;
    function GetVersion: TZMQVersion;
  protected
    function  GetTerminated: Boolean;
    function  GetDriverFile: WideString;
    function  GetContext: IZMQContext;
    procedure SetTerminated(const Value: Boolean);
    procedure SetDriverFile(const Value: WideString);
  public
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
    function  Poll(var pi: TZMQPollItem; timeout: Integer = -1): Integer; overload;
    procedure Proxy(const frontend, backend, capture: PZMQSocket);
    procedure Device(device: TZMQDevice; const insocket, outsocket: PZMQSocket);

    procedure FreeAndNilSocket(var socket: PZMQSocket);
    function  StartStopWatch: Pointer;
    function  StopStopWatch(watch: Pointer): LongWord;
    procedure Sleep(const seconds: Integer);
    procedure Terminate;

    function  IsZMQException(AExcetpion: Exception): Boolean;

    property Version: TZMQVersion read GetVersion;
    property Terminated: Boolean read GetTerminated write SetTerminated;
    property Context: IZMQContext read GetContext;
  end;

procedure _zmq_free_fn(data, hint: Pointer); cdecl;

var
  varApi: ZmqIntf.TZmqApi;

procedure _RegZmqClass;
procedure _UnregZmqClass;
procedure _InitZmqApi(const Api: PPointer; const Instance: HINST);
procedure _FinalZmqApi(const Api: PPointer; const Instance: HINST);

procedure __MonitorProc(ZMQMonitorRec: PZMQMonitorRec);

function  __ZMQManager: PIZMQMananger;


function ZMQMonitorEventsToInt(const events: TZMQMonitorEvents): Integer;
function ZMQSendFlagsToInt(const flags: TZMQSendFlags): Integer;
function ZMQRecvFlagsToInt(const flags: TZMQRecvFlags): Integer;
function ZMQPollEventsToInt(const events: TZMQPollEvents): Integer;
function IntToZMQPollEvents(const events: Integer): TZMQPollEvents;

implementation

var
  varContexts: TList;
  varZMQManager: IZMQMananger;
  varWC: TWndClassA;
  
const
  cZMQPoller_Register       = 'reg';
  cZMQPoller_SyncRegister   = 'syncreg';
  cZMQPoller_DeRegister     = 'dereg';
  cZMQPoller_SyncDeRegister = 'syncdereg';
  cZMQPoller_Terminate      = 'term';
  cZMQPoller_PollNumber     = 'pollno';
  cZMQPoller_SyncPollNumber = 'syncpollno';

procedure _zmq_free_fn(data, hint: Pointer); cdecl;
var
  h: PZMQFreeHint;
begin
  h := hint;
  h.fn(data, h.hint);
end;

{$IF CompilerVersion <= 18.5}
procedure BinToHex(Buffer: PAnsiChar; Text: PWideChar; BufSize: Integer);
const
  Convert: array[0..15] of WideChar = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
var
  I: Integer;
begin
  for I := 0 to BufSize - 1 do
  begin
    Text[0] := Convert[Byte(Buffer[I]) shr 4];
    Text[1] := Convert[Byte(Buffer[I]) and $F];
    Inc(Text, 2);
  end;
end;
function HexToBin(Text : PWideChar; Buffer: PAnsiChar; BufSize: Integer): Integer;
const
  Convert: array['0'..'f'] of SmallInt =
    ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15);
var
  I: Integer;
  TextH, TextL: AnsiChar;
begin
  I := BufSize;
  while I > 0 do
  begin
    TextH := AnsiChar(Word(Text[0]));
    TextL := AnsiChar(Word(Text[1]));
    if ((TextH in [':'..'@']) or (TextH in ['G'..#96])) or
       ((TextL in [':'..'@']) or (TextL in ['G'..#96])) then
       Break;
    if not (TextH in ['0'..'f']) or not (TextL in ['0'..'f']) then Break;
    Buffer[0] := AnsiChar((Convert[AnsiChar(TextH)] shl 4) + Convert[AnsiChar(TextL)]);
    Inc(Buffer);
    Inc(Text, 2);
    Dec(I);
  end;
  Result := BufSize - I;
end;
{$IFEND}

function ZMQMonitorEventsToInt(const events: TZMQMonitorEvents): Integer;
begin
  Result := 0;
  if meConnected in events then
    Result := Result or ZMQ_EVENT_CONNECTED;
  if meConnectDelayed in events then
    Result := Result or ZMQ_EVENT_CONNECT_DELAYED;
  if meConnectRetried in events then
    Result := Result or ZMQ_EVENT_CONNECT_RETRIED;
  if meListening in events then
    Result := Result or ZMQ_EVENT_LISTENING;
  if meBindFailed in events then
    Result := Result or ZMQ_EVENT_BIND_FAILED;
  if meAccepted in events then
    Result := Result or ZMQ_EVENT_ACCEPTED;
  if meAcceptFailed in events then
    Result := Result or ZMQ_EVENT_ACCEPT_FAILED;
  if meClosed in events then
    Result := Result or ZMQ_EVENT_CLOSED;
  if meCloseFailed in events then
    Result := Result or ZMQ_EVENT_CLOSE_FAILED;
  if meDisconnected in events then
    Result := Result or ZMQ_EVENT_DISCONNECTED;
end;

function ZMQSendFlagsToInt(const flags: TZMQSendFlags): Integer;
begin
  Result := 0;
  if sfDontWait in flags then
    Result := Result or ZMQ_DONTWAIT;
  if sfSndMore in flags then
    Result := Result or ZMQ_SNDMORE;
end;

function ZMQRecvFlagsToInt(const flags: TZMQRecvFlags): Integer;
begin
 Result := 0;
  if rfDontWait in flags then
    Result := Result or ZMQ_DONTWAIT;
end;

function ZMQPollEventsToInt(const events: TZMQPollEvents): Integer;
begin
 Result := 0;
  if pePollIn in events then
    Result := Result or ZMQ_POLLIN;
  if pePollOut in events then
    Result := Result or ZMQ_POLLOUT;
  if pePollErr in events then
    Result := Result or ZMQ_POLLERR;
end;

function IntToZMQPollEvents(const events: Integer): TZMQPollEvents;
begin
 Result := [];
  if ZMQ_POLLIN and events = ZMQ_POLLIN then
    Result := Result + [pePollIn];
  if ZMQ_POLLOUT and events = ZMQ_POLLOUT then
    Result := Result + [pePollOut];
  if ZMQ_POLLERR and events = ZMQ_POLLERR then
    Result := Result + [pePollErr];
end;

procedure _RegZmqClass;
begin
  varApi.Flags      := 'ZMQ';
  varApi.Instance   := SysInit.HInstance;
  varApi.InitProc   := _InitZMQApi;
  varApi.FinalProc  := _FinalZMQApi;
  varApi.FuncsCount := ZmqApi_FuncsCount;
  SetLength(varApi.Funcs, ZmqApi_FuncsCount);
  varApi.Funcs[FuncIdx_ZMQMananger]  := @__ZMQManager;
  
  FillChar(varWC, SizeOf(varWC), 0);
  varWC.lpszClassName := CLASSNAME_Zmq4D;
  varWC.style         := CS_GLOBALCLASS;
  varWC.hInstance     := SysInit.HInstance;
  varWC.lpfnWndProc   := @varApi;
  if Windows.RegisterClassA(varWC)=0 then
    Halt;
end;

procedure _UnregZmqClass;
begin
  Windows.UnregisterClassA(CLASSNAME_Zmq4D, SysInit.HInstance);
end;

procedure _InitZmqApi(const Api: PPointer; const Instance: HINST);
begin

end;

procedure _FinalZmqApi(const Api: PPointer; const Instance: HINST);
begin

end;

function  __ZMQManager: PIZMQMananger;
begin
  if varZMQManager = nil then
    varZMQManager := TZMQMananger.Create;
  Result := @varZMQManager;
end;

{
   This function is called when a CTRL_C_EVENT received, important that this
   function is executed in a separate thread, because Terminate terminates the
   context, which blocks until there are open sockets.
}
function Console_handler(dwCtrlType: DWORD): BOOL;
var
  i: Integer;
begin
  if CTRL_C_EVENT = dwCtrlType then
  begin
    ZMQ.Terminated := true;
    for i := varContexts.Count - 1 downto 0 do
      TZMQContext(varContexts[i]).Terminate;
    Result := True;
    // if I set to True than the app won't exit,
    // but it's not the solution.
    // ZMQTerminate;
  end
  else
    Result := False;
end;

{ EZMQException }

constructor EZMQException.Create;
begin
  fErrorCode := ZAPI.zmq_errno;
  inherited Create(String(Utf8String( ZAPI.zmq_strerror( fErrorCode ) ) ) );
end;

constructor EZMQException.Create(aErrorCode: Integer);
begin
  fErrorCode := aErrorCode;
  inherited Create(String(Utf8String(ZAPI.zmq_strerror(fErrorCode))));
end;

{ TZMQInterfacedObject }

procedure TZMQInterfacedObject.BeforeDestruction;
begin
  FDestroying := True;
  inherited;
end;

function TZMQInterfacedObject._AddRef: Integer;
begin
  if FDestroying then
    Result := FRefCount
  else
    Result := inherited _AddRef;
end;

function TZMQInterfacedObject._Release: Integer;
begin
  if FDestroying then
    Result := FRefCount
  else
    Result := inherited _Release;
end;

{ TZMQFrame }

procedure TZMQFrame.CheckResult(rc: Integer);
begin
  if rc = 0 then
  begin
    // ok
  end
  else
  if rc = -1 then
  begin
    raise EZMQException.Create;
  end
  else
    raise EZMQException.Create('Function result is not 0, or -1!');
end;

procedure TZMQFrame.Copy(const msg: IZMQFrame);
begin
  CheckResult(ZAPI.zmq_msg_copy(@fMessage, msg.Handle));
end;

constructor TZMQFrame.Create;
begin
  CheckResult(ZAPI.zmq_msg_init(@fMessage));
end;

constructor TZMQFrame.Create(data: Pointer; size: Cardinal;
  ffn: TZMQFreeProc; hint: Pointer);
begin
  fFreeHint.frame := Self;
  fFreeHint.fn := ffn;
  fFreeHint.hint := hint;
  CheckResult(ZAPI.zmq_msg_init_data(@fMessage, data, size, _zmq_free_fn, @fFreeHint));
end;

constructor TZMQFrame.Create(size: Cardinal);
begin
  CheckResult(ZAPI.zmq_msg_init_size(@fMessage, size));
end;

function TZMQFrame.Data: Pointer;
begin
  Result := ZAPI.zmq_msg_data(@fMessage);
end;

destructor TZMQFrame.Destroy;
begin
  CheckResult(ZAPI.zmq_msg_close(@fMessage));
  inherited;
end;

function TZMQFrame.Dump: WideString;
var
  iSize: Integer;
begin
  // not complete.
  iSize := size;
  if iSize = 0 then
    result := ''
  else
  if WideChar(data^) = #0 then
  begin
    SetLength( Result, iSize * 2 );
    BinToHex( data, PWideChar(Result), iSize );
  end
  else
    result := Self.S;
end;

function TZMQFrame.Dup: IZMQFrame;
begin
  Result := TZMQFrame.create(size);
  System.Move(data^, Result.data^, size);
end;

function TZMQFrame.GetC: Currency;
begin
  Result := Currency(data^);
end;

function TZMQFrame.GetDT: TDateTime;
begin
  Result := TDateTime(data^);
end;

function TZMQFrame.GetD: Double;
begin
  Result := Double(data^);
end;

function TZMQFrame.GetF: Single;
begin
  Result := Single(data^);
end;

function TZMQFrame.GetH: WideString;
begin
  SetLength(result, size * 2 div ZMQ_CHAR_SIZE);
  BinToHex(data, PWideChar(result), size);
end;

function TZMQFrame.GetI: Integer;
begin
  Result := Integer(data^);
end;

function TZMQFrame.GetS: WideString;
begin
  SetString(Result, PWideChar(data), size div ZMQ_CHAR_SIZE);
end;

function TZMQFrame.GetHandle: Pointer;
begin
  Result := @fMessage
end;

function TZMQFrame.GetProp(prop: TZMQMessageProperty): Integer;
begin
  result := ZAPI.zmq_msg_get( @fMessage, Byte( prop ) );
  if result = -1 then
    raise EZMQException.Create
  else
    raise EZMQException.Create( 'zmq_msg_more return value undefined!' );
end;

function TZMQFrame.Implementor: Pointer;
begin
  Result := Self;
end;

procedure TZMQFrame.LoadFromStream(const strm: IStream);
var
  statstg: TStatStg;
  cbRead: LongInt; 
begin
  Assert(strm.Stat(statstg, 0)=0, 'IStream.Stat has error!');

  if statstg.cbSize <> size then
    rebuild( statstg.cbSize );
  strm.Read(data, statstg.cbSize, @cbRead);
end;

function TZMQFrame.More: Boolean;
var
  rc: Integer;
begin
  rc := ZAPI.zmq_msg_more(@fMessage);
  if rc = 0 then
    result := false
  else
  if rc = 1 then
    result := true
  else
    raise EZMQException.Create( 'zmq_msg_more return value undefined!' );
end;

procedure TZMQFrame.Move(const msg: IZMQFrame);
begin
  CheckResult(ZAPI.zmq_msg_move(@fMessage, msg.Handle));
end;

procedure TZMQFrame.Rebuild;
begin
  CheckResult(ZAPI.zmq_msg_close(@fMessage));
  CheckResult(ZAPI.zmq_msg_init(@fMessage));
end;

procedure TZMQFrame.Rebuild(size: Cardinal);
begin
  CheckResult(ZAPI.zmq_msg_close(@fMessage));
  CheckResult(ZAPI.zmq_msg_init_size(@fMessage, size));
end;

procedure TZMQFrame.Rebuild(data: Pointer; size: Cardinal;
  ffn: TZMQFreeProc; hint: Pointer);
begin
  CheckResult(ZAPI.zmq_msg_close(@fMessage));
  
  fFreeHint.frame := Self;
  fFreeHint.fn := ffn;
  fFreeHint.hint := hint;
  CheckResult(ZAPI.zmq_msg_init_data(@fMessage, data, size, _zmq_free_fn, @fFreeHint));
end;

procedure TZMQFrame.SaveToStream(const strm: IStream);
var
  cbWritten: Longint;
begin
  strm.Write( data, size, @cbWritten);
end;

procedure TZMQFrame.SetC(const Value: Currency);
var
  iSize: Integer;
begin
  iSize := SizeOf( Value );
  Rebuild( iSize );
  Currency(data^) := Value;
end;

procedure TZMQFrame.SetDT(const Value: TDateTime);
var
  iSize: Integer;
begin
  iSize := SizeOf( Value );
  Rebuild( iSize );
  TDateTime(data^) := Value;
end;

procedure TZMQFrame.SetD(const Value: Double);
var
  iSize: Integer;
begin
  iSize := SizeOf( Value );
  Rebuild( iSize );
  Double(data^) := Value;
end;

procedure TZMQFrame.SetF(const Value: Single);
var
  iSize: Integer;
begin
  iSize := SizeOf( Value );
  Rebuild( iSize );
  Single(data^) := Value;
end;

procedure TZMQFrame.SetH(const Value: WideString);
var
  iSize: Integer;
begin
  iSize := Length(Value) div 2;
  rebuild(iSize*ZMQ_CHAR_SIZE);
  HexToBin(PWideChar(value), data, iSize);
end;

procedure TZMQFrame.SetI(const Value: Integer);
var
  iSize: Integer;
begin
  iSize := SizeOf( Value );
  Rebuild( iSize );
  Integer(data^) := Value;
end;

procedure TZMQFrame.SetS(const Value: WideString);
var
  iSize: Integer;
begin
  iSize := Length(Value);
  rebuild(iSize*ZMQ_CHAR_SIZE);
  System.Move(Value[1], data^, iSize*ZMQ_CHAR_SIZE);
end;

procedure TZMQFrame.SetProp(prop: TZMQMessageProperty; value: Integer);
begin
  CheckResult( ZAPI.zmq_msg_set( @fMessage, Byte( prop ), value ) );
end;

function TZMQFrame.Size: Cardinal;
begin
 Result := ZAPI.zmq_msg_size(@fMessage);
end;

{ TZMQMsg }

function TZMQMsg.Add(const msg: IZMQFrame): Integer;
begin
  try
    Result := fMsgs.Add(msg);
    fSize := fSize + msg.size;
    fCursor := 0;
  except
    on e: Exception do
    begin
      Result := -1;
      TraceException('[TZMQMsg.Add]'+e.Message);
    end;
  end;
end;

function TZMQMsg.AddInt(const msg: Integer): Integer;
var
  frame: IZMQFrame;
begin
  frame := TZMQFrame.create( sizeOf( Integer ) );
  frame.I := msg;
  Result := add( frame );
end;

function TZMQMsg.AddStr(const msg: WideString): Integer;
var
  frame: IZMQFrame;
begin
  frame := TZMQFrame.Create;
  frame.S := msg;
  Result := Add( frame );
end;

procedure TZMQMsg.Clear;
begin
  fMsgs.Clear;
  fSize := 0;
  fCursor := 0;
end;

function TZMQMsg.ContentSize: Integer;
begin
  Result := fSize;
end;

constructor TZMQMsg.Create;
begin
  fMsgs := TInterfaceList.Create;
  fSize := 0;
  fCursor := 0;
end;

destructor TZMQMsg.Destroy;
begin
  Clear;
  fMsgs := nil;
  inherited;
end;

function TZMQMsg.Dump: WideString;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to size - 1 do
  begin
    if i > 0 then
      Result := Result + #13#10;
    Result := Result + item[i].Dump;
  end;
end;

function TZMQMsg.Dup: IZMQMsg;
var
  msg, msgnew: IZMQFrame;
  iSize: Integer;
begin
  Result := TZMQMsg.create;
  msg := first;
  while msg <> nil do
  begin
    iSize := msg.size;
    msgnew := TZMQFrame.create( iSize );
    {$ifdef UNIX}
    Move( msg.data^, msgnew.data^, iSize );
    {$else}
    CopyMemory( msgnew.data, msg.data, iSize );
    {$endif}
    Result.Add( msgnew );
    msg := next;
  end;
  
  TZMQMsg(Result.Implementator).fSize := fSize;
  TZMQMsg(Result.Implementator).fCursor := fCursor;
end;

function TZMQMsg.First: IZMQFrame;
begin
  if size > 0 then
  begin
    Result := fMsgs[0] as IZMQFrame;
    fCursor := 1;
  end
  else
  begin
    Result := nil;
    fCursor := 0;
  end;
end;

function TZMQMsg.GetItem(indx: Integer): IZMQFrame;
begin
  Result := fMsgs[indx] as IZMQFrame;
end;

function TZMQMsg.Implementator: Pointer;
begin
  Result := Self;
end;

function TZMQMsg.Last: IZMQFrame;
begin
  if Size > 0 then
    Result := fMsgs[Size - 1] as IZMQFrame
  else
    Result := nil;
  fCursor := Size;
end;

procedure TZMQMsg.LoadFromHex(const data: WideString);
var
  tsl: TStringList;
  i: Integer;
  frame: IZMQFrame;
begin
  Clear;
  tsl := TStringList.Create;
  try            
    tsl.Text := data; 
    for i := 0 to tsl.Count - 1 do
    begin
      frame := TZMQFrame.create;
      frame.H := tsl[i];
      Add( frame );
    end;
  finally
    tsl.Free;
  end;
end;

function TZMQMsg.Next: IZMQFrame;
begin
  if fCursor < size then
  begin
    Result := fMsgs[fCursor] as IZMQFrame;
    inc(fCursor);
  end
  else
    Result := nil;
end;

function TZMQMsg.Pop: IZMQFrame;
begin
  if Size > 0 then
  begin
    Result := fMsgs[0] as IZMQFrame;
    fSize := fSize - Result.Size;
    fMsgs.Delete(0);
    fCursor := 0;
  end
  else
    Result := nil;
end;

function TZMQMsg.PopInt: Integer;
var
  frame: IZMQFrame;
begin
  frame := pop;
  try
    Result := frame.I;
  finally
    frame := nil;
  end;
end;

function TZMQMsg.PopStr: WideString;
var
  frame: IZMQFrame;
begin
  frame := pop;
  try
    Result := frame.S;
  finally
    frame := nil;
  end;
end;

function TZMQMsg.Push(const msg: IZMQFrame): Integer;
begin
  try
    fMsgs.Insert(0, msg);
    fSize := fSize + msg.size;
    fCursor := 0;
    Result := 0;
  except
    on e: Exception do
    begin
      Result := -1;
      TraceException('[TZMQMsg.Push]'+e.Message);
    end;
  end;
end;

function TZMQMsg.PushInt(const msg: Integer): Integer;
var
  frame: IZMQFrame;
begin
  frame := TZMQFrame.create( sizeOf( Integer ) );
  frame.I := msg;
  Result := Push( frame );
end;

function TZMQMsg.PushStr(const str: WideString): Integer;
var
  frm: IZMQFrame;
begin
  frm := TZMQFrame.create;
  frm.S := str;
  Result := push( frm );
end;

procedure TZMQMsg.Remove(const msg: IZMQFrame);
var
  i: Integer;
begin
  i := fMsgs.IndexOf(msg);
  if i > 0 then
  begin
    fSize := fSize - Item[i].size;
    fMsgs.Delete(i);
    fCursor := 0;
  end;
end;

function TZMQMsg.SaveAsHex: WideString;
var
  i: Integer;
begin
  for i := 0 to size - 1 do
  begin
    Result := Result + item[i].H;
    if i < size - 1 then
      Result := Result + #13 + #10;
  end;
end;

function TZMQMsg.Size: Integer;
begin
  Result := fMsgs.Count;
end;

function TZMQMsg.Unwrap: IZMQFrame;
begin
  Result := pop;
  if (size > 0) and (Item[0].size = 0) then
    pop;
end;

procedure TZMQMsg.Wrap(const msg: IZMQFrame);
var
  frame: IZMQFrame;
begin
  frame := TZMQFrame.Create(0);
  push(frame);
  push(msg);
end;

{ TZMQSocketImpl }

procedure TZMQSocketImpl.AddAcceptFilter(const addr: WideString);
var
  saddr: UTF8String;
begin
  saddr := UTF8Encode(addr);
  SetSockOpt( ZMQ_TCP_ACCEPT_FILTER, PAnsiChar(saddr), Length( saddr ) );
  {$IF CompilerVersion > 18.5}
  fAcceptFilter.Add( addr );
  {$ELSE}
  fAcceptFilter.Add( saddr );
  {$IFEND}
end;

procedure TZMQSocketImpl.Bind(const addr: WideString);
begin
  CheckResult(ZAPI.zmq_bind(SocketPtr, PAnsiChar(UTF8String(addr))));
end;

function TZMQSocketImpl.CheckResult(rc: Integer): Integer;
var
  errn: Integer;
begin
  Result := rc;
  if rc = -1 then
  begin
    errn := ZAPI.zmq_errno;
    if ( errn <> ZMQEAGAIN ) or fRaiseEAgain then
      raise EZMQException.Create( errn );
  end
  else
  if rc <> 0 then
    raise EZMQException.Create('Function result is not 0, or -1!');
end;

procedure TZMQSocketImpl.Close;
begin
  if SocketPtr = nil then
    Exit;
  CheckResult(ZAPI.zmq_close(SocketPtr));
  fSocket := nil;
end;

procedure TZMQSocketImpl.Connect(const addr: WideString);
begin                                                        
  CheckResult( ConnectEx(addr) );
end;

constructor TZMQSocketImpl.Create();
begin
  fRaiseEAgain := False;
  fAcceptFilter := TStringList.Create;
  fMonitorRec := nil;
  fData.SocketType := GetSocketType;
  fData.RcvMore := GetRcvMore;
  fData.RcvTimeout := GetRcvTimeout;
  fData.SndTimeout := GetSndTimeout;
  fData.Affinity := GetAffinity;
  fData.Identity := GetIdentity;
  fData.Rate := GetRate;
  fData.RecoveryIVL := GetRecoveryIVL;
  fData.SndBuf := GetSndBuf;
  fData.RcvBuf := GetRcvBuf;
  fData.Linger := GetLinger;
  fData.ReconnectIVL := GetReconnectIVL;
  fData.ReconnectIVLMax := GetReconnectIVLMax;
  fData.Backlog := GetBacklog;
  fData.FD := GetFD;
  fData.Events := GetEvents;
  fData.HWM := GetHWM;
  fData.SndHWM := GetSndHWM;
  fData.RcvHWM := GetRcvHWM;
  fData.MaxMsgSize := GetMaxMsgSize;
  fData.MulticastHops := GetMulticastHops;
  fData.IPv4Only := GetIPv4Only;
  fData.LastEndpoint := GetLastEndpoint;
  fData.KeepAlive := GetKeepAlive;
  fData.KeepAliveIdle := GetKeepAliveIdle;
  fData.KeepAliveCnt := GetKeepAliveCnt;
  fData.KeepAliveIntvl := GetKeepAliveIntvl;
  fData.AcceptFilter := GetAcceptFilter;
  fData.Context := GetContext;
  fData.Socket := GetSocket;
  fData.RaiseEAgain := GetRaiseEAgain;
  fData.SetHWM := SetHWM;
  fData.SetRcvTimeout := SetRcvTimeout;
  fData.SetSndTimeout := SetSndTimeout;
  fData.SetAffinity := SetAffinity;
  fData.SetIdentity := SetIdentity;
  fData.SetRate := SetRate;
  fData.SetRecoveryIvl := SetRecoveryIvl;
  fData.SetSndBuf := SetSndBuf;
  fData.SetRcvBuf := SetRcvBuf;
  fData.SetLinger := SetLinger;
  fData.SetReconnectIvl := SetReconnectIvl;
  fData.SetReconnectIvlMax := SetReconnectIvlMax;
  fData.SetBacklog := SetBacklog;
  fData.SetSndHWM := SetSndHWM;
  fData.SetRcvHWM := SetRcvHWM;
  fData.SetMaxMsgSize := SetMaxMsgSize;
  fData.SetMulticastHops := SetMulticastHops;
  fData.SetIPv4Only := SetIPv4Only;
  fData.SetKeepAlive := SetKeepAlive;
  fData.SetKeepAliveIdle := SetKeepAliveIdle;
  fData.SetKeepAliveCnt := SetKeepAliveCnt;
  fData.SetKeepAliveIntvl := SetKeepAliveIntvl;
  fData.SetAcceptFilter := SetAcceptFilter;
  fData.SetRouterMandatory := SetRouterMandatory;
  fData.SetRaiseEAgain := SetRaiseEAgain;
  fData.Implementator := Implementator;
  fData.Bind := Bind;
  fData.Unbind := Unbind;
  fData.Connect := Connect;
  fData.ConnectEx := ConnectEx;
  fData.Disconnect := Disconnect;
  fData.Free := Free;
  fData.Subscribe := Subscribe;
  fData.UnSubscribe := UnSubscribe;
  fData.AddAcceptFilter := AddAcceptFilter;
  fData.SendFrame := Send;
  fData.SendStream := Send;
  fData.SendString := Send;
  fData.SendMsg := Send;
  fData.SendStrings := Send;
  fData.SendBuffer := SendBuffer;
  fData.RecvFrame := Recv;
  fData.RecvStream := Recv;
  fData.RecvString := Recv;
  fData.RecvMsg := Recv;
  fData.RecvBuffer := RecvBuffer;
  fData.RegisterMonitor := RegisterMonitor;
  fData.UnregisterMonitor := UnregisterMonitor;
end;

procedure TZMQSocketImpl.UnregisterMonitor;
var
  rc: Cardinal;
begin
  if fMonitorRec <> nil then
  begin
    fMonitorRec.Terminated := True;
    rc := WaitForSingleObject( fMonitorThread, INFINITE );
    if rc = WAIT_FAILED then
      raise Exception.Create( 'error in WaitForSingleObject for Monitor Thread' );
    CheckResult(ZAPI.zmq_socket_monitor( SocketPtr, nil ,0 ) );
    Dispose( fMonitorRec );
    fMonitorRec := nil;
  end;
end;

destructor TZMQSocketImpl.Destroy;
begin
  if fMonitorRec <> nil then
  begin
    UnregisterMonitor;
    fMonitorRec := nil;
  end;

  Close;

  if fContext <> nil then
  begin
    fContext.RemoveSocket( Self );
    fContext := nil;
  end;

  if fAcceptFilter <> nil then
  begin
    fAcceptFilter.Free;
    fAcceptFilter := nil;
  end;
  
  inherited;
end;

procedure TZMQSocketImpl.Disconnect(const addr: WideString);
begin
  CheckResult(ZAPI.zmq_disconnect(SocketPtr, PAnsiChar(UTF8String(addr))));
end;

procedure TZMQSocketImpl.Free;
begin
  TObject(Self).Free;
end;

function TZMQSocketImpl.GetAcceptFilter(indx: Integer): WideString;
begin
  if ( indx < 0 ) or ( indx >= fAcceptFilter.Count ) then
    raise EZMQException.Create( '[getAcceptFilter] Index out of bounds.' );
  Result := fAcceptFilter[indx];
end;

function TZMQSocketImpl.GetAffinity: UInt64;
begin
  Result := GetSockOptInt64(ZMQ_AFFINITY);
end;

function TZMQSocketImpl.GetBacklog: Integer;
begin
  Result := GetSockOptInteger( ZMQ_BACKLOG );
end;

function TZMQSocketImpl.GetContext: IZMQContext;
begin
  Result := fContext;
end;

function TZMQSocketImpl.GetData: PZMQSocket;
begin
  Result := @fData;
end;

function TZMQSocketImpl.GetEvents: TZMQPollEvents;
var
  optvallen: size_t;
  i: Cardinal;
begin
  optvallen := SizeOf( i );
  GetSockOpt( ZMQ_EVENTS, @i, optvallen );
  Result := IntToZMQPollEvents(i);
end;

function TZMQSocketImpl.GetFD: Pointer;
var
  optvallen: size_t;
begin
  // Not sure this works, haven't tested.
  optvallen := SizeOf( result );
  GetSockOpt( ZMQ_FD, @result, optvallen );
end;

function TZMQSocketImpl.GetHWM: Integer;
begin
  Result := GetRcvHWM;
  // warning deprecated.
end;

function TZMQSocketImpl.GetIdentity: WideString;
var
  s: ShortString;
  optvallen: size_t;
begin
  optvallen := 255;
  GetSockOpt( ZMQ_IDENTITY, @s[1], optvallen );
  SetLength( s, optvallen );
  {$IF CompilerVersion > 18.5}
  Result := UTF8ToString(s);
  {$ELSE}
  Result := UTF8Decode(s);
  {$IFEND}
end;

function TZMQSocketImpl.GetIPv4Only: Boolean;
begin
  Result := GetSockOptInteger( ZMQ_IPV4ONLY ) <> 0;
end;

function TZMQSocketImpl.GetKeepAlive: TZMQKeepAlive;
begin
  Result := TZMQKeepAlive(GetSockOptInteger( ZMQ_TCP_KEEPALIVE ) + 1 );
end;

function TZMQSocketImpl.GetKeepAliveCnt: Integer;
begin
  Result := GetSockOptInteger( ZMQ_TCP_KEEPALIVE_CNT );
end;

function TZMQSocketImpl.GetKeepAliveIdle: Integer;
begin
  Result := GetSockOptInteger( ZMQ_TCP_KEEPALIVE_IDLE );
end;

function TZMQSocketImpl.GetKeepAliveIntvl: Integer;
begin
  Result := GetSockOptInteger( ZMQ_TCP_KEEPALIVE_INTVL );
end;

function TZMQSocketImpl.GetLastEndpoint: WideString;
var
  s: ShortString;
  optvallen: size_t;
begin
  optvallen := 255;
  getSockOpt( ZMQ_LAST_ENDPOINT, @s[1], optvallen );
  SetLength( s, optvallen - 1);
  {$IF CompilerVersion > 18.5}
  Result := UTF8ToString(s);
  {$ELSE}
  Result := UTF8Decode(s);
  {$IFEND}
end;

function TZMQSocketImpl.GetLinger: Integer;
begin
  Result := GetSockOptInteger( ZMQ_LINGER );
end;

function TZMQSocketImpl.GetMaxMsgSize: Int64;
begin
  Result := GetSockOptInt64( ZMQ_MAXMSGSIZE );
end;

function TZMQSocketImpl.GetMulticastHops: Integer;
begin
  Result := GetSockOptInteger( ZMQ_MULTICAST_HOPS );
end;

function TZMQSocketImpl.GetRaiseEAgain: Boolean;
begin
  Result :=fRaiseEAgain;
end;

function TZMQSocketImpl.GetRate: Integer;
begin
  Result := GetSockOptInteger( ZMQ_RATE );
end;

function TZMQSocketImpl.GetRcvBuf: Integer;
begin
  Result := GetSockOptInteger( ZMQ_RCVBUF );
end;

function TZMQSocketImpl.GetRcvHWM: Integer;
begin
  Result := GetSockOptInteger( ZMQ_RCVHWM );
end;

function TZMQSocketImpl.GetRcvMore: Boolean;
begin
  Result := GetSockOptInteger( ZMQ_RCVMORE ) = 1;
end;

function TZMQSocketImpl.GetRcvTimeout: Integer;
begin
  Result := GetSockOptInteger(ZMQ_RCVTIMEO);
end;

function TZMQSocketImpl.GetReconnectIVL: Integer;
begin
  Result := GetSockOptInteger( ZMQ_RECONNECT_IVL );
end;

function TZMQSocketImpl.GetReconnectIVLMax: Integer;
begin
  Result := GetSockOptInteger( ZMQ_RECONNECT_IVL_MAX );
end;

function TZMQSocketImpl.GetRecoveryIVL: Integer;
begin
  Result := GetSockOptInteger( ZMQ_RECOVERY_IVL );
end;

function TZMQSocketImpl.GetSndBuf: Integer;
begin
  Result := GetSockOptInteger( ZMQ_SNDBUF );
end;

function TZMQSocketImpl.GetSndHWM: Integer;
begin
  Result := GetSockOptInteger( ZMQ_SNDHWM );
end;

function TZMQSocketImpl.GetSndTimeout: Integer;
begin
  Result := GetSockOptInteger(ZMQ_SNDTIMEO);
end;

function TZMQSocketImpl.GetSocket: Pointer;
begin
  Result := fSocket;
end;

function TZMQSocketImpl.GetSocketType: TZMQSocketType;
begin
  Result := TZMQSocketType(getSockOptInteger(ZMQ_TYPE));
end;

procedure TZMQSocketImpl.GetSockOpt(option: Integer; optval: Pointer;
  var optvallen: Cardinal);
begin
  CheckResult(ZAPI.zmq_getsockopt(SocketPtr, option, optval, optvallen));
end;

function TZMQSocketImpl.GetSockOptInt64(option: Integer): Int64;
var
  optvallen: size_t;
begin
  optvallen := SizeOf( result );
  GetSockOpt( option, @result, optvallen );
end;

function TZMQSocketImpl.GetSockOptInteger(option: Integer): Integer;
var
  optvallen: size_t;
begin
  optvallen := SizeOf( result );
  GetSockOpt( option, @result, optvallen );
end;

function TZMQSocketImpl.Implementator: Pointer;
begin
  Result := Self;
end;

function TZMQSocketImpl.Recv(var msg: IZMQFrame;
  flags: TZMQRecvFlags): Integer;
begin
  Result := Recv(msg, ZMQRecvFlagsToInt(flags));
end;

function TZMQSocketImpl.Recv(const strm: IStream;
  flags: TZMQRecvFlags): Integer;
var
  frame: IZMQFrame;
  cbWritten: LongInt;
begin
  frame := TZMQFrame.Create;
  try
    Result := recv( frame, flags );
    strm.Write(frame.data, result, @cbWritten);
  finally
    frame := nil;
  end;
end;

function TZMQSocketImpl.Recv(var msg: IZMQFrame; flags: Integer): Integer;
var
  errn: Integer;
begin
  if msg = nil then
    msg := TZMQFrame.Create;
  if msg.size > 0 then
    msg.rebuild;
  Result := ZAPI.zmq_recvmsg( SocketPtr, msg.Handle, flags );
  if Result < -1 then
    raise EZMQException.Create('zmq_recvmsg return value less than -1.')
  else
  if Result = -1 then
  begin
    errn := ZAPI.zmq_errno;
    if ( errn <> ZMQEAGAIN ) or fRaiseEAgain then
      raise EZMQException.Create( errn );
  end;
end;

function TZMQSocketImpl.Recv(var msgs: IZMQMsg; flags: TZMQRecvFlags): Integer;
var
  msg: IZMQFrame;
  bRcvMore: Boolean;
  rc: Integer;
begin
  if msgs = nil then
    msgs := TZMQMsg.Create;
    
  bRcvMore := True;
  result := 0;
  while bRcvMore do
  begin
    msg := TZMQFrame.create;
    rc := recv( msg, flags );
    if rc <> -1 then
    begin
      msgs.Add(msg);
      inc(result);
    end
    else
    begin
      result := -1;
      msg := nil;
      break;
    end;
    bRcvMore := RcvMore;
  end;
end;

function TZMQSocketImpl.Recv(var msg: WideString;
  flags: TZMQRecvFlags): Integer;
var
  frame: IZMQFrame;
begin
  frame := TZMQFrame.Create;
  try
    Result := recv( frame, flags );
    msg := frame.S;
  finally
    frame := nil;
  end;
end;

function TZMQSocketImpl.RecvBuffer(var Buffer; len: size_t;
  flags: TZMQRecvFlags): Integer;
var
  errn: Integer;
begin
  result := ZAPI.zmq_recv( SocketPtr, Buffer, len, ZMQRecvFlagsToInt(flags) );
  if result < -1 then
    raise EZMQException.Create('zmq_recv return value less than -1.')
  else if result = -1 then
  begin
    errn := ZAPI.zmq_errno;
    if ( errn <> ZMQEAGAIN ) or fRaiseEAgain then
      raise EZMQException.Create( errn );
  end;
end;

procedure __MonitorProc(ZMQMonitorRec: PZMQMonitorRec);
var
  socket: TZMQSocketImpl;
  msg: IZMQFrame;
  msgsize: Integer;
  event: zmq_event_t;
  zmqEvent: TZMQEvent;
  i: Integer;
begin    
  socket := TZMQContext(ZMQMonitorRec.context).Socket( stPair ).Implementator;
  try
    socket.RcvTimeout := 100; // 1 sec.
    socket.connect( ZMQMonitorRec.Addr );
    msg := TZMQFrame.create;
    while not ZMQMonitorRec.Terminated do
    begin
      try
        msgsize := socket.Recv( msg, [] );
        if ZMQMonitorRec.Terminated then
          Break;
        if msgsize > -1 then
        begin
          CopyMemory(@event, msg.data, SizeOf(event));
          i := 0;
          while event.event <> 0 do
          begin
            event.event := event.event shr 1;
            inc( i );
          end;
          zmqEvent.event := TZMQMonitorEvent( i - 1 );
          {$IF CompilerVersion > 18.5}
          zmqEvent.addr := UTF8ToString(event.addr);
          {$ELSE}
          zmqEvent.addr := UTF8Decode(event.addr);
          {$IFEND}
          zmqEvent.fd    := event.fd;
          if ZMQMonitorRec.Terminated then
            Break;
          ZMQMonitorRec.proc( zmqEvent );
          msg.rebuild;
        end;
      except
        on e: EZMQException do
          if e.ErrorCode <> ZMQEAGAIN then
            raise;
      end;
      Sleep(10);
    end;
    msg := nil;
  finally
    if not TZMQContext(ZMQMonitorRec.context).FDestroying then
      socket.Free;
  end;
end;

procedure TZMQSocketImpl.RegisterMonitor(proc: TZMQMonitorProc;
  events: TZMQMonitorEvents);
var
  tid: Cardinal;
begin
  if fMonitorRec <> nil then
    UnregisterMonitor;

  New( fMonitorRec );
  fMonitorRec.Terminated := False;
  fMonitorRec.context := fContext;
  fMonitorRec.Addr := 'inproc://monitor.' + IntToHex( Integer( SocketPtr ),8 );
  fMonitorRec.Proc := proc;

  CheckResult(ZAPI.zmq_socket_monitor( SocketPtr,
    PAnsiChar( Utf8String( fMonitorRec.Addr ) ), ZMQMonitorEventsToInt(events) ) );

  fMonitorThread := BeginThread( nil, 0, @__MonitorProc, fMonitorRec, 0, tid );
  sleep(1);
end;

// send single or multipart message, in blocking or nonblocking mode,
// depending on the flags.
function TZMQSocketImpl.Send(const msg: WideString; flags: TZMQSendFlags): Integer;
var
  frame: IZMQFrame;
begin
  frame := TZMQFrame.create;
  try
    frame.S := msg;
    Result := send( frame, flags );
  finally
    frame := nil;
  end;
end;

function TZMQSocketImpl.Send(var msgs: IZMQMsg; dontwait: Boolean): Integer;
var
  flags: TZMQSendFlags;
  frame: IZMQFrame;
  rc: Integer;
begin
  Result := 0;
  if dontwait then
    flags := [sfDontWait]
  else
    flags := [];
  while msgs.size > 0 do
  begin
    frame := msgs.pop;
    if msgs.size = 0 then
      rc := send( frame, flags )
    else
      rc := send( frame, flags + [sfSndMore] );
    if rc = -1 then
    begin
      result := -1;
      break;
    end
    else
      inc( result )
  end;
  if result <> -1 then
    msgs := nil;
end;

function TZMQSocketImpl.Send(const msg: array of WideString;
  dontwait: Boolean): Integer;
var
  msgs: IZMQMsg;
  frame: IZMQFrame;
  i: Integer;
begin
  msgs := TZMQMsg.create;
  try
    for i := 0 to Length( msg ) - 1 do
    begin
      frame := TZMQFrame.create;
      frame.S := msg[i];
      msgs.Add( frame );
    end;
    Result := Send( msgs, dontwait );
  finally
    msgs := nil;
  end;
end;

function TZMQSocketImpl.Send(var msg: IZMQFrame;
  flags: TZMQSendFlags): Integer;
begin
  Result := Send(msg, ZMQSendFlagsToInt(flags));
end;

function TZMQSocketImpl.Send(var msg: IZMQFrame; flags: Integer): Integer;
var
  errn: Integer;
begin
  Result := ZAPI.zmq_sendmsg(SocketPtr, msg.Handle, flags );
  if Result < -1 then
    raise EZMQException.Create('zmq_sendmsg return value less than -1.')
  else
  if Result = -1 then
  begin
    errn := ZAPI.zmq_errno;
    if ( errn <> ZMQEAGAIN ) or fRaiseEAgain then
      raise EZMQException.Create( errn );
  end
  else
    msg := nil;
end;

function TZMQSocketImpl.Send(const strm: IStream; size: Integer;
  flags: TZMQSendFlags): Integer;
var
  frame: IZMQFrame;
  cbRead: LongInt;
begin
  frame := TZMQFrame.Create( size );
  try
    strm.Read( frame.data, size, @cbRead);
    result := send( frame, flags );
  finally
    frame := nil;
  end;
end;

function TZMQSocketImpl.SendBuffer(const Buffer; len: Size_t;
  flags: TZMQSendFlags): Integer;
var
  errn: Integer;
begin
  result := ZAPI.zmq_send(SocketPtr, Buffer, len, ZMQSendFlagsToInt(flags));
  if result < -1 then
    raise EZMQException.Create('zmq_send return value less than -1.')
  else
  if result = -1 then
  begin
    errn := ZAPI.zmq_errno;
    if ( errn <> ZMQEAGAIN ) or fRaiseEAgain then
      raise EZMQException.Create( errn );
  end;
end;

procedure TZMQSocketImpl.SetAcceptFilter(indx: Integer;
  const Value: WideString);
var
  i,num: Integer;
  sValue: UTF8String;
begin
  num := 0;
  if ( indx < 0 ) or ( indx >= fAcceptFilter.Count ) then
    raise EZMQException.Create( '[getAcceptFilter] Index out of bounds.' );

  SetSockOpt( ZMQ_TCP_ACCEPT_FILTER, nil, 0 );
  for i := 0 to fAcceptFilter.Count - 1 do
  begin
    try
      if i <> indx then
      begin
        sValue := UTF8Encode(fAcceptFilter[i]);
        SetSockOpt( ZMQ_TCP_ACCEPT_FILTER, @sValue[1], Length(sValue) )
      end
      else
      begin
        sValue := UTF8Encode(Value);
        SetSockOpt( ZMQ_TCP_ACCEPT_FILTER, @sValue[1], Length(sValue) );
        {$IF CompilerVersion > 18.5}
        fAcceptFilter.Add( Value );
        {$ELSE}
        fAcceptFilter.Add( sValue );
        {$IFEND}
      end;
    except
      on e: EZMQException do
      begin
        num := e.ErrorCode;
        if i = indx then
          SetSockOpt( ZMQ_TCP_ACCEPT_FILTER, @fAcceptFilter[i][1], Length( fAcceptFilter[i] ) )
      end
      else
        raise;
    end;
  end;
  if num <> 0 then
    raise EZMQException.Create( num );
end;

procedure TZMQSocketImpl.SetAffinity(const Value: UInt64);
begin
  SetSockOptInt64( ZMQ_AFFINITY, Value );
end;

procedure TZMQSocketImpl.SetBacklog(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_BACKLOG, Value );
end;

procedure TZMQSocketImpl.SetHWM(const Value: Integer);
begin
  SndHWM := Value;
  RcvHWM := Value;
end;

procedure TZMQSocketImpl.SetIdentity(const Value: WideString);
var
  s: UTF8String;
begin
  s := UTF8Encode(Value);
  SetSockOpt( ZMQ_IDENTITY, @s[1], Length( s ) );
end;

procedure TZMQSocketImpl.SetIPv4Only(const Value: Boolean);
begin
  SetSockOptInteger( ZMQ_IPV4ONLY, Integer(Value) );
end;

procedure TZMQSocketImpl.SetKeepAlive(const Value: TZMQKeepAlive);
begin
  SetSockOptInteger( ZMQ_TCP_KEEPALIVE, Byte(Value) - 1 );
end;

procedure TZMQSocketImpl.SetKeepAliveCnt(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_TCP_KEEPALIVE_CNT, Value );
end;

procedure TZMQSocketImpl.SetKeepAliveIdle(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_TCP_KEEPALIVE_IDLE, Value );
end;

procedure TZMQSocketImpl.SetKeepAliveIntvl(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_TCP_KEEPALIVE_INTVL, Value );
end;

procedure TZMQSocketImpl.SetLinger(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_LINGER, Value );
end;

procedure TZMQSocketImpl.SetMaxMsgSize(const Value: Int64);
begin
  SetSockOptInt64( ZMQ_MAXMSGSIZE, Value );
end;

procedure TZMQSocketImpl.SetMulticastHops(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_MULTICAST_HOPS, Value );
end;

procedure TZMQSocketImpl.SetRaiseEAgain(const Value: Boolean);
begin
  fRaiseEAgain := Value;
end;

procedure TZMQSocketImpl.SetRate(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_RATE, Value );
end;

procedure TZMQSocketImpl.SetRcvBuf(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_RCVBUF, Value );
end;

procedure TZMQSocketImpl.SetRcvHWM(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_RCVHWM, Value );
end;

procedure TZMQSocketImpl.SetRcvTimeout(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_RCVTIMEO, Value );
end;

procedure TZMQSocketImpl.SetReconnectIvl(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_RECONNECT_IVL, Value );
end;

procedure TZMQSocketImpl.SetReconnectIvlMax(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_RECONNECT_IVL_MAX, Value );
end;

procedure TZMQSocketImpl.SetRecoveryIvl(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_RECOVERY_IVL, Value );
end;

procedure TZMQSocketImpl.SetRouterMandatory(const Value: Boolean);
var
  i: Integer;
begin
  if Value then
    i := 1
  else
    i := 0;
  SetSockOptInteger( ZMQ_ROUTER_MANDATORY, i );
end;

procedure TZMQSocketImpl.SetSndBuf(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_SNDBUF, Value );
end;

procedure TZMQSocketImpl.SetSndHWM(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_SNDHWM, Value );
end;

procedure TZMQSocketImpl.SetSndTimeout(const Value: Integer);
begin
  SetSockOptInteger( ZMQ_SNDTIMEO, Value );
end;

procedure TZMQSocketImpl.SetSockOpt(option: Integer; optval: Pointer;
  optvallen: Cardinal);
begin
  CheckResult(ZAPI.zmq_setsockopt(SocketPtr, option, optval, optvallen));
end;

procedure TZMQSocketImpl.SetSockOptInt64(option: Integer; const Value: Int64);
var
  optvallen: size_t;
begin
  optvallen := SizeOf( Value );
  SetSockOpt( option, @Value, optvallen );
end;

procedure TZMQSocketImpl.SetSockOptInteger(option: Integer;
  const Value: Integer);
var
  optvallen: size_t;
begin
  optvallen := SizeOf( Value );
  SetSockOpt( option, @Value, optvallen );
end;

procedure TZMQSocketImpl.Subscribe(const filter: WideString);
begin
  if filter = '' then
    SetSockOpt( ZMQ_SUBSCRIBE, nil, 0 )
  else
    SetSockOpt( ZMQ_SUBSCRIBE, @filter[1], Length(filter)*ZMQ_CHAR_SIZE );
end;

procedure TZMQSocketImpl.Unbind(const addr: WideString);
begin
  CheckResult(ZAPI.zmq_unbind(SocketPtr, PAnsiChar(UTF8String(addr))));
end;

procedure TZMQSocketImpl.UnSubscribe(const filter: WideString);
begin
  if filter = '' then
    SetSockOpt(ZMQ_UNSUBSCRIBE, nil, 0)
  else
    SetSockOpt(ZMQ_UNSUBSCRIBE, @filter[1], Length(filter)*ZMQ_CHAR_SIZE);
end;

function TZMQSocketImpl.ConnectEx(const addr: WideString): Integer;
begin                                                  
  Result := ZAPI.zmq_connect(SocketPtr, PAnsiChar(UTF8Encode(addr)));
end;

{ TZMQContext }

procedure TZMQContext.CheckResult(rc: Integer);
begin
  if rc = 0 then
  begin
    // ok
  end
  else
  if rc = -1 then
  begin
    raise EZMQException.Create;
  end
  else
    raise EZMQException.Create('Function result is not 0, or -1!');
end;

constructor TZMQContext.Create;
begin
  fTerminated := false;
  fMainThread := true;
  varContexts.Add( Self );
  fContext := ZAPI.zmq_ctx_new;
  fLinger := -2;
  if fContext = nil then
    raise EZMQException.Create;
  fSockets := TThreadList.Create;
end;

constructor TZMQContext.CreateShadow(const Context: TZMQContext);
begin
  fTerminated := false;
  fMainThread := false;
  varContexts.Add( Self );
  fContext   := Context.ContextPtr;
  fLinger    := Context.Linger;
  fSockets   := TThreadList.Create;
end;

destructor TZMQContext.Destroy;
var
  i: Integer;
  LList: TList;
begin
  if fSockets <> nil  then
  begin
    LList := fSockets.LockList;
    try
      if fLinger >= -1 then
        for i:= 0 to LList.Count - 1 do
          TZMQSocketImpl(LList[i]).Linger := fLinger;
      while LList.Count > 0 do
        TZMQSocketImpl(LList[LList.Count-1]).Free;
      LList.Clear;
    finally
      fSockets.UnlockList;
    end;
    FreeAndNil(fSockets);
  end;

  if (fContext <> nil) and fMainThread then
    CheckResult(ZAPI.zmq_ctx_destroy(fContext));
  fContext := nil;
  
  varContexts.Delete(varContexts.IndexOf(Self));
  inherited;
end;

function TZMQContext.GetContextPtr: Pointer;
begin
  Result := fContext;
end;

function TZMQContext.GetIOThreads: Integer;
begin
  Result := GetOption( ZMQ_IO_THREADS );
end;

function TZMQContext.GetLinger: Integer;
begin
  Result := fLinger;
end;

function TZMQContext.GetMaxSockets: Integer;
begin
  Result := GetOption( ZMQ_MAX_SOCKETS );
end;

function TZMQContext.GetOption(option: Integer): Integer;
begin
  result := ZAPI.zmq_ctx_get( ContextPtr, option );
  if Result = -1 then
    raise EZMQException.Create
  else
  if Result < -1 then
    raise EZMQException.Create('Function result is less than -1!');
end;

function TZMQContext.GetTerminated: Boolean;
begin
  Result := fTerminated;
end;

procedure TZMQContext.RemoveSocket(const socket: TZMQSocketImpl);
var
  i: Integer;
  LList: TList;
begin
  LList := fSockets.LockList;
  try
    i := LList.IndexOf(socket);
    if i < 0 then
      raise EZMQException.Create( 'Socket not in context' );
    LList.Delete(i);
  finally
    fSockets.UnlockList;
  end;
end;

procedure TZMQContext.SetIOThreads(const Value: Integer);
begin
  SetOption( ZMQ_IO_THREADS, Value );
end;

procedure TZMQContext.SetLinger(const Value: Integer);
begin
  fLinger := Value;
end;

procedure TZMQContext.SetMaxSockets(const Value: Integer);
begin
  SetOption(ZMQ_MAX_SOCKETS, Value);
end;

procedure TZMQContext.SetOption(option, optval: Integer);
begin
  CheckResult(ZAPI.zmq_ctx_set( ContextPtr, option, optval ) );
end;

function TZMQContext.Shadow: IZMQContext;
begin
  Result := TZMQContext.CreateShadow(self);
end;

function TZMQContext.Socket(stype: TZMQSocketType): PZMQSocket;
var
  LSocket: TZMQSocketImpl;
  LList: TList;
begin
  LList := fSockets.LockList;
  try
    LSocket := TZMQSocketImpl.Create();
    LSocket.fSocket := ZAPI.zmq_socket(fContext, Byte(stype));
    if LSocket.fSocket = nil then
    begin
      Result := nil;
      LSocket.Free;
      raise EZMQException.Create;
    end;
    LSocket.fContext := Self;
    LList.Add(LSocket);

    Result := LSocket.Data;
  finally
    fSockets.UnlockList;
  end;
end;

procedure TZMQContext.Terminate;
var
  p: Pointer;
begin
  if not Terminated then
  begin
    fTerminated := true;
    p := fContext;
    fContext := nil;

    if fMainThread then
      CheckResult(ZAPI.zmq_ctx_destroy(p));;
  end;
end;

{ TZMQPollerThread }

procedure TZMQPollerThread.AddToPollItems(const socket: TZMQSocketImpl; events: TZMQPollEvents);
begin
  EnterCriticalSection(FLock);
  try
    if fPollItemCapacity = fPollItemCount then
    begin
      fPollItemCapacity := fPollItemCapacity + 10;
      SetLength(fPollItem, fPollItemCapacity);
      SetLength(fPollSocket, fPollItemCapacity);
    end;
    fPollSocket[fPollItemCount] := socket;
    fPollItem[fPollItemCount].socket := socket.SocketPtr;
    fPollItem[fPollItemCount].fd := 0;
    fPollItem[fPollItemCount].events := ZMQPollEventsToInt(events);
    fPollItem[fPollItemCount].revents := 0;
    fPollItemCount := fPollItemCount + 1;
    fPollNumber := fPollItemCount;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TZMQPollerThread.CheckResult(rc: Integer);
begin
  if rc = -1 then
    raise EZMQException.Create
  else
  if rc < -1 then
    raise EZMQException.Create('Function result is less than -1!');
end;

constructor TZMQPollerThread.Create(aOwner: TZMQPoller; aSync: Boolean;
  const aContext: IZMQContext);
begin
  fOwner := aOwner;
  fSync := aSync;
  InitializeCriticalSection(fLock);

  fOnException := nil;
  if not fSync then
  begin
    if aContext = nil then
      fContext := TZMQContext.create
    else
      fContext := aContext;
    fAddr := 'inproc://poller' + IntToHex(Integer(Self), 8);
    fPair := fContext.Socket(stPair).Implementator;
    fPair.bind(fAddr);
  end;
  fPollItemCapacity := 10;
  fPollItemCount := 0;
  fPollNumber := 0;
  SetLength(fPollItem, fPollItemCapacity);
  SetLength(fPollSocket, fPollItemCapacity);

  fTimeOut := -1;
  inherited Create(fSync);
end;

procedure TZMQPollerThread.DelFromPollItems(const socket: TZMQSocketImpl;
  events: TZMQPollEvents; index: Integer);
var
  i: Integer;
begin
  EnterCriticalSection(FLock);
  try
    fPollItem[index].events := fPollItem[index].events and not ZMQPollEventsToInt(events);
    if fPollItem[index].events = 0 then
    begin
      for i := index to fPollItemCount - 2 do
      begin
        fPollItem[i] := fPollItem[i + 1];
        fPollSocket[i] := fPollSocket[i + 1];
      end;
      Dec(fPollItemCount);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TZMQPollerThread.Deregister(const socket: PZMQSocket;
  events: TZMQPollEvents; bWait: Boolean);
var
  s: WideString;
  i: Integer;
begin
  if fSync then
  begin
    i := 0;
    while (i < fPollItemCount) and (fPollSocket[i].Implementator <> socket.Implementator) do
      inc(i);
    if i = fPollItemCount then
      raise EZMQException.Create( 'socket not in pollitems!' );
    DelFromPollItems(TZMQSocketImpl(socket.Implementator), events, i);
  end
  else
  begin
    if bWait then
      s := cZMQPoller_SyncDeregister
    else
      s := cZMQPoller_Deregister;
    fPair.Send([s, IntToStr(Integer(socket.Implementator)), IntToStr(ZMQPollEventsToInt(events))]);
    if bWait then
      fPair.recv( s );
  end;
end;

destructor TZMQPollerThread.Destroy;
begin
  if not fSync then
  begin
    fPair.send(cZMQPoller_Terminate);
    fPair := nil;
    fContext := nil;
  end;
  DeleteCriticalSection(fLock);
  inherited;
end;

procedure TZMQPollerThread.Execute;
type
  TTempRec = record
    socket: TZMQSocketImpl;
    events: TZMQPollEvents;
    reg,           // true if reg, false if dereg.
    sync: Boolean; // if true, socket should send back a message
  end;
var
  LPairThread: TZMQSocketImpl;
  rc: Integer;
  i,j: Integer;
  pes: TZMQPollEvents;
  msg: IZMQMsg;
  sMsg: WideString;

  reglist: array of TTempRec;
  reglistcap,
  reglistcount: Integer;

  procedure _AddToRegList(const so: TZMQSocketImpl; ev: TZMQPollEvents; reg: Boolean; sync: Boolean);
  begin
    if reglistcap = reglistcount then
    begin
      reglistcap := reglistcap + 10;
      SetLength( reglist, reglistcap );
    end;
    reglist[reglistcount].socket := so;
    reglist[reglistcount].events := ev;
    reglist[reglistcount].reg := reg;
    reglist[reglistcount].sync := sync;
    inc( reglistcount );
  end;
begin
  reglistcap := 10;
  reglistcount := 0;
  SetLength(reglist, reglistcap);

  LPairThread := fContext.Socket(stPair).Implementator;
  try
    LPairThread.Connect(fAddr);

    fPollItemCount := 1;
    fPollNumber := 1;

    fPollSocket[0]       := LPairThread;
    fPollItem[0].socket  := LPairThread.SocketPtr;
    fPollItem[0].fd      := 0;
    fPollItem[0].events  := ZMQ_POLLIN;
    fPollItem[0].revents := 0;

    msg := TZMQMsg.Create;
    while not Terminated do
    try
      rc := ZAPI.zmq_poll(@fPollItem[0], fPollNumber, fTimeOut);
      CheckResult(rc);
      if rc = 0 then
      begin
        if @fOnTimeOut <> nil then
          fOnTimeOut(fOwner);
      end
      else
      begin
        for i := 0 to fPollNumber - 1 do
        if fPollItem[i].revents > 0 then
        begin
          if i = 0 then
          begin
            // control messages.
            msg.Clear;
            fPollSocket[0].recv(msg);
            sMsg := msg[0].S;
            if (sMsg = cZMQPoller_Register) or (sMsg = cZMQPoller_SyncRegister)then
            begin
              pes := IntToZMQPollEvents(msg[2].I);
              _AddToRegList(TZMQSocketImpl(StrToInt(msg[1].S)), pes, True, sMsg = cZMQPoller_SyncRegister);
            end
            else
            if (sMsg = cZMQPoller_DeRegister) or (sMsg = cZMQPoller_SyncDeRegister) then
            begin
              pes := IntToZMQPollEvents(msg[2].I);
              _AddToRegList(TZMQSocketImpl(StrToInt(msg[1].S)), pes, False, sMsg = cZMQPoller_SyncDeRegister);
            end
            else
            if (sMsg = cZMQPoller_PollNumber) or (sMsg = cZMQPoller_SyncPollNumber) then
            begin
              fPollNumber := msg[1].I;
              if sMsg = cZMQPoller_SyncPollNumber then
                LPairThread.send('');
            end
            else
            if sMsg = cZMQPoller_Terminate then
              Terminate;
          end
          else
          if @fOnEvent <> nil then
          begin
            pes := IntToZMQPollEvents(fPollItem[i].revents);
            fOnEvent(fPollSocket[i].Data, pes);
          end;
        end;

        if reglistcount > 0 then
        begin
          for i := 0 to reglistcount - 1 do
          begin
            j := 1;
            while (j < fPollItemCount) and (fPollSocket[j] <> reglist[i].socket) do
              inc( j );
            if j < fPollItemCount then
            begin
              if reglist[i].reg then
                fPollItem[j].events := fPollItem[j].events or ZMQPollEventsToInt(reglist[i].events)
              else
                DelFromPollItems( reglist[i].socket, reglist[i].events, j );
            end
            else
            begin
              if reglist[i].reg then
                AddToPollItems( reglist[i].socket, reglist[i].events )
              //else
                //warn not found, but want to delete.
            end;
            if reglist[i].sync then
              LPairThread.send('');
          end;
          reglistcount := 0;
        end;
      end;
    except
      on e: Exception do
      begin
        if (e is EZMQException) and (EZMQException(e).ErrorCode = ETERM) then
          Terminate;
        if Assigned(fOnException) then
          fOnException(e);
      end;
    end;
    msg := nil;
  finally
    LPairThread.Free;
  end;
end;

function TZMQPollerThread.GetPollItem(const Index: Integer): TZMQPollItem;
begin
  EnterCriticalSection(fLock);
  try
    Result.socket := fPollSocket[Index].Data;
    Byte(Result.events) := fPollItem[Index].events;
    Byte(Result.revents) := fPollItem[Index].revents;
  finally
    LeaveCriticalSection(fLock);
  end;
end;

function TZMQPollerThread.GetPollResult(
  const Index: Integer): TZMQPollItem;
var
  i,j: Integer;
begin
  if not fSync then
    raise EZMQException.Create('Poller created in Synchronous mode');
  i := 0;
  j := -1;
  while (i < fPollItemCount) and (j < Index) do
  begin
    if (fPollItem[i].revents and fPollItem[i].events) > 0 then
      inc(j);
    if j < Index then
      inc(i);
  end;
  Result.socket := fPollSocket[i].Data;
  Byte(Result.events) := fPollItem[i].revents;
end;

function TZMQPollerThread.Poll(timeout, lPollNumber: Integer): Integer;
var
  pc, i: Integer;
begin
  if not fSync then
    raise EZMQException.Create('Poller hasn''t created in Synchronous mode');
  if fPollItemCount = 0 then
    raise EZMQException.Create( 'Nothing to poll!' );
  if lPollNumber = -1 then
    pc := fPollItemCount
  else
  if (lpollNumber > -1) and (lpollNumber <= fPollItemCount) then
    pc := lpollNumber
  else
    raise EZMQException.Create( 'wrong pollCount parameter.' );

  for i := 0 to fPollItemCount - 1 do
    fPollItem[i].revents := 0;
  Result := ZAPI.zmq_poll(@fPollItem[0], pc, timeout);
  if result < 0 then
    raise EZMQException.Create
end;

procedure TZMQPollerThread.Register(const socket: PZMQSocket;
  events: TZMQPollEvents; bWait: Boolean);
var
  s: WideString;
begin
  if fSync then
    AddToPollItems(socket.Implementator, events)
  else
  begin
    if bWait then
      s := cZMQPoller_SyncRegister
    else
      s := cZMQPoller_Register;
    fPair.Send([s, IntToStr(Integer(socket.Implementator)), IntToStr(ZMQPollEventsToInt(events))]);
    if bWait then
      fPair.recv(s);
  end;
end;

procedure TZMQPollerThread.SetPollNumber(const Value: Integer;
  bWait: Boolean);
var
  s: WideString;
begin
  if fSync then
    fPollNumber := Value
  else
  begin
    if bWait then
      s := cZMQPoller_PollNumber
    else
      s := cZMQPoller_SyncPollNumber;
    fPair.Send([s, IntToStr(Value)]);
    if bWait then
      fPair.Recv(s);
  end;
end;

{ TZMQPoller }

constructor TZMQPoller.Create(aSync: Boolean; const aContext: IZMQContext);
begin
  FThread := TZMQPollerThread.Create(Self, aSync, aContext);
end;

destructor TZMQPoller.Destroy;
begin
  if (FThread <> nil) and (not FThread.FreeOnTerminate) then
    FreeAndNil(FThread);
  FThread := nil;
  inherited;
end;

function TZMQPoller.GetFreeOnTerminate: Boolean;
begin
  Result := FThread.FreeOnTerminate;
end;

function TZMQPoller.GetHandle: THandle;
begin
  Result := FThread.Handle;
end;

function TZMQPoller.GetOnEvent: TZMQPollEventProc;
begin
  Result := FThread.OnEvent;
end;

function TZMQPoller.GetOnException: TZMQExceptionProc;
begin
  Result := FThread.OnException;
end;

function TZMQPoller.GetOnTerminate: TNotifyEvent;
begin
  Result := FThread.OnTerminate;
end;

function TZMQPoller.GetOnTimeOut: TZMQTimeOutProc;
begin
  Result := FThread.OnTimeOut;
end;

function TZMQPoller.GetPollItem(const Index: Integer): TZMQPollItem;
begin
  Result := FThread.PollItem[index];
end;

function TZMQPoller.GetPollNumber: Integer;
begin
  Result := FThread.PollNumber;
end;

function TZMQPoller.GetPollResult(const Index: Integer): TZMQPollItem;
begin
  Result := FThread.GetPollResult(Index);
end;

function TZMQPoller.GetSuspended: Boolean;
begin
  Result := FThread.Suspended;
end;

function TZMQPoller.GetThreadID: THandle;
begin
  Result := FThread.ThreadID;
end;

function TZMQPoller.Poll(timeout, lPollNumber: Integer): Integer;
begin
  Result := FThread.Poll(timeout, lPollNumber)
end;

procedure TZMQPoller.Register(const socket: PZMQSocket;
  const events: TZMQPollEvents; bWait: Boolean);
begin
  FThread.Register(socket, events, bWait);
end;

procedure TZMQPoller.Resume;
begin
{$WARNINGS OFF}
  FThread.Resume;
{$WARNINGS ON}
end;

procedure TZMQPoller.SetFreeOnTerminate(const Value: Boolean);
begin
  FThread.FreeOnTerminate := Value;
end;

procedure TZMQPoller.SetOnEvent(const AValue: TZMQPollEventProc);
begin
  FThread.OnEvent := AValue;
end;

procedure TZMQPoller.SetOnException(const AValue: TZMQExceptionProc);
begin
  FThread.OnException := AValue;
end;

procedure TZMQPoller.SetOnTerminate(const Value: TNotifyEvent);
begin
  FThread.OnTerminate := Value;
end;

procedure TZMQPoller.SetOnTimeOut(const AValue: TZMQTimeOutProc);
begin
  FThread.OnTimeOut := AValue;
end;

procedure TZMQPoller.SetPollNumber(const AValue: Integer);
begin
  FThread.SetPollNumber(AValue, False);
end;

procedure TZMQPoller.SetPollNumberAndWait(const Value: Integer);
begin
  FThread.SetPollNumber(Value, True);
end;

procedure TZMQPoller.SetSuspended(const Value: Boolean);
begin
  FThread.Suspended := Value;
end;

procedure TZMQPoller.Suspend;
begin
{$WARNINGS OFF}
  FThread.Suspend;
{$WARNINGS ON}
end;

procedure TZMQPoller.Terminate;
begin
   FThread.Terminate;
end;

procedure TZMQPoller.Unregister(const socket: PZMQSocket;
  const events: TZMQPollEvents; bWait: Boolean);
begin
  FThread.Deregister(socket, events, bWait);
end;

function TZMQPoller.WaitFor: LongWord;
begin
  Result := FThread.WaitFor;
end;

{ TZMQThread }

constructor TZMQThread.Create(lArgs: Pointer; const ctx: IZMQContext);
begin
  FThread := TZMQInternalThread.Create(lArgs, ctx);
end;

constructor TZMQThread.CreateAttached(lAttachedMeth: TAttachedThreadMethod;
  const ctx: IZMQContext; lArgs: Pointer);
begin
  FThread := TZMQInternalThread.CreateAttached(lAttachedMeth, ctx, lArgs);
end;

constructor TZMQThread.CreateAttachedProc(
  lAttachedProc: TAttachedThreadProc; const ctx: IZMQContext;
  lArgs: Pointer);
begin
  FThread := TZMQInternalThread.CreateAttachedProc(lAttachedProc, ctx, lArgs);
end;

constructor TZMQThread.CreateDetached(lDetachedMeth: TDetachedThreadMethod;
  lArgs: Pointer);
begin
  FThread := TZMQInternalThread.CreateDetached(lDetachedMeth, lArgs);
end;

constructor TZMQThread.CreateDetachedProc(
  lDetachedProc: TDetachedThreadProc; lArgs: Pointer);
begin
  FThread := TZMQInternalThread.CreateDetachedProc(lDetachedProc, lArgs);
end;

destructor TZMQThread.Destroy;
begin
  if (FThread <> nil) and (not FThread.FreeOnTerminate) then
    FreeAndNil(FThread);
  inherited;
end;

function TZMQThread.GetArgs: Pointer;
begin
  Result := FThread.Args;
end;

function TZMQThread.GetContext: IZMQContext;
begin
  Result := FThread.Context;
end;

function TZMQThread.GetFreeOnTerminate: Boolean;
begin
  Result := FThread.FreeOnTerminate;
end;

function TZMQThread.GetHandle: THandle;
begin
  Result := FThread.Handle;
end;

function TZMQThread.GetOnExecute: TZMQThreadExecuteMethod;
begin
  Result := FThread.OnExecute;
end;

function TZMQThread.GetOnTerminate: TNotifyEvent;
begin
  Result := FThread.OnTerminate;
end;

function TZMQThread.GetPipe: PZMQSocket;
begin
  Result := FThread.Pipe.Data;
end;

function TZMQThread.GetSuspended: Boolean;
begin
  Result := FThread.Suspended;
end;

function TZMQThread.GetThreadID: THandle;
begin
  Result := FThread.ThreadID;
end;

procedure TZMQThread.Resume;
begin
{$WARNINGS OFF}
  FThread.Resume;
{$WARNINGS ON}
end;

procedure TZMQThread.SetFreeOnTerminate(const AValue: Boolean);
begin
  FThread.FreeOnTerminate := AValue;
end;

procedure TZMQThread.SetOnExecute(const AValue: TZMQThreadExecuteMethod);
begin
  FThread.OnExecute := AValue;
end;

procedure TZMQThread.SetOnTerminate(const AValue: TNotifyEvent);
begin
  FThread.OnTerminate := AValue;
end;

procedure TZMQThread.SetSuspended(const AValue: Boolean);
begin
  FThread.Suspended := AValue;
end;

procedure TZMQThread.Suspend;
begin
{$WARNINGS OFF}
  FThread.Suspend;
{$WARNINGS ON}
end;

procedure TZMQThread.Terminate;
begin
  FThread.Terminate;
end;

function TZMQThread.WaitFor: LongWord;
begin
  Result := FThread.WaitFor;
end;

{ TZMQInternalThread }

constructor TZMQInternalThread.Create(lArgs: Pointer;
  const ctx: IZMQContext);
begin
  inherited Create(True);
  fArgs := lArgs;
  if ctx = nil then
    fContext := TZMQContext.Create
  else
  begin
    fContext := ctx.Shadow;
    fPipe := Context.Socket(stPair).Implementator;
    fPipe.Bind(Format( 'inproc://zmqthread-pipe-%p', [@fPipe]));
  end;
end;

constructor TZMQInternalThread.CreateAttached(
  lAttachedMeth: TAttachedThreadMethod; const ctx: IZMQContext;
  lArgs: Pointer);
begin
  Create(lArgs, ctx);
  fAttachedMeth := lAttachedMeth;
end;

constructor TZMQInternalThread.CreateAttachedProc(
  lAttachedProc: TAttachedThreadProc; const ctx: IZMQContext;
  lArgs: Pointer);
begin
  Create(lArgs, ctx);
  fAttachedProc := lAttachedProc;
end;

constructor TZMQInternalThread.CreateDetached(
  lDetachedMeth: TDetachedThreadMethod; lArgs: Pointer);
begin
  Create(lArgs, nil);
  fDetachedMeth := lDetachedMeth;
end;

constructor TZMQInternalThread.CreateDetachedProc(
  lDetachedProc: TDetachedThreadProc; lArgs: Pointer);
begin
  Create(lArgs, nil);
  fDetachedProc := lDetachedProc;
end;

destructor TZMQInternalThread.Destroy;
begin
  fContext := nil;
  inherited;
end;

procedure TZMQInternalThread.DoExecute;
begin
  if @fAttachedMeth <> nil then
    fAttachedMeth(fArgs, Context, thrPipe.Data)
  else
  if @fDetachedMeth <> nil then
    fDetachedMeth(fArgs, Context)
  else
  if @fAttachedProc <> nil then
    fAttachedProc(fArgs, Context, thrPipe.Data)
  else
  if @fDetachedProc <> nil then
    fDetachedProc(fArgs, Context);
end;

procedure TZMQInternalThread.Execute;
begin
  if @fOnExecute <> nil then
    fOnExecute(Self)
  else
  if (@fAttachedProc <> nil) or (@fAttachedMeth <> nil)  then
  begin // attached thread
    thrPipe := Context.Socket(stPair).Implementator;
    thrPipe.Connect(Format('inproc://zmqthread-pipe-%p', [@fPipe]));
  end;
  DoExecute;
end;

{ TZMQMananger }

function TZMQMananger.CreateFrame: IZMQFrame;
begin
  Result := TZMQFrame.Create;
end;

function TZMQMananger.CreateFrame(size: Cardinal): IZMQFrame;
begin
  Result := TZMQFrame.Create(size);
end;

function TZMQMananger.CreateContext: IZMQContext;
begin
  Result := TZMQContext.Create;
end;

function TZMQMananger.CreateFrame(data: Pointer; size: Cardinal;
  ffn: TZMQFreeProc; hint: Pointer): IZMQFrame;
begin
  Result := TZMQFrame.Create(data, size, ffn, hint);
end;

function TZMQMananger.CreateMsg: IZMQMsg;
begin
  Result := TZMQMsg.Create;
end;

procedure TZMQMananger.Device(device: TZMQDevice; const insocket,
  outsocket: PZMQSocket);
begin
  if ZAPI.zmq_device(Ord(device), insocket.Socket, outsocket.Socket) <> -1 then
    raise EZMQException.Create( 'Device does not return -1' );
end;

function TZMQMananger.GetTerminated: Boolean;
begin
  Result := FTerminated;
end;

function TZMQMananger.GetVersion: TZMQVersion;
begin
  ZAPI.zmq_version(Result.major, Result.minor, Result.patch);
end;

function TZMQMananger.Poll(var pia: TZMQPollItemArray; timeout: Integer): Integer;
var
  PollItem: array of zmq_pollitem_t;
  i,l,n: Integer;
begin
  l := Length( pia );
  if l = 0 then
    raise EZMQException.Create( 'Nothing to poll!' );
  SetLength( PollItem, l );
  try
    for i := 0 to l - 1 do
    begin
      PollItem[i].socket := pia[i].Socket.Socket;
      PollItem[i].fd := 0;
      PollItem[i].events := ZMQPollEventsToInt( pia[i].events );
      PollItem[i].revents := 0;
    end;
    n := l;
    result := ZAPI.zmq_poll(@PollItem[0], n, timeout);
    if result < 0 then
      raise EZMQException.Create;
    for i := 0 to l - 1 do
      pia[i].revents := IntToZMQPollEvents(PollItem[i].revents);
  finally
    PollItem := nil;
  end;
end;

function TZMQMananger.Poll(var pi: TZMQPollItem; timeout: Integer): Integer;
var
  PollItem: zmq_pollitem_t;
begin
  PollItem.socket  := pi.Socket.Socket;
  PollItem.fd      := 0;
  PollItem.events  := ZMQPollEventsToInt( pi.events );
  PollItem.revents := 0;
  result := ZAPI.zmq_poll(@PollItem, 1, timeout );
  if result < 0 then
    raise EZMQException.Create;
  pi.revents := IntToZMQPollEvents(PollItem.revents);
end;

procedure TZMQMananger.Proxy(const frontend, backend, capture: PZMQSocket);
var
  p: Pointer;
begin
  if capture <> nil then
    p := capture.Socket
  else
    p := nil;
  if ZAPI.zmq_proxy(frontend.Socket, backend.Socket, p) <> -1 then
    raise EZMQException.Create('Proxy does not return -1');
end;

procedure TZMQMananger.SetTerminated(const Value: Boolean);
begin
  FTerminated := Value;
end;

procedure TZMQMananger.Terminate;
begin
  GenerateConsoleCtrlEvent(CTRL_C_EVENT, 0);
end;

function TZMQMananger.CreatePoller(aSync: Boolean;
  const aContext: IZMQContext): IZMQPoller;
begin
  Result := TZMQPoller.Create(aSync, aContext);
end;

function TZMQMananger.CreateAttached(lAttachedMeth: TAttachedThreadMethod;
  const ctx: IZMQContext; lArgs: Pointer): IZMQThread;
begin
  Result := TZMQThread.CreateAttached(lAttachedMeth, ctx, lArgs);  
end;

function TZMQMananger.CreateAttachedProc(
  lAttachedProc: TAttachedThreadProc; const ctx: IZMQContext;
  lArgs: Pointer): IZMQThread;
begin
  Result := TZMQThread.CreateAttachedProc(lAttachedProc, ctx, lArgs);
end;

function TZMQMananger.CreateDetached(lDetachedMeth: TDetachedThreadMethod;
  lArgs: Pointer): IZMQThread;
begin
  Result := TZMQThread.CreateDetached(lDetachedMeth, lArgs);
end;

function TZMQMananger.CreateDetachedProc(
  lDetachedProc: TDetachedThreadProc; lArgs: Pointer): IZMQThread;
begin
  Result := TZMQThread.CreateDetachedProc(lDetachedProc, lArgs);
end;

function TZMQMananger.CreateThread(lArgs: Pointer;
  const ctx: IZMQContext): IZMQThread;
begin
  Result := TZMQThread.Create(lArgs, ctx);
end;

function TZMQMananger.IsZMQException(AExcetpion: Exception): Boolean;
begin
  Result := AExcetpion is EZMQException;
end;

function TZMQMananger.GetDriverFile: WideString;
begin
  Result := varDriverFile;
end;

procedure TZMQMananger.SetDriverFile(const Value: WideString);
begin
  varDriverFile := Value;
end;

procedure TZMQMananger.Sleep(const seconds: Integer);
begin
  ZAPI.zmq_sleep(seconds);
end;

function TZMQMananger.StartStopWatch: Pointer;
begin
  Result := ZAPI.zmq_stopwatch_start;
end;

function TZMQMananger.StopStopWatch(watch: Pointer): LongWord;
begin
  Result := ZAPI.zmq_stopwatch_stop(watch);
end;

procedure TZMQMananger.FreeAndNilSocket(var socket: PZMQSocket);
var
  s: TZMQSocketImpl;
begin
  s := TZMQSocketImpl(socket.Implementator);
  socket := nil;
  s.Free;
end;

function TZMQMananger.GetContext: IZMQContext;
begin
  if FContext = nil then
    FContext := ZMQ.CreateContext;
  Result := FContext;
end;

initialization
  varContexts := TList.Create;
  Windows.SetConsoleCtrlHandler(@Console_handler, True);
  _RegZmqClass;

finalization
  _UnregZmqClass;
  varContexts.Free;

end.
