; === Network Script (AutoIt) ===
; Periodically connects to localhost:8080, sends "Ping", receives reply
; Silent version (no system sounds, no popups)

Opt("TCPTimeout", 5) ; 5 second timeout
Opt("TrayIconHide", 1) ; hides tray icon if compiled

; --- Startup ---
TCPStartup()

; Main loop
While 1
    Local $iSocket = TCPConnect("127.0.0.1", 8080)

    If @error Or $iSocket = -1 Then
        ; Connection failed - stay silent
    Else
        ; Send Ping
        If TCPSend($iSocket, "Ping") > 0 Then
            ; Receive response
            Local $sReply = TCPRecv($iSocket, 512)
            If $sReply <> "" Then
                ; Handle reply quietly (no sound, no popup)
                ; Example: log to console
                ConsoleWrite("Reply: " & $sReply & @CRLF)
            EndIf
        EndIf

        ; Close socket
        TCPCloseSocket($iSocket)
    EndIf

    ; Wait 5 minutes before next check
    Sleep(300000)
WEnd

; --- Shutdown (never reached in infinite loop, but good practice) ---
TCPShutdown()
