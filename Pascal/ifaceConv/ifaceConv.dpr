{$APPTYPE CONSOLE}
program ifaceConv;

uses
  SysUtils;

type
  TMiniLexer = class
  private
    FText: string;
    FPtr: PChar;
    FPos: integer;
  public
    procedure LoadText(Text: string);
    function NextToken: string; //empty string = end of text
  end;

procedure TMiniLexer.LoadText(Text: string);
begin
   FText:=Text;
   FPtr:=PChar(FText);
   FPos:=0;
end;

function TMiniLexer.NextToken: string;
var
  Head,Tail: PChar;
begin
  Assert(FPtr<>nil);
  result:='';
  Head := FPtr+FPos;
  if Head^=#0 then exit;
  while (Head^ in[#1..' ']) do inc(Head); //white chars without #0
  if Head^=#0 then exit;
  Tail := Head;
  case Tail^ of
    'A'..'Z','a'..'z','_': while Tail^ in['A'..'Z','a'..'z','0'..'9','_'] do inc(Tail); //ident
    '0'..'9':
    begin
      if (Tail^='0')and(Tail[1]='x') then
      begin
        inc(Tail,2);
        while Tail^ in['0'..'9','A'..'F','a'..'f'] do inc(Tail);
      end
      else while Tail^ in['0'..'9'] do inc(Tail); //number
    end else
    begin
      if (Tail^='-') and (Tail[1] in['0'..'9']) then
      begin
        inc(Tail);
        while Tail^ in['0'..'9'] do inc(Tail);
      end else
      inc(Tail); //token = one char
    end;
  end;
  SetString(result, Head, Tail-Head);
  while (Tail^ in[#1..' ']) do inc(Tail);//white chars without #0
  FPos:=Tail-FPtr;
end;

procedure createH(filename: string);
var
  f: TextFile;
  outF: TextFile;
  line: string;
  key,name,num: string;
  lexer: TMiniLexer;
begin
  AssignFile(f,filename);
  AssignFile(outF,'Scintilla.h.gen');
  Reset(f);
  Rewrite(outF);
  lexer:=TMiniLexer.Create;
  while not eof(f) do
  begin
    readln(f, line);
    if line='' then continue;
    if (Length(line)>=2)and(line[1]='#')and(line[2]='#') then continue;
    if line='# For SciLexer.h' then
    begin
      CloseFile(outF);
      AssignFile(outF,'SciLexer.h.gen');
      Rewrite(outF);
    end;
    if line='# Events' then
    begin
      CloseFile(outF);
      AssignFile(outF,'Scintilla.h.gen');
      Append(outF);
    end;
    if line='cat Provisional' then break;
    lexer.LoadText(line);
    key:=lexer.NextToken;
    if key='val' then
    begin
      name:=lexer.NextToken;
      lexer.NextToken; //=
      num:=lexer.NextToken;
      writeln(outF, '#define ',UpperCase(name),' ',num);
    end
    else if (key='fun')or(key='get')or(key='set') then
    begin
      lexer.NextToken; //type
      name:=lexer.NextToken;
      lexer.NextToken; //=
      num:=lexer.NextToken;
      writeln(outF, '#define SCI_',UpperCase(name),' ',num);
    end else if key='evt' then
    begin
      lexer.NextToken; //type
      name:=lexer.NextToken;
      lexer.NextToken; //=
      num:=lexer.NextToken;
      writeln(outF, '#define SCN_',UpperCase(name),' ',num);
    end;
  end;
  lexer.Free;
  CloseFile(outF);
  CloseFile(f);
end;

begin
  createH('Scintilla.iface');
end.

