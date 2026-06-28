package com.smash.api.auth;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MemberRegisterResponse {

    private Long id;
    private String name;
    private String studentNo;
    private String status;

    @Getter
    @Builder
    public static class BulkResponse {
        private List<MemberRegisterResponse> succeeded;
        private List<FailedItem> failed;
        private int totalRequested;
        private int successCount;
    }

    @Getter
    @Builder
    public static class FailedItem {
        private String studentNo;
        private String reason;
    }
}
