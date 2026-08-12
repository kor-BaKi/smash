package com.smash.api.transport;

import com.smash.domain.group.Group;
import jakarta.validation.constraints.NotEmpty;
import lombok.Getter;

import java.util.List;

@Getter
public class TransportGroupRequest {

    @NotEmpty(message = "그룹 목록을 입력해주세요.")
    private List<Group> groups;

    @Getter
    public static class Group {
        @NotEmpty(message = "그룹 멤버를 입력해주세요.")
        private List<Long> memberIds;
    }
}
