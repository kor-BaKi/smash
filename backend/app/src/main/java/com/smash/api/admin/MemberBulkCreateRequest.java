package com.smash.api.admin;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

// 항목별 필드는 검증 어노테이션을 두지 않는다. 한 건이라도 빈 값이면 @Valid가 요청 전체를
// 400으로 막아버려서, A-2가 보장해야 할 "부분 성공"이 깨진다. 항목별 검증은 MemberService가
// 담당하고 그 결과가 failed 목록의 MISSING_REQUIRED로 나타난다.
public record MemberBulkCreateRequest(@NotEmpty(message = "members는 최소 1건 이상이어야 합니다.") List<MemberItem> members) {

    public record MemberItem(String name, String studentNo, String department, String phone, String joinTerm) {
    }
}
