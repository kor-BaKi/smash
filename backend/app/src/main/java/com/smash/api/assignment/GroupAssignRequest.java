package com.smash.api.assignment;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class GroupAssignRequest {

    @NotNull
    private Long groupId;
}