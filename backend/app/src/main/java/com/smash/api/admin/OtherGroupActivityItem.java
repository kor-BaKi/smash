package com.smash.api.admin;

import com.smash.service.OtherGroupActivityView;
import java.time.LocalDate;

public record OtherGroupActivityItem(Long activityId, LocalDate date, String groupLabel) {

    public static OtherGroupActivityItem from(OtherGroupActivityView view) {
        return new OtherGroupActivityItem(
                view.activityId(), view.date(), GroupLabel.of(view.groupDayOfWeek(), view.groupTimeSlot()));
    }
}
