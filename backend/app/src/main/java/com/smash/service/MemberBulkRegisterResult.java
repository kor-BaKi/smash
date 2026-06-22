package com.smash.service;

import java.util.List;

public record MemberBulkRegisterResult(
        List<MemberRegisterSucceeded> succeeded,
        List<MemberRegisterFailed> failed,
        int totalRequested
) {
}
