package com.smash.api.member;

import com.smash.api.admin.GroupLabel;
import com.smash.domain.activity.ActivityType;
import com.smash.service.ActivityTodayView;
import java.time.LocalDate;
import java.util.List;

public record TodayActivityItem(
        Long activityId,
        LocalDate activityDate,
        Long groupId,
        String groupLabel,
        ActivityType activityType,
        boolean isMyGroup,
        List<ClientParticipationType> availableButtons,
        MyParticipation myParticipation,
        boolean voteClosed
) {

    public record MyParticipation(ClientParticipationType type, Long targetActivityId) {
    }

    public static TodayActivityItem from(ActivityTodayView view) {
        MyParticipation myParticipation = (view.myParticipationType() == null)
                ? null
                : new MyParticipation(
                        ParticipationTypeMapper.toClient(view.myParticipationType()), view.myParticipationTargetActivityId());

        return new TodayActivityItem(
                view.activityId(),
                view.activityDate(),
                view.groupId(),
                GroupLabel.of(view.groupDayOfWeek(), view.groupTimeSlot()),
                view.activityType(),
                view.isMyGroup(),
                view.availableButtons().stream().map(ParticipationTypeMapper::toClient).toList(),
                myParticipation,
                view.voteClosed()
        );
    }
}
