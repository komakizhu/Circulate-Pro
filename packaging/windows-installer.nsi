Unicode true
RequestExecutionLevel admin
Name "Circulate VST3"
OutFile "${OUTFILE}"
InstallDir "$PROGRAMFILES64\Common Files\VST3\Circulate.vst3"
InstallDirRegKey HKLM "Software\GullDSP\Circulate" "InstallDir"
Icon "${PLUGIN_ICON}"
ShowInstDetails show
ShowUninstDetails show

VIProductVersion "2.0.1.1"
VIAddVersionKey "ProductName" "Circulate VST3"
VIAddVersionKey "CompanyName" "GullDSP"
VIAddVersionKey "LegalCopyright" "GPL-3.0"
VIAddVersionKey "FileDescription" "Circulate VST3 Windows Installer"
VIAddVersionKey "FileVersion" "2.0.1.1"

!include "MUI2.nsh"
!define MUI_ABORTWARNING
!define MUI_ICON "${PLUGIN_ICON}"
!define MUI_UNICON "${PLUGIN_ICON}"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Circulate VST3" SEC_MAIN
  SetOutPath "$INSTDIR"
  File /r "${PLUGIN_STAGE}\Contents"
  File "${PLUGIN_STAGE}\desktop.ini"
  File "${PLUGIN_STAGE}\PlugIn.ico"
  WriteRegStr HKLM "Software\GullDSP\Circulate" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall Circulate.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\Uninstall Circulate.exe"
  RMDir /r "$INSTDIR\Contents"
  Delete "$INSTDIR\desktop.ini"
  Delete "$INSTDIR\PlugIn.ico"
  RMDir "$INSTDIR"
  DeleteRegKey HKLM "Software\GullDSP\Circulate"
SectionEnd
