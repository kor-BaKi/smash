package com.smash.service;

import java.util.List;

public record OtherGroupSummary(Long userId, String name, int count, List<OtherGroupActivityView> activities) {
}
