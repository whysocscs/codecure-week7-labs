# 제3자 참고 자료 및 라이선스

아래 저장소의 README, LICENSE, 파일 트리 및 관련 소스를 확인하고 시나리오 분류와 교육 흐름을 참고했습니다. 이 프로젝트는 원본 코드를 복사하지 않은 독립 구현이며 원본의 의존성도 그대로 이식하지 않았습니다. 각 저장소에 명시된 라이선스와 저작권은 다음과 같습니다. 확인 시점은 2026-11-09이며 커밋은 조회 당시 기본 브랜치의 HEAD입니다.

| 저장소 | 확인한 HEAD | 원본 저작권 | 주요 확인 영역 |
|---|---|---|---|
| [txdadlab/prompt-injection-lab](https://github.com/txdadlab/prompt-injection-lab) | `e20af8647c4272ee8d0503122022be1821841da4` | Copyright (c) 2026 txdadlab | FastAPI, levels, server, defenses, static, requirements |
| [eyemnv/prompt-injection-scanner](https://github.com/eyemnv/prompt-injection-scanner) | `60e6417cfb93a0d432d8548003ba0477e721c1cf` | Copyright (c) 2026 eyemnv | mock chatbot, document summarizer, payloads, scanner, demo; 기본 데모 외부 의존성 없음 |
| [Serathill/prompt-injection-playground](https://github.com/Serathill/prompt-injection-playground) | `bd6959d75da4b8f9511389c67c5e3cebf7cbe8fc` | Copyright (c) 2026 DeviDevs Technologies S.R.L. | DIR-001, DIR-002, JB-003, 간접 문서 주입 YAML 및 보고 도구 |
| [akanjilal-work/llm-security-lab](https://github.com/akanjilal-work/llm-security-lab) | `3d4ee8e886864328effda6b2811f3d6533879b16` | Copyright (c) 2026 akanjilal.dev | vulnerable/hardened chat 및 summarize, mock, tests; FastAPI는 선택 의존성 |
| [ppradyoth/prompt-injection-ctf](https://github.com/ppradyoth/prompt-injection-ctf) | `1a98bebb09ace179ffc7abe999f58672ce004d2e` | Copyright (c) 2026 Pradyoth Prashanth | 학습 화면과 방어 흐름; Next.js/Firebase 스택은 도입하지 않음 |

다섯 저장소 모두 MIT 라이선스를 사용합니다. 아래는 각 원본의 MIT 공통 허가 문구입니다. 위 표의 각 저작권 고지와 함께 읽어야 합니다. 이 표시는 이 프로젝트의 독립 작성 코드에 타인의 저작권을 주장하는 뜻이 아닙니다.

```text
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

이론적 구분: Zou et al., [Universal and Transferable Adversarial Attacks on Aligned Language Models](https://arxiv.org/abs/2307.15043). 본 앱은 해당 논문의 코드나 최적화 기법을 포함하지 않습니다.

## 글꼴

[**Pretendard Variable**](https://github.com/orioncactus/pretendard)는 SIL Open Font License 1.1로 배포됩니다. 원본 저작권 고지와 전체 라이선스는 [PRETENDARD-LICENSE.txt](static/fonts/PRETENDARD-LICENSE.txt)에 포함했습니다.
