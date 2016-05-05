Unit Classes;

{
   LVCL - Very LIGHT VCL routines
   ------------------------------

   Tiny replacement for the standard VCL Classes.pas
   Just put the LVCL directory in your Project/Options/Directories/SearchPath
   and your .EXE will shrink from 300KB to 30KB

   Notes:
   - implements TComponent+TFileStream+TList+TMemoryStream+TPersistent+TReader
       +TResourceStream+TStream+TStringList
   - compatible with the standard .DFM files
   - only use existing properties in your DFM, otherwise you'll get error on startup
   - TList and TStringList are simplier than standard ones
   - TStrings is not implemented (but mapped to TStringList)
   - TMemoryStream use faster Delphi heap manager, not the slow GlobalAlloc()
   - TThread/TEvent simple implementation (on Windows only)
   - Cross-Platform: it can be used on (Cross)Kylix under Linux (tested)

  The contents of this file are subject to the Mozilla Public License
  Version 1.1 (the "License"); you may not use this file except in
  compliance with the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS"
  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
  License for the specific language governing rights and limitations
  under the License.

  The Initial Developer of the Original Code is Arnaud Bouchez.
  This work is Copyright (c)2008 Arnaud Bouchez - http://bouchez.info
  Emulates the original Delphi/Kylix Cross-Platform Runtime Library
  (c)2000,2001 Borland Software Corporation
  Portions created by Paul Toth are (c)2001 Paul Toth - http://tothpaul.free.fr
  All Rights Reserved.

  Contributors:
  - Vadim (pult)

  Some modifications by Leonid Glazyrin, Feb 2012 <leonid.glazyrin@gmail.com>

  * New types of DFM properties supported: List and Set
  * Some (or maybe all) unsupported (sub)properties in DFM ignored without errors

}

{.$define debug} // send error messages from TReader in a Console window
{$ifdef debug} {$APPTYPE CONSOLE} {$endif}

{$IF CompilerVersion >= 24.00}
  {$ZEROBASEDSTRINGS OFF}
{$IFEND}

{$R-,T-,X+,H+,B-}

{$WARNINGS OFF}

Interface

uses
  SysUtils,
{$ifdef MSWINDOWS}
  Windows;
{$else}
  Types,
  LibC;
{$endif}

const
  MaxListSize = Maxint div 16;

type
  EClassesError = class(Exception);
  EListError = class(Exception);
  EResNotFound = class(Exception);
  EStringListError = class(Exception);
  EStreamError = class(Exception);

  TNotifyEvent = procedure(Sender:TObject) of object;

  PPointerList = ^TPointerList;
  TPointerList = array[0..MaxListSize - 1] of Pointer;
  TListSortCompare = function (Item1, Item2: Pointer): Integer;
  TListNotification = (lnAdded, lnExtracted, lnDeleted);
  TListAssignOp = (laCopy, laAnd, laOr, laXor, laSrcUnique, laDestUnique);

  TList = class(TObject)
  private
    FList: PPointerList;
    FCount: Integer;
    FCapacity: Integer;
  protected
    function Get(Index: Integer): Pointer;
    procedure Grow; virtual;
    procedure Put(Index: Integer; Item: Pointer);
    procedure Notify(Ptr: Pointer; Action: TListNotification); virtual;
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);
    class procedure Error(const Msg: string; Data: Integer); overload; virtual;
    class procedure Error(Msg: PResStringRec; Data: Integer); overload;
  public
    destructor Destroy; override;
    function Add(Item: Pointer): Integer;
    procedure Clear; virtual;
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function Expand: TList;
    function Extract(Item: Pointer): Pointer;
    function First: Pointer;
    function IndexOf(Item: Pointer): Integer;
    procedure Insert(Index: Integer; Item: Pointer);
    function Last: Pointer;
    procedure Move(CurIndex, NewIndex: Integer);
    function Remove(Item: Pointer): Integer;
    procedure Pack;
    procedure Sort(Compare: TListSortCompare);
    procedure Assign(ListA: TList; AOperator: TListAssignOp = laCopy; ListB: TList = nil);
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Pointer read Get write Put; default;
    property List: PPointerList read FList;
  end;

{ TThreadList class }

  TThreadList = class
  private
    FList: TList;
    FLock: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Item: Pointer);
    procedure Clear;
    function  LockList: TList;
    procedure Remove(Item: Pointer);
    procedure UnlockList;
  end;

{ IInterfaceList interface }

  IInterfaceList = interface
  ['{285DEA8A-B865-11D1-AAA7-00C04FB17A72}']
    function Get(Index: Integer): IInterface;
    function GetCapacity: Integer;
    function GetCount: Integer;
    procedure Put(Index: Integer; const Item: IInterface);
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);

    procedure Clear;
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function First: IInterface;
    function IndexOf(const Item: IInterface): Integer;
    function Add(const Item: IInterface): Integer;
    procedure Insert(Index: Integer; const Item: IInterface);
    function Last: IInterface;
    function Remove(const Item: IInterface): Integer;
    procedure Lock;
    procedure Unlock;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: IInterface read Get write Put; default;
  end;

{ TInterfaceList class }

  TInterfaceList = class(TInterfacedObject, IInterfaceList)
  private
    FList: TThreadList;
  protected
    { IInterfaceList }
    function Get(Index: Integer): IInterface;
    function GetCapacity: Integer;
    function GetCount: Integer;
    procedure Put(Index: Integer; const Item: IInterface);
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    function Expand: TInterfaceList;
    function First: IInterface;
    function IndexOf(const Item: IInterface): Integer;
    function Add(const Item: IInterface): Integer;
    procedure Insert(Index: Integer; const Item: IInterface);
    function Last: IInterface;
    function Remove(const Item: IInterface): Integer;
    procedure Lock;
    procedure Unlock;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: IInterface read Get write Put; default;
  end;

  TStringList = class;
  TStringListSortCompare = function(List: TStringList; Index1, Index2: Integer): Integer;

  TStringList = class
  private
    fListStr: array of string;
    // fListObj[] is allocated only if objects are used (not nil)
    fListObj: array of TObject;
    fCount: integer;
    fSize : integer;
    fCaseSensitive: boolean;
    FDelimiter: Char;
    FSorted: Boolean;
    function GetItem(index: integer): string;
    procedure SetItem(index: integer; const value: string);
    function GetObject(index: integer): TObject;
    procedure SetObject(index: integer; value: TObject);
    function GetText: string;
    procedure SetText(const Value: string);
    function GetDelimitedText: string;
    procedure SetDelimitedText(const Value: string);
    procedure SetSorted(Value: Boolean);
  protected
    procedure QuickSort(L, R: Integer; SCompare: TStringListSortCompare);
    function CompareStrings(const S1, S2: string): Integer; virtual;
  public
    constructor Create;
    function Add(const s: string): integer;
    function AddObject(const s: string; AObject: TObject): integer;
    procedure AddStrings(Strings: TStringList);
    procedure Delete(index: integer);
    function IndexOf(const s: string): integer;
    function IndexOfObject(item: pointer): integer;
    function IndexOfName(const Name: string; const Separator: string='='): integer;
    function ValueOf(const Name: string; const Separator: string='='): string;
    function NameOf(const Value: string; const Separator: string='='): string;
    procedure Clear;
    function TextLen: integer;
    procedure LoadFromFile(const FileName: string);
    procedure SaveToFile(const FileName: string);
    procedure CustomSort(Compare: TStringListSortCompare);
    procedure Sort; virtual;
    property Count: integer read fCount;
    property Delimiter: Char read FDelimiter write FDelimiter;
    property DelimitedText: string read GetDelimitedText write SetDelimitedText;
    property Sorted: Boolean read FSorted write SetSorted;
    property CaseSensitive: boolean read fCaseSensitive write fCaseSensitive;
    property Strings[index: integer]: string read GetItem write SetItem; default;
    property Objects[index: integer]: TObject read GetObject write SetObject;
    property Text: string read GetText write SetText;
  end;

  TStrings = TStringList; // for easy debugging

  TSeekOrigin = (soBeginning, soCurrent, soEnd);

const
  fmCreate = $FFFF;

  // used in TStream.Seek()
  soFromBeginning = 0;
  soFromCurrent = 1;
  soFromEnd = 2;

type
  TStream = class
  protected
    procedure SetPosition(value: integer); virtual;
    function GetPosition: integer; virtual;
    function GetSize: integer; virtual;
    procedure SetSize(Value: integer); virtual;
  public
    function Read(var Buffer; Count: integer): integer; virtual; abstract;
    procedure ReadBuffer(var Buffer; Count: integer);
    function Write(const Buffer; Count: integer): integer; virtual; abstract;
    function Seek(Offset: Longint; Origin: Word): Longint; overload; virtual;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; virtual;
    procedure Clear;
    procedure LoadFromStream(aStream: TStream); virtual;
    procedure SaveToStream(aStream: TStream); virtual;
    procedure LoadFromFile(const FileName: string);
    procedure SaveToFile(const FileName: string);
    function CopyFrom(Source: TStream; Count: integer): integer;
    property Size: integer read GetSize write SetSize;
    property Position: integer read GetPosition write SetPosition;
  end;

  THandleStream = class(TStream)
  private
    fHandle: THandle;
  protected
    procedure SetSize(Value: integer); override;
  public
    constructor Create(aHandle: THandle);
    function Read(var Buffer; count: integer): integer; override;
    function Write(const Buffer; Count: integer): integer; override;
    function Seek(Offset: integer; Origin: Word): integer; override;
    property Handle: THandle read fHandle;
  end;

  TFileStream = class(THandleStream)
  private
    fFileName: string;
  protected
{$ifdef Linux} // this special function use stat() instead of seek()
    function GetSize: cardinal; override; {$endif}
  public
    constructor Create(const FileName: string; Mode: Word);
    destructor Destroy; override;
  end;

  TCustomMemoryStream = class(TStream)
  protected
    fPosition, fSize: integer;
    fMemory: pointer;
    procedure SetPosition(value: integer); override;
    function GetPosition: integer; override;
    function GetSize: integer; override;
    procedure SetSize(Value: integer); override;
  public
    function Read(var Buffer; count: integer): integer; override;
    procedure SetPointer(Buffer: pointer; Count: integer);
    function Seek(Offset: integer; Origin: Word): integer; override;
    procedure SaveToStream(aStream: TStream); override;
    property Memory: pointer read fMemory;
  end;

  TResourceStream = class(TCustomMemoryStream)
  private
    HResInfo: THandle;
    HGlobal: THandle;
    procedure Initialize(Instance: THandle; Name, ResType: PChar; FromID: Boolean);
  public
    constructor Create(Instance: THandle; const ResName: string; ResType: PChar);
    constructor CreateFromID(Instance: THandle; ResID: Integer; ResType: PChar);
    destructor Destroy; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

  TStreamOwnership = (soReference, soOwned);

  TMemoryStream = class(TCustomMemoryStream)
  protected
    fCapacity: integer;
    procedure SetSize(Value: integer); override;
    procedure SetCapacity(Value: integer);
  public
    destructor Destroy; override;
    function Write(const Buffer; Count: integer): integer; override;
    procedure LoadFromStream(aStream: TStream); override;
  end;

{$ifdef MSWINDOWS}
  TFilerFlag = (ffInherited, ffChildPos, ffInline);
  TFilerFlags = set of TFilerFlag;

  PValueType = ^TValueType;
  TValueType = (vaNull, vaList, vaInt8, vaInt16, vaInt32, vaExtended,
    vaString, vaIdent, vaFalse, vaTrue, vaBinary, vaSet, vaLString,
    vaNil, vaCollection, vaSingle, vaCurrency, vaDate, vaWString, vaInt64,
    vaUTF8String);

  TOperation = (opInsert, opRemove);

  TThread = class;

  TThreadMethod = procedure of object;
  
  /// minimal Threading implementation, using direct Windows API
  TThread = class
  private
    FHandle: THandle;
    FThreadID: cardinal;
    FFinished,
    FTerminated,
    FSuspended,
    FCreateSuspended,
    FFreeOnTerminate: Boolean;
    procedure SetSuspended(Value: Boolean);
  protected
    FOnTerminate: TNotifyEvent;
    procedure Execute; virtual; abstract;
  public
    constructor Create(CreateSuspended: Boolean);
    procedure AfterConstruction; override;
    destructor Destroy; override;
    procedure Resume;
    procedure Suspend;
    function WaitFor: LongWord;
    procedure Terminate;
    property Handle: THandle read FHandle;
    property ThreadID: cardinal read FThreadID;
    property Suspended: Boolean read FSuspended write SetSuspended;
    property Terminated: Boolean read FTerminated;
    property FreeOnTerminate: Boolean read FFreeOnTerminate write FFreeOnTerminate;
    property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
  end;

  TWaitResult = (wrSignaled, wrTimeout, wrAbandoned, wrError);

  TEvent = class
  protected
    FHandle: THandle;
  public
    constructor Create(EventAttributes: PSecurityAttributes; ManualReset,
      InitialState: Boolean; const Name: string);
    function WaitFor(Timeout: LongWord): TWaitResult;
    procedure SetEvent;
    procedure ResetEvent;
    destructor Destroy; override;
    property Handle: THandle read FHandle;
  end;

{$endif}

// if the beginning of p^ is same as up^ (ignore case - up^ must be already Upper)
// (only exists in LVCL)
function IdemPChar(p, up: PChar): boolean;


implementation

resourcestring
  SListIndexError = 'List index out of bounds (%d)';
  SDuplicateString = 'String list does not allow duplicates';
  SSortedListError = 'Operation not allowed on sorted list';
  SResNotFound = 'Resource %s not found';
  SCantWriteResourceStreamError = 'Can''t write to a read-only resource stream';

{ TList }

destructor TList.Destroy;
begin
  Clear;
end;

function TList.Add(Item: Pointer): Integer;
begin
  Result := FCount;
  if Result = FCapacity then
    Grow;
  FList^[Result] := Item;
  Inc(FCount);
  if Item <> nil then
    Notify(Item, lnAdded);
end;

procedure TList.Clear;
begin
  SetCount(0);
  SetCapacity(0);
end;

procedure TList.Delete(Index: Integer);
var
  Temp: Pointer;
begin
  if (Index < 0) or (Index >= FCount) then
    Exit;
  Temp := Items[Index];
  Dec(FCount);
  if Index < FCount then
    System.Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(Pointer));
  if Temp <> nil then
    Notify(Temp, lnDeleted);
end;

procedure TList.Exchange(Index1, Index2: Integer);
var
  Item: Pointer;
begin
  if (Index1 < 0) or (Index1 >= FCount) then
    Exit;
  if (Index2 < 0) or (Index2 >= FCount) then
    Exit;
  Item := FList^[Index1];
  FList^[Index1] := FList^[Index2];
  FList^[Index2] := Item;
end;

function TList.Expand: TList;
begin
  if FCount = FCapacity then
    Grow;
  Result := Self;
end;

function TList.First: Pointer;
begin
  Result := Get(0);
end;

function TList.Get(Index: Integer): Pointer;
begin
  Result := nil;
  if (Index < 0) or (Index >= FCount) then
    Exit;
  Result := FList^[Index];
end;

procedure TList.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then
    Delta := FCapacity div 4
  else
    if FCapacity > 8 then
      Delta := 16
    else
      Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

function TList.IndexOf(Item: Pointer): Integer;
begin
  Result := 0;
  while (Result < FCount) and (FList^[Result] <> Item) do
    Inc(Result);
  if Result = FCount then
    Result := -1;
end;

procedure TList.Insert(Index: Integer; Item: Pointer);
begin
  if (Index < 0) or (Index > FCount) then
    Exit;
  if FCount = FCapacity then
    Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(Pointer));
  FList^[Index] := Item;
  Inc(FCount);
  if Item <> nil then
    Notify(Item, lnAdded);
end;

function TList.Last: Pointer;
begin
  Result := Get(FCount - 1);
end;

procedure TList.Move(CurIndex, NewIndex: Integer);
var
  Item: Pointer;
begin
  if CurIndex <> NewIndex then
  begin
    if (NewIndex < 0) or (NewIndex >= FCount) then
      Exit;
    Item := Get(CurIndex);
    FList^[CurIndex] := nil;
    Delete(CurIndex);
    Insert(NewIndex, nil);
    FList^[NewIndex] := Item;
  end;
end;

procedure TList.Put(Index: Integer; Item: Pointer);
var
  Temp: Pointer;
begin
  if (Index < 0) or (Index >= FCount) then
    Exit;
  if Item <> FList^[Index] then
  begin
    Temp := FList^[Index];
    FList^[Index] := Item;
    if Temp <> nil then
      Notify(Temp, lnDeleted);
    if Item <> nil then
      Notify(Item, lnAdded);
  end;
end;

function TList.Remove(Item: Pointer): Integer;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

procedure TList.Pack;
var
  I: Integer;
begin
  for I := FCount - 1 downto 0 do
    if Items[I] = nil then
      Delete(I);
end;

procedure TList.SetCapacity(NewCapacity: Integer);
begin
  if (NewCapacity < FCount) or (NewCapacity > MaxListSize) then
    Exit;
  if NewCapacity <> FCapacity then
  begin
    ReallocMem(FList, NewCapacity * SizeOf(Pointer));
    FCapacity := NewCapacity;
  end;
end;

procedure TList.SetCount(NewCount: Integer);
var
  I: Integer;
begin
  if (NewCount < 0) or (NewCount > MaxListSize) then
    Exit;
  if NewCount > FCapacity then
    SetCapacity(NewCount);
  if NewCount > FCount then
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(Pointer), 0)
  else
    for I := FCount - 1 downto NewCount do
      Delete(I);
  FCount := NewCount;
end;

procedure QuickSort(SortList: PPointerList; L, R: Integer;
  SCompare: TListSortCompare);
var
  I, J: Integer;
  P, T: Pointer;
begin
  repeat
    I := L;
    J := R;
    P := SortList^[(L + R) shr 1];
    repeat
      while SCompare(SortList^[I], P) < 0 do
        Inc(I);
      while SCompare(SortList^[J], P) > 0 do
        Dec(J);
      if I <= J then
      begin
        T := SortList^[I];
        SortList^[I] := SortList^[J];
        SortList^[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then
      QuickSort(SortList, L, J, SCompare);
    L := I;
  until I >= R;
end;

procedure TList.Sort(Compare: TListSortCompare);
begin
  if (FList <> nil) and (Count > 0) then
    QuickSort(FList, 0, Count - 1, Compare);
end;

function TList.Extract(Item: Pointer): Pointer;
var
  I: Integer;
begin
  Result := nil;
  I := IndexOf(Item);
  if I >= 0 then
  begin
    Result := Item;
    FList^[I] := nil;
    Delete(I);
    Notify(Result, lnExtracted);
  end;
end;

procedure TList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  //nothing
end;

procedure TList.Assign(ListA: TList; AOperator: TListAssignOp; ListB: TList);
var
  I: Integer;
  LTemp, LSource: TList;
begin
  if ListB <> nil then
  begin
    LSource := ListB;
    Assign(ListA);
  end
  else
    LSource := ListA;

  case AOperator of

    laCopy:
      begin
        Clear;
        Capacity := LSource.Capacity;
        for I := 0 to LSource.Count - 1 do
          Add(LSource[I]);
      end;

    laAnd:
      for I := Count - 1 downto 0 do
        if LSource.IndexOf(Items[I]) = -1 then
          Delete(I);

    laOr:
      for I := 0 to LSource.Count - 1 do
        if IndexOf(LSource[I]) = -1 then
          Add(LSource[I]);

    laXor:
      begin
        LTemp := TList.Create;
        try
          LTemp.Capacity := LSource.Count;
          for I := 0 to LSource.Count - 1 do
            if IndexOf(LSource[I]) = -1 then
              LTemp.Add(LSource[I]);
          for I := Count - 1 downto 0 do
            if LSource.IndexOf(Items[I]) <> -1 then
              Delete(I);
          I := Count + LTemp.Count;
          if Capacity < I then
            Capacity := I;
          for I := 0 to LTemp.Count - 1 do
            Add(LTemp[I]);
        finally
          LTemp.Free;
        end;
      end;

    laSrcUnique:
      for I := Count - 1 downto 0 do
        if LSource.IndexOf(Items[I]) <> -1 then
          Delete(I);

    laDestUnique:
      begin
        LTemp := TList.Create;
        try
          LTemp.Capacity := LSource.Count;
          for I := LSource.Count - 1 downto 0 do
            if IndexOf(LSource[I]) = -1 then
              LTemp.Add(LSource[I]);
          Assign(LTemp);
        finally
          LTemp.Free;
        end;
      end;
  end;
end;

class procedure TList.Error(const Msg: string; Data: Integer);
  function ReturnAddr: Pointer;
  asm
          MOV     EAX,[EBP+4]
  end;

begin
  raise EListError.CreateFmt(Msg, [Data]) at ReturnAddr;
end;

class procedure TList.Error(Msg: PResStringRec; Data: Integer);
begin
  TList.Error(LoadResString(Msg), Data);
end;


{ TThreadList }

constructor TThreadList.Create;
begin
  inherited Create;
  InitializeCriticalSection(FLock);
  FList := TList.Create;
end;

destructor TThreadList.Destroy;
begin
  LockList;    // Make sure nobody else is inside the list.
  try
    FList.Free;
    inherited Destroy;
  finally
    UnlockList;
    DeleteCriticalSection(FLock);
  end;
end;

procedure TThreadList.Add(Item: Pointer);
begin
  LockList;
  try
    FList.Add(Item)
  finally
    UnlockList;
  end;
end;

procedure TThreadList.Clear;
begin
  LockList;
  try
    FList.Clear;
  finally
    UnlockList;
  end;
end;

function  TThreadList.LockList: TList;
begin
  EnterCriticalSection(FLock);
  Result := FList;
end;

procedure TThreadList.Remove(Item: Pointer);
begin
  LockList;
  try
    FList.Remove(Item);
  finally
    UnlockList;
  end;
end;

procedure TThreadList.UnlockList;
begin
  LeaveCriticalSection(FLock);
end;

{ TInterfaceList }

constructor TInterfaceList.Create;
begin
  inherited Create;
  FList := TThreadList.Create;
end;

destructor TInterfaceList.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

procedure TInterfaceList.Clear;
var
  I: Integer;
begin
  if FList <> nil then
  begin
    with FList.LockList do
    try
      for I := 0 to Count - 1 do
        IInterface(List[I]) := nil;
      Clear;
    finally
      Self.FList.UnlockList;
    end;
  end;
end;

procedure TInterfaceList.Delete(Index: Integer);
begin
  with FList.LockList do
  try
    Self.Put(Index, nil);
    Delete(Index);
  finally
    Self.FList.UnlockList;
  end;
end;

function TInterfaceList.Expand: TInterfaceList;
begin
  with FList.LockList do
  try
    Expand;
    Result := Self;
  finally
    Self.FList.Unlocklist;
  end;
end;

function TInterfaceList.First: IInterface;
begin
  Result := Get(0);
end;

function TInterfaceList.Get(Index: Integer): IInterface;
begin
  with FList.LockList do
  try
    if (Index < 0) or (Index >= Count) then
      Error(@SListIndexError, Index);
    Result := IInterface(List[Index]);
  finally
    Self.FList.UnlockList;
  end;
end;

function TInterfaceList.GetCapacity: Integer;
begin
  with FList.LockList do
  try
    Result := Capacity;
  finally
    Self.FList.UnlockList;
  end;
end;

function TInterfaceList.GetCount: Integer;
begin
  with FList.LockList do
  try
    Result := Count;
  finally
    Self.FList.UnlockList;
  end;
end;

function TInterfaceList.IndexOf(const Item: IInterface): Integer;
begin
  with FList.LockList do
  try
    Result := IndexOf(Pointer(Item));
  finally
    Self.FList.UnlockList;
  end;
end;

function TInterfaceList.Add(const Item: IInterface): Integer;
begin
  with FList.LockList do
  try
    Result := Add(nil);
    IInterface(List[Result]) := Item;
  finally
    Self.FList.UnlockList;
  end;
end;

procedure TInterfaceList.Insert(Index: Integer; const Item: IInterface);
begin
  with FList.LockList do
  try
    Insert(Index, nil);
    IInterface(List[Index]) := Item;
  finally
    Self.FList.UnlockList;
  end;
end;

function TInterfaceList.Last: IInterface;
begin
  with FList.LockList do
  try
    Result := Self.Get(Count - 1);
  finally
    Self.FList.UnlockList;
  end;
end;

procedure TInterfaceList.Put(Index: Integer; const Item: IInterface);
begin
  with FList.LockList do
  try
    if (Index < 0) or (Index >= Count) then Error(@SListIndexError, Index);
    IInterface(List[Index]) := Item;
  finally
    Self.FList.UnlockList;
  end;
end;

function TInterfaceList.Remove(const Item: IInterface): Integer;
begin
  with FList.LockList do
  try
    Result := IndexOf(Pointer(Item));
    if Result > -1 then
    begin
      IInterface(List[Result]) := nil;
      Delete(Result);
    end;
  finally
    Self.FList.UnlockList;
  end;
end;

procedure TInterfaceList.SetCapacity(NewCapacity: Integer);
begin
  with FList.LockList do
  try
    Capacity := NewCapacity;
  finally
    Self.FList.UnlockList;
  end;
end;

procedure TInterfaceList.SetCount(NewCount: Integer);
begin
  with FList.LockList do
  try
    Count := NewCount;
  finally
    Self.FList.UnlockList;
  end;
end;

procedure TInterfaceList.Exchange(Index1, Index2: Integer);
begin
  with FList.LockList do
  try
    Exchange(Index1, Index2);
  finally
    Self.FList.UnlockList;
  end;
end;

procedure TInterfaceList.Lock;
begin
  FList.LockList;
end;

procedure TInterfaceList.Unlock;
begin
  FList.UnlockList;
end;

{ TStringList }

constructor TStringList.Create;
begin
  inherited Create;
  FDelimiter := ',';
end;

function TStringList.GetItem(index: integer): string;
{$ifdef PUREPASCAL}
begin
  if cardinal(index)>=cardinal(FCount) then
    TList.Error(index);
  Result := fListStr[index];
end;
{$else}
asm // eax=self, edx=index, ecx=result
    cmp edx,[eax].TStringList.fCount
    mov eax,[eax].TStringList.fListStr
    jae TList.Error
    mov edx,[eax+edx*4]
    mov eax,ecx
    jmp System.@LStrLAsg
end;
{$endif}

procedure TStringList.SetItem(index: integer; const value: string);
begin
  if (self<>nil) and (cardinal(index)<cardinal(fCount)) then
    fListStr[index] := value;
end;

function TStringList.GetObject(index: integer): TObject;
begin
  if (self=nil) or (cardinal(index)>=cardinal(fCount)) or
     (index>=length(fListObj)) then
    result := nil else
    result := fListObj[index];
end;

procedure TStringList.SetObject(index: integer; value: TObject);
begin
  if (self<>nil) and (cardinal(index)<cardinal(fCount)) and (value<>nil) then begin
    if high(fListObj)<>fSize then
      SetLength(fListObj,fSize+1);
    fListObj[index] := value;
  end;
end;

function TStringList.Add(const s: string): integer;
begin
  result := AddObject(s,nil);
end;

function TStringList.AddObject(const s: string; AObject: TObject): integer;
begin
  if fCount=fSize then begin
   if fSize>64 then
     inc(fSize,fSize shr 2) else
     inc(fSize,16);
   Setlength(fListStr,fSize+1);
  end;
  fListStr[fCount] := s;
  result := fCount;
  inc(fCount);
  if AObject<>nil then
    Objects[result] := AObject;
end;

procedure TStringList.AddStrings(Strings: TStringList);
var i: integer;
begin
  for i := 0 to Strings.Count-1 do
    AddObject(Strings[i],Objects[i]);
end;

procedure TStringList.Delete(index: integer);
var L: integer;
begin
  if (self=nil) or (cardinal(index)>=cardinal(fCount)) then
    exit;
  fListStr[index] := ''; // avoid GPF
  Dec(FCount);
  if index<FCount then begin
    L := (FCount-index)*4;
    Move(FListStr[index + 1], FListStr[index], L);
    if FListObj<>nil then
      Move(FListObj[index + 1], FListObj[index], L);
  end;
  pointer(fListStr[FCount]) := nil; // avoid GPF
end;

function TStringList.IndexOf(const s: string): integer;
begin
  if fCaseSensitive then begin
    for result := 0 to fCount-1 do
    if fListStr[result]=s then
      exit;
  end else
    for result := 0 to fCount-1 do
    if SameText(fListStr[result],s) then
      exit;
  result := -1;
end;

function TStringList.IndexOfObject(item: pointer): integer;
begin
  if fListObj<>nil then
  for result := 0 to fCount-1 do
    if fListObj[result]=item then
      exit;
  result := -1;
end;

function IdemPChar(p, up: PChar): boolean;
// if the beginning of p^ is same as up^ (ignore case - up^ must be already Upper)
var c: char;
begin
  result := false;
  if (p=nil) or (up=nil) then
    exit;
  while up^<>#0 do begin
    c := p^;
    if up^<>c then
      if c in ['a'..'z'] then begin
        dec(c,32);
        if up^<>c then
          exit;
      end else exit;
    inc(up);
    inc(p);
  end;
  result := true;
end;

function TStringList.IndexOfName(const Name: string; const Separator: string='='): integer;
var L: integer;
    Tmp: string;
begin
  if self<>nil then begin
    Tmp := UpperCase(Name)+Separator;
    L := length(Tmp);
    if L>1 then
      for result := 0 to fCount-1 do
        if IdemPChar(pointer(fListStr[result]),pointer(Tmp)) then
          exit;
  end;
  result := -1;
end;

function TStringList.ValueOf(const Name: string; const Separator: string='='): string;
var i: integer;
begin
  i := IndexOfName(Name,Separator);
  if i>=0 then
    result := copy(fListStr[i],length(Name)+length(Separator)+1,maxInt) else
    result := '';
end;

function TStringList.NameOf(const Value: string; const Separator: string='='): string;
var i,j,L: integer;
    P: PChar;
begin
  L := length(Separator)-1;
  for i := 0 to fCount-1 do begin
    j := pos(Separator,fListStr[i]);
    if j=0 then continue;
    P := PChar(pointer(fListStr[i]))+j+L;
    while P^=' ' do inc(P); // trim left value
    if StrIComp(P,PChar(Value))=0 then begin
      result := copy(fListStr[i],1,j-1);
      exit;
    end;
  end;
  result := '';
end;

procedure TStringList.Clear;
begin
  if (self=nil) or (fCount<=0) then exit;
  fCount := 0;
  fSize := 0;
  Finalize(fListStr);
  Finalize(fListObj);
end;

procedure TStringList.LoadFromFile(const FileName: string);
var F: system.text;
    s: string;
    buf: array[0..4095] of byte;
begin
  Clear;
{$I-}
  Assign(F,FileName);
  SetTextBuf(F,buf);
  Reset(F);
  if ioresult<>0 then exit;
  while not eof(F) do begin
    readln(F,s);
    Add(s);
  end;
  ioresult;
  Close(F);
  ioresult;
{$I+}
end;

procedure TStringList.SaveToFile(const FileName: string);
var F: system.text;
    i: integer;
    buf: array[0..4095] of byte;
begin
{$I-}
  Assign(F,FileName);
  SetTextBuf(F,buf);
  rewrite(F);
  if ioresult<>0 then exit;
  for i := 0 to FCount-1 do
    writeln(F,FListStr[i]);
  ioresult;
  Close(F);
  ioresult; // ignore any error
{$I+}
end;

procedure TStringList.QuickSort(L, R: Integer; SCompare: TStringListSortCompare);
var I, J, P, Tmp: Integer;
begin
  repeat
    I := L;
    J := R;
    P := (L+R) shr 1;
    repeat
      while SCompare(Self,I,P)<0 do Inc(I);
      while SCompare(Self,J,P)>0 do Dec(J);
      if I <= J then begin
        Tmp := integer(fListObj[I]);
        fListObj[I] := fListObj[J];
        fListObj[J] := pointer(Tmp);
        Tmp := integer(FListStr[I]);
        integer(FListStr[I]) := integer(FListStr[J]);
        integer(FListStr[J]) := Tmp;
        if P=I then
          P := J else
        if P=J then
          P := I;
        Inc(I);
        Dec(J);
      end;
    until I>J;
    if L<J then QuickSort(L,J,SCompare);
    L := I;
  until I>=R;
end;

procedure TStringList.SetSorted(Value: Boolean);
begin
  if FSorted <> Value then begin
    if Value then
      Sort;
    FSorted := Value;
  end;
end;

function StringListCompareStrings(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := List.CompareStrings(List.fListStr[Index1],List.fListStr[Index2]);
end;

procedure TStringList.Sort;
begin
  CustomSort(StringListCompareStrings);
end;

procedure TStringList.CustomSort(Compare: TStringListSortCompare);
begin
  if (self=nil) or (FCount<=1) then
    exit;
  QuickSort(0,FCount-1,Compare);
end;

function TStringList.CompareStrings(const S1, S2: string): Integer;
begin
  if CaseSensitive then
    Result := AnsiCompareStr(S1, S2) else
    Result := AnsiCompareText(S1, S2);
end;

function TStringList.TextLen: integer;
var i: integer;
begin
  result := fCount*2; // #13#10 size
  for i := 0 to fCount-1 do
    if integer(fListStr[i])<>0 then
      inc(result,pInteger(integer(fListStr[i])-4)^); // fast add length(List[i])
end;

function TStringList.GetText: string;
var i,V,L: integer;
    P: PChar;
begin
  // much faster than for i := 0 to Count-1 do result := result+List[i]+#13#10;
  result := '';
  if fCount=0 then exit;
  SetLength(result,TextLen);
  P := pointer(result);
  for i := 0 to fCount-1 do begin
    V := integer(fListStr[i]);
    if V<>0 then begin
      L := pInteger(V-4)^;  // L := length(List[i])
      move(pointer(V)^,P^,L);
      inc(P,L);
    end;
    PWord(P)^ := 13+10 shl 8;
    inc(P,2);
  end;
end;

procedure TStringList.SetText(const Value: string);
function GetNextLine(d: pChar; out next: pChar): string;
begin
  next := d;
  while not (d^ in [#0,#10,#13]) do inc(d);
  SetString(result,next,d-next);
  if d^=#13 then inc(d);
  if d^=#10 then inc(d);
  if d^=#0 then
    next := nil else
    next := d;
end;
var P: PChar;
begin
  Clear;
  P := pointer(Value);
  while P<>nil do
    Add(GetNextLine(P,P));
end;

function TStrings.GetDelimitedText: string;
var
  S: string;
  P: PChar;
  I: Integer;
  LDelimiters: TSysCharSet;
  QuoteChar: Char;
begin
  QuoteChar := '"';
  if (Count = 1) and (fListStr[0] = '') then
    Result := QuoteChar + QuoteChar
  else
  begin
    Result := '';
    LDelimiters := [#0, QuoteChar, Delimiter];
    //if not StrictDelimiter then
    LDelimiters := LDelimiters + [#1..' '];
    for I := 0 to Count - 1 do
    begin
      S := fListStr[I];
      P := PChar(S);
      while not (P^ in LDelimiters) do
      {$IFDEF MSWINDOWS}
        P := CharNext(P);
      {$ELSE}
        Inc(P);
      {$ENDIF}
      if (P^ <> #0) then S := AnsiQuotedStr(S, QuoteChar);
      Result := Result + S + Delimiter;
    end;
    System.Delete(Result, Length(Result), 1);
  end;
end;

procedure TStrings.SetDelimitedText(const Value: string);
var
  P, P1: PChar;
  S: string;
  QuoteChar: Char;
begin
  QuoteChar := '"';
  //BeginUpdate;
  //try
    Clear;
    P := PChar(Value);
    //if not StrictDelimiter then
      while P^ in [#1..' '] do
      {$IFDEF MSWINDOWS}
        P := CharNext(P);
      {$ELSE}
        Inc(P);
      {$ENDIF}
    while P^ <> #0 do
    begin
      if P^ = QuoteChar then
        S := AnsiExtractQuotedStr(P, QuoteChar)
      else
      begin
        P1 := P;
        while (({not FStrictDelimiter and} (P^ > ' ')) {or
              (FStrictDelimiter and (P^ <> #0))}) and (P^ <> Delimiter) do
        {$IFDEF MSWINDOWS}
          P := CharNext(P);
        {$ELSE}
          Inc(P);
        {$ENDIF}
        SetString(S, P1, P - P1);
      end;
      Add(S);
      //if not FStrictDelimiter then
        while P^ in [#1..' '] do
        {$IFDEF MSWINDOWS}
          P := CharNext(P);
        {$ELSE}
          Inc(P);
        {$ENDIF}

      if P^ = Delimiter then
      begin
        P1 := P;
        {$IFDEF MSWINDOWS}
        if CharNext(P1)^ = #0 then
        {$ELSE}
        Inc(P1);
        if P1^ = #0 then
        {$ENDIF}
          Add('');
        repeat
          {$IFDEF MSWINDOWS}
          P := CharNext(P);
          {$ELSE}
          Inc(P);
          {$ENDIF}
        until not ({not FStrictDelimiter and} (P^ in [#1..' ']));
      end;
    end;
  //finally
  //  EndUpdate;
  //end;
end;

{ TStream }

function TStream.Seek(Offset: Longint; Origin: Word): Longint;

  procedure RaiseException;
  begin
    raise EStreamError.CreateFmt('Not Implemented method %s%.Seek', [Classname]);
  end;

type
  TSeek64 = function (const Offset: Int64; Origin: TSeekOrigin): Int64 of object;
var
  Impl: TSeek64;
  Base: TSeek64;
  ClassTStream: TClass;
begin
{ Deflect 32 seek requests to the 64 bit seek, if 64 bit is implemented.
  No existing TStream classes should call this method, since it was originally
  abstract.  Descendent classes MUST implement at least one of either
  the 32 bit or the 64 bit version, and must not call the inherited
  default implementation. }
  Impl := Seek;
  ClassTStream := Self.ClassType;
  while (ClassTStream <> nil) and (ClassTStream <> TStream) do
    ClassTStream := ClassTStream.ClassParent;
  if ClassTStream = nil then RaiseException;
  Base := TStream(@ClassTStream).Seek;
  if TMethod(Impl).Code = TMethod(Base).Code then
    RaiseException;
  Result := Seek(Int64(Offset), TSeekOrigin(Origin));
end;

function TStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
{ Default implementation of 64 bit seek is to deflect to existing 32 bit seek.
  Descendents that override 64 bit seek must not call this default implementation. }
  if (Offset < Low(Longint)) or (Offset > High(Longint)) then
    raise ERangeError.Create('Range check error');
  Result := Seek(Longint(Offset), Ord(Origin));
end;

procedure TStream.Clear;
begin
  Position := 0;
  Size := 0;
end;

function TStream.CopyFrom(Source: TStream; Count: integer): integer;
const
  MaxBufSize = $F000*4; // 240KB buffer (should be fast enough ;)
var
  BufSize, N: integer;
  Buffer: PChar;
begin
  if Count=0 then begin  // Count=0 for whole stream copy
    Source.Position := 0;
    Count := Source.Size;
  end;
  result := Count;
  if Count>MaxBufSize then
    BufSize := MaxBufSize else
    BufSize := Count;
  GetMem(Buffer, BufSize);
  try
    while Count<>0 do begin
      if Count>BufSize then
        N := BufSize else
        N := Count;
      if Source.Read(Buffer^, N)<>N then
        break; // stop on any read error
      if Write(Buffer^, N)<>N then
        break; // stop on any write error
      Dec(Count, N);
    end;
  finally
    FreeMem(Buffer, BufSize);
  end;
end;

function TStream.GetPosition: integer;
begin
  Result := Seek(0, soFromCurrent);
end;

function TStream.GetSize: integer;
var Pos: integer;
begin
  Pos := Seek(0, soFromCurrent);
  Result := Seek(0, soFromEnd);
  Seek(Pos, soFromBeginning);
end;

procedure TStream.SetPosition(value: integer);
begin
  Seek(Value, soFromBeginning);
end;

procedure TStream.SetSize(Value: integer);
begin
  // default = do nothing  (read-only streams, etc)
  // descendents should implement this method
end;

procedure TStream.LoadFromFile(const FileName: string);
var F: TFileStream;
begin
  F := TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(F);
  finally
    F.Free;
  end;
end;

procedure TStream.LoadFromStream(aStream: TStream);
begin
  CopyFrom(aStream,0); // Count=0 for whole stream copy
end;

procedure TStream.ReadBuffer(var Buffer; Count: integer);
begin
  Read(Buffer,Count);
end;

procedure TStream.SaveToFile(const FileName: string);
var F: TFileStream;
begin
  F := TFileStream.Create(FileName,fmCreate);
  try
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

procedure TStream.SaveToStream(aStream: TStream);
begin
  aStream.CopyFrom(self,0); // Count=0 for whole stream copy
end;

{ TFileStream }

constructor TFileStream.Create(const FileName: string; Mode: Word);
begin
  fFileName := FileName;
  if Mode=fmCreate then
    fHandle := FileCreate(FileName) else
    fHandle := FileOpen(FileName,Mode);
  if integer(fHandle)<0 then
    raise EStreamError.Create(FileName);
end;

{$ifdef Linux}
function TFileStream.GetSize: cardinal;
var st: TStatBuf;
begin
  if stat(PChar(fFileName),st)=0 then
    result := st.st_size else
    result := 0;
end;
{$endif}

destructor TFileStream.Destroy;
begin
  FileClose(fHandle);
  inherited;
end;

{ TMemoryStream }

procedure TMemoryStream.SetCapacity(Value: integer);
begin
  if self=nil then
    exit;
  fCapacity := Value;
  ReallocMem(fMemory,fCapacity);
  if fPosition>=fCapacity then // adjust Position if truncated
    fPosition := fCapacity-1;
  if fSize>=fCapacity then     // adjust Size if truncated
    fSize := fCapacity-1;
end;

procedure TMemoryStream.SetSize(Value: integer);
begin
  if Value>fCapacity then
    SetCapacity(Value+16384); // reserve some space for inplace growing
  fSize := Value;
end;

destructor TMemoryStream.Destroy;
begin
  if Memory<>nil then
    Freemem(Memory);
  inherited;
end;

function TMemoryStream.Write(const Buffer; Count: integer): integer;
var Pos: integer;
begin
  if (FPosition>=0) and (Count>0) then begin
    Pos := FPosition+Count;
    if Pos>FSize then begin
      if Pos>FCapacity then
        if Pos>65536 then // growing by 16KB chunck up to 64KB, then by 1/4 of size
          SetCapacity(Pos+Pos shr 2) else
          SetCapacity(Pos+16384);
      FSize := Pos;
    end;
    Move(Buffer, (PAnsiChar(Memory)+FPosition)^, Count);
    FPosition := Pos;
    result := Count;
  end else
    result := 0;
end;

procedure TMemoryStream.LoadFromStream(aStream: TStream);
var L: integer;
begin
  if aStream=nil then exit;
  L := aStream.Size;
  SetCapacity(L);
  aStream.Position := 0;
  if (L<>0) and (aStream.Read(Memory^,L)<>L) then
    raise EStreamError.Create('Load');
  fPosition := 0;
  fSize := L;
end;


{ TResourceStream }


constructor TResourceStream.Create(Instance: THandle; const ResName: string;
  ResType: PChar);
begin
  inherited Create;
  Initialize(Instance, PChar(ResName), ResType, False);
end;

constructor TResourceStream.CreateFromID(Instance: THandle; ResID: Integer;
  ResType: PChar);
begin
  inherited Create;
  Initialize(Instance, PChar(ResID), ResType, True);
end;

procedure TResourceStream.Initialize(Instance: THandle; Name, ResType: PChar;
  FromID: Boolean);

  procedure Error;
  var
    S: string;
  begin
    if FromID then
      S := IntToStr(IntPtr(Name))
    else
      S := Name;
    raise EResNotFound.CreateFmt('Resource "%s" not found', [S]);
  end;

begin
  HResInfo := FindResource(Instance, Name, ResType);
  if HResInfo = 0 then Error;
  HGlobal := LoadResource(Instance, HResInfo);
  if HGlobal = 0 then Error;
  SetPointer(LockResource(HGlobal), SizeOfResource(Instance, HResInfo));
end;

destructor TResourceStream.Destroy;
begin
  UnlockResource(HGlobal);
  FreeResource(HGlobal);
  inherited Destroy;
end;

function TResourceStream.Write(const Buffer; Count: Longint): Longint;
begin
  raise EStreamError.Create('Cannot Write Resource Stream');
end;

{$ifdef MSWINDOWS}

{ TThread }

function ThreadProc(Thread: TThread): Integer;
var FreeThread: Boolean;
begin
  if not Thread.FTerminated then
  try
    result := 0; // default ExitCode
    try
      Thread.Execute;
    except
      on Exception do
        result := -1;
    end;
  finally
    FreeThread := Thread.FFreeOnTerminate;
    Thread.FFinished := True;
    if Assigned(Thread.OnTerminate) then
    try
      Thread.OnTerminate(Thread);
    except
      Thread.OnTerminate := nil;
    end;
    if FreeThread then
      Thread.Free;
    EndThread(result);   
  end;
end;

procedure TThread.AfterConstruction;
begin
  if not FCreateSuspended then
    Resume;
end;

constructor TThread.Create(CreateSuspended: Boolean);
begin
  IsMultiThread := true; // for FastMM4 locking, e.g.
  inherited Create;
  FSuspended := CreateSuspended;
  FCreateSuspended := CreateSuspended;
  FHandle := BeginThread(nil, 0, @ThreadProc, Pointer(Self), CREATE_SUSPENDED, FThreadID);
  if FHandle = 0 then
    raise Exception.Create(SysErrorMessage(GetLastError));
  SetThreadPriority(FHandle, THREAD_PRIORITY_NORMAL); 
end;

destructor TThread.Destroy;
begin
  if (FThreadID<>0) and not FFinished then begin
    Terminate;
    if FCreateSuspended then
      Resume;
    WaitFor;
  end;
  if FHandle<>0 then
    CloseHandle(FHandle);
  inherited Destroy;
end;

procedure TThread.Resume;
begin
  if ResumeThread(FHandle)=1 then // returns the thread's previous suspend count
    FSuspended := False;
end;

procedure TThread.SetSuspended(Value: Boolean);
begin
  if Value<>FSuspended then
    if Value then
      Suspend else
      Resume;
end;

procedure TThread.Suspend;
var OldSuspend: Boolean;
begin
  OldSuspend := FSuspended;
  FSuspended := True;
  if Integer(SuspendThread(FHandle))<0 then
    FSuspended := OldSuspend;
end;

procedure TThread.Terminate;
begin
  FTerminated := True;
end;

function TThread.WaitFor: LongWord;
begin
  if GetCurrentThreadID<>MainThreadID then
    WaitForSingleObject(FHandle, INFINITE);
  GetExitCodeThread(FHandle, result);
end;

{ TCustomMemoryStream }

function TCustomMemoryStream.GetPosition: integer;
begin
  result := fPosition;
end;

function TCustomMemoryStream.GetSize: integer;
begin
  result := fSize;
end;

function TCustomMemoryStream.Read(var Buffer; count: integer): integer;
begin
  if (self<>nil) and (Memory<>nil) then
  if (FPosition>=0) and (Count>0) then begin
    result := FSize - FPosition;
    if result>0 then begin
      if result>Count then result := Count;
      Move((PAnsiChar(Memory)+FPosition)^, Buffer, result);
      Inc(FPosition, result);
      Exit;
    end;
  end;
  result := 0;
end;

procedure TCustomMemoryStream.SaveToStream(aStream: TStream);
begin
  if (self<>nil) and (FSize<>0) and (aStream<>nil) and (Memory<>nil) then
    aStream.Write(Memory^, FSize);
end;

function TCustomMemoryStream.Seek(Offset: integer; Origin: Word): integer;
begin
  result := Offset; // default is soFromBeginning
  case Origin of
    soFromEnd:       inc(result,fSize);
    soFromCurrent:   inc(result,fPosition);
  end;
  if result<=fSize then
    fPosition := result else begin
    result := fSize;
    fPosition := fSize;
  end;
end;

procedure TCustomMemoryStream.SetPointer(Buffer: pointer; Count: integer);
begin
  fMemory := Buffer;
  fSize := Count;
end;

procedure TCustomMemoryStream.SetPosition(value: integer);
begin
  if value>fSize then
    value := fSize;
  fPosition := value;
end;

procedure TCustomMemoryStream.SetSize(Value: integer);
begin
  fSize := Value;
end;

{ THandleStream }

constructor THandleStream.Create(aHandle: THandle);
begin
  fHandle := aHandle;
end;

function THandleStream.Read(var Buffer; count: integer): integer;
begin
  if (Integer(fHandle)<0) or (Count<=0) then
    result := 0 else
    result := FileRead(fHandle,Buffer,Count);
end;

function THandleStream.Seek(Offset: integer; Origin: Word): integer;
begin
  if integer(fHandle)<0 then
    result := 0 else
    result := FileSeek(fHandle,offset,Origin);
end;

procedure THandleStream.SetSize(Value: integer);
begin
  Seek(Value, soFromBeginning);
{$ifdef MSWINDOWS}
  if not SetEndOfFile(fHandle) then
{$else}
  if ftruncate(fHandle, Value)=-1 then
{$endif}
    raise EStreamError.Create('SetSize');
end;

function THandleStream.Write(const Buffer; Count: integer): integer;
begin
  if (integer(fHandle)<0) or (Count<=0) then
    result := 0 else
    result := FileWrite(fHandle,Buffer,Count);
end;


{ TEvent }

constructor TEvent.Create(EventAttributes: PSecurityAttributes;
  ManualReset, InitialState: Boolean; const Name: string);
begin
  FHandle := CreateEvent(EventAttributes,ManualReset,InitialState,pointer(Name));
end;

destructor TEvent.Destroy;
begin
  CloseHandle(FHandle);
end;

procedure TEvent.ResetEvent;
begin
  Windows.ResetEvent(Handle);
end;

procedure TEvent.SetEvent;
begin
  Windows.SetEvent(Handle);
end;

function TEvent.WaitFor(Timeout: LongWord): TWaitResult;
begin
  case WaitForSingleObject(Handle, Timeout) of
    WAIT_ABANDONED: result := wrAbandoned;
    WAIT_OBJECT_0:  result := wrSignaled;
    WAIT_TIMEOUT:   result := wrTimeout;
    else            result := wrError;
  end;
end;

initialization

finalization
{$endif}
end.

