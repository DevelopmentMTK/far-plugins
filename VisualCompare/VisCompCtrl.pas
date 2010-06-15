{******************************************************************************}
{* (c) 2008 Max Rusov                                                         *}
{*                                                                            *}
{* Noisy Far plugin                                                           *}
{* ��������� �������������� � �������                                         *}
{******************************************************************************}

{$I Defines.inc}

unit VisCompCtrl;

interface

  uses
    Windows,
    ShellAPI,
    MixTypes,
    MixUtils,
    MixStrings,
    MixWinUtils,

   {$ifdef bUnicodeFar}
    PluginW,
   {$else}
    Plugin,
   {$endif bUnicodeFar}
    FarCtrl,
    FarColorDlg;


  type
    TMessages = (
      strLang,
      strTitle,
      strError,

      strLeftFolder,
      strRightFolder,
      strFileMask,
      strRecursive,
      strSkipHidden,
      strDoNotScanOrphan,
      strCompareContents,

      strCompareTitle,
      strCompareCommand,

      strCompareFoldersTitle,
      strMCompareFiles,
      strMView1,
      strMEdit1,
      strMCopy1,
      strMMove1,
      strMDelete1,
      strMCompareContents,
      strMGotoFile,
      strMSendToTemp,
      strMSortBy1,
      strMOptions1,

      strOptionsTitle1,
      strMShowSame,
      strMShowDiff,
      strMShowOrphan,
      strMCompContents,
      strMCompSize,
      strMCompTime,
      strMCompAttr,
      strMCompFolderAttrs,
      strMShowFolderSummary,
      strMShowSize,
      strMShowTime,
      strMShowAttrs,
      strMShowFolderAttrs,
      strMHilightDiff,
      strMUnfold,
      strMColors1,

      strSortByTitle,
      strSortByName,
      strSortByExt,
      strSortByDate,
      strSortBySize,
      strDiffAtTop,

      strCompTextsTitle,
      strMNextDiff,
      strMPrevDiff,
      strMView2,
      strMEdit2,
      strMCodePage,
      strMOptions2,

      strOptionsTitle2,
      strMIgnoreEmptyLines,
      strMIgnoreSpaces,
      strMIgnoreCase,
      strMShowLineNumbers,
      strMShowSpaces,
      strMColors2,

      strCodePages,
      strMAnsi,
      strMOEM,
      strMUnicode,
      strMUTF8,
      strMDefault,

      strColorsTitle,
      strClCurrentLine,
      strClSelectedLine,
      strClHilightedLine,
      strClSameItem,
      strClOrphanItem,
      strClDiffItem,
      strClOlderItem,
      strClFoundText,
      strClCaption1,

      strClNormalText,
      strClSelectedText,
      strClDifference,
      strClLineNumbers,
      strClCaption2,
      strRestoreDefaults,

      strInterrupt,
      strInterruptPrompt,
      strYes,
      strNo,

      strColorDialog,
      str_CD_Foreground,
      str_CD_Background,
      str_CD_Sample,
      str_CD_Set,
      str_CD_Cancel,

      strDelete,
      strDeleteFile,
      strDeleteFolder,
      strDeleteNItems,
      strBothSides,
      strLeftSide,
      strRightSide,
      strDeleteBut,

      strWarning,
      strDeleteReadOnlyFile,
      strDeleteNotEmptyFolder,
      strDelete1But,
      strAllBut,
      strSkipBut,
      strSkipAllBut,

      strOk,
      strCancel
    );


 {-----------------------------------------------------------------------------}

  const
    smByName  = 1;
    smByExt   = 2;
    smByDate  = 3;
    smBySize  = 4;

  const
    cDefaultLang   = 'English';
    cMenuFileMask  = '*.mnu';

    cPlugRegFolder = 'VisComp';
    cPlugColorRegFolder = 'Colors';

    cPlugMenuPrefix = 'vc';

    cNormalIcon = '['#$18']';
    cMaximizedIcon = '['#$12']';

  var
    optCompareCmd          :TString = '';

    optScanRecursive       :Boolean = True;
    optNoScanHidden        :Boolean = True;
    optNoScanOrphan        :Boolean = True;
    optScanContents        :Boolean = True;
    optScanFileMask        :TString = '*.*';

    optShowFilesInFolders  :Boolean = True;
    optShowSize            :Boolean = True;
    optShowTime            :Boolean = True;
    optShowAttr            :Boolean = False;
    optShowFolderAttrs     :Boolean = False;

    optShowLinesNumber     :Boolean = True;
    optShowSpaces          :Boolean = False;

    optCompareContents     :Boolean = True;
    optCompareSize         :Boolean = True;
    optCompareTime         :Boolean = True;
    optCompareAttr         :Boolean = True;
    optCompareFolderAttrs  :Boolean = False;

    optShowSame            :Boolean = True;
    optShowDiff            :Boolean = True;
    optShowOrphan          :Boolean = True;

    optHilightDiff         :Boolean = True;
    optDiffAtTop           :Boolean = True;
    optFileSortMode        :Integer = smByName;

    optTextIgnoreEmptyLine :Boolean = True;
    optTextIgnoreSpace     :Boolean = True;
    optTextIgnoreCase      :Boolean = True;

    optMaximized           :Boolean = False;

    optSpaceChar           :TChar   = #$B7;
    optTabChar             :TChar   = #$1A; //#$BB;
    optTabSpaceChar        :TChar   = ' ';

    optDefaultFormat       :TStrFileFormat = sffAnsi;

  var
    optCurColor            :Integer;
    optSelColor            :Integer;
    optDiffColor           :Integer;
    optSameColor           :Integer;
    optOrphanColor         :Integer;
    optOlderColor          :Integer;
    optNewerColor          :Integer;
    optFoundColor          :Integer;
    optHeadColor           :Integer;

    optTextColor           :Integer;
    optTextSelColor        :Integer;
    optTextDiffColor       :Integer;
    optTextNumColor        :Integer;
    optTextHeadColor       :Integer;


  var
    FRegRoot :TString;


  function GetMsg(AMess :TMessages) :PFarChar;
  function GetMsgStr(AMess :TMessages) :TString;

  procedure HandleError(AError :Exception);

  procedure RestoreDefFilesColor;
  procedure RestoreDefTextColor;

  procedure ReadSetup;
  procedure WriteSetup;
  procedure ReadSetupColors;
  procedure WriteSetupColors;

  function ShellOpen(AWnd :THandle; const FName, Param :TString) :Boolean;

  function CurrentPanelSide :Integer;
  function GetPanelDir(Active :Boolean) :TString;
  procedure CopyToClipboard(const AStr :TString);

{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MixDebug;


  function GetMsg(AMess :TMessages) :PFarChar;
  begin
    Result := FarCtrl.GetMsg(Integer(AMess));
  end;

  function GetMsgStr(AMess :TMessages) :TString;
  begin
    Result := FarCtrl.GetMsgStr(Integer(AMess));
  end;


  procedure HandleError(AError :Exception);
  begin
    ShowMessage('Visual Compare', AError.Message, FMSG_WARNING or FMSG_MB_OK);
  end;


  procedure ReadSetup;
  var
    vKey :HKEY;
  begin
    if not RegOpenRead(HKCU, FRegRoot + '\' + cPlugRegFolder, vKey) then
      Exit;
    try
      optCompareCmd := RegQueryStr(vKey, 'CompareCmd', optCompareCmd);

      optScanRecursive := RegQueryLog(vKey, 'ScanRecursive', optScanRecursive);
      optNoScanHidden := RegQueryLog(vKey, 'NoScanHidden', optNoScanHidden);
      optNoScanOrphan := RegQueryLog(vKey, 'NoScanOrphan', optNoScanOrphan);
      optScanContents := RegQueryLog(vKey, 'ScanContents', optScanContents);
      optScanFileMask := RegQueryStr(vKey, 'ScanFileMask', optScanFileMask);

      optShowFilesInFolders := RegQueryLog(vKey, 'ShowFilesInFolders', optShowFilesInFolders);

      optShowSize := RegQueryLog(vKey, 'ShowSize', optShowSize);
      optShowTime := RegQueryLog(vKey, 'ShowTime', optShowTime);
      optShowAttr := RegQueryLog(vKey, 'ShowAttr', optShowAttr);
      optShowFolderAttrs := RegQueryLog(vKey, 'ShowFolderAttrs', optShowFolderAttrs);

      optShowLinesNumber := RegQueryLog(vKey, 'ShowLinesNumber', optShowLinesNumber);
      optShowSpaces := RegQueryLog(vKey, 'ShowSpaces', optShowSpaces);

      optHilightDiff := RegQueryLog(vKey, 'HilightDiff', optHilightDiff);
      optDiffAtTop := RegQueryLog(vKey, 'DiffAtTop', optDiffAtTop);
      optFileSortMode := RegQueryInt(vKey, 'SortMode', optFileSortMode);

      optCompareContents := RegQueryLog(vKey, 'CompareContents', optCompareContents);
      optCompareSize := RegQueryLog(vKey, 'CompareSize', optCompareSize);
      optCompareTime := RegQueryLog(vKey, 'CompareTime', optCompareTime);
      optCompareAttr := RegQueryLog(vKey, 'CompareAttr', optCompareAttr);
      optCompareFolderAttrs := RegQueryLog(vKey, 'CompareFolderAttrs', optCompareFolderAttrs);

      optTextIgnoreEmptyLine := RegQueryLog(vKey, 'TextIgnoreEmptyLine', optTextIgnoreEmptyLine);
      optTextIgnoreSpace := RegQueryLog(vKey, 'TextIgnoreSpace', optTextIgnoreSpace);
      optTextIgnoreCase := RegQueryLog(vKey, 'TextIgnoreCase', optTextIgnoreCase);

      optMaximized := RegQueryLog(vKey, 'Maximized', optMaximized);

      Byte(optDefaultFormat) := IntMin(RegQueryInt(vKey, 'DefaultFormat', Byte(optDefaultFormat)), Byte(sffAuto) - 1);

    finally
      RegCloseKey(vKey);
    end;
  end;


  procedure WriteSetup;
  var
    vKey :HKEY;
  begin
    RegOpenWrite(HKCU, FRegRoot + '\' + cPlugRegFolder, vKey);
    try
      RegWriteStr(vKey, 'CompareCmd', optCompareCmd);

      RegWriteLog(vKey, 'ScanRecursive', optScanRecursive);
      RegWriteLog(vKey, 'NoScanHidden', optNoScanHidden);
      RegWriteLog(vKey, 'NoScanOrphan', optNoScanOrphan);
      RegWriteLog(vKey, 'ScanContents', optScanContents);
      RegWriteStr(vKey, 'ScanFileMask', optScanFileMask);

      RegWriteLog(vKey, 'ShowFilesInFolders', optShowFilesInFolders);

      RegWriteLog(vKey, 'ShowSize', optShowSize);
      RegWriteLog(vKey, 'ShowTime', optShowTime);
      RegWriteLog(vKey, 'ShowAttr', optShowAttr);
      RegWriteLog(vKey, 'ShowFolderAttrs', optShowFolderAttrs);

      RegWriteLog(vKey, 'ShowLinesNumber', optShowLinesNumber);
      RegWriteLog(vKey, 'ShowSpaces', optShowSpaces);

      RegWriteLog(vKey, 'HilightDiff', optHilightDiff);
      RegWriteLog(vKey, 'DiffAtTop', optDiffAtTop);
      RegWriteInt(vKey, 'SortMode', optFileSortMode);

      RegWriteLog(vKey, 'CompareContents', optCompareContents);
      RegWriteLog(vKey, 'CompareSize', optCompareSize);
      RegWriteLog(vKey, 'CompareTime', optCompareTime);
      RegWriteLog(vKey, 'CompareAttr', optCompareAttr);
      RegWriteLog(vKey, 'CompareFolderAttrs', optCompareFolderAttrs);

      RegWriteLog(vKey, 'TextIgnoreEmptyLine', optTextIgnoreEmptyLine);
      RegWriteLog(vKey, 'TextIgnoreSpace', optTextIgnoreSpace);
      RegWriteLog(vKey, 'TextIgnoreCase', optTextIgnoreCase);

      RegWriteLog(vKey, 'Maximized', optMaximized);

      RegWriteInt(vKey, 'DefaultFormat', Byte(optDefaultFormat));

    finally
      RegCloseKey(vKey);
    end;
  end;


  procedure ReadSetupColors;
  var
    vKey :HKEY;
  begin
    if not RegOpenRead(HKCU, FRegRoot + '\' + cPlugRegFolder + '\' + cPlugColorRegFolder, vKey) then
      Exit;
    try
      optCurColor    := RegQueryInt(vKey, 'FCurColor',  optCurColor);
      optSelColor    := RegQueryInt(vKey, 'FSelColor',  optSelColor);
      optDiffColor   := RegQueryInt(vKey, 'FDiffColor',  optDiffColor);
      optSameColor   := RegQueryInt(vKey, 'FSameColor', optSameColor);
      optOrphanColor := RegQueryInt(vKey, 'FOrphanColor', optOrphanColor);
      optOlderColor  := RegQueryInt(vKey, 'FOlderColor', optOlderColor);
      optNewerColor  := RegQueryInt(vKey, 'FNewerColor', optNewerColor);
      optFoundColor  := RegQueryInt(vKey, 'FFoundColor', optFoundColor);
      optHeadColor   := RegQueryInt(vKey, 'FHeadColor', optHeadColor);

      optTextColor  := RegQueryInt(vKey, 'TColor', optTextColor);
      optTextSelColor  := RegQueryInt(vKey, 'TSelColor', optTextSelColor);
      optTextDiffColor  := RegQueryInt(vKey, 'TDiffColor', optTextDiffColor);
      optTextNumColor  := RegQueryInt(vKey, 'TNumColor', optTextNumColor);
      optTextHeadColor  := RegQueryInt(vKey, 'THeadColor', optTextHeadColor);
    finally
      RegCloseKey(vKey);
    end;
  end;


  procedure WriteSetupColors;
  var
    vKey :HKEY;
  begin
    RegOpenWrite(HKCU, FRegRoot + '\' + cPlugRegFolder + '\' + cPlugColorRegFolder, vKey);
    try
      RegWriteInt(vKey, 'FCurColor',  optCurColor);
      RegWriteInt(vKey, 'FSelColor',  optSelColor);
      RegWriteInt(vKey, 'FDiffColor', optDiffColor);
      RegWriteInt(vKey, 'FSameColor', optSameColor);
      RegWriteInt(vKey, 'FOrphanColor', optOrphanColor);
      RegWriteInt(vKey, 'FOlderColor', optOlderColor);
      RegWriteInt(vKey, 'FNewerColor', optNewerColor);
      RegWriteInt(vKey, 'FFoundColor', optFoundColor);
      RegWriteInt(vKey, 'FHeadColor', optHeadColor);

      RegWriteInt(vKey, 'TColor', optTextColor);
      RegWriteInt(vKey, 'TSelColor', optTextSelColor);
      RegWriteInt(vKey, 'TDiffColor', optTextDiffColor);
      RegWriteInt(vKey, 'TNumColor', optTextNumColor);
      RegWriteInt(vKey, 'THeadColor', optTextHeadColor);
    finally
      RegCloseKey(vKey);
    end;
  end;


  procedure RestoreDefFilesColor;
  begin
    optCurColor      := 0;
    optSelColor      := $20;
    optDiffColor     := $B0;
    optSameColor     := $08;
    optOrphanColor   := $09;
    optOlderColor    := $04;
    optNewerColor    := $0C;
    optFoundColor    := $0A;
    optHeadColor     := $2F;
  end;


  procedure RestoreDefTextColor;
  begin
    optTextColor     := 0;
    optTextSelColor  := 0;
    optTextDiffColor := $B0;
    optTextNumColor  := $08;
    optTextHeadColor := $2F;
  end;


 {-----------------------------------------------------------------------------}

  function ShellOpenEx(AWnd :THandle; const FName, Param :TString; AMask :ULONG;
    AShowMode :Integer; AInfo :PShellExecuteInfo) :Boolean;
  var
    vInfo :TShellExecuteInfo;
  begin
//  Trace(FName);
    if not Assigned(AInfo) then
      AInfo := @vInfo;
    FillChar(AInfo^, SizeOf(AInfo^), 0);
    AInfo.cbSize        := SizeOf(AInfo^);
    AInfo.fMask         := AMask;
    AInfo.Wnd           := AWnd {AppMainForm.Handle};
    AInfo.lpFile        := PTChar(FName);
    AInfo.lpParameters  := PTChar(Param);
    AInfo.nShow         := AShowMode;
    Result := ShellExecuteEx(AInfo);
  end;


  function ShellOpen(AWnd :THandle; const FName, Param :TString) :Boolean;
  begin
    Result := ShellOpenEx(AWnd, FName, Param, 0{ or SEE_MASK_FLAG_NO_UI}, SW_Show, nil);
  end;


  function CurrentPanelSide :Integer;
  var
    vInfo  :TPanelInfo;
  begin
    FillChar(vInfo, SizeOf(vInfo), 0);
   {$ifdef bUnicodeFar}
    FARAPI.Control(PANEL_ACTIVE, FCTL_GetPanelInfo, 0, @vInfo);
   {$else}
    FARAPI.Control(INVALID_HANDLE_VALUE, FCTL_GetPanelShortInfo, @vInfo);
   {$endif bUnicodeFar}
    if PFLAGS_PANELLEFT and vInfo.Flags <> 0 then
      Result := 0  {Left}
    else
      Result := 1; {Right}
  end;


  function GetPanelDir(Active :Boolean) :TString;
 {$ifdef bUnicodeFar}
 {$else}
  var
    vInfo :TPanelInfo;
 {$endif bUnicodeFar}
  begin
   {$ifdef bUnicodeFar}
    Result := FarPanelGetCurrentDirectory(HandleIf(Active, PANEL_ACTIVE, PANEL_PASSIVE));
   {$else}
    FillChar(vInfo, SizeOf(vInfo), 0);
    FARAPI.Control(INVALID_HANDLE_VALUE, IntIf(Active, FCTL_GetPanelInfo, FCTL_GetAnotherPanelInfo), @vInfo);
    Result := StrOEMToAnsi(vInfo.CurDir);
   {$endif bUnicodeFar}
  end;


  procedure CopyToClipboard(const AStr :TString);
 {$ifdef bUnicodeFar}
  begin
    FARSTD.CopyToClipboard(PTChar(AStr));
 {$else}
  var
    vStr :TFarStr;
  begin
    vStr := StrAnsiToOEM(AStr);
    FARSTD.CopyToClipboard(PFarChar(vStr));
 {$endif bUnicodeFar}
  end;


initialization
  ColorDlgResBase := Byte(strColorDialog);
end.
