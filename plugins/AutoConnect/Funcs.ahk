;;
;; AutoConnect Plugin for AdminHelper.ahk
;; Author: Danil Valov <danil@valov.me>
;;

class AutoConnect
{
  _checkerRunning := 0

  _serversList := []

  _serverIP := ""
  _configFile := "AutoConnectConfig.ini"
  _sampFile := ""
  _chatlogFile := ""

  _nickName := ""
  _autoConnectOnStartup := 0
  _saveChatlog := 0

  __stringJoin(Array, Delimiter = ";")
  {
    Result =
    Loop
      If Not Array[A_Index] Or Not Result .= (Result ? Delimiter : "") Array[A_Index]
        Return Result
  }

  checkOpenedSAMP()
  {
    Return !(!refreshGTA() || !refreshSAMP() || !refreshMemory())
  }

  serversListRead()
  {
    Global Config

    this._serversList := []
    ServerName =

    FileRead, Contents, % Config["plugins"]["Connect"]["ServersFile"]
    if not ErrorLevel
    {
      Loop, Parse, Contents, `n, `r
      {
        Line := Trim(A_LoopField)
        if (StrLen(Line)) {
          RegExMatch(Line, "(\d){1,3}.(\d){1,3}.(\d){1,3}.(\d){1,3}", IP)

          if (SubStr(Line, 1, 1) = "[" && SubStr(Line, 0) = "]") {
            ServerName := SubStr(Line, 2, -1)
          } else if (StrLen(IP) && IP = Line && StrLen(ServerName)) {
            ServerObject := {}
            ServerObject["name"] := StrReplace(ServerName, "|", "-")
            ServerObject["ip"] := IP
            this._serversList.Insert(ServerObject)
            ServerName := ""
          }
        }
      }

      if (this._serversList.MaxIndex()) {
        this._serverIP := this._serversList[1].ip
      }
    } else {
      MsgBox, ������: �� ������ ������� ���� �� ������� ��������

      Return False
    }

    Return True
  }

  getNickName()
  {
    RegRead, NickName, HKEY_CURRENT_USER\Software\SAMP, PlayerName

    this._nickName := NickName

    Return
  }

  getPathToSAMPFile()
  {
    RegRead, PathToSAMPFile, HKEY_CLASSES_ROOT\samp\shell\open\command

    PathToSAMPFile := SubStr(PathToSAMPFile, 2, InStr(PathToSAMPFile, "%") - 5)

    if (FileExist(PathToSAMPFile)) {
      this._sampFile := PathToSAMPFile
    }

    Return
  }

  getPathToChatlogFile()
  {
    PathToChatlogFile = %A_MyDocuments%\GTA San Andreas User Files\SAMP\chatlog.txt

    if (FileExist(PathToChatlogFile)) {
      this._chatlogFile := PathToChatlogFile
    }

    Return
  }

  selectSAMPFile(SAMPFile)
  {
    this._sampFile := SAMPFile
    GuiControl, AutoConnect:, AutoConnectSAMPFile, %SAMPFile%

    Return
  }

  selectChatlogFile(ChatlogFile)
  {
    this._chatlogFile := ChatlogFile
    GuiControl, AutoConnect:, AutoConnectChatlogFile, %ChatlogFile%

    Return
  }

  getServerIPByName(ServerName)
  {
    Loop, % this._serversList.MaxIndex()
    {
      if (this._serversList[A_Index].name = ServerName) {
        Return this._serversList[A_Index].ip
      }
    }

    Return False
  }

  getServerNameByIP(IP)
  {
    Loop, % this._serversList.MaxIndex()
    {
      if (this._serversList[A_Index].ip = IP) {
        Return this._serversList[A_Index].name
      }
    }

    Return False
  }

  getServerIndexByIP(IP)
  {
    Loop, % this._serversList.MaxIndex()
    {
      if (this._serversList[A_Index].ip = IP) {
        Return A_Index
      }
    }

    Return False
  }

  getConfig()
  {
    IniRead, LocalSAMPFile, % this._configFile, Connect, SAMPFile, % this._sampFile
    IniRead, LocalChatlogFile, % this._configFile, Connect, ChatlogFile, % this._chatlogFile
    IniRead, LocalNickName, % this._configFile, Connect, NickName, % this._nickName
    IniRead, LocalServerIP, % this._configFile, Connect, ServerIP, % this._serverIP
    IniRead, LocalAutoConnectOnStartup, % this._configFile, Connect, AutoConnectOnStartup, % this._autoConnectOnStartup
    IniRead, LocalSaveChatlog, % this._configFile, Connect, SaveChatlog, % this._saveChatlog

    this._sampFile := LocalSAMPFile
    this._chatlogFile := LocalChatlogFile
    this._nickName := LocalNickName
    this._serverIP := LocalServerIP
    this._autoConnectOnStartup := LocalAutoConnectOnStartup
    this._saveChatlog := LocalSaveChatlog

    Return
  }

  saveConfig()
  {
    IniWrite, % this._sampFile, % this._configFile, Connect, SAMPFile
    IniWrite, % this._chatlogFile, % this._configFile, Connect, ChatlogFile
    IniWrite, % this._nickName, % this._configFile, Connect, NickName
    IniWrite, % this._serverIP, % this._configFile, Connect, ServerIP
    IniWrite, % this._autoConnectOnStartup, % this._configFile, Connect, AutoConnectOnStartup
    IniWrite, % this._saveChatlog, % this._configFile, Connect, SaveChatlog

    Return
  }

  generateGUI(Force := 0, Startup := 0)
  {
    Global

    this.serversListRead()
    this.getNickName()
    this.getPathToSAMPFile()
    this.getPathToChatlogFile()

    this.getConfig()

    Local NameServersList := []

    Local LocalServerIndex := 1

    Loop, % this._serversList.MaxIndex()
    {
      if (this._serversList[A_Index].ip = this._serverIP) {
        LocalServerIndex := A_Index
      }

      NameServersList.Insert(this._serversList[A_Index].name)
    }

    Gui, AutoConnect:New

    Gui, AutoConnect:Default

    Gui, AutoConnect:+LastFound

    Gui, AutoConnect:Add, Text, +Wrap w320 x10 y+15, ���:
    Gui, AutoConnect:Add, Edit, w150 vAutoConnectNickName, % this._nickName

    Gui, AutoConnect:Add, Text, +Wrap w320 x10 y+10, ������:
    Gui, AutoConnect:Add, DropDownList, w320 vAutoConnectServerName, % this.__stringJoin(NameServersList, "|")
    GuiControl, ChooseString, AutoConnectServerName, % NameServersList[LocalServerIndex]

    Gui, AutoConnect:Add, Text, +Wrap w320 y+15, ���� �� ����� `samp.exe`:
    Gui, AutoConnect:Add, Edit, w268 h20 +ReadOnly vAutoConnectSAMPFile, % this._sampFile
    Gui, AutoConnect:Add, Button, x+10 h20 gAutoConnectSAMPFileBrowse, �����

    Gui, AutoConnect:Add, Text, +Wrap w320 x10 y+10, ���� �� ����� `chatlog.txt`:
    Gui, AutoConnect:Add, Edit, w268 h20 +ReadOnly vAutoConnectChatlogFile, % this._chatlogFile
    Gui, AutoConnect:Add, Button, x+10 h20 gAutoConnectChatlogFileBrowse, �����

    Gui, AutoConnect:Tab

    Gui, AutoConnect:Add, Checkbox, w320 y+21 x10 vAutoConnectOnStartup, ������������ ������������� ��� �������
    GuiControl, , AutoConnectOnStartup, % this._autoConnectOnStartup

    Gui, AutoConnect:Add, Checkbox, w320 y+10 x10 vAutoConnectSaveChatlog, ��������� ������� ���������
    GuiControl, , AutoConnectSaveChatlog, % this._saveChatlog

    Gui, AutoConnect:Add, Button, x200 y+25 gAutoConnectConnect, % !checkHandles() ? "������������" : "���������"
    Gui, AutoConnect:Add, Button, x+10 gAutoConnectClose, �������

    if (!Force && this._autoConnectOnStartup && this.connect(Startup)) {
      Return
    }

    if ((!this.checkOpenedSAMP() || !Startup) && (!this._autoConnectOnStartup || !Startup)) {
      Gui, AutoConnect:Show, h341, ����������� � SAMP-RP
    }
  }

  connect(Startup := 0)
  {
    LocalSAMPFile := this._sampFile

    GuiControlGet, AutoConnectNickName
    GuiControlGet, AutoConnectServerName
    GuiControlGet, AutoConnectOnStartup
    GuiControlGet, AutoConnectSaveChatlog

    AutoConnectNickName := Trim(AutoConnectNickName)

    RegExMatch(AutoConnectNickName, "([a-zA-Z0-9\_]){3,20}", NickName)

    AutoConnectServerIP := this.getServerIPByName(AutoConnectServerName)

    if (StrLen(LocalSAMPFile) && StrLen(this._chatlogFile) && StrLen(NickName) && NickName = AutoConnectNickName && AutoConnectServerIP && !this.checkOpenedSAMP()) {
      this._nickName := AutoConnectNickName
      this._serverIP := AutoConnectServerIP
      this._autoConnectOnStartup := AutoConnectOnStartup
      this._saveChatlog := AutoConnectSaveChatlog

      LocalServer := this._serverIP
      LocalNickName := this._nickName

      Chatlog.__chatlogFilePath := this._chatlogFile

      this.saveConfig()

      if (this._saveChatlog) {
        ChatlogDirectory := this._chatlogFile
        ChatlogDirectoryEx := StrSplit(ChatlogDirectory, "\")
        ChatlogDirectory := SubStr(ChatlogDirectory, 1, InStr(ChatlogDirectory, ChatlogDirectoryEx[ChatlogDirectoryEx.MaxIndex()]) - 1)
        ChatlogLogsDirectory := ChatlogDirectory "logs"

        IfNotExist, %ChatlogLogsDirectory%
          FileCreateDir, %ChatlogLogsDirectory%

        FileGetTime, ChatlogModificationTime, % this._chatlogFile, M

        FileCopy, % this._chatlogFile, %ChatlogLogsDirectory%\%ChatlogModificationTime%.txt
      }

      Gui, AutoConnect:Destroy

      ServerIndexByIP := this.getServerIndexByIP(this._serverIP)

      Return True
    } else if (!StrLen(LocalSAMPFile)) {
      MsgBox, �� �� ������� ���� �� ����� `samp.exe`
    } else if (!StrLen(this._chatlogFile)) {
      MsgBox, �� �� ������� ���� �� ����� `chatlog.txt`
    } else if (!StrLen(AutoConnectNickName)) {
      MsgBox, �� �� ������� ��� ���
    } else if (!AutoConnectServerIP) {
      MsgBox, �� �� ������� ������ ��� �����������
    } else if (!Startup) {
      this._nickName := AutoConnectNickName
      this._serverIP := AutoConnectServerIP
      this._autoConnectOnStartup := AutoConnectOnStartup
      this._saveChatlog := AutoConnectSaveChatlog

      this.saveConfig()

      MsgBox, ��������� ������� ���������
    } else if (Startup) {
      Gui, AutoConnect:Destroy

      Return True
    }

    Return False
  }

  init()
  {
    this.generateGUI(0, 1)

    Menu, Tray, Add, �����������, AutoConnectGUIOpen
    Menu, Tray, Add

    Return
  }
}

AutoConnect := new AutoConnect()


AutoConnectChecker(ChatlogString)
{
  if (AutoConnect._checkerRunning && StrLen(AutoConnect._serverIP) && InStr(ChatlogString, "Connecting to ")) {
    Sleep 700

    connect(AutoConnect._serverIP)

    Chatlog.stopTimer()
    AutoConnect._checkerRunning := 0
  } else if (AutoConnect._checkerRunning && !StrLen(AutoConnect._serverIP)) {
    Chatlog.stopTimer()
    AutoConnect._checkerRunning := 0
  }
}

Chatlog.checker.Insert("AutoConnectChecker")

AutoConnect.init()
