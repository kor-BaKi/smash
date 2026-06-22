package com.smash.api.admin;

import java.util.List;

public record GroupsCreateResponse(List<GroupCreatedResponse> createdGroups) {
}
