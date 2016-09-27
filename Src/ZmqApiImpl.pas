unit ZmqApiImpl;

interface

uses
  SysUtils, Classes, Windows, MemLibrary;

const
  libzmq = 'libzmq.dll';

(*  Version macros for compile-time API version detection                     *)
  ZMQ_VERSION_MAJOR = 3;
  ZMQ_VERSION_MINOR = 2;
  ZMQ_VERSION_PATCH = 5;

type
  int32_t  = Integer;
  uint16_t = SmallInt;
  uint8_t  = AnsiChar;
  Puint8_t = PAnsiChar;
  size_t = Cardinal;

(******************************************************************************)
(*  0MQ errors.                                                               *)
(******************************************************************************)
const
(*  A number random enough not to collide with different errno ranges on      *)
(*  different OSes. The assumption is that error_t is at least 32-bit type.   *)
  ZMQ_HAUSNUMERO = 156384712;

(*  On Windows platform some of the standard POSIX errnos are not defined.    *)
  ENOTSUP         = ZMQ_HAUSNUMERO + 1;
  EPROTONOSUPPORT = ZMQ_HAUSNUMERO + 2;
  ENOBUFS         = ZMQ_HAUSNUMERO + 3;
  ENETDOWN        = ZMQ_HAUSNUMERO + 4;
  EADDRINUSE      = ZMQ_HAUSNUMERO + 5;
  EADDRNOTAVAIL   = ZMQ_HAUSNUMERO + 6;
  ECONNREFUSED    = ZMQ_HAUSNUMERO + 7;
  EINPROGRESS     = ZMQ_HAUSNUMERO + 8;
  ENOTSOCK        = ZMQ_HAUSNUMERO + 9;
  EMSGSIZE        = ZMQ_HAUSNUMERO + 10;
  EAFNOSUPPORT    = ZMQ_HAUSNUMERO + 11;
  ENETUNREACH     = ZMQ_HAUSNUMERO + 12;
  ECONNABORTED    = ZMQ_HAUSNUMERO + 13;
  ECONNRESET      = ZMQ_HAUSNUMERO + 14;
  ENOTCONN        = ZMQ_HAUSNUMERO + 15;
  ETIMEDOUT       = ZMQ_HAUSNUMERO + 16;
  EHOSTUNREACH    = ZMQ_HAUSNUMERO + 17;
  ENETRESET       = ZMQ_HAUSNUMERO + 18;

(*  Native 0MQ error codes.                                                   *)
  EFSM            = ZMQ_HAUSNUMERO + 51;
  ENOCOMPATPROTO  = ZMQ_HAUSNUMERO + 52;
  ETERM           = ZMQ_HAUSNUMERO + 53;
  EMTHREAD        = ZMQ_HAUSNUMERO + 54;
  
type
(*  Run-time API version detection                                            *)
  Tzmq_version = procedure(var major, minor, patch: Integer); cdecl;
  
(*  This function retrieves the errno as it is known to 0MQ library. The goal *)
(*  of this function is to make the code 100% portable, including where 0MQ   *)
(*  compiled with certain CRT library (on Windows) is linked to an            *)
(*  application that uses different CRT library.                              *)
  Tzmq_errno = function(): Integer; cdecl;
(*  Resolves system errors and 0MQ errors to human-readable string.           *)
  Tzmq_strerror = function(errnum: Integer): PAnsiChar; cdecl;
  
(******************************************************************************)
(*  0MQ infrastructure (a.k.a. context) initialisation & termination.         *)
(******************************************************************************)
const
(*  New API                                                                   *)
(*  Context options                                                           *)
  ZMQ_IO_THREADS  = 1;
  ZMQ_MAX_SOCKETS = 2;

(*  Default for new contexts                                                  *)
  ZMQ_IO_THREADS_DFLT  = 1;
  ZMQ_MAX_SOCKETS_DFLT = 1024;

type
  Tzmq_ctx_new = function(): Pointer; cdecl;
  Tzmq_ctx_destroy = function (context: Pointer): Integer; cdecl;
  Tzmq_ctx_set = function(context: Pointer; option: Integer; optval: Integer): Integer; cdecl;
  Tzmq_ctx_get = function(context: Pointer; option: Integer): Integer; cdecl;

(*  Old (legacy) API                                                          *)
  Tzmq_init = function(io_threads: Integer): Pointer; cdecl;
  Tzmq_term = function(context: Pointer): Integer; cdecl;

(******************************************************************************)
(*  0MQ message definition.                                                   *)
(******************************************************************************)
  zmq_msg_t = packed record
    _: array[0..31] of AnsiChar;
  end;
  Pzmq_msg_t = ^zmq_msg_t;

  zmq_free_fn = procedure(data, hint: Pointer); cdecl;
  Tzmq_msg_init = function(msg: Pzmq_msg_t): Integer; cdecl;
  Tzmq_msg_init_size = function(msg: Pzmq_msg_t; size: size_t): Integer; cdecl;
  Tzmq_msg_init_data = function(msg: Pzmq_msg_t; data: Pointer; size: size_t;
    ffn: zmq_free_fn; hint: Pointer): Integer; cdecl;
  Tzmq_msg_send = function(msg: Pzmq_msg_t; s: Pointer; flags: Integer): Integer; cdecl;
  Tzmq_msg_recv = function(msg: Pzmq_msg_t; s: Pointer; flags: Integer): Integer; cdecl;
  Tzmq_msg_close = function(msg: Pzmq_msg_t): Integer; cdecl;
  Tzmq_msg_move = function(dest, src: Pzmq_msg_t): Integer; cdecl;
  Tzmq_msg_copy = function(dest, src: Pzmq_msg_t): Integer; cdecl;
  Tzmq_msg_data = function(msg: Pzmq_msg_t): Pointer; cdecl;
  Tzmq_msg_size = function(msg: Pzmq_msg_t): size_t; cdecl;
  Tzmq_msg_more = function(msg: Pzmq_msg_t): Integer; cdecl;
  Tzmq_msg_get = function(msg: Pzmq_msg_t; option: Integer): Integer; cdecl;
  Tzmq_msg_set = function(msg: Pzmq_msg_t; option, optval: Integer): Integer; cdecl;

(******************************************************************************)
(*  0MQ socket definition.                                                    *)
(******************************************************************************)
const
(*  Socket types.                                                             *)
  ZMQ_PAIR = 0;
  ZMQ_PUB = 1;
  ZMQ_SUB = 2;
  ZMQ_REQ = 3;
  ZMQ_REP = 4;
  ZMQ_DEALER = 5;
  ZMQ_ROUTER = 6;
  ZMQ_PULL = 7;
  ZMQ_PUSH = 8;
  ZMQ_XPUB = 9;
  ZMQ_XSUB = 10;

(*  Deprecated aliases                                                        *)
  ZMQ_XREQ = ZMQ_DEALER;
  ZMQ_XREP = ZMQ_ROUTER;

(*  Socket options.                                                           *)
  ZMQ_AFFINITY = 4;
  ZMQ_IDENTITY = 5;
  ZMQ_SUBSCRIBE = 6;
  ZMQ_UNSUBSCRIBE = 7;
  ZMQ_RATE = 8;
  ZMQ_RECOVERY_IVL = 9;
  ZMQ_SNDBUF = 11;
  ZMQ_RCVBUF = 12;
  ZMQ_RCVMORE = 13;
  ZMQ_FD = 14;
  ZMQ_EVENTS = 15;
  ZMQ_TYPE = 16;
  ZMQ_LINGER = 17;
  ZMQ_RECONNECT_IVL = 18;
  ZMQ_BACKLOG = 19;
  ZMQ_RECONNECT_IVL_MAX = 21;
  ZMQ_MAXMSGSIZE = 22;
  ZMQ_SNDHWM = 23;
  ZMQ_RCVHWM = 24;
  ZMQ_MULTICAST_HOPS = 25;
  ZMQ_RCVTIMEO = 27;
  ZMQ_SNDTIMEO = 28;
  ZMQ_IPV4ONLY = 31;
  ZMQ_LAST_ENDPOINT = 32;
  ZMQ_ROUTER_MANDATORY = 33;
  ZMQ_TCP_KEEPALIVE = 34;
  ZMQ_TCP_KEEPALIVE_CNT = 35;
  ZMQ_TCP_KEEPALIVE_IDLE = 36;
  ZMQ_TCP_KEEPALIVE_INTVL = 37;
  ZMQ_TCP_ACCEPT_FILTER = 38;
  ZMQ_DELAY_ATTACH_ON_CONNECT = 39;
  ZMQ_XPUB_VERBOSE = 40;
 
  
  ZMQ_ROUTER_HANDOVER = 56;
  ZMQ_TOS = 57;
  ZMQ_CONNECT_RID = 61;
  ZMQ_GSSAPI_SERVER = 62;
  ZMQ_GSSAPI_PRINCIPAL = 63;
  ZMQ_GSSAPI_SERVICE_PRINCIPAL = 64;
  ZMQ_GSSAPI_PLAINTEXT = 65;
  ZMQ_HANDSHAKE_IVL = 66;
  ZMQ_SOCKS_PROXY = 68;
  ZMQ_XPUB_NODROP = 69;


(*  Message options                                                           *)
  ZMQ_MORE   = 1;

(*  Send/recv options.                                                        *)
  ZMQ_DONTWAIT = 1;
  ZMQ_SNDMORE = 2;

(*  Deprecated options and aliases                                            *)
  ZMQ_NOBLOCK                 = ZMQ_DONTWAIT;
  ZMQ_FAIL_UNROUTABLE         = ZMQ_ROUTER_MANDATORY;
  ZMQ_ROUTER_BEHAVIOR         = ZMQ_ROUTER_MANDATORY;

(******************************************************************************)
(*  0MQ socket events and monitoring                                          *)
(******************************************************************************)

(*  Socket transport events (tcp and ipc only)                                *)
  ZMQ_EVENT_CONNECTED        = $0001;
  ZMQ_EVENT_CONNECT_DELAYED  = $0002;
  ZMQ_EVENT_CONNECT_RETRIED  = $0004;

  ZMQ_EVENT_LISTENING        = $0008;
  ZMQ_EVENT_BIND_FAILED      = $0010;

  ZMQ_EVENT_ACCEPTED         = $0020;
  ZMQ_EVENT_ACCEPT_FAILED    = $0040;

  ZMQ_EVENT_CLOSED           = $0080;
  ZMQ_EVENT_CLOSE_FAILED     = $0100;
  ZMQ_EVENT_DISCONNECTED     = $0200;

  ZMQ_EVENT_ALL              = $FFFF;

type
(*  Socket event data  *)
  zmq_event_t = record
    event: Integer;
    addr: PAnsiChar;
    case Integer of
      0, // connected
      3, // listening
      5, // accepted
      7, // closed
      9: // disconnected
      (
        fd: Integer;
      );
      1, // connect_delayed
      4, // bind_failed
      6, // accept_failed
      8: // close_failed
      (
        err: Integer;
      );
      2: //connect_retried
      (
        interval: Integer;
      );
  end;
  Pzmq_event_t = ^zmq_event_t;
  
  Tzmq_socket = function(context: Pointer; type_: Integer): Pointer; cdecl;
  Tzmq_close = function(s: Pointer): Integer; cdecl;
  Tzmq_setsockopt = function(s: Pointer; option: Integer; const optval: Pointer; optvallen: size_t): Integer; cdecl;
  Tzmq_getsockopt = function(s: Pointer; option: Integer; optval: Pointer; var optvallen: size_t): Integer; cdecl;
  Tzmq_bind = function(s: Pointer; const addr: PAnsiChar): Integer; cdecl;
  Tzmq_connect = function(s: Pointer; const addr: PAnsiChar): Integer; cdecl;
  Tzmq_unbind = function(s: Pointer; const addr: PAnsiChar): Integer; cdecl;
  Tzmq_disconnect = function(s: Pointer; const addr: PAnsiChar): Integer; cdecl;
  Tzmq_send = function(s: Pointer; const buf; len: size_t; flags: Integer): Integer; cdecl;
  Tzmq_recv = function(s: Pointer; var buffer; len: size_t; flags: Integer): Integer; cdecl;
  Tzmq_socket_monitor = function(s: Pointer; const addr: PAnsiChar; events: Integer): Integer; cdecl;

  Tzmq_sendmsg = function(s: Pointer; msg: Pzmq_msg_t; flags: Integer): Integer; cdecl;
  Tzmq_recvmsg = function(s: Pointer; msg: Pzmq_msg_t; flags: Integer): Integer; cdecl;
  
(*  Experimental                                                              *)
  iovec = record end;
  Piovec = ^iovec;
  
  Tzmq_sendiov = function(s: Pointer; iov: Piovec; count: size_t; flags: Integer): Integer; cdecl;
  Tzmq_recviov = function(s: Pointer; iov: Piovec; var count: size_t; flags: Integer): Integer; cdecl;

(******************************************************************************)
(*  I/O multiplexing.                                                         *)
(******************************************************************************)
const
  ZMQ_POLLIN  = 1;
  ZMQ_POLLOUT = 2;
  ZMQ_POLLERR = 4;
  
type
  zmq_pollitem_t = record
    socket: Pointer;
    fd: Integer; // TSocket???
    events: Word;
    revents: Word;
  end;
  Pzmq_pollitem_t = ^zmq_pollitem_t;
  
  Tzmq_poll = function(items: Pzmq_pollitem_t; nitems: Integer; timeout: Longint): Integer; cdecl;

(******************************************************************************)
(*  Message proxying                                                          *)
(******************************************************************************)
  Tzmq_proxy = function(frontend, backend, capture: Pointer): Integer; cdecl;

const
(*  Deprecated aliases *)
  ZMQ_STREAMER = 1;
  ZMQ_FORWARDER = 2;
  ZMQ_QUEUE = 3;

type
(*  Deprecated method *)
  Tzmq_device = function(type_: Integer; frontend, backend: Pointer): Integer; cdecl;

{*  Helper functions are used by perf tests so that they don't have to care   *}
{*  about minutiae of time-related functions on different OS platforms.       *}

{*  Starts the stopwatch. Returns the handle to the watch.                    *}
  Tzmq_stopwatch_start = function : Pointer; cdecl;

{*  Stops the stopwatch. Returns the number of microseconds elapsed since     *}
{*  the stopwatch was started.                                                *}
  Tzmq_stopwatch_stop = function ( watch: Pointer ): LongWord; cdecl;

{*  Sleeps for specified number of seconds.                                   *}
  Tzmq_sleep = procedure ( seconds: Integer ); cdecl; 


  TZMQAPI  = class
  private
    FDLLMemory: TResourceStream;
    FDLLHandle: THandle;
    FLastError: string;
    FDriverFile: string;
  protected
    function GetLoaded: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function LoadDLL(const ADriverFile: string): Boolean;
    procedure UnloadDLL;

    property LastError: string read FLastError;
    property Loaded: Boolean read GetLoaded;
    property DLLHandle: THandle read FDLLHandle;
  public
    zmq_version: Tzmq_version;
    zmq_errno: Tzmq_errno;
    zmq_strerror: Tzmq_strerror;
    zmq_ctx_new: Tzmq_ctx_new;
    zmq_ctx_set: Tzmq_ctx_set;
    zmq_ctx_get: Tzmq_ctx_get;
    zmq_init: Tzmq_init;
    zmq_term: Tzmq_term;
    zmq_ctx_destroy: Tzmq_ctx_destroy;
    zmq_msg_init: Tzmq_msg_init;
    zmq_msg_init_size: Tzmq_msg_init_size;
    zmq_msg_init_data: Tzmq_msg_init_data;
    zmq_msg_send: Tzmq_msg_send;
    zmq_msg_recv: Tzmq_msg_recv;
    zmq_msg_close: Tzmq_msg_close;
    zmq_msg_move: Tzmq_msg_move;
    zmq_msg_copy: Tzmq_msg_copy;
    zmq_msg_data: Tzmq_msg_data;
    zmq_msg_size: Tzmq_msg_size;
    zmq_msg_more: Tzmq_msg_more;
    zmq_msg_get: Tzmq_msg_get;
    zmq_msg_set: Tzmq_msg_set;
    zmq_socket: Tzmq_socket;
    zmq_close: Tzmq_close;
    zmq_setsockopt: Tzmq_setsockopt;
    zmq_getsockopt: Tzmq_getsockopt;
    zmq_bind: Tzmq_bind;
    zmq_connect: Tzmq_connect;
    zmq_unbind: Tzmq_unbind;
    zmq_disconnect: Tzmq_disconnect;
    zmq_send: Tzmq_send;
    zmq_recv: Tzmq_recv;
    zmq_socket_monitor: Tzmq_socket_monitor;
    zmq_sendmsg: Tzmq_sendmsg;
    zmq_recvmsg: Tzmq_recvmsg;
    zmq_sendiov: Tzmq_sendiov;
    zmq_recviov: Tzmq_recviov;
    zmq_poll: Tzmq_poll;
    zmq_proxy: Tzmq_proxy;
    zmq_device: Tzmq_device;
    zmq_stopwatch_start: Tzmq_stopwatch_start;
    zmq_stopwatch_stop: Tzmq_stopwatch_stop;
    zmq_sleep: Tzmq_sleep;
  end;

var
  varDriverFile: string = ':memory:';

function ZAPI: TZMQAPI;

procedure Trace(const ALog: string);
procedure TraceError(const ALog: string);
procedure TraceException(const ALog: string);


implementation


var
  varZAPI: TZMQAPI;

function ZAPI: TZMQAPI;
begin
  if varZAPI = nil then
  begin
    varZAPI := TZMQAPI.Create;
    Assert(varZAPI.LoadDLL(varDriverFile));
  end;
  Result := varZAPI;
end;

var
  varLock: TRTLCriticalSection;
procedure Trace(const ALog: string);
var
  f: textfile;
  sLogFile: string;
begin
  EnterCriticalSection(varLock);
  try
    if {$WARNINGS OFF} DebugHook = 1 {$WARNINGS ON} then
      OutputDebugString(PChar(ALog))
    else
    try                    
      sLogFile := ChangeFileExt(ParamStr(0), '_' + DateToStr(Now) + '.log');
      ForceDirectories(ExtractFilePath(sLogFile));
      AssignFile(f, sLogFile);
      try
        if FileExists(sLogFile) then
          Append(f)
        else
          Rewrite(f);
        Writeln(f, Format('【%s】%s', [DateTimeToStr(Now), ALog]));
      finally
        CloseFile(f);
      end;
    except
      on e: Exception do
      begin
        OutputDebugString(PChar('[_NativeTrace]'+e.Message));
      end;
    end;
  finally
    LeaveCriticalSection(varLock);
  end;
end;

procedure TraceError(const ALog: string);
begin
  Trace('[error]'+ALog);
end;

procedure TraceException(const ALog: string);
begin
  Trace('[exception]'+ALog);
end;
        
{ TZMQAPI }

constructor TZMQAPI.Create;
begin
  if varDriverFile = EmptyStr then
    varDriverFile := ':memory:';
end;

destructor TZMQAPI.Destroy;
begin
  UnloadDLL;
  if FDLLMemory <> nil  then
    FreeAndNil(FDLLMemory);
  inherited;
end;

function TZMQAPI.GetLoaded: Boolean;
begin
  Result := FDLLHandle > 0;
end;

function TZMQAPI.LoadDLL(const ADriverFile: string): Boolean;
var
  sDriverFile: string;
  LGetProcAddress: function (hModule: HMODULE; lpProcName: PChar): FARPROC; stdcall;
begin
  Result := False;
  try
    if FDLLHandle > 0 then
    begin
      Result := True;
      Exit;
    end;
    if ADriverFile = EmptyStr then
      sDriverFile := varDriverFile
    else
      sDriverFile := ADriverFile;
    UnloadDLL;

    if SameText(sDriverFile, ':memory:')  then
    begin
      if FDLLMemory = nil then
        FDLLMemory := TResourceStream.Create(HInstance, 'libzmq', PChar('dll'));

      FDLLHandle := memLoadLibrary(FDLLMemory.Memory, FDLLMemory.Size);
      if FDLLHandle < 32 then
      begin
        FLastError := Format('加载[%s]失败！', [sDriverFile]);
        TraceError(FLastError);
        Exit;
      end;
      LGetProcAddress := memGetProcAddress;
    end
    else
    begin
      if not FileExists(sDriverFile) then
      begin
        FLastError := Format('[%s]组件不存在！', [sDriverFile]);
        TraceError(FLastError);
        Exit;    
      end;
      FDLLHandle := LoadLibrary(PChar(sDriverFile));
      if FDLLHandle < 32 then
      begin
        FLastError := Format('加载[%s]失败！', [sDriverFile]);
        TraceError(FLastError);
        Exit;
      end;
      LGetProcAddress := GetProcAddress;
    end;
    FDriverFile := ADriverFile;

    @zmq_version := LGetProcAddress(FDLLHandle, 'zmq_version');
    @zmq_errno := LGetProcAddress(FDLLHandle, 'zmq_errno');
    @zmq_strerror := LGetProcAddress(FDLLHandle, 'zmq_strerror');
    @zmq_ctx_new := LGetProcAddress(FDLLHandle, 'zmq_ctx_new');
    @zmq_ctx_set := LGetProcAddress(FDLLHandle, 'zmq_ctx_set');
    @zmq_ctx_get := LGetProcAddress(FDLLHandle, 'zmq_ctx_get');
    @zmq_init := LGetProcAddress(FDLLHandle, 'zmq_init');
    @zmq_term := LGetProcAddress(FDLLHandle, 'zmq_term');
    @zmq_ctx_destroy := LGetProcAddress(FDLLHandle, 'zmq_ctx_destroy');
    @zmq_msg_init := LGetProcAddress(FDLLHandle, 'zmq_msg_init');
    @zmq_msg_init_size := LGetProcAddress(FDLLHandle, 'zmq_msg_init_size');
    @zmq_msg_init_data := LGetProcAddress(FDLLHandle, 'zmq_msg_init_data');
    @zmq_msg_send := LGetProcAddress(FDLLHandle, 'zmq_msg_send');
    @zmq_msg_recv := LGetProcAddress(FDLLHandle, 'zmq_msg_recv');
    @zmq_msg_close := LGetProcAddress(FDLLHandle, 'zmq_msg_close');
    @zmq_msg_move := LGetProcAddress(FDLLHandle, 'zmq_msg_move');
    @zmq_msg_copy := LGetProcAddress(FDLLHandle, 'zmq_msg_copy');
    @zmq_msg_data := LGetProcAddress(FDLLHandle, 'zmq_msg_data');
    @zmq_msg_size := LGetProcAddress(FDLLHandle, 'zmq_msg_size');
    @zmq_msg_more := LGetProcAddress(FDLLHandle, 'zmq_msg_more');
    @zmq_msg_get := LGetProcAddress(FDLLHandle, 'zmq_msg_get');
    @zmq_msg_set := LGetProcAddress(FDLLHandle, 'zmq_msg_set');
    @zmq_socket := LGetProcAddress(FDLLHandle, 'zmq_socket');
    @zmq_close := LGetProcAddress(FDLLHandle, 'zmq_close');
    @zmq_setsockopt := LGetProcAddress(FDLLHandle, 'zmq_setsockopt');
    @zmq_getsockopt := LGetProcAddress(FDLLHandle, 'zmq_getsockopt');
    @zmq_bind := LGetProcAddress(FDLLHandle, 'zmq_bind');
    @zmq_connect := LGetProcAddress(FDLLHandle, 'zmq_connect');
    @zmq_unbind := LGetProcAddress(FDLLHandle, 'zmq_unbind');
    @zmq_disconnect := LGetProcAddress(FDLLHandle, 'zmq_disconnect');
    @zmq_send := LGetProcAddress(FDLLHandle, 'zmq_send');
    @zmq_recv := LGetProcAddress(FDLLHandle, 'zmq_recv');
    @zmq_socket_monitor := LGetProcAddress(FDLLHandle, 'zmq_socket_monitor');
    @zmq_sendmsg := LGetProcAddress(FDLLHandle, 'zmq_sendmsg');
    @zmq_recvmsg := LGetProcAddress(FDLLHandle, 'zmq_recvmsg');
    @zmq_sendiov := LGetProcAddress(FDLLHandle, 'zmq_sendiov');
    @zmq_recviov := LGetProcAddress(FDLLHandle, 'zmq_recviov');
    @zmq_poll := LGetProcAddress(FDLLHandle, 'zmq_poll');
    @zmq_proxy := LGetProcAddress(FDLLHandle, 'zmq_proxy');
    @zmq_device := LGetProcAddress(FDLLHandle, 'zmq_device');
    @zmq_stopwatch_start := LGetProcAddress(FDLLHandle, 'zmq_stopwatch_start');
    @zmq_stopwatch_stop := LGetProcAddress(FDLLHandle, 'zmq_stopwatch_stop');
    @zmq_sleep := LGetProcAddress(FDLLHandle, 'zmq_sleep');
      
    Result := True;
  except
    on E: Exception do
    begin
      TraceException('[TWkeAPI.LoadDLL]'+E.Message);
    end
  end;
end;

procedure TZMQAPI.UnloadDLL;
begin
  if not GetLoaded then
    Exit;
  @zmq_version := nil;
  @zmq_errno := nil;
  @zmq_strerror := nil;
  @zmq_ctx_new := nil;
  @zmq_ctx_set := nil;
  @zmq_ctx_get := nil;
  @zmq_init := nil;
  @zmq_term := nil;
  @zmq_ctx_destroy := nil;
  @zmq_msg_init := nil;
  @zmq_msg_init_size := nil;
  @zmq_msg_init_data := nil;
  @zmq_msg_send := nil;
  @zmq_msg_recv := nil;
  @zmq_msg_close := nil;
  @zmq_msg_move := nil;
  @zmq_msg_copy := nil;
  @zmq_msg_data := nil;
  @zmq_msg_size := nil;
  @zmq_msg_more := nil;
  @zmq_msg_get := nil;
  @zmq_msg_set := nil;
  @zmq_socket := nil;
  @zmq_close := nil;
  @zmq_setsockopt := nil;
  @zmq_getsockopt := nil;
  @zmq_bind := nil;
  @zmq_connect := nil;
  @zmq_unbind := nil;
  @zmq_disconnect := nil;
  @zmq_send := nil;
  @zmq_recv := nil;
  @zmq_socket_monitor := nil;
  @zmq_sendmsg := nil;
  @zmq_recvmsg := nil;
  @zmq_sendiov := nil;
  @zmq_recviov := nil;
  @zmq_poll := nil;
  @zmq_proxy := nil;
  @zmq_device := nil;
  @zmq_stopwatch_start := nil;
  @zmq_stopwatch_stop := nil;
  @zmq_sleep := nil;

  if FDLLHandle > 0 then
  try
    if SameText(FDriverFile, ':memory:')  then
    begin
      memFreeLibrary(FDLLHandle);
    end
    else
      FreeLibrary(FDLLHandle);
  except
    on E: Exception do
      TraceError('[TZMQAPI.UnloadDLL]'+E.Message);
  end;
  FDLLHandle := 0;
end;

initialization
  InitializeCriticalSection(varLock);

finalization
  if varZAPI <> nil then
    FreeAndNil(varZAPI);
  DeleteCriticalSection(varLock);
  
end.
