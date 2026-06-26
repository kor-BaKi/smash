package com.smash.api.activity;

import com.smash.domain.activity.ActivityType;
import lombok.Getter;

@Getter
public class ActivityUpdateRequest {

    private Boolean isCancelled;
    private ActivityType activityType;
}
