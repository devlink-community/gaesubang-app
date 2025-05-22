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

  /// 기본 학습 팁 생성 - 스킬 영역에 따라 다양한 폴백 학습 팁 제공
  Map<String, dynamic> getFallbackStudyTip(String skillArea) {
    final skill = skillArea.toLowerCase();

    if (skill.contains('python')) {
      return _getRandomPythonStudyTip();
    } else if (skill.contains('flutter') || skill.contains('dart')) {
      return _getRandomFlutterStudyTip();
    } else if (skill.contains('javascript') || skill.contains('js')) {
      return _getRandomJavaScriptStudyTip();
    } else if (skill.contains('react')) {
      return _getRandomReactStudyTip();
    } else if (skill.contains('java')) {
      return _getRandomJavaStudyTip();
    } else if (skill.contains('kotlin')) {
      return _getRandomKotlinStudyTip();
    } else if (skill.contains('swift')) {
      return _getRandomSwiftStudyTip();
    } else if (skill.contains('c#') || skill.contains('csharp')) {
      return _getRandomCSharpStudyTip();
    } else if (skill.contains('typescript') || skill.contains('ts')) {
      return _getRandomTypeScriptStudyTip();
    }

    // 기본 개발자 팁
    return _getRandomBasicDeveloperTip();
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

  // Python 학습 팁 (다양화)
  Map<String, dynamic> _getRandomPythonStudyTip() {
    final tips = [
      {
        "title": "파이썬 학습 시 실습 중심 접근",
        "content": "파이썬을 효과적으로 배우려면 단순히 읽는 것보다 직접 코드를 작성해보는 것이 중요합니다. 작은 프로젝트를 만들거나 코딩 챌린지를 통해 학습하는 것이 효과적입니다.",
        "relatedSkill": "Python",
        "englishPhrase": "Readability counts.",
        "translation": "가독성이 중요하다.",
        "source": "The Zen of Python",
      },
      {
        "title": "파이썬 디버깅 기법 마스터하기",
        "content": "print() 함수보다는 pdb 모듈이나 IDE의 디버거를 활용하세요. breakpoint() 함수를 사용하면 Python 3.7+에서 간편하게 디버깅할 수 있습니다.",
        "relatedSkill": "Python",
        "englishPhrase": "print() is not a debugger.",
        "translation": "print()는 디버거가 아니다.",
        "source": "Python 개발 모범사례",
      },
      {
        "title": "파이썬 가상환경 활용법",
        "content": "프로젝트마다 독립적인 가상환경을 만들어 패키지 의존성 문제를 해결하세요. venv, conda, poetry 등 다양한 도구를 상황에 맞게 선택할 수 있습니다.",
        "relatedSkill": "Python",
        "englishPhrase": "Virtual environments are essential.",
        "translation": "가상환경은 필수다.",
        "source": "Python 패키징 가이드",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // Flutter 학습 팁 (다양화)
  Map<String, dynamic> _getRandomFlutterStudyTip() {
    final tips = [
      {
        "title": "Flutter 위젯 트리 이해하기",
        "content": "Flutter에서 모든 것은 위젯입니다. StatefulWidget과 StatelessWidget의 차이를 확실히 이해하고 각각 언제 사용해야 하는지 파악하는 것이 중요합니다.",
        "relatedSkill": "Flutter",
        "englishPhrase": "Everything is a widget.",
        "translation": "모든 것이 위젯이다.",
        "source": "Flutter 공식 문서",
      },
      {
        "title": "Flutter 성능 최적화 팁",
        "content": "불필요한 위젯 재빌드를 방지하려면 const 생성자를 적극 활용하고, 상태가 자주 변경되는 부분만 별도 위젯으로 분리하세요. Flutter Inspector로 성능을 모니터링할 수 있습니다.",
        "relatedSkill": "Flutter",
        "englishPhrase": "Avoid unnecessary rebuilds.",
        "translation": "불필요한 재빌드를 피하라.",
        "source": "Flutter 성능 가이드",
      },
      {
        "title": "Flutter 상태 관리 선택하기",
        "content": "앱의 복잡도에 따라 적절한 상태 관리를 선택하세요. 간단한 앱은 setState, 중간 규모는 Provider나 Riverpod, 복잡한 앱은 BLoC 패턴을 고려해보세요.",
        "relatedSkill": "Flutter",
        "englishPhrase": "Choose the right state management.",
        "translation": "올바른 상태 관리를 선택하라.",
        "source": "Flutter 아키텍처 가이드",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // JavaScript 학습 팁 (다양화)
  Map<String, dynamic> _getRandomJavaScriptStudyTip() {
    final tips = [
      {
        "title": "JavaScript 비동기 처리 마스터하기",
        "content": "Callback에서 시작해 Promise, 그리고 async/await까지 순차적으로 학습하세요. 각 방식의 장단점을 이해하고 적절한 상황에 활용할 수 있어야 합니다.",
        "relatedSkill": "JavaScript",
        "englishPhrase": "Callbacks are the foundation of async programming.",
        "translation": "콜백은 비동기 프로그래밍의 기초이다.",
        "source": "JavaScript: The Good Parts",
      },
      {
        "title": "JavaScript ES6+ 최신 문법 활용",
        "content": "구조 분해 할당, 템플릿 리터럴, 화살표 함수 등 ES6+ 문법을 익혀 더 간결하고 읽기 쉬운 코드를 작성하세요. let/const를 사용해 var의 문제점을 해결할 수 있습니다.",
        "relatedSkill": "JavaScript",
        "englishPhrase": "Modern JavaScript is cleaner.",
        "translation": "최신 자바스크립트는 더 깔끔하다.",
        "source": "ES6 스펙 문서",
      },
      {
        "title": "JavaScript 타입 시스템 이해하기",
        "content": "동적 타입 언어인 JavaScript의 특성을 이해하고 === 연산자를 사용해 엄격한 비교를 하세요. TypeScript 도입을 고려해 타입 안전성을 높일 수 있습니다.",
        "relatedSkill": "JavaScript",
        "englishPhrase": "Type coercion can be tricky.",
        "translation": "타입 변환은 까다로울 수 있다.",
        "source": "You Don't Know JS",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // React 학습 팁 (다양화)
  Map<String, dynamic> _getRandomReactStudyTip() {
    final tips = [
      {
        "title": "React 상태 관리 전략",
        "content": "작은 프로젝트에서는 Context API와 useReducer를 활용해보고, 규모가 커질수록 Redux나 Zustand 같은 외부 라이브러리를 도입하세요.",
        "relatedSkill": "React",
        "englishPhrase": "Lift state up, push effects down.",
        "translation": "상태는 위로 올리고, 효과는 아래로 내리세요.",
        "source": "React 디자인 패턴",
      },
      {
        "title": "React Hooks 활용 팁",
        "content": "useEffect의 의존성 배열을 정확히 관리하고, 커스텀 훅을 만들어 로직을 재사용하세요. useCallback과 useMemo를 적절히 사용해 성능을 최적화할 수 있습니다.",
        "relatedSkill": "React",
        "englishPhrase": "Hooks make React simpler.",
        "translation": "훅이 리액트를 더 간단하게 만든다.",
        "source": "React Hooks 공식 문서",
      },
      {
        "title": "React 컴포넌트 설계 원칙",
        "content": "단일 책임 원칙을 따라 컴포넌트를 작게 나누고, props는 최소한으로 전달하세요. 재사용 가능한 컴포넌트를 만들어 개발 효율성을 높일 수 있습니다.",
        "relatedSkill": "React",
        "englishPhrase": "Keep components small and focused.",
        "translation": "컴포넌트는 작고 집중되게 유지하라.",
        "source": "React 컴포넌트 디자인",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // Java 학습 팁 (새로 추가)
  Map<String, dynamic> _getRandomJavaStudyTip() {
    final tips = [
      {
        "title": "Java OOP 원칙 이해하기",
        "content": "캡슐화, 상속, 다형성, 추상화의 4가지 OOP 원칙을 실제 코드에 적용해보세요. 인터페이스와 추상 클래스의 차이를 명확히 이해하는 것이 중요합니다.",
        "relatedSkill": "Java",
        "englishPhrase": "Encapsulation is key to maintainable code.",
        "translation": "캡슐화는 유지보수 가능한 코드의 핵심이다.",
        "source": "Effective Java",
      },
      {
        "title": "Java 메모리 관리 이해하기",
        "content": "Heap과 Stack 메모리의 차이를 이해하고, 가비지 컬렉션의 동작 원리를 파악하세요. 메모리 누수를 방지하려면 참조를 적절히 해제하는 것이 중요합니다.",
        "relatedSkill": "Java",
        "englishPhrase": "Memory management matters in Java.",
        "translation": "자바에서 메모리 관리는 중요하다.",
        "source": "Java Performance Tuning",
      },
      {
        "title": "Java 8+ 스트림 API 활용",
        "content": "함수형 프로그래밍 패러다임을 도입한 Stream API를 활용해 컬렉션 처리를 더 간결하고 읽기 쉽게 만드세요. map, filter, reduce 등의 메서드를 숙지하세요.",
        "relatedSkill": "Java",
        "englishPhrase": "Streams make collections powerful.",
        "translation": "스트림이 컬렉션을 강력하게 만든다.",
        "source": "Modern Java in Action",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // Kotlin 학습 팁 (새로 추가)
  Map<String, dynamic> _getRandomKotlinStudyTip() {
    final tips = [
      {
        "title": "Kotlin null 안전성 활용하기",
        "content": "Kotlin의 강력한 null 안전성 기능을 활용하세요. ?와 ?: 연산자를 적절히 사용하고, let, run, apply 등의 스코프 함수로 null 처리를 깔끔하게 할 수 있습니다.",
        "relatedSkill": "Kotlin",
        "englishPhrase": "Null safety prevents runtime crashes.",
        "translation": "널 안전성이 런타임 크래시를 방지한다.",
        "source": "Kotlin 공식 문서",
      },
      {
        "title": "Kotlin 코루틴으로 비동기 처리",
        "content": "코루틴을 사용해 비동기 프로그래밍을 간단하게 처리하세요. suspend 함수와 async/await 패턴을 이해하면 콜백 지옥을 피할 수 있습니다.",
        "relatedSkill": "Kotlin",
        "englishPhrase": "Coroutines simplify async programming.",
        "translation": "코루틴이 비동기 프로그래밍을 간단하게 만든다.",
        "source": "Kotlin Coroutines Guide",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // Swift 학습 팁 (새로 추가)
  Map<String, dynamic> _getRandomSwiftStudyTip() {
    final tips = [
      {
        "title": "Swift 옵셔널 타입 마스터하기",
        "content": "Swift의 옵셔널 타입을 제대로 이해하고 if let, guard let 구문을 적절히 활용하세요. 옵셔널 체이닝과 nil 병합 연산자도 유용합니다.",
        "relatedSkill": "Swift",
        "englishPhrase": "Optionals make Swift safer.",
        "translation": "옵셔널이 Swift를 더 안전하게 만든다.",
        "source": "Swift Programming Language",
      },
      {
        "title": "Swift 프로토콜 지향 프로그래밍",
        "content": "Swift는 프로토콜 지향 프로그래밍을 지원합니다. 상속보다는 프로토콜을 활용해 코드의 유연성을 높이고, 익스텐션으로 기능을 확장하세요.",
        "relatedSkill": "Swift",
        "englishPhrase": "Protocol-oriented programming is powerful.",
        "translation": "프로토콜 지향 프로그래밍은 강력하다.",
        "source": "WWDC Protocol-Oriented Programming",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // C# 학습 팁 (새로 추가)
  Map<String, dynamic> _getRandomCSharpStudyTip() {
    final tips = [
      {
        "title": "C# LINQ 활용하기",
        "content": "LINQ(Language Integrated Query)를 사용해 컬렉션 처리를 더 직관적으로 만드세요. Where, Select, GroupBy 등의 메서드를 활용하면 SQL과 유사한 방식으로 데이터를 조작할 수 있습니다.",
        "relatedSkill": "C#",
        "englishPhrase": "LINQ makes data queries intuitive.",
        "translation": "LINQ가 데이터 쿼리를 직관적으로 만든다.",
        "source": "C# in Depth",
      },
      {
        "title": "C# async/await 패턴 이해하기",
        "content": "비동기 프로그래밍에서 async/await 패턴을 올바르게 사용하세요. Task와 ValueTask의 차이를 이해하고, ConfigureAwait(false)를 적절히 사용해 데드락을 방지하세요.",
        "relatedSkill": "C#",
        "englishPhrase": "Async/await improves responsiveness.",
        "translation": "async/await가 응답성을 향상시킨다.",
        "source": "C# Concurrency Cookbook",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

  // TypeScript 학습 팁 (새로 추가)
  Map<String, dynamic> _getRandomTypeScriptStudyTip() {
    final tips = [
      {
        "title": "TypeScript 타입 시스템 활용하기",
        "content": "인터페이스와 타입 별칭을 적절히 활용하고, 제네릭을 사용해 재사용 가능한 타입을 만드세요. 유니온 타입과 교차 타입도 강력한 도구입니다.",
        "relatedSkill": "TypeScript",
        "englishPhrase": "Types catch errors at compile time.",
        "translation": "타입이 컴파일 시점에 에러를 잡는다.",
        "source": "TypeScript Handbook",
      },
      {
        "title": "TypeScript 설정 최적화하기",
        "content": "tsconfig.json을 프로젝트에 맞게 설정하세요. strict 모드를 활성화하고, 적절한 target과 module 설정을 통해 최적의 빌드 결과를 얻을 수 있습니다.",
        "relatedSkill": "TypeScript",
        "englishPhrase": "Configuration matters for TypeScript.",
        "translation": "TypeScript에서는 설정이 중요하다.",
        "source": "TypeScript Deep Dive",
      },
    ];
    return tips[_random.nextInt(tips.length)];
  }

// 기본 개발자 팁 (다양화)
  Map<String, dynamic> _getRandomBasicDeveloperTip() {
    final tips = [
      {
        "title": "개발자를 위한 시간 관리 팁",
        "content": "효과적인 개발을 위해서는 '딥 워크'가 필요합니다. 2-3시간 동안 방해 없이 집중할 수 있는 환경을 만드세요. 포모도로 기법(25분 집중 + 5분 휴식)도 효과적입니다.",
        "relatedSkill": "프로그래밍 기초",
        "englishPhrase": "Deep work drives deep results.",
        "translation": "깊은 작업이 깊은 결과를 만든다.",
        "source": "Deep Work",
      },
      {
        "title": "문서화의 중요성",
        "content": "코드는 작성할 때만 의미가 있는 것이 아니라, 유지보수할 때 더 큰 의미가 있습니다. 코드 주석과 README를 꼼꼼히 작성하고, API 문서와 아키텍처 다이어그램을 만들어두세요.",
        "relatedSkill": "개발 프로세스",
        "englishPhrase": "Code tells you how, comments tell you why.",
        "translation": "코드는 어떻게 하는지, 주석은 왜 하는지를 알려준다.",
        "source": "Clean Code",
      },
      {
        "title": "꾸준한 코드 리뷰의 힘",
        "content": "코드 리뷰는 단순히 버그를 찾는 과정이 아닙니다. 팀의 지식을 공유하고, 코딩 스타일을 일관되게 유지하며, 서로의 성장을 돕는 중요한 과정입니다.",
        "relatedSkill": "팀 협업",
        "englishPhrase": "Review the code, not the coder.",
        "translation": "코드를 리뷰하되, 코더를 리뷰하지 마라.",
        "source": "Google Engineering Practices",
      },
      {
        "title": "버전 관리 시스템 활용하기",
        "content": "Git을 제대로 활용하세요. 커밋 메시지는 명확하게 작성하고, 브랜치 전략을 수립해 협업 효율을 높이세요. git rebase와 git merge의 차이를 이해하는 것도 중요합니다.",
        "relatedSkill": "개발 도구",
        "englishPhrase": "Good commits tell a story.",
        "translation": "좋은 커밋은 이야기를 들려준다.",
        "source": "Pro Git",
      },
      {
        "title": "테스트 주도 개발 실천하기",
        "content": "테스트를 먼저 작성하고 코드를 구현하는 TDD 방식을 연습하세요. 단위 테스트부터 시작해 통합 테스트까지 단계적으로 확장하면 버그 없는 코드를 작성할 수 있습니다.",
        "relatedSkill": "테스트",
        "englishPhrase": "Red, Green, Refactor.",
        "translation": "빨강, 초록, 리팩터.",
        "source": "Test Driven Development",
      },
      {
        "title": "지속적인 학습의 중요성",
        "content": "기술은 빠르게 변화하므로 지속적인 학습이 필수입니다. 온라인 강의, 기술 블로그, 오픈소스 프로젝트 참여 등을 통해 꾸준히 새로운 지식을 습득하세요.",
        "relatedSkill": "자기계발",
        "englishPhrase": "Stay curious, stay relevant.",
        "translation": "호기심을 유지하고, 관련성을 유지하라.",
        "source": "The Pragmatic Programmer",
      },
    ];

    // 랜덤하게 하나 선택
    return tips[_random.nextInt(tips.length)];
  }
}