package com.smash.api.admin;

import com.smash.service.MemberBulkRegisterResult;
import java.util.List;

public record MemberBulkCreateResponse(
        List<SucceededItem> succeeded,
        List<FailedItem> failed,
        int totalRequested,
        int successCount
) {

    public record SucceededItem(String studentNo, Long id) {
    }

    public record FailedItem(String studentNo, String reason) {
    }

    public static MemberBulkCreateResponse from(MemberBulkRegisterResult result) {
        return new MemberBulkCreateResponse(
                result.succeeded().stream().map(s -> new SucceededItem(s.studentNo(), s.id())).toList(),
                result.failed().stream().map(f -> new FailedItem(f.studentNo(), f.reason())).toList(),
                result.totalRequested(),
                result.succeeded().size()
        );
    }
}
