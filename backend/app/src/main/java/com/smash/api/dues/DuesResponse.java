package com.smash.api.dues;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.smash.domain.user.User;
import lombok.Builder;
import lombok.Getter;

@Builder
public class DuesResponse {
    private Long userId;
    private String name;        // 화면에 이름, 학번 표시할때 사용
    private String studentNo;
    private Long groupId;       // 각 조별로 구분할 때 사용
    private boolean isPaid;     // 체크박스


    public Long getUserId() { return userId; }
    public String getName() { return name; }
    public String getStudentNo() { return studentNo; }
    public Long getGroupId() { return groupId; }

    @JsonProperty("isPaid")
    public boolean isPaid() { return isPaid; }

    public static DuesResponse of(User user, boolean isPaid) {
        return DuesResponse.builder()
                .userId(user.getId())
                .name(user.getName())
                .studentNo(user.getStudentNo())
                .groupId(user.getGroupId())
                .isPaid(isPaid)
                .build();
    }
}
