package com.smash.api.attendent;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ShortfallResponse {

    private Long userId;
    private String name;
    private String groupLabel;
    private int fulfilled;
    private int guaranteed;
    private int shortfall;

}
