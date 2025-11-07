program TestCommandLine;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, Process
  {$IFDEF UNIX}, BaseUnix{$ENDIF};

procedure EnsureScript(out ScriptPath: string);
const
  ScriptRelative = 'whonix test dir/script.sh';
var
  ScriptDir: string;
  ScriptFile: TextFile;
begin
  ScriptDir := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    ExtractFileDir(ScriptRelative);
  ForceDirectories(ScriptDir);

  ScriptPath := IncludeTrailingPathDelimiter(ScriptDir) + ExtractFileName(ScriptRelative);

  AssignFile(ScriptFile, ScriptPath);
  Rewrite(ScriptFile);
  try
    Writeln(ScriptFile, '#!/bin/sh');
    Writeln(ScriptFile, 'echo "script ran with arg: $1"');
  finally
    CloseFile(ScriptFile);
  end;

  {$IFDEF UNIX}
  FpChmod(PChar(ScriptPath), S_IRUSR or S_IWUSR or S_IXUSR or
    S_IRGRP or S_IXGRP or S_IROTH or S_IXOTH);
  {$ENDIF}
end;

procedure RunCommand(const Cmd: string);
var
  Proc: TProcess;
  Output: TStringList;
  Line: string;
begin
  Proc := TProcess.Create(nil);
  Output := TStringList.Create;
  try
    Proc.Options := Proc.Options + [poUsePipes, poStderrToOutPut];
    Proc.CommandLine := Cmd;
    try
      Proc.Execute;
    except
      on E: Exception do
      begin
        Writeln('Exception: ', E.Message);
        Exit;
      end;
    end;

    Output.LoadFromStream(Proc.Output);
    for Line in Output do
      Writeln(Line);
  finally
    Output.Free;
    Proc.Free;
  end;
end;

var
  ScriptPath: string;

begin
  EnsureScript(ScriptPath);

  Writeln('Running without quotes:');
  RunCommand(ScriptPath + ' arg1');

  Writeln;
  Writeln('Running with quotes:');
  RunCommand('"' + ScriptPath + '" arg1');
end.
