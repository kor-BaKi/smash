package com.smash.api.admin;

import com.smash.service.OtherGroupSummary;
import java.util.List;

public record OtherGroupItem(Long userId, String name, int count, List<OtherGroupActivityItem> activities) {

    public static OtherGroupItem from(OtherGroupSummary summary) {
        return new OtherGroupItem(
                summary.userId(), summary.name(), summary.count(),
                summary.activities().stream().map(OtherGroupActivityItem::from).toList());
    }
}
