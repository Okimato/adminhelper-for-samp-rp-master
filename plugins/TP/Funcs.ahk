;;
;; TP Plugin for AdminHelper.ahk
;; Author: Danil Valov <danil@valov.me>
;;

class TP
{
  _playersList := []
  _playersListForCurrentTP := []
  _playersSMSList := []
  maxCountSMSPlayers := 0
  minSMSLVL := 1
  checkSMSInChatlog := 0
  __running := 0

  __nameDec(NumStr, OneItemName, TwoItemName, FiveItemName)
  {
    if ((SubStr(NumStr, StrLen(NumStr)) > 1) && (SubStr(NumStr, StrLen(NumStr)) < 5) && (!(SubStr(NumStr, StrLen(NumStr) - 1, 1) = 1))) {
      Return TwoItemName
    } else if((SubStr(NumStr, StrLen(NumStr)) = 1) && ((StrLen(NumStr) < 2) || (!(SubStr(NumStr, StrLen(NumStr) - 1, 1) = 1)))) {
      Return OneItemName
    } else {
      Return FiveItemName
    }
  }

  __hasValueInArray(Array, Value)
  {
    for Key, Val in Array {
      if (Val = Value) {
        Return Key
      }
    }
    Return 0
  }

  help()
  {
    addMessageToChatWindow("{A31515}[ ������� ��� ������������ ]")
    addMessageToChatWindow("{FFFF00}/atp [id] [id] {FFFFFF}- �������� id ������� ��� ������������")
    addMessageToChatWindow("{C4EFFF}������: {FFFFFF}/atp 1 2 4 {C4EFFF} - ������� � ������ �� ������� � ID 1, 2 � 4")
    addMessageToChatWindow("{FFFF00}/rtp [id] {FFFFFF}- ������� ������/������� �� ������ ������������")
    addMessageToChatWindow("{C4EFFF}������: {FFFFFF}/rtp 2 4 {C4EFFF} - ������� �� ������ �� ������� � ID 2 � 4")
    addMessageToChatWindow("{FFFF00}/ltp [����������] {FFFFFF}- ������ ���� ������� � ������ ������������ �� SMS")
    addMessageToChatWindow("{FFFFFF}(���� ���������� �� ������� - ���� ������� ���������� ����� ����� ����� ������ ������� �� ����� ������ ��� ����� /ltp �����)")
    addMessageToChatWindow("{FFFF00}/ntp [������] [minLVL-maxLVL] {FFFFFF}- �������� ����� ������� ������� � ������ ��")
    addMessageToChatWindow("{C4EFFF}������: {FFFFFF}/ntp 60 3 {C4EFFF} - ������� � ������ ���� ������� 3 ���� � ���� � ������� 60 ������ �� ���")
    addMessageToChatWindow("{FFFF00}/gtp {FFFFFF}- �������� ������ ������ ������� ��� ������������")
    addMessageToChatWindow("{FFFF00}/ctp {FFFFFF}- �������� ������ ������������")
    addMessageToChatWindow("{FFFF00}/stp {FFFFFF}- ������ ������������")
    
    Return
  }
  
  clearPlayersList()
  {
    this.stop()
    this.__smsStopAddingPlayersInList()

    if (this._playersList.MaxIndex() || this._playersSMSList.MaxIndex()) {
      this._playersList := []
      this._playersSMSList := []

      addMessageToChatWindow("{FFFF00}������ ������� ��� ������������ ������.")
    } else {
      addMessageToChatWindow("{FF0000}������ ������� ��� ��� ����.")
    }
  
    Return
  }

  addPlayersInList(Data)
  {
    this.__smsStopAddingPlayersInList()

    if (hardUpdateOScoreboardData()) {
      Count := 0

      addMessageToChatWindow("{FFFF00}��������� � ������ ������������ ��������� ������:")

      Loop, % (Data.MaxIndex() - 1)
      {
        Id := Trim(Data[A_Index + 1])
        Id := RegExReplace(Id, "[^0-9]", "")

        if (StrLen(Id)) {
          Count++

          PlayerNick := getPlayerNameById(Id)

          if (StrLen(PlayerNick)) {
            if (this.__hasValueInArray(this._playersList, Id)) {
              addMessageToChatWindow("{FF0000} " PlayerNick "[" Id "] ��� ���� � ������.")
            } else {
              this._playersList.Insert(Id)
              addMessageToChatWindow("{00D900} �������� ����� " PlayerNick "[" Id "].")
            }
          } else {
            addMessageToChatWindow("{FF0000} ����� � ID " Id " �� ������ � ����. �������� � �������� Tab, ����� ���� ���������� ��������� �������.")
          }
        }
      }

      if (Count < 1) {
        addMessageToChatWindow("{FF0000} �� ������� �� ������ ID. {FFFFFF}������� {FFFF00}/atp [id ������] [id ������� ������]")
      } else if (!this._playersList.MaxIndex()) {
        addMessageToChatWindow("{FF0000}������ ������������ ����.")
      } else {
        addMessageToChatWindow("{FFFFFF}" (this._playersList.MaxIndex() > 1 ? "����� ����� ���������������:" : "����� ��������������") " " this._playersList.MaxIndex() " " this.__nameDec(this._playersList.MaxIndex(), "�����", "������", "�������") ".")
      }
    }

    Return
  }

  removePlayersFromList(Data)
  {
    hardUpdateOScoreboardData()

    Count := 0

    Loop, % (Data.MaxIndex() - 1)
    {
      Id := Trim(Data[A_Index + 1])
      Id := RegExReplace(Id, "[^0-9]", "")

      if (StrLen(Id)) {
        Count++

        Index := this.__hasValueInArray(this._playersList, Id)

        if (Index) {
          this._playersList.RemoveAt(Index)
          PlayerNick := getPlayerNameById(Id)
          if (StrLen(PlayerNick)) {
           addMessageToChatWindow("{FF0000} " PlayerNick "[" Id "] ����� �� ������ ������������.")
          } else {
           addMessageToChatWindow("{FF0000} ����� � ID " Id " ����� �� ������ ������������.")
          }
        } else {
          addMessageToChatWindow("{FF0000} ������ � ID " Id " ��� � ������ ������������.")
        }
      }
    }

    if (Count < 1) {
      addMessageToChatWindow("{FF0000} �� ������� �� ������ ID. {FFFFFF}������� {FFFF00}/rtp [id ������ �� ������ ������������] [id ������� ������ �� ������ ������������]")
    }

    Return
  }

  startAddingPlayersInListFromSMS(Data)
  {
    this.stop()

    if (!this.checkSMSInChatlog) {
      if (this._playersList.MaxIndex()) {
        this.clearPlayersList()
      }

      Chatlog.reader()

      hardUpdateOScoreboardData()

      this.maxCountSMSPlayers := 0

      CountSMSPlayers := 0
      if (StrLen(Trim(Data[2])) && StrLen(RegExReplace(Trim(Data[2]), "[^0-9]", ""))) {
        CountSMSPlayers := Trim(Data[2])
        CountSMSPlayers := RegExReplace(CountSMSPlayers, "[^0-9]", "")
      }
      if (CountSMSPlayers) {
        this.maxCountSMSPlayers := CountSMSPlayers
      }

      this.minSMSLVL := 1

      MinLVL := 1
      if (StrLen(Trim(Data[3])) && StrLen(RegExReplace(Trim(Data[3]), "[^0-9]", ""))) {
        MinLVL := Trim(Data[3])
        MinLVL := RegExReplace(MinLVL, "[^0-9]", "")
      }
      if (MinLVL) {
        this.minSMSLVL := MinLVL
      }

      addMessageToChatWindow("{FFFF00}���������� ������������ ������� �� SMS.")
      this.checkSMSInChatlog := 1

      SetTimer, TPSMSTimer, 1200

      Chatlog.startTimer()
    } else {
      this.__smsStopAddingPlayersInList()
    }

    Return
  }

  __smsStopAddingPlayersInList()
  {
    if (this.checkSMSInChatlog) {
      Chatlog.stopTimer()

      this.checkSMSInChatlog := 0
      maxCountPlayersInList := this._playersList.MaxIndex() ? this._playersList.MaxIndex() : 0
      maxCountSMSPlayersToStop := (TP.maxCountSMSPlayers ? "/" TP.maxCountSMSPlayers " " this.__nameDec(TP.maxCountSMSPlayers, "�����", "������", "�������") : " " this.__nameDec(maxCountPlayersInList, "�����", "������", "�������"))

      addMessageToChatWindow("{FFFF00}������������ ������� �� SMS ���� ����������� [ � ������ " maxCountPlayersInList maxCountSMSPlayersToStop " ].")
    }

    Return
  }

  addNearPlayersInList(Data)
  {
    this.stop()
    this.__smsStopAddingPlayersInList()

    if (this._playersList.MaxIndex()) {
      this.clearPlayersList()
    }

    Sleep 500

    if (!StrLen(Data[3])) {
      Data[3] := 2
    }

    this._playersList := NearbyPlayers.get(Data)

    Return
  }

  showPlayersList()
  {
    this.__smsStopAddingPlayersInList()

    hardUpdateOScoreboardData()

    Count := 1

    addMessageToChatWindow("{FFFF00}������ ������� ��� ������������:")

    Loop, % this._playersList.MaxIndex()
    {
      Id := this._playersList[Count]
      PlayerNick := getPlayerNameById(Id)

      if (StrLen(PlayerNick)) {
        addMessageToChatWindow("{00D900} " PlayerNick "[" Id "]")

        Count++
      } else {
        this._playersList.RemoveAt(Count)

        addMessageToChatWindow("{FF0000} ����� � ID " Id " �� ������ � ���� � ��� �����.")
      }
    }

    if (!this._playersList.MaxIndex()) {
      addMessageToChatWindow("{FF0000}������ ������������ ����.")
    } else {
      addMessageToChatWindow("{FFFFFF}�����: " this._playersList.MaxIndex() " " this.__nameDec(this._playersList.MaxIndex(), "�����", "������", "�������") ".")
    }

    Return
  }

  start()
  {
    if (!this.__running) {
      this.__running := 1
      this.__smsStopAddingPlayersInList()

      if (!this._playersList.MaxIndex()) {
        addMessageToChatWindow("{FF0000}� ������ ������������ ��� �� ������ ������.")

        Return
      }

      addMessageToChatWindow("{FFFF00}������������ ��������")

      this._playersListForCurrentTP := this._playersList.Clone()

      SetTimer, TPTimer, 1200
    } else {
      this.stop()

      addMessageToChatWindow("{FF0000}������������ ������������� ���������.")
    }

    Return
  }

  stop()
  {
    if (this.__running) {
      this.__running := 0
    }

    Return
  }

  setTP(Data)
  {
    X := RegExReplace(Data[2], "[^0-9`-.]", "")
    Y := RegExReplace(Data[3], "[^0-9`-.]", "")
    Z := RegExReplace(Data[4], "[^0-9`-.]", "")
    Interior := RegExReplace(Data[5], "[^0-9`-.]", "")

    if (!StrLen(Interior)) {
      Interior := getPlayerInteriorId()
    }

    if (StrLen(X) && StrLen(Y) && StrLen(Z)) {
      Sleep 800

      setCoordinates(X, Y, Z, Interior)

      Sleep 100

      sendChatMessage("/goto " getId())
    } else {
      addMessageToChatWindow("{FF0000}�������� ������. {FFFFFF}�������: {FFFF00}/gotp [x-����������] [y-����������] [z-����������] [id ���������]")
    }

    Return
  }

  timerTPFromSMS()
  {
    if (this.checkSMSInChatlog || this._playersSMSList.MaxIndex()) {
      if (this._playersSMSList.MaxIndex()) {
        sendChatMessage("/gethere " this._playersSMSList[1])

        showGameText("Teleporting [ID: " this._playersSMSList[1] "] [" (this._playersList.MaxIndex() + 1 - this._playersSMSList.MaxIndex()) "/" this._playersList.MaxIndex() "]", 1200, 4)

        this._playersSMSList.RemoveAt(1)
      }
    } else {
      SetTimer, TPSMSTimer, Off
    }

    Return
  }

  timerTPFromList()
  {
    if (this.__running && this._playersListForCurrentTP.MaxIndex()) {
      sendChatMessage("/gethere " this._playersListForCurrentTP[1])

      showGameText("Teleporting [ID: " this._playersListForCurrentTP[1] "] [" (this._playersList.MaxIndex() + 1 - this._playersListForCurrentTP.MaxIndex()) "/" this._playersList.MaxIndex() "]", 1200, 4)

      this._playersListForCurrentTP.RemoveAt(1)
    } else {
      this.stop()

      SetTimer, TPTimer, Off

      if (!this._playersListForCurrentTP.MaxIndex()) {
        addMessageToChatWindow("{FFFF00}������������ ���������.")
      } else {
        this._playersListForCurrentTP := []
      }
    }

    Return
  }
}

TP := new TP()


CMD.commands["atp"] := "TP.addPlayersInList"
CMD.commands["rtp"] := "TP.removePlayersFromList"
CMD.commands["ltp"] := "TP.startAddingPlayersInListFromSMS"
CMD.commands["ntp"] := "TP.addNearPlayersInList"
CMD.commands["gtp"] := "TP.showPlayersList"
CMD.commands["ctp"] := "TP.clearPlayersList"
CMD.commands["stp"] := "TP.start"
CMD.commands["tphelp"] := "TP.help"
CMD.commands["helptp"] := "TP.help"
CMD.commands["htp"] := "TP.help"
CMD.commands["gotp"] := "TP.setTP"


TPSMSChatlogChecker(ChatlogString)
{
  if (TP.checkSMSInChatlog && SubStr(ChatlogString, 2, 5) = "SMS: " && InStr(ChatlogString, ". �����������: ")) {
    RegExMatch(SubStr(ChatlogString, StrLen(ChatlogString) - 3), "(\d){1,3}", Id)

    if ((!TP.maxCountSMSPlayers || TP._playersList.MaxIndex() <= TP.maxCountSMSPlayers) && StrLen(Id) > 0) {
      if (!TP.__hasValueInArray(TP._playersSMSList, Id)) {
        PlayerNick := SubStr(ChatlogString, InStr(ChatlogString, ". �����������: ") + StrLen(". �����������: "))
        PlayerNick := SubStr(PlayerNick, 1, InStr(PlayerNick, "[") - 1)

        if (checkInIgnoreList(PlayerNick)) {
          addMessageToChatWindow("{FF0000} " PlayerNick "[" Id "] �������� (��������� � �����-�����).")
        } else if (getPlayerScoreById(Id) < TP.minSMSLVL) {
          addMessageToChatWindow("{FF0000} " PlayerNick "[" Id "] �������� (�� �������� �� LVL).")
        } else {
          if (!TP.__hasValueInArray(TP._playersList, Id)) {
            TP._playersList.Insert(Id)
          }
          TP._playersSMSList.Insert(Id)
          maxCountSMSPlayersToStop := (TP.maxCountSMSPlayers ? "/" TP.maxCountSMSPlayers : "")
          addMessageToChatWindow("{00D900}[" TP._playersList.MaxIndex() maxCountSMSPlayersToStop "] �������� ����� " PlayerNick "[" Id "]")
        }
      }

      if (TP.maxCountSMSPlayers && TP._playersList.MaxIndex() == TP.maxCountSMSPlayers) {
        addMessageToChatWindow("{FFFF00}���� ������� �� SMS ��� ������������ �������� [" TP._playersList.MaxIndex() " " TP.__nameDec(TP._playersList.MaxIndex(), "�����", "������", "�������") "]")
        TP.checkSMSInChatlog := 0
      }
    }
  }
}

Chatlog.checker.Insert("TPSMSChatlogChecker")
