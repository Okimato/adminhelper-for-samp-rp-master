;;
;; AutoHP Plugin for AdminHelper.ahk
;; Author: Danil Valov <danil@valov.me>
;;

class AutoHP
{
  __starting := 0
  __running := 0

  start()
  {
    global Config

    if (!this.__starting) {
      this.__starting := 1

      SetTimer, AutoHPTimer, % (Config["plugins"]["AutoHP"]["Timeout"] * 1000)

      addMessageToChatWindow("{FFFF00}�������������� ���������� HP ��������")
    }

    Return
  }

  stop()
  {
    if (this.__starting) {
      this.__starting := 0

      SetTimer, AutoHPTimer, Off

      addMessageToChatWindow("{FF0000}�������������� ���������� HP �����������")
    }

    Return
  }

  toggle()
  {
    if (!this.__starting) {
      this.start()
    } else {
      this.stop()
    }

    Return
  }

  changeMinHP(Data)
  {
    global Config

    NewMinHP := RegExReplace(Data[2], "[^0-9]", "")

    if (StrLen(NewMinHP) && NewMinHP >= 1 && NewMinHP < 100) {
      Config["plugins"]["AutoHP"]["MinHP"] := NewMinHP
    } else {
      if (!StrLen(NewMinHP)) {
        addMessageToChatWindow("{FF0000}�� �� ������� ������������ ���������� HP.")
      } else {
        addMessageToChatWindow("{FF0000}�� ������� ������������ �������� ���������� HP. ���������� �������� - �� 1 �� 99.")
      }
    }

    Return
  }

  changeTime(Data)
  {
    global Config

    NewTime := RegExReplace(Data[2], "[^0-9]", "")

    if (StrLen(NewTime)) {
      Config["plugins"]["AutoHP"]["Timeout"] := NewTime

      if (!this.__starting) {
        this.start()
      } else {
        SetTimer, AutoHPTimer, % (Config["plugins"]["AutoHP"]["Timeout"] * 1000)

        addMessageToChatWindow("{FFFF00}�������� �������� HP �������. ������ HP ����� ����������� ������ " NewTime " ������(�)")
      }
    } else {
      addMessageToChatWindow("{FF0000}�� �� ������� ���������� ������")
    }

    Return
  }

  timer()
  {
    global Config

    if (getPlayerHealth() > -1 && getPlayerHealth() < Config["plugins"]["AutoHP"]["MinHP"]) {
      sendChatMessage("/hp")
      if (Config["plugins"]["AutoHP"]["MessageBoolean"]) {
        addMessageToChatWindow("{FFFF00}����� HP �������� �������������")
      }
    }

    Return
  }
}

AutoHP := new AutoHP()

if (Config["plugins"]["AutoHP"]["AutostartBoolean"]) {
  AutoHP.start()
}

CMD.commands["ahp"] := "AutoHP.toggle"
CMD.commands["autohp"] := "AutoHP.toggle"
CMD.commands["ahptime"] := "AutoHP.changeTime"
CMD.commands["ahpmin"] := "AutoHP.changeMinHP"
