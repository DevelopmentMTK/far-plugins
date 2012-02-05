{$I Defines.inc}

unit MacroListDlg;

{******************************************************************************}
{* (c) 2011 Max Rusov                                                         *}
{*                                                                            *}
{* FAR Macro Library                                                          *}
{* ������ - ������ ��������                                                   *}
{******************************************************************************}

interface

  uses
    Windows,
    MixTypes,
    MixUtils,
    MixClasses,
    MixStrings,

    Far_API,
    FarCtrl,
    FarDlg,
    FarGrid,
    FarMatch,
    FarListDlg,

    MacroLibConst,
    MacroLibClasses;



  type
    TMacroList = class(TFilteredListDlg)
    public
      constructor Create; override;
      destructor Destroy; override;

      function GetMacro(ARow :Integer) :TMacro;

    protected
      procedure Prepare; override;
      procedure InitDialog; override;
      function KeyDown(AID :Integer; AKey :Integer) :Boolean; override;
      function DialogHandler(Msg :Integer; Param1 :Integer; Param2 :TIntPtr) :TIntPtr; override;

      procedure SelectItem(ACode :Integer); override;
      procedure UpdateHeader; override;
      procedure ReInitGrid; override;
      procedure ReinitAndSaveCurrent; override;

      function GridGetDlgText(ASender :TFarGrid; ACol, ARow :Integer) :TString; override;
      procedure GridGetCellColor(ASender :TFarGrid; ACol, ARow :Integer; var AColor :TFarColor); override;
      procedure GridPaintCell(ASender :TFarGrid; X, Y, AWidth :Integer; ACol, ARow :Integer; AColor :TFarColor); override;

      function ItemCompare(AIndex1, AIndex2 :Integer; Context :TIntPtr) :Integer; override;

    protected
      FMacroses    :TExList;

      FResInd      :Integer;
      FResCmd      :Integer;

      procedure UpdateMacroses;
      procedure EditCurrent;

      procedure SetOrder(AOrder :Integer);
      function GetColumStr(AMacro :TMacro; AColTag :Integer) :TString;
      function FindMacro(AMacro :TMacro) :Integer;
      function FindMacroByLink(const ALink :TString) :Integer;
    end;

  var
    LastRevision :Integer;
    LastMacro    :TMacro;
    LastLink     :TString;

    MacroLock    :Integer;


  function ListMacrosesDlg(AMacroses :TExList; var AIndex :Integer) :Boolean;


{******************************************************************************}
{******************************} implementation {******************************}
{******************************************************************************}

  uses
    MacroLibHints,
    MixDebug;

    
 {-----------------------------------------------------------------------------}
 { TMacroList                                                                  }
 {-----------------------------------------------------------------------------}

  constructor TMacroList.Create; {override;}
  begin
    inherited Create;
    RegisterHints(Self);
    FFilter := TListFilter.Create;
    FFilter.Owner := Self;
  end;


  destructor TMacroList.Destroy; {override;}
  begin
    UnRegisterHints;
    inherited Destroy;
  end;


  procedure TMacroList.Prepare; {override;}
  begin
    inherited Prepare;
    FGUID := cMacroListDlgID;
    FHelpTopic := 'List';
    FGrid.Options := [{goRowSelect,} goWrapMode {, goFollowMouse}];
  end;


  procedure TMacroList.InitDialog; {override;}
  begin
    inherited InitDialog;

    if (FResInd = -1) and (LastMacro <> nil) and (LastRevision = MacroLibrary.Revision) then
      FResInd := FindMacro(LastMacro);

    if FResInd <> -1 then
      SetCurrent(FResInd);
  end;


  procedure TMacroList.UpdateHeader; {override;}
  var
    vTitle :TString;
  begin
    vTitle := GetMsg(strMacrosesTitle);

    if FFilterMask = '' then
      vTitle := Format('%s (%d)', [ vTitle, FTotalCount ])
    else
      vTitle := Format('%s [%s] (%d/%d)', [vTitle, FFilterMask, FFilter.Count, FTotalCount ]);
    SetText(IdFrame, vTitle);

    if length(vTitle) + 4 > FMenuMaxWidth then
      FMenuMaxWidth := length(vTitle) + 4;
  end;


  function TMacroList.GetColumStr(AMacro :TMacro; AColTag :Integer) :TString;
  begin
    case AColTag of
      0: Result := AMacro.Name;
      1: Result := AMacro.Descr;
      2: Result := AMacro.GetBindAsStr(optShowBind);
      3: Result := AMacro.GetAreaAsStr(optShowArea);
      4: Result := AMacro.GetFileTitle(optShowFile);
    end;
  end;


  function TMacroList.ItemCompare(AIndex1, AIndex2 :Integer; Context :TIntPtr) :Integer; {override;}
  var
    vMacro1, vMacro2 :TMacro;
  begin
    vMacro1 := FMacroses[AIndex1];
    vMacro2 := FMacroses[AIndex2];

    Result := 0;
    case Abs(Context) of
      1: Result := UpCompareStr(vMacro1.Descr, vMacro2.Descr);
      2: Result := UpCompareStr(vMacro1.GetBindAsStr(optShowBind), vMacro2.GetBindAsStr(optShowBind));
      3: Result := UpCompareStr(vMacro1.GetAreaAsStr(optShowArea), vMacro2.GetAreaAsStr(optShowArea));
      4: Result := UpCompareStr(vMacro1.GetFileTitle(optShowFile), vMacro2.GetFileTitle(optShowFile));
    end;

    if Context < 0 then
      Result := -Result;
    if Result = 0 then
      Result := IntCompare(AIndex1, AIndex2);
  end;


  procedure TMacroList.ReInitGrid; {virtual;}
  var
    I, vCount, vPos, vFndLen, vMaxLen1, vMaxLen2, vMaxLen3, vMaxLen4, vMaxLen5 :Integer;
    vMacro :TMacro;
    vStr, vMask, vXMask :TString;
    vHasMask :Boolean;
  begin
    FTotalCount := FMacroses.Count;

    vHasMask := False;
    vMask := FFilterMask;
    if vMask <> '' then begin

      if (FFilterColumn = 3) and (optShowArea = 2) and (vMask[1] <> '*') then
        { ���������� �� �������� � ���� ������ - ������ �� ��������� }
        vMask := '*' + vMask;

      vHasMask := (ChrPos('*', vMask) <> 0) or (ChrPos('?', vMask) <> 0);
      if vHasMask and (vMask[Length(vMask)] <> '*') {and (vMask[Length(FMask)] <> '?')} then
        vMask := vMask + '*';
    end;

    vCount := 0;
    FFilter.Clear;
    if vMask <> '' then begin
      if optXLatMask then
        vXMask := FarXLatStr(vMask);
    end;

    vMaxLen1 := 2; vMaxLen2 := 2; vMaxLen3 := 2; vMaxLen4 := 2; vMaxLen5 := 2;

    for I := 0 to FMacroses.Count - 1 do begin
      vMacro := FMacroses[I];

      vPos := 0; vFndLen := 0;
      if vMask <> '' then begin
        vStr := GetColumStr(vMacro, FFilterColumn);
        if not ChrCheckXMask(vMask, vXMask, PTChar(vStr), vHasMask, vPos, vFndLen) then
          Continue;
      end;

      FFilter.Add(I, vPos, vFndLen);

      vMaxLen1 := IntMax(vMaxLen1, Length(vMacro.Name));
      vMaxLen2 := IntMax(vMaxLen2, Length(vMacro.Descr));
      if optShowBind > 0 then
        vMaxLen3 := IntMax(vMaxLen3, Length(vMacro.GetBindAsStr(optShowBind)));
      if optShowArea > 0 then
        vMaxLen4 := IntMax(vMaxLen4, Length(vMacro.GetAreaAsStr(optShowArea)));
      if optShowFile > 0 then
        vMaxLen5 := IntMax(vMaxLen5, Length(vMacro.GetFileTitle(optShowFile)));

      Inc(vCount);
    end;

    if optSortMode <> 0 then
      FFilter.SortList(True, optSortMode);

    FGrid.ResetSize;

    FGrid.Columns.FreeAll;
//  if optShowName then
//    FGrid.Columns.Add( TColumnFormat.CreateEx('', '', vMaxLen1+2, taLeftJustify, [coColMargin{, coOwnerDraw}], 0) );
    if True {optShowDescr} then
      FGrid.Columns.Add( TColumnFormat.CreateEx('', '', vMaxLen2+2, taLeftJustify, [coColMargin, coOwnerDraw], 1) );
    if optShowBind > 0 then
      FGrid.Columns.Add( TColumnFormat.CreateEx('', '', vMaxLen3+2, taLeftJustify, [coColMargin, coOwnerDraw], 2) );
    if optShowArea > 0 then
      FGrid.Columns.Add( TColumnFormat.CreateEx('', '', vMaxLen4+2, taLeftJustify, [coColMargin, coOwnerDraw], 3) );
    if optShowFile > 0 then
      FGrid.Columns.Add( TColumnFormat.CreateEx('', '', vMaxLen5+2, taLeftJustify, [coColMargin, coOwnerDraw], 4) );

    FGrid.Column[0].MinWidth := IntMin(vMaxLen2, 15);
    for I := 1 to FGrid.Columns.Count - 1 do
      with FGrid.Column[I] do
        MinWidth := IntMin(Width, 6);

    FGrid.ReduceColumns(FarGetWindowSize.CX - (10 + FGrid.Columns.Count));

    FMenuMaxWidth := 0;
    for I := 0 to FGrid.Columns.Count - 1 do
      with FGrid.Column[I] do
        if Width <> 0 then
          Inc(FMenuMaxWidth, Width + IntIf(coNoVertLine in Options, 0, 1) );
    Dec(FMenuMaxWidth);

    FGrid.RowCount := vCount;

    UpdateHeader;
    ResizeDialog;
  end;


  procedure TMacroList.ReinitAndSaveCurrent; {override;}
  var
    vMacro :TMacro;
  begin
    vMacro := GetMacro(FGrid.CurRow);
    ReinitGrid;
    if vMacro <> nil then
      SetCurrent(FindMacro(vMacro), lmCenter);
  end;


  function TMacroList.GetMacro(ARow :Integer) :TMacro;
  var
    vIdx :Integer;
  begin
    Result := nil;
    vIdx := RowToIdx(ARow);
    if (vIdx >= 0) and (vIdx < FMacroses.Count) then
      Result := FMacroses[vIdx];
  end;


  function TMacroList.FindMacro(AMacro :TMacro) :Integer;
  var
    I :Integer;
  begin
    for I := 0 to FGrid.RowCount - 1 do
      if GetMacro(I) = AMacro then begin
        Result := I;
        Exit;
      end;
    Result := -1;
  end;


  function TMacroList.FindMacroByLink(const ALink :TString) :Integer;
  var
    I :Integer;
  begin
    for I := 0 to FGrid.RowCount - 1 do
      if GetMacro(I).GetSrcLink = ALink then begin
        Result := I;
        Exit;
      end;
    Result := -1;
  end;


  function TMacroList.GridGetDlgText(ASender :TFarGrid; ACol, ARow :Integer) :TString; {override;}
  var
    vMacro :TMacro;
  begin
    Result := '';
    vMacro := GetMacro(ARow);
    if vMacro <> nil then
      Result := GetColumStr(vMacro, FGrid.Column[ACol].Tag);
  end;


  procedure TMacroList.GridGetCellColor(ASender :TFarGrid; ACol, ARow :Integer; var AColor :TFarColor); {override;}
  begin
    if (ACol = -1) and (FGrid.CurRow = ARow) and (FGrid.CurCol = 0) then
      AColor := FGrid.SelColor;
  end;


  procedure TMacroList.GridPaintCell(ASender :TFarGrid; X, Y, AWidth :Integer; ACol, ARow :Integer; AColor :TFarColor); {override;}
  var
    vMacro :TMacro;
    vTag :Integer;
    vStr :TString;
    vRec :PFilterRec;
  begin
    vMacro := GetMacro(ARow);
    if vMacro <> nil then begin

      vTag := FGrid.Column[ACol].Tag;
      vStr := GetColumStr(vMacro, vTag);

      vRec := nil;
      if (FFilterMask <> '') and (FFilterColumn = vTag) then
        vRec := PFilterRec(FFilter.PItems[ARow]);

      if vRec <> nil then
        FGrid.DrawChrEx(X, Y, PTChar(vStr), AWidth, vRec.FPos, vRec.FLen, AColor, ChangeFG(AColor, optFoundColor))
      else
        FGrid.DrawChr(X, Y, PTChar(vStr), AWidth, AColor);
    end;
  end;


  procedure TMacroList.SelectItem(ACode :Integer); {override;}
  begin
    if FGrid.CurRow < FGrid.RowCount then begin
      FResInd := RowToIdx(FGrid.CurRow);
      FResCmd := ACode;
      SendMsg(DM_CLOSE, -1, 0);
    end else
      Beep;
  end;


 {-----------------------------------------------------------------------------}

  procedure TMacroList.SetOrder(AOrder :Integer);
  begin
    if AOrder <> optSortMode then
      optSortMode := AOrder
    else
      optSortMode := -AOrder;

//  LocReinitAndSaveCurrent;
    ReinitGrid;
    PluginConfig(True);
  end;


 {-----------------------------------------------------------------------------}

  procedure TMacroList.UpdateMacroses;
  var
    vMacro :TMacro;
    vIndex :Integer;
  begin
    if FMacroses <> MacroLibrary.Macroses then
      begin Beep; Exit; end;

    LastRevision := MacroLibrary.Revision;
    LastMacro := nil;
    LastLink := '';

    vMacro := GetMacro(FGrid.CurRow);
    if vMacro <> nil then begin
      LastMacro := vMacro;
      LastLink := vMacro.GetSrcLink
    end;

    MacroLibrary.RescanMacroses(True);

    if LastRevision <> MacroLibrary.Revision then begin
      FMacroses := MacroLibrary.Macroses;
      ReinitGrid;

      vIndex := -1;
      if LastLink <> '' then
        vIndex := FindMacroByLink(LastLink);
      if vIndex <> -1 then begin
        SetCurrent(vIndex, lmCenter);

        LastRevision := MacroLibrary.Revision;
        LastMacro := GetMacro(vIndex);
        LastLink := LastMacro.GetSrcLink;
      end;
    end;
  end;


  procedure TMacroList.EditCurrent;
  var
    vMacro :TMacro;
    vSave :THandle;
    vFull :Boolean;
    vIndex :Integer;
  begin
    vMacro := GetMacro(FGrid.CurRow);
    if vMacro = nil then
      begin beep; exit; end;

    { ������, ���� � �������� ���������/�������������� ����� �������� ������ �������...}
    SendMsg(DM_ShowDialog, 0, 0);
    vSave := FARAPI.SaveScreen(0, 0, -1, -1);
    vFull := FMacroses = MacroLibrary.Macroses;
    if vFull then
      Dec(MacroLock);
    try
      LastRevision := MacroLibrary.Revision;
      LastMacro := vMacro;
      LastLink := vMacro.GetSrcLink;

      FarEditOrView(vMacro.FileName, True, 0, vMacro.Row + 1, vMacro.Col + 1);

      if LastRevision <> MacroLibrary.Revision then begin
        FMacroses := MacroLibrary.Macroses;
        ReinitGrid;

        vIndex := -1;
        if LastLink <> '' then
          vIndex := FindMacroByLink(LastLink);
        if vIndex <> -1 then
          SetCurrent(vIndex, lmCenter);
      end;

    finally
      if vFull then
        Inc(MacroLock);
      FARAPI.RestoreScreen(vSave);
      SendMsg(DM_ShowDialog, 1, 0);
    end;
  end;


  function TMacroList.KeyDown(AID :Integer; AKey :Integer) :Boolean; {override;}

    procedure LocToggleOption(var AOption :Boolean);
    begin
      ToggleOption( AOption );
      ReInitGrid;
    end;

    procedure LocToggleOptionInt(var AOption :Integer; ANewValue :Integer);
    begin
      AOption  := ANewValue;
      PluginConfig(True);
      ReInitGrid;
    end;

  begin
    Result := True;
    case AKey of
      KEY_ENTER:
        SelectItem(1);

      KEY_F4:
        SelectItem(2);
      KEY_ALTF4:
        EditCurrent;
      KEY_F5:
        UpdateMacroses;

      KEY_CTRL2:
        LocToggleOptionInt(optShowBind, IntIf(optShowBind < 2, optShowBind + 1, 0));
      KEY_CTRL3:
        LocToggleOptionInt(optShowArea, IntIf(optShowArea < 2, optShowArea + 1, 0));
      KEY_CTRL4:
        LocToggleOptionInt(optShowFile, IntIf(optShowFile < 2, optShowFile + 1, 0));

      KEY_CTRLF1, KEY_CTRLSHIFTF1:
        SetOrder(1);
      KEY_CTRLF2, KEY_CTRLSHIFTF2:
        SetOrder(2);
      KEY_CTRLF3, KEY_CTRLSHIFTF3:
        SetOrder(3);
      KEY_CTRLF4, KEY_CTRLSHIFTF4:
        SetOrder(4);
      KEY_CTRLF11:
        SetOrder(0);
//        KEY_CTRLF12:
//          SortByDlg;
      KEY_ALTF12:
        SetOrder(FGrid.CurCol + 1);

    else
      Result := inherited KeyDown(AID, AKey);
    end;
  end;


  function TMacroList.DialogHandler(Msg :Integer; Param1 :Integer; Param2 :TIntPtr) :TIntPtr; {override;}
  begin
    Result := 1;
    case Msg of
      DN_RESIZECONSOLE:
        begin
          ReinitAndSaveCurrent;
//        SetCurrent(FGrid.CurRow);
        end;
    else
      Result := inherited DialogHandler(Msg, Param1, Param2);
    end;
  end;


 {-----------------------------------------------------------------------------}
 {                                                                             }
 {-----------------------------------------------------------------------------}

  procedure EditMacro(AMacro :TMacro);
  begin
    OpenEditor(AMacro.FileName, AMacro.Row + 1, AMacro.Col + 1);
  end;


  function ListMacrosesDlg(AMacroses :TExList; var AIndex :Integer) :Boolean;
  var
    vDlg :TMacroList;
    vMacro :TMacro;
  begin
    Result := False;
    Inc(MacroLock);
    vDlg := TMacroList.Create;
    try
      vDlg.FMacroses := AMacroses;
      vDlg.FResInd   := AIndex;

      if vDlg.Run = -1 then
        Exit;

      AIndex := vDlg.FResInd;

      if (AIndex >= 0) and (AIndex < vDlg.FMacroses.Count) then begin
        vMacro := vDlg.FMacroses[AIndex];

        LastRevision := MacroLibrary.Revision;
        LastMacro := vMacro;
        LastLink := vMacro.GetSrcLink;

        case vDlg.FResCmd of
          1: Result := True;
          2: EditMacro(vMacro);
        end;
      end;

    finally
      FreeObj(vDlg);
      Dec(MacroLock);
    end;
  end;

end.

