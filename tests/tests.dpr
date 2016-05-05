program tests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IF CompilerVersion <= 18.5}
  FastMM4,
  {$ELSE}
  SimpleShareMem,
  {$IFEND}
  SysUtils,
  Forms,
  ZmqIntf,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  SocketTestCase in 'SocketTestCase.pas',
  ContextTestCase in 'ContextTestCase.pas',
  PushPullTestCase in 'PushPullTestCase.pas',
  PollTestCase in 'PollTestCase.pas',
  ThreadTestCase in 'ThreadTestCase.pas';

{$R *.RES}

begin
  {$IF CompilerVersion > 15.0 }
  ReportMemoryLeaksOnShutdown := True;
  {$IFEND}
  LoadZMQ4D(ExtractFilePath(ParamStr(0)) {$IF CompilerVersion > 18.5} + '..\'{$IFEND} + DLL_Zmq4D);
  //ZMQ.DriverFile := ExtractFilePath(ParamStr(0)) {$IF CompilerVersion > 18.5} + '..\'{$IFEND} + 'libzmq.dll';
  Application.Initialize;
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    GUITestRunner.RunRegisteredTests;
end.

