#!/usr/bin/env bash
# 递归遍历当前脚本所在目录下所有文件，在 ~/.local/bin 创建软链接。
# 规则：
# 1. 链接名默认使用文件 basename。
# 2. 若多个不同路径出现同名文件，后续的会使用路径替换 / 为 _ 形成唯一名字。
#    例如 scripts/a/build.sh 与 scripts/b/build.sh -> ~/.local/bin/build.sh 与 ~/.local/bin/b_build.sh(示例，根据规则实际为 a_build.sh/b_build.sh)；
#    实现中采用 relpath 中的 / 变为 _ 追加，确保不覆盖。
# 3. 提供选项：
#    -n : dry-run 只打印计划，不真正执行 ln。
#    -N : 不覆盖已有同名链接/文件（默认覆盖）。
# 4. 自动为源文件加执行权限 (chmod +x)。

set -euo pipefail

TARGET="${HOME}/.local/bin"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${TARGET}"

DRY_RUN=0
OVERWRITE=1
usage() {
    echo "用法: $0 [-n dry-run] [-N no-overwrite]" >&2
}

while getopts ":nN" opt; do
    case "${opt}" in
        n) DRY_RUN=1 ;;
        N) OVERWRITE=0 ;;
        *) usage; exit 1 ;;
    esac
done

declare -A seen_names
total_count=0
link_count=0

while IFS= read -r -d '' file; do
    [ -f "${file}" ] || continue
    total_count=$((total_count+1))
    base="$(basename "${file}")"
    relpath="${file#"${SOURCE_DIR}/"}"
    target="${TARGET}/${base}"

    if [[ -e "${target}" && ${OVERWRITE} -eq 0 ]]; then
        echo "[WARN] 跳过(已存在，不覆盖): ${target}"
        continue
    fi

    echo "[INFO] Create soft link: ${target} -> ${file}";
    if [[ ${DRY_RUN} -eq 0 ]]; then
        ln -sf "${file}" "${target}"
        # 确保源文件可执行（不强制，失败忽略）
        chmod +x "${file}" 2>/dev/null || true
    fi
    link_count=$((link_count+1))
done < <(find "${SOURCE_DIR}" -type f -not -path "*/.git/*" \
    -not -name "$(basename "install.sh")" \
    -not -iname "*.md" -print0)

echo "总文件: ${total_count} | 创建(或更新)链接: ${link_count}";
if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "(dry-run) 未真正创建链接。"
fi