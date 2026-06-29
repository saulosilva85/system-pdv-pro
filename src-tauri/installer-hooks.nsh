; Hooks NSIS do System PDV PRO
; ---------------------------------------------------------------------------
; Tauri/NSIS so remove os arquivos que ele mesmo instalou. Arquivos criados
; em tempo de execucao (logs, node_modules descompactado, etc.) e a propria
; pasta ficavam para tras em "C:\Program Files\System PDV PRO", o que gerava
; erro ao reinstalar. Aqui forcamos a remocao completa da pasta.

!macro NSIS_HOOK_PREUNINSTALL
  ; Encerra o app (e, via /T, o servidor Node filho) caso esteja aberto, para
  ; nao deixar arquivos travados. Nao matamos node.exe globalmente para nao
  ; afetar outros processos Node do usuario.
  nsExec::Exec 'taskkill /F /IM "System PDV PRO.exe" /T'
  Sleep 800
!macroend

!macro NSIS_HOOK_POSTUNINSTALL
  ; Remove a pasta de instalacao inteira (inclui arquivos criados em runtime).
  RMDir /r "$INSTDIR"
!macroend
