# 🛠 문서 병합 스크립트

이 폴더에는 `docs/` 아래의 모든 마크다운 문서를 하나로 병합하는 스크립트(`merge_docs.sh`)가 포함되어 있습니다.  
병합 결과는 이 폴더 내 `project_standard.md` 파일로 생성되며, ChatGPT 등 외부 협업 도구에서 참고용으로 사용됩니다.

---

## ✅ 사용법

### ▶ 일반 사용 (VSCode, macOS/Linux)

```bash
bash _tools/merge_docs.sh
```

또는 실행 권한 부여 후:

```bash
chmod +x _tools/merge_docs.sh
./_tools/merge_docs.sh
```

---

### 🪟 Windows + Android Studio 사용자

#### 1. Git Bash 설치

[https://git-scm.com/download/win](https://git-scm.com/download/win)  
설치 중 "Git Bash Here" 옵션을 포함하도록 진행합니다.

#### 2. Android Studio 설정

- 메뉴: `File > Settings > Tools > Terminal`
- **Shell path**를 아래로 설정:

```
C:\Program Files\Git\bin\bash.exe
```

(*Git 설치 경로에 따라 달라질 수 있습니다*)

#### 3. 스크립트 실행

- `merge_docs.sh` 파일 열기
- 상단에 나타나는 ▶ 버튼 클릭 (또는 터미널에서 수동 실행)

---

## 📦 병합 결과

- 경로: `_tools/project_standard.md`
- 내용: `docs/` 하위의 모든 `.md` 파일을 정렬하여 하나로 병합
- 구성: 각 파일의 경로를 주석으로 포함하고, 구분선(`---`)으로 나눔

---

## 🛡 스크립트 유지보수 규칙

- `docs/` 폴더 하위에 새로운 디렉토리나 파일이 추가되어도 스크립트는 자동으로 모두 병합합니다.
- `.md` 확장자가 아닌 파일은 자동으로 무시합니다.
- 특별한 이유(예: 특정 폴더 제외)가 없다면 `merge_docs.sh` 수정은 필요 없습니다.
- 스크립트를 수정해야 하는 경우, 병합 대상 디렉토리나 파일 확장자 패턴만 조심해서 수정해 주세요.

---

## 🧽 주의사항

- 병합된 파일은 항상 **최신 상태로 덮어쓰기**됩니다.
- 내부에서 사용하는 참고용 문서이며, 버전관리 필요 여부는 팀 기준에 맞게 결정하세요.

---

✅ 문서 기준 통일이 필요할 때마다 이 스크립트를 실행해 주세요.