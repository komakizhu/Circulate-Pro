Unicode true
RequestExecutionLevel admin
!ifndef CIRCULATE_VERSION
  !define CIRCULATE_VERSION "3.1.0.0"
!endif
!ifndef PRODUCT_NAME
  !define PRODUCT_NAME "Circulate Pro"
!endif
Name "${PRODUCT_NAME} VST3 ${CIRCULATE_VERSION}"
OutFile "${OUTFILE}"
InstallDir "$PROGRAMFILES64\Common Files\VST3\Circulate.vst3"
InstallDirRegKey HKLM "Software\GullDSP\Circulate" "InstallDir"
Icon "${PLUGIN_ICON}"
ShowInstDetails show
ShowUninstDetails show

VIProductVersion "${CIRCULATE_VERSION}"
VIAddVersionKey "ProductName" "${PRODUCT_NAME} VST3"
VIAddVersionKey "CompanyName" "GullDSP"
VIAddVersionKey "LegalCopyright" "GPL-3.0"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} VST3 Windows Installer"
VIAddVersionKey "FileVersion" "${CIRCULATE_VERSION}"

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

Section "${PRODUCT_NAME} VST3" SEC_MAIN
  SetOutPath "$INSTDIR\Contents"
  File /r "${PLUGIN_STAGE}\Contents\*"
  SetOutPath "$INSTDIR"
  File "${PLUGIN_STAGE}\desktop.ini"
  File "${PLUGIN_STAGE}\PlugIn.ico"
  SetRegView 64
  WriteRegStr HKLM "Software\GullDSP\Circulate" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall Circulate Pro.exe"
SectionEnd

Section "Uninstall"
  SetRegView 64
  Delete "$INSTDIR\Uninstall Circulate Pro.exe"
  RMDir /r "$INSTDIR\Contents"
  Delete "$INSTDIR\desktop.ini"
  Delete "$INSTDIR\PlugIn.ico"
  RMDir "$INSTDIR"
  DeleteRegKey HKLM "Software\GullDSP\Circulate"
SectionEnd
