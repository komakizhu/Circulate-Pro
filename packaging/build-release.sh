#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${CIRCULATE_OUTPUT_DIR:-${PROJECT_DIR}/outputs}"
VERSION="${CIRCULATE_VERSION:-2.0.0}"
VST3_SOURCE="${CIRCULATE_VST3_SOURCE:-${OUTPUT_DIR}/Circulate.vst3}"
AU_SOURCE="${CIRCULATE_AU_SOURCE:-${OUTPUT_DIR}/Circulate.component}"
APPLICATION_IDENTITY="${CIRCULATE_DEVELOPER_ID_APPLICATION:-}"
INSTALLER_IDENTITY="${CIRCULATE_DEVELOPER_ID_INSTALLER:-}"
NOTARY_PROFILE="${CIRCULATE_NOTARY_PROFILE:-}"

PKG_NAME="Circulate-macOS-${VERSION}-Universal.pkg"
DMG_NAME="Circulate-macOS-${VERSION}-Universal.dmg"
FINAL_PKG="${OUTPUT_DIR}/${PKG_NAME}"
FINAL_DMG="${OUTPUT_DIR}/${DMG_NAME}"
FINAL_DMG_SHA="${FINAL_DMG}.sha256"
DMG_README_NAME="1 README.txt"
DMG_INSTALLER_NAME="2 Install Circulate.pkg"
DMG_COPYRIGHT_NAME="3 版权文件夹"
DMG_UNINSTALLER_NAME="4 Circulate Uninstaller.app"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This release builder requires macOS." >&2
    exit 1
fi

for required_path in "${VST3_SOURCE}" "${AU_SOURCE}" "${PROJECT_DIR}/work/Circulate-VST/LICENSE.txt"; do
    if [[ ! -e "${required_path}" ]]; then
        echo "Missing required input: ${required_path}" >&2
        exit 1
    fi
done

if [[ -L "${AU_SOURCE}/Contents/Resources/plugin.vst3" ]]; then
    echo "The AU bundle contains a VST3 symlink; refusing to package it." >&2
    exit 1
fi

verify_universal_bundle() {
    local bundle="$1"
    local require_signature="${2:-0}"
    local binary="${bundle}/Contents/MacOS/Circulate"

    [[ -d "${bundle}" ]] || { echo "Not a bundle: ${bundle}" >&2; exit 1; }
    [[ -f "${binary}" ]] || { echo "Missing executable: ${binary}" >&2; exit 1; }
    /usr/bin/lipo "${binary}" -verify_arch arm64 x86_64
    if ! /usr/bin/codesign --verify --deep --strict "${bundle}"; then
        if [[ "${require_signature}" == "1" ]]; then
            echo "Code signature verification failed: ${bundle}" >&2
            exit 1
        fi
        echo "Warning: input bundle is not fully bundle-signed; it will be signed in the package staging area." >&2
    fi
}

verify_universal_bundle "${VST3_SOURCE}"
verify_universal_bundle "${AU_SOURCE}"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/circulate-release.XXXXXX")"
trap 'rm -rf "${WORK_DIR}"' EXIT

PACKAGE_ROOT="${WORK_DIR}/package-root"
PACKAGE_SCRIPTS="${WORK_DIR}/package-scripts"
DMG_ROOT="${WORK_DIR}/dmg-root"
COPYRIGHT_DIR="${DMG_ROOT}/${DMG_COPYRIGHT_NAME}"
UNSIGNED_PKG="${WORK_DIR}/Circulate-unsigned.pkg"
STAGED_VST3="${PACKAGE_ROOT}/Library/Audio/Plug-Ins/VST3/Circulate.vst3"
STAGED_AU="${PACKAGE_ROOT}/Library/Audio/Plug-Ins/Components/Circulate.component"

mkdir -p "${PACKAGE_ROOT}/Library/Audio/Plug-Ins/VST3"
mkdir -p "${PACKAGE_ROOT}/Library/Audio/Plug-Ins/Components"
mkdir -p "${PACKAGE_SCRIPTS}"
mkdir -p "${DMG_ROOT}"
mkdir -p "${COPYRIGHT_DIR}"

/usr/bin/ditto --norsrc "${VST3_SOURCE}" "${STAGED_VST3}"
/usr/bin/ditto --norsrc "${AU_SOURCE}" "${STAGED_AU}"
/usr/bin/ditto --norsrc "${PROJECT_DIR}/packaging/pkg-scripts/postinstall" "${PACKAGE_SCRIPTS}/postinstall"
/bin/chmod 755 "${PACKAGE_SCRIPTS}/postinstall"

sign_bundle() {
    local bundle="$1"
    if [[ -n "${APPLICATION_IDENTITY}" ]]; then
        /usr/bin/codesign --force --deep --options runtime --timestamp \
            --sign "${APPLICATION_IDENTITY}" "${bundle}"
    else
        /usr/bin/codesign --force --deep --sign - "${bundle}"
    fi
}

sign_bundle "${STAGED_VST3}"
sign_bundle "${STAGED_AU}"
/usr/bin/xattr -rc "${STAGED_VST3}" "${STAGED_AU}" 2>/dev/null || true
# Remove any physical AppleDouble files that may have been present in an input
# bundle. macOS may still encode its protected provenance xattr in the package;
# that metadata is not a plugin resource and is recreated by the system.
find "${PACKAGE_ROOT}" \( -name '._*' -o -name '.__*' \) -type f -delete
verify_universal_bundle "${STAGED_VST3}" 1
verify_universal_bundle "${STAGED_AU}" 1

/usr/bin/pkgbuild \
    --root "${PACKAGE_ROOT}" \
    --scripts "${PACKAGE_SCRIPTS}" \
    --identifier com.gulldsp.circulate.pkg \
    --version "${VERSION}" \
    --install-location / \
    "${UNSIGNED_PKG}"

if [[ -n "${INSTALLER_IDENTITY}" ]]; then
    /usr/bin/productsign --sign "${INSTALLER_IDENTITY}" "${UNSIGNED_PKG}" "${FINAL_PKG}"
else
    /usr/bin/ditto --norsrc "${UNSIGNED_PKG}" "${FINAL_PKG}"
fi

UNINSTALLER_APP="${DMG_ROOT}/${DMG_UNINSTALLER_NAME}"
mkdir -p "${UNINSTALLER_APP}/Contents/MacOS"
mkdir -p "${UNINSTALLER_APP}/Contents/Resources"

MACOS_SDK="$(xcrun --sdk macosx --show-sdk-path)"
SWIFT_MODULE_CACHE="${WORK_DIR}/swift-module-cache"
mkdir -p "${SWIFT_MODULE_CACHE}"
for architecture in arm64 x86_64; do
    xcrun swiftc -O -target "${architecture}-apple-macos11.0" -sdk "${MACOS_SDK}" \
        -module-cache-path "${SWIFT_MODULE_CACHE}" \
        -framework AppKit \
        "${PROJECT_DIR}/packaging/CirculateUninstaller.swift" \
        -o "${WORK_DIR}/CirculateUninstaller-${architecture}"
done
/usr/bin/lipo -create \
    "${WORK_DIR}/CirculateUninstaller-arm64" \
    "${WORK_DIR}/CirculateUninstaller-x86_64" \
    -output "${UNINSTALLER_APP}/Contents/MacOS/Circulate Uninstaller"
/usr/bin/ditto --norsrc "${PROJECT_DIR}/packaging/uninstaller-Info.plist" "${UNINSTALLER_APP}/Contents/Info.plist"
/usr/bin/ditto --norsrc "${PROJECT_DIR}/packaging/uninstall-root.sh" "${UNINSTALLER_APP}/Contents/Resources/uninstall-root.sh"
/usr/bin/ditto --norsrc "${PROJECT_DIR}/packaging/CirculateUninstaller.icns" "${UNINSTALLER_APP}/Contents/Resources/CirculateUninstaller.icns"
/bin/chmod 755 "${UNINSTALLER_APP}/Contents/MacOS/Circulate Uninstaller"
/bin/chmod 755 "${UNINSTALLER_APP}/Contents/Resources/uninstall-root.sh"

if [[ -n "${APPLICATION_IDENTITY}" ]]; then
    /usr/bin/codesign --force --options runtime --timestamp \
        --sign "${APPLICATION_IDENTITY}" "${UNINSTALLER_APP}"
else
    /usr/bin/codesign --force --sign - "${UNINSTALLER_APP}"
fi
/usr/bin/xattr -rc "${UNINSTALLER_APP}" 2>/dev/null || true
/usr/bin/codesign --verify --deep --strict "${UNINSTALLER_APP}"

/usr/bin/ditto --norsrc "${FINAL_PKG}" "${DMG_ROOT}/${DMG_INSTALLER_NAME}"
/usr/bin/ditto --norsrc "${PROJECT_DIR}/packaging/README-DMG.txt" "${DMG_ROOT}/${DMG_README_NAME}"
/usr/bin/ditto --norsrc "${PROJECT_DIR}/work/Circulate-VST/LICENSE.txt" "${COPYRIGHT_DIR}/GPL-3.0许可证.txt"
/usr/bin/ditto --norsrc "${PROJECT_DIR}/packaging/SOURCE-AND-MODIFICATIONS.txt" "${COPYRIGHT_DIR}/源码与修改说明.txt"

(
    cd "${DMG_ROOT}"
    /usr/bin/shasum -a 256 \
        "${DMG_INSTALLER_NAME}" \
        "${DMG_UNINSTALLER_NAME}/Contents/MacOS/Circulate Uninstaller" \
        "${DMG_README_NAME}" \
        > "${COPYRIGHT_DIR}/SHA256SUMS.txt"
)

# Do not carry the builder's quarantine/provenance resource attributes into the
# distributable disk image. Code signatures are stored in bundle files and are
# checked again after this cleanup.
/usr/bin/xattr -rc "${DMG_ROOT}" 2>/dev/null || true
/usr/bin/codesign --verify --deep --strict "${UNINSTALLER_APP}"

/usr/bin/hdiutil create \
    -volname "Circulate Installer" \
    -srcfolder "${DMG_ROOT}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov "${FINAL_DMG}"
/usr/bin/shasum -a 256 "${FINAL_DMG}" > "${FINAL_DMG_SHA}"

if [[ -n "${NOTARY_PROFILE}" ]]; then
    if [[ -z "${APPLICATION_IDENTITY}" || -z "${INSTALLER_IDENTITY}" ]]; then
        echo "Notarization requires both Developer ID identities." >&2
        exit 1
    fi
    xcrun notarytool submit "${FINAL_DMG}" --keychain-profile "${NOTARY_PROFILE}" --wait
    xcrun stapler staple "${FINAL_DMG}"
    xcrun stapler validate "${FINAL_DMG}"
fi

echo "Created: ${FINAL_PKG}"
echo "Created: ${FINAL_DMG}"
echo "Checksum: ${FINAL_DMG_SHA}"
