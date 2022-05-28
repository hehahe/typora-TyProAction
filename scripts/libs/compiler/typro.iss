#define MyAppName "Typro"
#define MyAppVersion "1.3.3-dev"
#define MyAppPublisher "taozhiyu studio"
#define MyAppURL "https://taozhiyu.github.io/TyProAction"
#define MyAppExeName "Typora.exe"
#define MyAppId "37771A20-7167-44C0-B322-FD3E54C56156"
#define MyRegInstallPath_sk "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Typora.exe"
#define MyRegInstallPath_vn ""
#define MyAppLicenseURL "https://taozhiyu.github.io/TyProAction"


[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={code:GetInstallPath}
DisableDirPage=yes
DefaultGroupName=Typora
AllowNoIcons=yes
OutputDir=..\..\..\
OutputBaseFilename={#MyAppName}-update-V{#MyAppVersion}
SetupIconFile=..\icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
Uninstallable=no
LanguageDetectionMethod=uilanguage
ShowLanguageDialog=no

[Languages]
Name: "english"; MessagesFile: ".\Default.isl"
Name: "chinesesimp"; MessagesFile: ".\Languages\ChineseSimp.isl"

[Files]
Source: ".\res\*"; DestDir: "{tmp}"; Flags: dontcopy solidbreak ; Attribs: hidden system
Source: "..\..\packages\{#MyAppVersion}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
//==============================Load DLL start==============================
type
  TBtnEventProc = procedure (h:HWND);
  TPBProc = function(h:hWnd;Msg,wParam,lParam:Longint):Longint;
  TTimerProc = procedure(H: LongWord; Msg: LongWord; IdEvent: LongWord; Time: LongWord);


Const
  GWL_EXSTYLE = (-20);
  GCL_STYLE = (-26);
  CS_DROPSHADOW = $20000;

  BtnClickEventID      = 1;
  BtnMouseEnterEventID = 2;


Const
  //´°¿ÚÒÆ¶¯
  WM_SYSCOMMAND = $0112;
  GWL_STYLE = (-16);
  ES_LEFT   =  0;
  ES_CENTER =  1;
  ES_RIGHT  =  2;
  //WS_CAPTION = $C00000;
  WS_CAPTION = $B00000;

var
  bgWelcome: TBitmapImage;
  imgBg2 :Longint;
  btnClose, btnMin:HWND;

  DpiScalePctg:integer;
  CurrentDPI:integer;

  // page welcome
  btnOneKey,btnCustomInstall:HWND;
  BtnOneKeyFont:TFont;
  chkLicense:HWND;
  lblAboutTitle,lblLicense,lblWelcome,lblAgree,lblAboutHome,lblAboutTypora:TLabel;

  // page finish;
  btnFinish:HWND;

type
 HDC=LongWord;
 HFont=LongWord;

function SetWindowLong(Wnd: HWnd; Index: Integer; NewLong: Longint): Longint; external 'SetWindowLongA@user32.dll stdcall';
function GetWindowLong(Wnd: HWnd; NewLong: Longint): Longint; external 'GetWindowLongA@user32.dll stdcall';

function CreateRoundRectRgn(p1, p2, p3, p4, p5, p6: Integer): THandle; external 'CreateRoundRectRgn@gdi32 stdcall';
function SetWindowRgn(hWnd: HWND; hRgn: THandle; bRedraw: Boolean): Integer; external 'SetWindowRgn@user32 stdcall';
function ReleaseCapture(): Longint; external 'ReleaseCapture@user32.dll stdcall';


function ImgLoad(Wnd :HWND; FileName :PAnsiChar; Left, Top, Width, Height :integer; Stretch, IsBkg :boolean) :Longint; external 'ImgLoad@files:botva2.dll stdcall delayload';
procedure ImgSetVisibility(img :Longint; Visible :boolean); external 'ImgSetVisibility@files:botva2.dll stdcall delayload';
procedure ImgApplyChanges(h:HWND); external 'ImgApplyChanges@files:botva2.dll stdcall delayload';
procedure ImgSetPosition(img :Longint; NewLeft, NewTop, NewWidth, NewHeight :integer); external 'ImgSetPosition@files:botva2.dll stdcall';
procedure ImgSetTransparent(img:Longint; Value:integer); external 'ImgSetTransparent@files:botva2.dll stdcall delayload';
procedure ImgRelease(img :Longint); external 'ImgRelease@files:botva2.dll stdcall delayload';
procedure gdipShutdown; external 'gdipShutdown@files:botva2.dll stdcall delayload';
function WrapBtnCallback(Callback: TBtnEventProc; ParamCount: Integer): Longword; external 'wrapcallback@files:innocallback.dll stdcall delayload';
function BtnCreate(hParent:HWND; Left,Top,Width,Height:integer; FileName:PAnsiChar; ShadowWidth:integer; IsCheckBtn:boolean):HWND; external 'BtnCreate@files:botva2.dll stdcall delayload';
procedure BtnSetText(h:HWND; Text:PAnsiChar); external 'BtnSetText@files:botva2.dll stdcall delayload';
procedure BtnSetVisibility(h:HWND; Value:boolean); external 'BtnSetVisibility@files:botva2.dll stdcall delayload';
procedure BtnSetFont(h:HWND; Font:Cardinal); external 'BtnSetFont@files:botva2.dll stdcall delayload';
procedure BtnSetFontColor(h:HWND; NormalFontColor, FocusedFontColor, PressedFontColor, DisabledFontColor: Cardinal); external 'BtnSetFontColor@files:botva2.dll stdcall delayload';
procedure BtnSetEvent(h:HWND; EventID:integer; Event:Longword); external 'BtnSetEvent@files:botva2.dll stdcall delayload';
procedure BtnSetCursor(h:HWND; hCur:Cardinal); external 'BtnSetCursor@files:botva2.dll stdcall delayload';
procedure BtnSetEnabled(h:HWND; Value:boolean); external 'BtnSetEnabled@files:botva2.dll stdcall delayload';
function GetSysCursorHandle(id:integer):Cardinal; external 'GetSysCursorHandle@files:botva2.dll stdcall delayload';
function BtnGetChecked(h:HWND):boolean; external 'BtnGetChecked@files:botva2.dll stdcall delayload';
procedure BtnSetChecked(h:HWND; Value:boolean); external 'BtnSetChecked@files:botva2.dll stdcall delayload';
procedure CreateFormFromImage(h:HWND; FileName:PAnsiChar); external 'CreateFormFromImage@files:botva2.dll stdcall delayload';
//function SetWindowLong(Wnd: HWnd; Index: Integer; NewLong: Longint): Longint; external 'SetWindowLongA@user32.dll stdcall';
function PBCallBack(P:TPBProc;ParamCount:integer):LongWord; external 'wrapcallback@files:innocallback.dll stdcall';
function CallWindowProc(lpPrevWndFunc: Longint; hWnd: HWND; Msg: UINT; wParam, lParam: Longint): Longint; external 'CallWindowProcA@user32.dll stdcall';
procedure ImgSetVisiblePart(img:Longint; NewLeft, NewTop, NewWidth, NewHeight : integer); external 'ImgSetVisiblePart@files:botva2.dll stdcall';
function SetLayeredWindowAttributes(hwnd:HWND; crKey:Longint; bAlpha:byte; dwFlags:longint ):longint; external 'SetLayeredWindowAttributes@user32 stdcall';
function SetClassLong(hWnd: HWND; nlndex: integer; dwNewLong: integer ): integer; external 'SetClassLongA@user32 stdcall';
function GetClassLong(IntPtr:hwnd;nIndex:integer ):integer; external 'GetClassLongA@user32 stdcall';
procedure ExitProcess(uExitCode: UINT);external 'ExitProcess@kernel32.dll stdcall';
function WrapTimerProc(Callback: TTimerProc; ParamCount: Integer): LongWord; external 'wrapcallback@files:innocallback.dll stdcall';
function SetTimer(hWnd: longword; nIDEvent, uElapse: LongWord; lpTimerFunc: LongWord):LongWord; external 'SetTimer@user32.dll stdcall';
//==============================Load DLL end==============================

type
  HoverEvent_OnHoverControlChanged = procedure (Control: TControl);

var
  LastMouse: TPoint;
  LastHoverControl: TControl;
  HoverChangeCallback:HoverEvent_OnHoverControlChanged;

function GetCursorPos(var lpPoint: TPoint): BOOL;
  external 'GetCursorPos@user32.dll stdcall';
function ScreenToClient(hWnd: HWND; var lpPoint: TPoint): BOOL;
  external 'ScreenToClient@user32.dll stdcall';
function ClientToScreen(hWnd: HWND; var lpPoint: TPoint): BOOL;
  external 'ClientToScreen@user32.dll stdcall';

function HoverEvent_FindControl(Parent: TWinControl; P: TPoint): TControl;
var
  Control: TControl;
  WinControl: TWinControl;
  I: Integer;
  P2: TPoint;
begin
  { Top-most controls are the last. We want to start with those. }
  for I := Parent.ControlCount - 1 downto 0 do
  begin
    Control := Parent.Controls[I];
    if Control.Visible and
       (Control.Left <= P.X) and (P.X < Control.Left + Control.Width) and
       (Control.Top <= P.Y) and (P.Y < Control.Top + Control.Height) then
    begin
      if Control is TWinControl then
      begin
        P2 := P;
        ClientToScreen(Parent.Handle, P2);
        WinControl := TWinControl(Control);
        ScreenToClient(WinControl.Handle, P2);
        Result := HoverEvent_FindControl(WinControl, P2);
        if Result <> nil then Exit;
      end;

      Result := Control;
      Exit;
    end;
  end;

  Result := nil;
end;

procedure HoverEvent_HoverTimerProc(H: LongWord; Msg: LongWord; IdEvent: LongWord; Time: LongWord);
var
  P: TPoint;
  Control: TControl;
begin
  GetCursorPos(P);
  if P <> LastMouse then { just optimization }
  begin
    LastMouse := P;
    ScreenToClient(WizardForm.Handle, P);

    if (P.X < 0) or (P.Y < 0) or
       (P.X > WizardForm.ClientWidth) or (P.Y > WizardForm.ClientHeight) then
    begin
      Control := nil;
    end
      else
    begin
      Control := HoverEvent_FindControl(WizardForm, P);
    end;

    if Control <> LastHoverControl then
    begin
      HoverChangeCallback(Control);
      LastHoverControl := Control;
    end;
  end;
end;

procedure HoverEvent_Init(cb:HoverEvent_OnHoverControlChanged);
begin
  HoverChangeCallback := cb;
  SetTimer(0, 0, 50, WrapTimerProc(@HoverEvent_HoverTimerProc, 4));
end;

function DpiScale(v:integer):integer;
begin
  Result:=v*DpiScalePctg/1000;
end;

procedure SetFormRoundRectRgn(aForm: TForm; edgeSize: integer);
var
  FormRegion:LongWord;
begin
  FormRegion:=CreateRoundRectRgn(0,0,aForm.Width,aForm.Height,edgeSize-6,edgeSize-6);
  SetWindowRgn(aForm.Handle,FormRegion,True);
end;

//´°¿ÚÒÆ¶¯
procedure _WizardFormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(WizardForm.Handle, WM_SYSCOMMAND, $F012, 0);
end;

procedure SetFormDragable(aForm: TForm);
var
  MainLabel:TLabel;
begin
  MainLabel := TLabel.Create(aForm);
  with MainLabel do
  begin
    Parent := aForm;
    AutoSize := False;
    Left := 0;
    Top := 0;
    Width := aForm.Width;
    Height := aForm.Height;
    Caption := '';
    Transparent := True;
    OnMouseDown := @_WizardFormMouseDown;
  end;
end;


procedure TconSetVisible(lbl:TControl; bVis:boolean);
begin
  if bVis then
    begin
     lbl.Show;
   end
  else
    begin
     lbl.Hide;
  end;
end;

procedure chkLicenseOnClick(bBtn :HWND);
var
   isCheck:boolean;
begin
   isCheck := BtnGetChecked(chkLicense);
   if isCheck then
   begin
     BtnSetEnabled(btnCustomInstall, True);
     BtnSetEnabled(btnOneKey, True);
   end
   else
   begin
     BtnSetEnabled(btnCustomInstall, False);
     BtnSetEnabled(btnOneKey, False);
   end;
end;

procedure BtnClose_OnClick(hBtn:HWND);
begin
  if ExitSetupMsgBox then
  begin
  WizardForm.Release;
  WizardForm.Close;
  ExitProcess(0);
  end;
end;

procedure btnMin_OnClick(hBtn:HWND);
begin
  SendMessage(WizardForm.Handle,WM_SYSCOMMAND,61472,0);
end;

procedure btnOneKey_OnClick(hBtn:HWND);
begin
  WizardForm.NextButton.OnClick(WizardForm);
  WizardForm.NextButton.OnClick(WizardForm);
end;

procedure btnFinish_OnClick(hBtn:HWND);
begin
  WizardForm.NextButton.OnClick(WizardForm);
end;
function GetInstallPath(Param: String):String;
var
  strPath:String;
  ErrorCode: Integer;
  regPath:Integer;
  isGot:Boolean;
begin
  if IsWin64 then
    regPath := hklm64
  else   
    regPath := hklm32;

  isGot:=RegQueryStringValue(regPath, '{#MyRegInstallPath_sk}', '{#MyRegInstallPath_vn}', strPath) 
  if isGot then
    Result := strPath
  else
  begin 
    isGot:=RegQueryStringValue(HKCU, '{#MyRegInstallPath_sk}', '{#MyRegInstallPath_vn}', strPath) 
    if isGot then
      Result := strPath
    else
    begin
      case SuppressibleMsgBox(CustomMessage('TyporaNotInstalled'), mbCriticalError, MB_YESNO, IDYES) of
        IDYES: ShellExec('open', CustomMessage('TyporaOfficialWebSite'), '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
        IDNO: ;
      end;
      ExitProcess(0);
    end
  end
end;

procedure lblLicenseClick(sender :TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', CustomMessage('myAgreementURL'), '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure lblAboutHomeClick(sender :TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', CustomMessage('aboutHomePageURL'), '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;


procedure lblAboutTyporaClick(sender :TObject);
var
  ErrorCode: Integer;
begin
  ShellExec('open', CustomMessage('TyporaOfficialWebSite'), '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure OnHoverControlChanged(Control: TControl);
begin
  if lblLicense <> nil then
  begin
    if lblLicense = Control then
    begin
      lblLicense.Font.Style := lblLicense.Font.Style + [fsUnderline];
    end
    else
    begin
      lblLicense.Font.Style := lblLicense.Font.Style - [fsUnderline];
    end;
  end ;
  if lblAboutTypora <> nil then
  begin
    if lblAboutTypora = Control then
    begin
      lblAboutTypora.Font.Style := lblAboutTypora.Font.Style + [fsUnderline];
    end
    else
    begin
      lblAboutTypora.Font.Style := lblAboutTypora.Font.Style - [fsUnderline];
    end;
  end ;
  if lblAboutHome <> nil then
  begin
    if lblAboutHome = Control then
    begin
      lblAboutHome.Font.Style := lblAboutHome.Font.Style + [fsUnderline];
    end
    else
    begin
      lblAboutHome.Font.Style := lblAboutHome.Font.Style - [fsUnderline];
    end;
  end ;
end;

Procedure InitializeWizard();
var
  winW:integer;
  winH:integer;
begin
  CurrentDPI := WizardForm.Font.PixelsPerInch;
  DpiScalePctg := 1000* CurrentDPI / 96;

  winW:=DpiScale(660)
  winH:=DpiScale(480)
  with WizardForm do
  begin
    InnerNotebook.Hide;
    OuterNotebook.Hide;
    BorderStyle:=bsNone;
    Position:=poDesktopCenter;

    Bevel.Hide;
    NextButton.Width:=0;
    BackButton.Width:=0;
    CancelButton.Width:=0;
    Width:=winW;
    Height:=winH;
    ClientHeight:=WinH;
    ClientWidth:=WinW;
  end;

  ExtractTemporaryFile(CustomMessage('welcomePageBackground_grey')+'.png');
  imgBg2 := ImgLoad(WizardForm.Handle,ExpandConstant('{tmp}\'+CustomMessage('welcomePageBackground_grey')+'.png'),(0),(0),winW,winH,True,True);



  bgWelcome:= TBitmapImage.Create(WizardForm);
  ExtractTemporaryFile(CustomMessage('welcomePageBackground_colorful')+'.bmp');
  with bgWelcome do
  begin
    Parent := WizardForm
    Bitmap.LoadFromFile(ExpandConstant('{tmp}')+'\'+CustomMessage('welcomePageBackground_colorful')+'.bmp');
    Left := 0;
    Height := DpiScale(480)
    Width:= DpiScale(0);
    Top := 0;
  end;

  ExtractTemporaryFile('btclose.png');
  btnClose:= BtnCreate(WizardForm.Handle, DpiScale(617), DpiScale(5), DpiScale(39),DpiScale(19), ExpandConstant('{tmp}\btclose.png'),1,False)
  BtnSetEvent(btnClose,BtnClickEventID,WrapBtnCallback(@BtnClose_OnClick,1));

  ExtractTemporaryFile('btmin.png');
  btnMin:=BtnCreate(WizardForm.Handle,DpiScale(590),DpiScale(5),DpiScale(39),DpiScale(19),ExpandConstant('{tmp}\btmin.png'),1,False)
  BtnSetEvent(btnMin,BtnClickEventID,WrapBtnCallback(@btnMin_OnClick,1));

  //Òþ²Ø±ß¿ò¡¢Ô²½Ç
  SetFormRoundRectRgn(WizardForm, 15);
  SetFormDragable(WizardForm);

  lblWelcome := TLabel.Create(WizardForm);
  with lblWelcome do
  begin
    Parent := WizardForm;
    Caption := FmtMessage(CustomMessage('welcomePageTitleLab'), ['{#MyAppName} V{#MyAppVersion}']);
    Transparent := true;
    Font.Size:= 10
    Font.Name:='Î¢ÈíÑÅºÚ'
    Font.Color:=$ffffff
    Left := DpiScale(10);
    Top := DpiScale(5);
  end;

  ExtractTemporaryFile('btnOneKeyInstall.png');
  btnOneKey:=BtnCreate(WizardForm.Handle,DpiScale(255),DpiScale(335),DpiScale(150), DpiScale(42), ExpandConstant('{tmp}\btnOneKeyInstall.png'),1,False)

  BtnSetText(btnOneKey, CustomMessage('welcomePageOnkeyBtn'));
  BtnOneKeyFont := TFont.Create;
  with BtnOneKeyFont do begin
    Size := StrToInt(CustomMessage('welcomePageOnkeyBtnSize'));
    Name:='Î¢ÈíÑÅºÚ';
    Color:=$000000;
  end;
  BtnSetFont(btnOneKey, BtnOneKeyFont.Handle);
  BtnSetFontColor(btnOneKey,$000000,$000000,$000000,$000000);
  BtnSetEvent(btnOneKey,BtnClickEventID,WrapBtnCallback(@btnOneKey_OnClick,1));


  ExtractTemporaryFile('check.png');
  chkLicense :=BtnCreate(WizardForm.Handle,DpiScale(33),DpiScale(StrToInt(CustomMessage('positionTopLicense'))+2),
  DpiScale(15),DpiScale(15), ExpandConstant('{tmp}\check.png'),1, True);
  //BtnSetChecked(chkLicense, True);
  chkLicenseOnClick(chkLicense);
  BtnSetEvent(chkLicense,BtnClickEventID,WrapBtnCallback(@chkLicenseOnClick,1));

  lblAgree := TLabel.Create(WizardForm);
  with lblAgree do begin
    Parent := WizardForm;
    Caption := CustomMessage('haveReadLicense');
    Transparent := true;
    Font.Size:= 10
    Font.Name:='Î¢ÈíÑÅºÚ'
    Font.Color:=$000000
    Left := DpiScale(50);
    Top := DpiScale(StrToInt(CustomMessage('positionTopLicense')));
  end;

  lblLicense := TLabel.Create(WizardForm);
  with lblLicense do
  begin
    Parent := WizardForm;
    Caption := CustomMessage('userLicense');
    Transparent := true;
    Font.Size:= 10
    Font.Name:='Î¢ÈíÑÅºÚ'
    Font.Color:=$986800
    Left:= DpiScale(StrToInt(CustomMessage('positionLeftLicense')));
    Top := DpiScale(StrToInt(CustomMessage('positionTopLicense')));
    OnClick:=@lblLicenseClick;
    Cursor:=crHand;
  end;


  lblAboutTitle := TLabel.Create(WizardForm);
  with lblAboutTitle do
  begin
    Parent := WizardForm;
    Caption := CustomMessage('aboutTitle');
    Transparent := true;
    Font.Size:= 10
    Font.Name:='Î¢ÈíÑÅºÚ'
    Font.Color:=$000000
    Left:= DpiScale(StrToInt(CustomMessage('positionLeftAboutTitle')));
    Top := DpiScale(StrToInt(CustomMessage('positionTopAbout')));
  end;


  lblAboutHome := TLabel.Create(WizardForm);
  with lblAboutHome do
  begin
    Parent := WizardForm;
    Caption := CustomMessage('aboutHomePage');
    Transparent := true;
    Font.Size:= 10
    Font.Name:='Î¢ÈíÑÅºÚ'
    Font.Color:=$986800
    Left:= DpiScale(StrToInt(CustomMessage('positionLeftHomePage')));
    Top := DpiScale(StrToInt(CustomMessage('positionTopAbout')));
    OnClick:=@lblAboutHomeClick;
    Cursor:=crHand;
  end;


  lblAboutTypora := TLabel.Create(WizardForm);
  with lblAboutTypora do
  begin
    Parent := WizardForm;
    Caption := 'Typora';
    Transparent := true;
    Font.Size:= 10
    Font.Name:='Î¢ÈíÑÅºÚ'
    Font.Color:=$986800
    Left:= DpiScale(StrToInt(CustomMessage('positionLeftTypora')));
    Top := DpiScale(StrToInt(CustomMessage('positionTopAbout')));
    OnClick:=@lblAboutTyporaClick;
    Cursor:=crHand;
  end;

  HoverEvent_Init(@OnHoverControlChanged);
  //Ó¦ÓÃÒ³ÃæÐÞ¸Ä
  ImgApplyChanges(WizardForm.Handle);
end;

//Ò³Ãæ·¢Éú±ä»¯
procedure CurPageChanged(CurPageID: Integer);
var
  isWpReady,isWpFinished,isWpInstalling : boolean;
begin
  // Log(format( 'CurPageID id = %d',[ CurPageID ]));
  isWpReady      := CurPageID = wpReady;
  isWpFinished   := CurPageID = wpFinished;
  isWpInstalling := CurPageID = wpInstalling;

  BtnSetVisibility(btnClose,      isWpReady);
  BtnSetVisibility(btnOneKey,     isWpReady);
  BtnSetVisibility(chkLicense,    isWpReady);

  if isWpInstalling then
  begin
    TconSetVisible(lblAboutTypora,  isWpReady);
    TconSetVisible(lblAboutHome,    isWpReady);
    TconSetVisible(lblAboutTitle,   isWpReady);
    TconSetVisible(lblLicense,      isWpReady);
    TconSetVisible(lblAgree,        isWpReady);
  end;

  if isWpFinished then
  begin
    // Log('CurPageID = wpFinished');

    btnFinish:=BtnCreate(WizardForm.Handle,DpiScale(255),DpiScale(335),DpiScale(150), DpiScale(42), ExpandConstant('{tmp}\btnOneKeyInstall.png'),1,False)

    BtnSetText(btnFinish, CustomMessage('finishPageFinishBtn'));
    BtnOneKeyFont := TFont.Create;
    with BtnOneKeyFont do begin
      Size := StrToInt(CustomMessage('finishPageFinishBtnSize'));
      Name:='Î¢ÈíÑÅºÚ';
      Color:=$000000;
    end;
    BtnSetFont(btnFinish, BtnOneKeyFont.Handle);
    BtnSetFontColor(btnFinish,$000000,$000000,$000000,$000000);
    BtnSetEvent(btnFinish,BtnClickEventID,WrapBtnCallback(@btnFinish_OnClick,1));
  end;

  ImgApplyChanges(WizardForm.Handle);
end;


procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
begin
  // Log(Format('Done: %.2f %%', [(CurProgress * 100.0) / MaxProgress]));
  bgWelcome.Width:= 660*CurProgress*DpiScalePctg / MaxProgress/1000;

  ImgApplyChanges(WizardForm.Handle);

  TconSetVisible(lblAboutTypora,  False);
  TconSetVisible(lblAboutHome,    False);
  TconSetVisible(lblAboutTitle,   False);
  TconSetVisible(lblLicense,      False);
  TconSetVisible(lblAgree,        False);
end;