{$I Defines.inc}

{$ifdef bDelphi}
 {$E hll}
{$endif bDelphi}

{$ImageBase $40370000}

library FarHintsFolders;

uses
 {$ifdef bTrace}
  MixCheck,
 {$endif bTrace}
  FarHintsFoldersMain;

exports
  GetPluginInterface;

{$R FarHintsFolders.res}

end.