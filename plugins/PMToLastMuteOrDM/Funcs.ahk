;;
;; PMToLastMuteOrDM Plugin for AdminHelper.ahk
;; Author: Danil Valov <danil@valov.me>
;;

PMToLastMuteOrDM =

PMToLastMuteOrDMChatlogChecker(ChatlogString)
{
  global PMToLastMuteOrDM

  LocalNickName := getUsername()

  NickName :=

  if (StrLen(LocalNickName)) {
    if (InStr(ChatlogString, "������������� " LocalNickName) && InStr(ChatlogString, " ������� � ��������")) {
      NickName := SubStr(ChatlogString, InStr(ChatlogString, " ������� � �������� ") + StrLen(" ������� � �������� "))
      NickName := SubStr(NickName, 1, InStr(NickName, ",") - 1)
      NickName := Trim(NickName)
    } else if (InStr(ChatlogString, " ������� ��� ���� �� �������������� " LocalNickName)) {
      NickName := SubStr(ChatlogString, 2, InStr(ChatlogString, " �������") - 2)
      NickName := Trim(NickName)
    } else if (InStr(ChatlogString, "������������� " LocalNickName " ���� ��� ���� � ")) {
      NickName := SubStr(ChatlogString, InStr(ChatlogString, "���� ��� ���� �") + StrLen("���� ��� ���� �") + 1)
      NickName := Trim(NickName)
    } else if (SubStr(ChatlogString, 2, StrLen("�� ��������")) = "�� ��������") {
      NickName := SubStr(ChatlogString, StrLen("�� ��������") + 3)
      NickName := SubStr(NickName, 1, InStr(NickName, "��") - 2)
      NickName := Trim(NickName)
    }
  }

  if (StrLen(NickName)) {
    RegExMatch(NickName, "\[(\d){1,3}]", Ids)

    if (StrLen(Ids)) {
      Id := SubStr(Ids, 2, -1)
    } else if (StrLen(NickName)) {
      Id := getPlayerIdByName(NickName)
    }

    if (!StrLen(Id) && StrLen(NickName) >= 0) {
      hardUpdateOScoreboardData()
      Sleep 500
      Id := getPlayerIdByName(NickName)
    }

    if (StrLen(Id) && Id >= 0) {
      PMToLastMuteOrDM := Id
    }
  }
}

Chatlog.checker.Insert("PMToLastMuteOrDMChatlogChecker")

HotKeyRegister(Config["plugins"]["PMToLastMuteOrDM"]["Key"], "PMToLastMuteOrDMHotKey")
