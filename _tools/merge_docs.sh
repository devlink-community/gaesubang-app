#!/bin/bash

# 스크립트 위치를 기반으로 프로젝트 루트로 이동
cd "$(dirname "$0")/.." || exit 1

# 이후는 기존대로 진행
OUTPUT_DIR="_tools"
OUTPUT_FILE="$OUTPUT_DIR/project_standard.md"

mkdir -p "$OUTPUT_DIR"
: > "$OUTPUT_FILE"

echo "> 📅 생성일시: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for FILE in $(find docs -type f -name "*.md" | sort); do
  echo "# 📄 $FILE" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  cat "$FILE" >> "$OUTPUT_FILE"
  echo -e "\n\n---\n\n" >> "$OUTPUT_FILE"
done

echo "✅ 문서 병합 완료: $OUTPUT_FILE"
