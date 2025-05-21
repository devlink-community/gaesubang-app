import 'dart:math';

/// AI 응답 생성에 실패했을 때 사용할 폴백 콘텐츠를 제공하는 서비스
class FallbackService {
  final Random _random = Random();

  /// 기본 퀴즈 생성 - 스킬 영역에 따라 다른 폴백 퀴즈 제공
  Map<String, dynamic> getFallbackQuiz(String skillArea) {
    final skill = skillArea.toLowerCase();

    if (skill.contains('python')) {
      return _getPythonQuiz();
    } else if (skill.contains('flutter') || skill.contains('dart')) {
      return _getFlutterQuiz();
    } else if (skill.contains('javascript') || skill.contains('js')) {
      return _getJavaScriptQuiz();
    } else if (skill.contains('react')) {
      return _getReactQuiz();
    } else if (skill.contains('java')) {
      return _getJavaQuiz();
    } else if (skill.contains('c#') || skill.contains('csharp')) {
      return _getCSharpQuiz();
    }

    // 기본 컴퓨터 기초 퀴즈
    return _getBasicComputerQuiz();
  }

  /// 기본 학습 팁 생성 - 스킬 영역에 따라 다른 폴백 학습 팁 제공
  Map<String, dynamic> getFallbackStudyTip(String skillArea) {
    final skill = skillArea.toLowerCase();

    if (skill.contains('python')) {
      return _getPythonStudyTip();
    } else if (skill.contains('flutter') || skill.contains('dart')) {
      return _getFlutterStudyTip();
    } else if (skill.contains('javascript') || skill.contains('js')) {
      return _getJavaScriptStudyTip();
    } else if (skill.contains('react')) {
      return _getReactStudyTip();
    }

    // 기본 개발자 팁
    return _getBasicDeveloperTip();
  }

  // Python 퀴즈
  Map<String, dynamic> _getPythonQuiz() {
    return {
      "question": "Python에서 리스트 컴프리헨션의 주요 장점은 무엇인가요?",
      "options": [
        "메모리 사용량 증가",
        "코드가 더 간결하고 가독성이 좋아짐",
        "항상 더 빠른 실행 속도",
        "버그 방지 기능",
      ],
      "correctOptionIndex": 1,
      "explanation":
          "리스트 컴프리헨션은 반복문과 조건문을 한 줄로 작성할 수 있어 코드가 더 간결해지고 가독성이 향상됩니다.",
      "relatedSkill": "Python",
    };
  }

  // Flutter 퀴즈
  Map<String, dynamic> _getFlutterQuiz() {
    return {
      "question": "Flutter에서 StatefulWidget과 StatelessWidget의 주요 차이점은 무엇인가요?",
      "options": [
        "StatefulWidget만 빌드 메서드를 가짐",
        "StatelessWidget이 더 성능이 좋음",
        "StatefulWidget은 내부 상태를 가질 수 있음",
        "StatelessWidget은 항상 더 적은 메모리를 사용함",
      ],
      "correctOptionIndex": 2,
      "explanation":
          "StatefulWidget은 내부 상태를 가지고 상태가 변경될 때 UI가 업데이트될 수 있지만, StatelessWidget은 불변이며 내부 상태를 가질 수 없습니다.",
      "relatedSkill": "Flutter",
    };
  }

  // JavaScript 퀴즈
  Map<String, dynamic> _getJavaScriptQuiz() {
    return {
      "question": "JavaScript에서 const와 let의 주요 차이점은 무엇인가요?",
      "options": [
        "const는 객체를 불변으로 만들지만, let은 가변 객체를 선언합니다.",
        "const로 선언된 변수는 재할당할 수 없지만, let은 가능합니다.",
        "const는 함수 스코프, let은 블록 스코프를 가집니다.",
        "const는 호이스팅되지 않지만, let은 호이스팅됩니다.",
      ],
      "correctOptionIndex": 1,
      "explanation":
          "const로 선언된 변수는 재할당할 수 없지만, let으로 선언된 변수는 재할당이 가능합니다. 둘 다 블록 스코프를 가집니다.",
      "relatedSkill": "JavaScript",
    };
  }

  // React 퀴즈
  Map<String, dynamic> _getReactQuiz() {
    return {
      "question": "React에서 hooks의 주요 규칙 중 하나는 무엇인가요?",
      "options": [
        "클래스 컴포넌트에서만 사용 가능하다",
        "반복문, 조건문, 중첩 함수 내에서 호출해야 한다",
        "컴포넌트 내부 최상위 레벨에서만 호출해야 한다",
        "항상 useEffect 내부에서 호출해야 한다",
      ],
      "correctOptionIndex": 2,
      "explanation":
          "React Hooks는 컴포넌트 최상위 레벨에서만 호출해야 하며, 반복문, 조건문, 중첩 함수 내에서 호출하면 안 됩니다. 이는 React가 hooks의 호출 순서에 의존하기 때문입니다.",
      "relatedSkill": "React",
    };
  }

  // Java 퀴즈
  Map<String, dynamic> _getJavaQuiz() {
    return {
      "question": "Java에서 'final' 키워드의 주요 용도는 무엇인가요?",
      "options": ["메서드 오버라이딩 방지", "변수를 상수로 만들기", "클래스 상속 방지", "위의 모든 것"],
      "correctOptionIndex": 3,
      "explanation":
          "Java에서 'final' 키워드는 변수를 상수로 만들거나, 메서드 오버라이딩을 방지하거나, 클래스 상속을 방지하는 데 사용될 수 있습니다.",
      "relatedSkill": "Java",
    };
  }

  // C# 퀴즈
  Map<String, dynamic> _getCSharpQuiz() {
    return {
      "question": "C#에서 'var' 키워드의 주요 특징은 무엇인가요?",
      "options": [
        "동적 타입을 선언한다 (런타임에 타입이 결정됨)",
        "컴파일 시점에 타입이 추론되는 암시적 타입 선언이다",
        "전역 변수로만 사용할 수 있다",
        "항상 null 값을 가지고 시작한다",
      ],
      "correctOptionIndex": 1,
      "explanation":
          "C#에서 'var'는 암시적 타입 선언으로, 컴파일러가 할당된 값에 기반하여 컴파일 시점에 변수의 타입을 추론합니다. dynamic과 달리 var는 컴파일 타임에 타입이 결정됩니다.",
      "relatedSkill": "C#",
    };
  }

  // 기본 컴퓨터 지식 퀴즈
  Map<String, dynamic> _getBasicComputerQuiz() {
    final quizzes = [
      {
        "question": "컴퓨터에서 1바이트는 몇 비트로 구성되어 있나요?",
        "options": ["4비트", "8비트", "16비트", "32비트"],
        "correctOptionIndex": 1,
        "explanation": "1바이트는 8비트로 구성되며, 컴퓨터 메모리의 기본 단위입니다.",
        "relatedSkill": "컴퓨터 기초",
      },
      {
        "question": "다음 중 관계형 데이터베이스가 아닌 것은?",
        "options": ["MySQL", "PostgreSQL", "MongoDB", "Oracle"],
        "correctOptionIndex": 2,
        "explanation":
            "MongoDB는 NoSQL 데이터베이스로, 문서 지향(Document-oriented) 데이터베이스입니다. 나머지는 모두 관계형 데이터베이스입니다.",
        "relatedSkill": "데이터베이스",
      },
      {
        "question": "HTTP 상태 코드 404는 무엇을 의미하나요?",
        "options": ["성공", "서버 오류", "리다이렉션", "리소스를 찾을 수 없음"],
        "correctOptionIndex": 3,
        "explanation": "HTTP 상태 코드 404는 클라이언트가 요청한 리소스를 서버가 찾을 수 없음을 의미합니다.",
        "relatedSkill": "웹 개발",
      },
    ];

    // 랜덤하게 하나 선택
    return quizzes[_random.nextInt(quizzes.length)];
  }

  // Python 학습 팁
  Map<String, dynamic> _getPythonStudyTip() {
    return {
      "title": "파이썬 학습 시 실습 중심으로 접근하기",
      "content":
          "파이썬을 효과적으로 배우려면 단순히 읽는 것보다 직접 코드를 작성해보는 것이 중요합니다. 작은 프로젝트를 만들거나 코딩 챌린지를 통해 학습하는 것이 효과적입니다. 또한 파이썬의 공식 문서와 함께 Stack Overflow를 적극 활용하세요.",
      "relatedSkill": "Python",
      "englishPhrase": "Readability counts.",
      "translation": "가독성이 중요하다.",
      "source": "The Zen of Python",
    };
  }

  // Flutter 학습 팁
  Map<String, dynamic> _getFlutterStudyTip() {
    return {
      "title": "Flutter 개발자를 위한 위젯 이해하기",
      "content":
          "Flutter에서 모든 것은 위젯입니다. StatefulWidget과 StatelessWidget의 차이를 확실히 이해하고 각각 언제 사용해야 하는지 파악하는 것이 중요합니다. Flutter 개발자 도구를 활용해 위젯 트리를 분석하고 성능 이슈를 디버깅하세요.",
      "relatedSkill": "Flutter",
      "englishPhrase": "Everything is a widget.",
      "translation": "모든 것이 위젯이다.",
      "source": "Flutter 공식 문서",
    };
  }

  // JavaScript 학습 팁
  Map<String, dynamic> _getJavaScriptStudyTip() {
    return {
      "title": "JavaScript 비동기 처리 마스터하기",
      "content":
          "JavaScript에서 비동기 처리는 웹 개발의 핵심입니다. Callback에서 시작해 Promise, 그리고 async/await까지 순차적으로 학습하세요. 각 방식의 장단점을 이해하고 적절한 상황에 활용할 수 있어야 합니다. 실제 API를 호출하는 작은 프로젝트로 연습해보세요.",
      "relatedSkill": "JavaScript",
      "englishPhrase":
          "Callbacks are the foundation of asynchronous programming.",
      "translation": "콜백은 비동기 프로그래밍의 기초이다.",
      "source": "JavaScript: The Good Parts",
    };
  }

  // React 학습 팁
  Map<String, dynamic> _getReactStudyTip() {
    return {
      "title": "React 상태 관리 전략",
      "content":
          "React에서는 상태 관리가 핵심입니다. 작은 프로젝트에서는 Context API와 useReducer를 활용해보고, 규모가 커질수록 Redux나 Zustand 같은 외부 라이브러리를 도입하세요. 상태를 너무 깊게 중첩하지 말고 필요한 곳에서만 최소한으로 사용하는 것이 중요합니다.",
      "relatedSkill": "React",
      "englishPhrase": "Lift state up, push effects down.",
      "translation": "상태는 위로 올리고, 효과는 아래로 내리세요.",
      "source": "React 디자인 패턴",
    };
  }

  // 기본 개발자 팁
  Map<String, dynamic> _getBasicDeveloperTip() {
    final tips = [
      {
        "title": "개발자를 위한 시간 관리 팁",
        "content":
            "효과적인 개발을 위해서는 '딥 워크'가 필요합니다. 2-3시간 동안 방해 없이 집중할 수 있는 환경을 만드세요. 알림을 끄고, 동료들에게 집중 시간임을 알리고, 소음 차단 헤드폰을 활용하세요. 포모도로 기법(25분 집중 + 5분 휴식)도 효과적입니다.",
        "relatedSkill": "프로그래밍 기초",
        "englishPhrase": "Premature optimization is the root of all evil.",
        "translation": "때 이른 최적화는 모든 악의 근원이다.",
        "source": "Donald Knuth",
      },
      {
        "title": "문서화의 중요성",
        "content":
            "코드는 작성할 때만 의미가 있는 것이 아니라, 유지보수할 때 더 큰 의미가 있습니다. 코드 주석과 README를 꼼꼼히 작성하고, API 문서와 아키텍처 다이어그램을 만들어두세요. 미래의 당신과 동료들이 감사할 것입니다.",
        "relatedSkill": "개발 프로세스",
        "englishPhrase": "Code tells you how, comments tell you why.",
        "translation": "코드는 어떻게 하는지, 주석은 왜 하는지를 알려준다.",
        "source": "Clean Code",
      },
      {
        "title": "꾸준한 코드 리뷰의 힘",
        "content":
            "코드 리뷰는 단순히 버그를 찾는 과정이 아닙니다. 팀의 지식을 공유하고, 코딩 스타일을 일관되게 유지하며, 서로의 성장을 돕는 중요한 과정입니다. 방어적이지 말고 피드백을 열린 마음으로 받아들이세요.",
        "relatedSkill": "팀 협업",
        "englishPhrase": "Review the code, not the coder.",
        "translation": "코드를 리뷰하되, 코더를 리뷰하지 마라.",
        "source": "Google Engineering Practices",
      },
    ];

    // 랜덤하게 하나 선택
    return tips[_random.nextInt(tips.length)];
  }
}
