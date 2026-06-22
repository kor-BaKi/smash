package com.smash.service;

public record MemberUnassignedView(Long userId, String name, UnassignedReason reason) {
}
