import '../../core/error/error_messages.dart';

/// 로그인, 가입 화면과 `AuthNotifier`가 보여 주는 문구 전부.
///
/// - 말투는 해요체, 띄어쓰기는 "해 주세요", 용어는 용어 사전(부원, 가입, 임원 …)을 따른다.
///   `test/core/copy_rules_guard_test.dart`가 이 파일을 소스 스캔으로 지킨다
/// - 연결, 시간 초과, 서버, 세션 만료처럼 앱 전체에서 같은 뜻으로 쓰는 문구는 [ErrorMessages]의 상수를 그대로 가져온다
///   (같은 문구를 여기서 다시 적지 않는다. 테스트가 확인한다)
/// - 로그인 실패 문구는 계정이 있는지, 어떤 상태인지를 드러내지 않는다 (학번 없음, 비밀번호 오류, 계정 상태 모두 같은 문구)
/// - 서버가 내려준 문구는 이 화면들에 보이지 않는다. 상태 코드와 연결 상태만 보고 여기서 문구를 고른다
abstract final class AuthMessages {
  // ---- 로그인 화면 ----
  static const loginTitle = '다시 만나 반가워요';
  static const loginSubtitle = 'SMASH 계정으로 로그인하세요';
  static const studentNoLabel = '학번';
  static const passwordLabel = '비밀번호';
  static const loginButton = '로그인';
  static const noAccount = '아직 계정이 없나요?';
  static const signupButton = '가입하기';

  // ---- 입력 확인 (로그인과 가입 공통) ----
  static const studentNoRequired = '학번을 입력해 주세요.';
  static const passwordRequired = '비밀번호를 입력해 주세요.';

  // ---- 로그인 오류 (AuthNotifier.login) ----
  /// 인터넷에 연결되지 않았다
  static const loginOffline = ErrorMessages.offline;

  /// 응답이 오지 않았다
  static const loginTimeout = ErrorMessages.timeout;

  /// 서버가 잠시 시도를 막았다 (429)
  static const loginTooMany = '로그인을 너무 많이 시도했어요. 잠시 후 다시 시도해 주세요.';

  /// 서버가 거절했다. 학번이 없는지, 비밀번호가 틀렸는지, 계정 상태가 어떤지는 알리지 않는다 (400, 401, 403 등 모두)
  static const loginRejected = '로그인하지 못했어요. 학번과 비밀번호를 확인해 주세요.';

  /// 서버 문제 (5xx)
  static const loginServer = ErrorMessages.server;

  /// 그 밖의 예외
  static const loginUnknown = ErrorMessages.generic;

  // ---- 세션 만료 (AuthNotifier.expireSession) ----
  static const sessionExpired = ErrorMessages.unauthorized;

  // ---- 가입 화면 ----
  static const signupAppBarTitle = '가입';

  /// 단계 이름 (진행 표시)
  static const signupSteps = ['가입코드', '학번', '비밀번호'];
  static const next = '다음';
  static const codeLabel = '가입코드';
  static const codeTitle = '가입코드를 입력해 주세요';
  static const codeSubtitle = '동아리에서 받은 가입코드가 필요해요';
  static const codeRequired = '가입코드를 입력해 주세요.';
  static const studentNoTitle = '학번을 입력해 주세요';
  static const studentNoSubtitle = '로그인할 때 학번을 사용해요';
  static const passwordTitle = '비밀번호를 정해 주세요';
  static const passwordSubtitle = '4자 이상으로 입력해 주세요';
  static const passwordTooShort = '비밀번호는 4자 이상으로 입력해 주세요.';
  static const signupSubmit = '가입하기';
  static const backToFirst = '1단계로 가기';

  // ---- 가입 오류 (AuthNotifier.signup) ----
  static const signupOffline = ErrorMessages.offline;
  static const signupTimeout = ErrorMessages.timeout;
  static const signupTooMany = ErrorMessages.tooManyRequests;
  static const signupServer = ErrorMessages.server;

  /// 서버가 거절했다 (가입코드나 학번이 맞지 않거나 이미 가입한 학번 등. 어느 쪽인지는 알리지 않는다)
  static const signupRejected = '가입하지 못했어요. 가입코드와 학번을 확인해 주세요.';
}
