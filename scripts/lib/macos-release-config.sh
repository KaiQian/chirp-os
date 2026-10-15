#!/bin/bash
# Local configuration is trusted shell code; never load configuration from a download.
load_macos_release_config() {
    local config="${CHIRPOS_RELEASE_CONFIG:-$ROOT/.local/macos-release.env}"
    local identity="${CHIRPOS_SIGNING_IDENTITY-}" profile="${CHIRPOS_NOTARY_PROFILE-}"
    if [[ -f "$config" ]]; then
        source "$config" || return 1
    elif [[ -n "${CHIRPOS_RELEASE_CONFIG:-}" ]]; then
        echo '指定的本地发布配置不存在 / Release configuration file not found.' >&2
        return 1
    fi
    # Nonempty environment settings take precedence over the local file.
    CHIRPOS_SIGNING_IDENTITY="${identity:-${CHIRPOS_SIGNING_IDENTITY:-}}"
    CHIRPOS_NOTARY_PROFILE="${profile:-${CHIRPOS_NOTARY_PROFILE:-}}"
    export CHIRPOS_SIGNING_IDENTITY CHIRPOS_NOTARY_PROFILE
}
check_macos_release_credentials() {
    if [[ -z "${CHIRPOS_SIGNING_IDENTITY:-}" || -z "${CHIRPOS_NOTARY_PROFILE:-}" ]]; then
        echo '缺少签名身份或公证配置名 / Missing signing identity or notarization profile.' >&2
        return 1
    fi
    if [[ "$CHIRPOS_SIGNING_IDENTITY" != 'Developer ID Application: '* ]]; then
        echo '需要 Developer ID Application 签名身份 / A Developer ID Application identity is required.' >&2
        return 1
    fi
    if ! security find-identity -v -p codesigning | grep -F -- "\"$CHIRPOS_SIGNING_IDENTITY\"" >/dev/null; then
        echo '钥匙串中未找到有效证书及私钥，或钥匙串不可访问 / Signing identity unavailable in the keychain.' >&2
        return 1
    fi
    if ! xcrun notarytool history --keychain-profile "$CHIRPOS_NOTARY_PROFILE" --output-format json >/dev/null; then
        echo '无法验证公证凭据，请检查钥匙串或网络 / Notarization credentials could not be verified; check keychain and network.' >&2
        return 1
    fi
}
